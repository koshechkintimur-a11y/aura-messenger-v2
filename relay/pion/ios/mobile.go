// Package ios provides gomobile-compatible bindings for Aura Messenger on iOS.
// Build: gomobile bind -target=ios -o AuraRelay.xcframework ./relay/pion/ios
package ios

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"

	"aura-v2/relay/messenger"
)

// ── Callback interface (implemented in Swift) ──

// AuraCallback receives events from the Go relay.
type AuraCallback interface {
	OnMessage(text string)       // JSON message received
	OnConnected()                // Tunnel connected
	OnDisconnected(reason string) // Tunnel disconnected
	OnLog(msg string)            // Debug log
}

// ── Global state ──

var (
	activeSession *messenger.Session
	activeBroker  *messenger.BrokerClient
	callback      AuraCallback
	mu            sync.Mutex
	connected     bool
)

// logf sends log to Swift callback and Go logger.
func logf(format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	log.Printf("[AuraRelay] %s", msg)
	mu.Lock()
	cb := callback
	mu.Unlock()
	if cb != nil {
		cb.OnLog(msg)
	}
}

// ── Exported functions (called from Swift) ──

// AuraInit initializes the relay with the broker URL and callback.
func AuraInit(brokerURL string, cb AuraCallback) {
	mu.Lock()
	defer mu.Unlock()
	activeBroker = messenger.NewBrokerClient(brokerURL)
	callback = cb
	logf("Initialized with broker: %s", brokerURL)
}

// AuraCreateRoom creates a new room and connects.
func AuraCreateRoom(senderID string) {
	go func() {
		mu.Lock()
		broker := activeBroker
		mu.Unlock()
		if broker == nil {
			notifyDisconnected("not initialized")
			return
		}

		info, err := broker.CreateRoom()
		if err != nil {
			notifyDisconnected(fmt.Sprintf("create room: %v", err))
			return
		}
		logf("Room created: %s", info.URI)

		// Create session with ephemeral key
		session, err := messenger.NewSession(info.URI, "", senderID, onMessage)
		if err != nil {
			notifyDisconnected(fmt.Sprintf("session: %v", err))
			return
		}

		mu.Lock()
		activeSession = session
		mu.Unlock()

		// TODO: connect WebRTC tunnel
		notifyConnected()

		// Send room info as JSON to Swift
		infoJSON, _ := json.Marshal(map[string]string{
			"type":      "room_created",
			"uri":       info.URI,
			"join_url":  info.JoinURL,
			"peer_id":   info.PeerID,
			"room_id":   info.RoomID,
		})
		dispatchMessage(string(infoJSON))
	}()
}

// AuraJoinRoom joins an existing room by URI.
func AuraJoinRoom(uri, senderID string) {
	go func() {
		mu.Lock()
		broker := activeBroker
		mu.Unlock()
		if broker == nil {
			notifyDisconnected("not initialized")
			return
		}

		_, err := broker.JoinRoom(uri)
		if err != nil {
			notifyDisconnected(fmt.Sprintf("join room: %v", err))
			return
		}
		logf("Joined room: %s", uri)

		session, err := messenger.NewSession(uri, "", senderID, onMessage)
		if err != nil {
			notifyDisconnected(fmt.Sprintf("session: %v", err))
			return
		}

		mu.Lock()
		activeSession = session
		mu.Unlock()

		// TODO: connect WebRTC tunnel
		notifyConnected()

		// Send join message through tunnel
		joinMsg := messenger.NewJoinMessage(senderID)
		encrypted, _ := session.SendMessage(joinMsg)
		_ = encrypted // TODO: send through tunnel
	}()
}

// AuraSendText sends a text message.
func AuraSendText(text, replyTo string) {
	mu.Lock()
	session := activeSession
	sender := ""
	if session != nil {
		sender = session.SenderID
	}
	mu.Unlock()

	if session == nil {
		logf("SendText: no active session")
		return
	}

	msg := messenger.NewTextMessage(sender, text, replyTo)
	encrypted, err := session.SendMessage(msg)
	if err != nil {
		logf("SendText: encrypt error: %v", err)
		return
	}
	_ = encrypted // TODO: send through tunnel
}

// AuraSendImage sends an image (JPEG data).
func AuraSendImage(jpegData []byte, fileName string) {
	mu.Lock()
	session := activeSession
	sender := ""
	if session != nil {
		sender = session.SenderID
	}
	mu.Unlock()

	if session == nil {
		logf("SendImage: no active session")
		return
	}

	chunks := messenger.NewMediaChunks(sender, "image", fileName, jpegData)
	for _, chunk := range chunks {
		encrypted, err := session.SendMessage(chunk)
		if err != nil {
			logf("SendImage: encrypt chunk error: %v", err)
			continue
		}
		_ = encrypted // TODO: send through tunnel
	}
}

// AuraSendTagInvite sends a tag invite through the broker.
func AuraSendTagInvite(tag, uri, chatName, inviter string) {
	go func() {
		mu.Lock()
		broker := activeBroker
		mu.Unlock()
		if broker == nil {
			return
		}
		if err := broker.TagInvite(tag, uri, chatName, inviter); err != nil {
			logf("TagInvite error: %v", err)
		}
	}()
}

// AuraCheckTagInvites checks pending tag invites.
func AuraCheckTagInvites(tag string) string {
	mu.Lock()
	broker := activeBroker
	mu.Unlock()
	if broker == nil {
		return "[]"
	}
	invites, err := broker.CheckTagInvites(tag)
	if err != nil {
		return "[]"
	}
	data, _ := json.Marshal(invites)
	return string(data)
}

// AuraLeaveRoom leaves the current room.
func AuraLeaveRoom(senderID string) {
	mu.Lock()
	session := activeSession
	mu.Unlock()

	if session != nil {
		msg := messenger.NewLeaveMessage(senderID)
		encrypted, _ := session.SendMessage(msg)
		_ = encrypted // TODO: send through tunnel
	}

	mu.Lock()
	activeSession = nil
	connected = false
	mu.Unlock()

	notifyDisconnected("left room")
}

// AuraDeleteRoom deletes room from local storage.
func AuraDeleteRoom(uri string) {
	logf("Room deleted locally: %s", uri)
	// No server-side deletion — room is ephemeral.
	// Just forget the URI in Swift via callback.
}

// ── Internal helpers ──

func onMessage(msg *messenger.Envelope) {
	data, _ := messenger.Encode(msg)
	dispatchMessage(string(data))
}

func dispatchMessage(text string) {
	mu.Lock()
	cb := callback
	mu.Unlock()
	if cb != nil {
		cb.OnMessage(text)
	}
}

func notifyConnected() {
	mu.Lock()
	connected = true
	cb := callback
	mu.Unlock()
	if cb != nil {
		cb.OnConnected()
	}
}

func notifyDisconnected(reason string) {
	mu.Lock()
	connected = false
	cb := callback
	mu.Unlock()
	if cb != nil {
		cb.OnDisconnected(reason)
	}
}
