// Package main — VPS message broker for Aura Messenger.
// Runs alongside the headless Telemost creator.
// Routes messages between iOS clients connected via the same SFU room.
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"
)

// ── Message queue per room ──

type RoomQueue struct {
	Messages []QueuedMessage
	mu       sync.Mutex
}

type QueuedMessage struct {
	Text      string `json:"text"`
	SenderID  string `json:"sid"`
	Timestamp int64  `json:"ts"`
}

var (
	rooms   = make(map[string]*RoomQueue)
	roomsMu sync.RWMutex
)

func getRoom(uri string) *RoomQueue {
	roomsMu.Lock()
	defer roomsMu.Unlock()
	if r, ok := rooms[uri]; ok {
		return r
	}
	r := &RoomQueue{}
	rooms[uri] = r
	return r
}

// ── HTTP API ──

// POST /relay/send — iOS sends a message to be relayed.
func handleRelaySend(w http.ResponseWriter, r *http.Request) {
	var msg struct {
		URI      string `json:"uri"`
		Text     string `json:"text"`
		SenderID string `json:"sender_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&msg); err != nil {
		http.Error(w, "invalid json", 400)
		return
	}
	if msg.URI == "" || msg.Text == "" {
		http.Error(w, "uri and text required", 400)
		return
	}

	room := getRoom(msg.URI)
	room.mu.Lock()
	room.Messages = append(room.Messages, QueuedMessage{
		Text:      msg.Text,
		SenderID:  msg.SenderID,
		Timestamp: time.Now().UnixMilli(),
	})
	// Keep only last 100 messages per room
	if len(room.Messages) > 100 {
		room.Messages = room.Messages[len(room.Messages)-100:]
	}
	room.mu.Unlock()

	w.WriteHeader(200)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// GET /relay/poll?uri=...&since=... — iOS polls for new messages.
func handleRelayPoll(w http.ResponseWriter, r *http.Request) {
	uri := r.URL.Query().Get("uri")
	if uri == "" {
		http.Error(w, "uri required", 400)
		return
	}

	room := getRoom(uri)
	room.mu.Lock()
	msgs := room.Messages
	room.mu.Unlock()

	// Return all messages (client deduplicates by ID)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(msgs)
}

// POST /relay/join — notify broker that a client joined.
func handleRelayJoin(w http.ResponseWriter, r *http.Request) {
	var msg struct {
		URI      string `json:"uri"`
		SenderID string `json:"sender_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&msg); err != nil {
		http.Error(w, "invalid json", 400)
		return
	}
	log.Printf("[broker] %s joined %s", msg.SenderID, msg.URI)
	w.WriteHeader(200)
}

// POST /relay/leave — notify broker that a client left.
func handleRelayLeave(w http.ResponseWriter, r *http.Request) {
	var msg struct {
		URI      string `json:"uri"`
		SenderID string `json:"sender_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&msg); err != nil {
		http.Error(w, "invalid json", 400)
		return
	}
	log.Printf("[broker] %s left %s", msg.SenderID, msg.URI)
	w.WriteHeader(200)
}

// startBrokerAPI starts the broker HTTP server on the given port.
func startBrokerAPI(port string) {
	mux := http.NewServeMux()
	mux.HandleFunc("/relay/send", handleRelaySend)
	mux.HandleFunc("/relay/poll", handleRelayPoll)
	mux.HandleFunc("/relay/join", handleRelayJoin)
	mux.HandleFunc("/relay/leave", handleRelayLeave)

	log.Printf("[broker] Starting on :%s", port)
	go func() {
		if err := http.ListenAndServe(":"+port, mux); err != nil {
			log.Fatalf("[broker] Failed: %v", err)
		}
	}()
}
