// Package messenger — HTTP client to VPS message broker.
// Used ONLY for room creation/joining. Messages go through the tunnel directly.
package messenger

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// BrokerClient talks to the VPS broker API.
type BrokerClient struct {
	BaseURL string
	client  *http.Client
}

// NewBrokerClient creates a new broker client.
func NewBrokerClient(baseURL string) *BrokerClient {
	return &BrokerClient{
		BaseURL: baseURL,
		client: &http.Client{Timeout: 15 * time.Second},
	}
}

// CreateRoomResponse from POST /create.
type CreateRoomResponse struct {
	URI         string `json:"uri"`
	JoinURL     string `json:"join_url"`
	PeerID      string `json:"peer_id"`
	RoomID      string `json:"room_id"`
	Credentials string `json:"credentials"`
}

// JoinRoomResponse from GET /join.
type JoinRoomResponse struct {
	PeerID      string `json:"peer_id"`
	RoomID      string `json:"room_id"`
	Credentials string `json:"credentials"`
}

// CreateRoom creates a new Telemost conference via the broker.
func (b *BrokerClient) CreateRoom() (*CreateRoomResponse, error) {
	url := b.BaseURL + "/create"
	resp, err := b.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("create room: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("create room: status %d: %s", resp.StatusCode, string(body))
	}

	var result CreateRoomResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("create room: decode: %w", err)
	}
	return &result, nil
}

// JoinRoom fetches connection info for an existing room.
func (b *BrokerClient) JoinRoom(uri string) (*JoinRoomResponse, error) {
	url := fmt.Sprintf("%s/join?uri=%s", b.BaseURL, uri)
	resp, err := b.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("join room: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("join room: status %d: %s", resp.StatusCode, string(body))
	}

	var result JoinRoomResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("join room: decode: %w", err)
	}
	return &result, nil
}

// TagInvite sends a tag invite to the broker.
func (b *BrokerClient) TagInvite(tag, uri, chatName, inviter string) error {
	url := b.BaseURL + "/tag-invite"
	body := map[string]string{
		"tag":       tag,
		"uri":       uri,
		"chat_name": chatName,
		"inviter":   inviter,
	}
	data, _ := json.Marshal(body)
	resp, err := b.client.Post(url, "application/json", bytes.NewReader(data))
	if err != nil {
		return fmt.Errorf("tag invite: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return fmt.Errorf("tag invite: status %d", resp.StatusCode)
	}
	return nil
}

// CheckTagInvites checks for pending tag invites.
func (b *BrokerClient) CheckTagInvites(tag string) ([]map[string]interface{}, error) {
	url := fmt.Sprintf("%s/tag-check?tag=%s", b.BaseURL, tag)
	resp, err := b.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("check invites: %w", err)
	}
	defer resp.Body.Close()

	var invites []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&invites); err != nil {
		return nil, fmt.Errorf("check invites: decode: %w", err)
	}
	return invites, nil
}
