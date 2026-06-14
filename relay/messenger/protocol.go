// Package messenger — JSON message protocol for Aura v2.
// All messages are encoded as JSON, encrypted with ChaCha20,
// and sent through the VP8/DataChannel tunnel.
package messenger

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// Version is the current protocol version.
const Version = 1

// ChunkSize is the max payload size per DataChannel message (4KB with margin).
const ChunkSize = 4096

// ── Message types ──

type MsgType string

const (
	MsgText     MsgType = "msg"
	MsgMedia    MsgType = "media"
	MsgJoin     MsgType = "join"
	MsgLeave    MsgType = "leave"
	MsgRoomInfo MsgType = "room_info"
	MsgPing     MsgType = "ping"
	MsgAck      MsgType = "ack"
)

// ── Envelope ──

// Envelope is the top-level JSON message.
type Envelope struct {
	V      int     `json:"v"`
	Type   MsgType `json:"type"`
	ID     string  `json:"id"`
	TS     float64 `json:"ts"`
	Sender string  `json:"sender"`

	// Text message
	Text    *string `json:"text,omitempty"`
	ReplyTo *string `json:"reply_to,omitempty"`

	// Media message
	MediaType   *string `json:"media_type,omitempty"`   // "image", "video"
	MediaName   *string `json:"media_name,omitempty"`   // filename
	MediaSize   *int    `json:"media_size,omitempty"`   // total bytes
	MediaHash   *string `json:"media_hash,omitempty"`   // "sha256:..."
	Chunk       *int    `json:"chunk,omitempty"`        // 0-based index
	ChunksTotal *int    `json:"chunks_total,omitempty"` // total chunks
	ChunkData   *string `json:"chunk_data,omitempty"`   // base64-encoded

	// Room info
	Name   *string `json:"name,omitempty"`
	Desc   *string `json:"desc,omitempty"`

	// Ack
	RefID *string `json:"ref_id,omitempty"`
}

// ── Message builder helpers ──

func NewID() string {
	id := strings.ReplaceAll(fmt.Sprintf("%x", time.Now().UnixNano()), "", "")
	if len(id) > 12 {
		id = id[:12]
	}
	return id
}

func NewTextMessage(sender, text string, replyTo string) *Envelope {
	msg := &Envelope{
		V:      Version,
		Type:   MsgText,
		ID:     NewID(),
		TS:     float64(time.Now().UnixMilli()) / 1000.0,
		Sender: sender,
		Text:   &text,
	}
	if replyTo != "" {
		msg.ReplyTo = &replyTo
	}
	return msg
}

func NewJoinMessage(sender string) *Envelope {
	return &Envelope{
		V:      Version,
		Type:   MsgJoin,
		ID:     NewID(),
		TS:     float64(time.Now().UnixMilli()) / 1000.0,
		Sender: sender,
	}
}

func NewLeaveMessage(sender string) *Envelope {
	return &Envelope{
		V:      Version,
		Type:   MsgLeave,
		ID:     NewID(),
		TS:     float64(time.Now().UnixMilli()) / 1000.0,
		Sender: sender,
	}
}

func NewRoomInfo(name, desc string) *Envelope {
	return &Envelope{
		V:      Version,
		Type:   MsgRoomInfo,
		ID:     NewID(),
		TS:     float64(time.Now().UnixMilli()) / 1000.0,
		Name:   &name,
		Desc:   &desc,
	}
}

func NewPing() *Envelope {
	return &Envelope{
		V:    Version,
		Type: MsgPing,
		ID:   NewID(),
		TS:   float64(time.Now().UnixMilli()) / 1000.0,
	}
}

func NewAck(refID string) *Envelope {
	return &Envelope{
		V:     Version,
		Type:  MsgAck,
		ID:    NewID(),
		TS:    float64(time.Now().UnixMilli()) / 1000.0,
		RefID: &refID,
	}
}

// NewMediaChunks splits binary data into chunked Envelope messages.
func NewMediaChunks(sender, mediaType, name string, data []byte) []*Envelope {
	hash := sha256.Sum256(data)
	hashStr := fmt.Sprintf("sha256:%x", hash)
	total := (len(data) + ChunkSize - 1) / ChunkSize
	if total == 0 {
		total = 1
	}

	chunks := make([]*Envelope, total)
	for i := 0; i < total; i++ {
		start := i * ChunkSize
		end := start + ChunkSize
		if end > len(data) {
			end = len(data)
		}
		chunkB64 := base64.StdEncoding.EncodeToString(data[start:end])

		chunkIdx := i
		chunks[i] = &Envelope{
			V:           Version,
			Type:        MsgMedia,
			ID:          NewID(),
			TS:          float64(time.Now().UnixMilli()) / 1000.0,
			Sender:      sender,
			MediaType:   &mediaType,
			MediaName:   &name,
			MediaSize:   &[]int{len(data)}[0],
			MediaHash:   &hashStr,
			Chunk:       &chunkIdx,
			ChunksTotal: &total,
			ChunkData:   &chunkB64,
		}
	}
	return chunks
}

// ── Encode / Decode ──

func Encode(msg *Envelope) ([]byte, error) {
	return json.Marshal(msg)
}

func Decode(data []byte) (*Envelope, error) {
	var msg Envelope
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("decode: %w", err)
	}
	if msg.V != Version {
		return nil, fmt.Errorf("decode: unsupported version %d", msg.V)
	}
	return &msg, nil
}

// ── Media reassembly ──

// MediaCollector collects chunks and reassembles the full file.
type MediaCollector struct {
	Total  int
	Hash   string
	Chunks map[int][]byte
}

func NewMediaCollector(total int, hash string) *MediaCollector {
	return &MediaCollector{
		Total:  total,
		Hash:   hash,
		Chunks: make(map[int][]byte),
	}
}

// AddChunk adds a chunk. Returns the full data if complete, nil otherwise.
func (mc *MediaCollector) AddChunk(chunkIdx int, data []byte) ([]byte, error) {
	if chunkIdx < 0 || chunkIdx >= mc.Total {
		return nil, fmt.Errorf("chunk index %d out of range [0,%d)", chunkIdx, mc.Total)
	}
	mc.Chunks[chunkIdx] = data
	if len(mc.Chunks) != mc.Total {
		return nil, nil // not complete yet
	}

	// Reassemble
	var full []byte
	for i := 0; i < mc.Total; i++ {
		chunk, ok := mc.Chunks[i]
		if !ok {
			return nil, fmt.Errorf("missing chunk %d", i)
		}
		full = append(full, chunk...)
	}

	// Verify hash
	hash := sha256.Sum256(full)
	got := fmt.Sprintf("sha256:%x", hash)
	if got != mc.Hash {
		return nil, fmt.Errorf("hash mismatch: expected %s, got %s", mc.Hash, got)
	}

	return full, nil
}

// IsComplete returns true if all chunks have been received.
func (mc *MediaCollector) IsComplete() bool {
	return len(mc.Chunks) == mc.Total
}
