// Package messenger — session management for Aura v2.
// Each room gets a Session with its own ChaCha20 key.
// Keys are ephemeral — generated per session, never stored.
package messenger

import (
	"crypto/rand"
	"fmt"
	"sync"

	"golang.org/x/crypto/nacl/secretbox"
)

const (
	KeySize   = 32
	NonceSize = 24
)

// Session holds the state for one chat room.
type Session struct {
	mu       sync.Mutex
	RoomURI  string
	RoomName string
	Key      [KeySize]byte
	SenderID string // @tag or name
	OnMsg    func(msg *Envelope)
}

// NewSession creates a new session with a random key.
func NewSession(roomURI, roomName, senderID string, onMsg func(*Envelope)) (*Session, error) {
	var key [KeySize]byte
	if _, err := rand.Read(key[:]); err != nil {
		return nil, fmt.Errorf("gen key: %w", err)
	}
	return &Session{
		RoomURI:  roomURI,
		RoomName: roomName,
		Key:      key,
		SenderID: senderID,
		OnMsg:    onMsg,
	}, nil
}

// KeyBytes returns the key for sharing with Go relay layer.
func (s *Session) KeyBytes() *[KeySize]byte {
	return &s.Key
}

// Seal encrypts a plaintext message. Returns nonce + ciphertext.
func (s *Session) Seal(plaintext []byte) ([]byte, error) {
	var nonce [NonceSize]byte
	if _, err := rand.Read(nonce[:]); err != nil {
		return nil, fmt.Errorf("nonce: %w", err)
	}
	encrypted := secretbox.Seal(nonce[:], plaintext, &nonce, &s.Key)
	return encrypted, nil
}

// Open decrypts a sealed blob. Returns plaintext on success.
func (s *Session) Open(packed []byte) ([]byte, error) {
	if len(packed) < NonceSize+secretbox.Overhead {
		return nil, fmt.Errorf("too short: %d bytes", len(packed))
	}
	var nonce [NonceSize]byte
	copy(nonce[:], packed[:NonceSize])
	decrypted, ok := secretbox.Open(nil, packed[NonceSize:], &nonce, &s.Key)
	if !ok {
		return nil, fmt.Errorf("auth failed")
	}
	return decrypted, nil
}

// HandleMessage decrypts and dispatches an incoming message to OnMsg callback.
func (s *Session) HandleMessage(encrypted []byte) {
	plain, err := s.Open(encrypted)
	if err != nil {
		return // skip corrupt/unauth messages silently
	}
	msg, err := Decode(plain)
	if err != nil {
		return
	}
	if s.OnMsg != nil {
		s.OnMsg(msg)
	}
}

// SendMessage encrypts and returns the sealed bytes for an Envelope.
func (s *Session) SendMessage(msg *Envelope) ([]byte, error) {
	plain, err := Encode(msg)
	if err != nil {
		return nil, fmt.Errorf("encode: %w", err)
	}
	return s.Seal(plain)
}
