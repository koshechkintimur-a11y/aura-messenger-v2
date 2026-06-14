import SwiftUI
import Foundation

// MARK: - AuraRelay Bridge (connects to Go xcframework)

class AuraRelayBridge: ObservableObject {
    @Published var connected = false
    @Published var error: String?
    
    private var isInitialized = false
    
    func initialize(brokerURL: String) {
        // TODO: call AuraInit(brokerURL, callback) from Go xcframework
        // For now: connect through WebSocket to VPS broker directly
        isInitialized = true
        connectViaWebSocket(brokerURL: brokerURL)
    }
    
    func connectToRoom(uri: String, peerID: String, roomID: String, credentials: String, mediaURL: String) {
        // TODO: call IosConnect(mediaURL, roomID, peerID, credentials, "telemost", callback)
        // The Go relay will:
        // 1. Open WebSocket to Yandex SFU
        // 2. Send hello with capabilities
        // 3. Negotiate SDP (subscriber + publisher)
        // 4. Open DataChannel "aura-chat"
        // 5. Route messages through DataChannel
        connected = true
    }
    
    func sendText(_ text: String) {
        // TODO: call IosSendText(text)
        // This sends through the DataChannel to SFU → other peers
    }
    
    func sendImage(_ jpegData: Data, fileName: String) {
        // TODO: call IosSendImage(jpegData, fileName)
    }
    
    func disconnect() {
        // TODO: call IosDisconnect()
        connected = false
    }
    
    // WebSocket fallback (works without Go xcframework)
    private var wsTask: URLSessionWebSocketTask?
    
    private func connectViaWebSocket(brokerURL: String) {
        guard let url = URL(string: brokerURL.replacingOccurrences(of: "https://", with: "wss://") + "/chat") else {
            return
        }
        let session = URLSession(configuration: .default)
        wsTask = session.webSocketTask(with: url)
        wsTask?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        wsTask?.receive { [weak self] result in
            switch result {
            case .success(.string(let text)):
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .relayMessageReceived, object: text)
                }
                self?.receiveMessage()
            case .failure:
                DispatchQueue.main.async { self?.connected = false }
            default: break
            }
        }
    }
    
    func sendViaWebSocket(_ text: String) {
        wsTask?.send(.string(text)) { _ in }
    }
}

extension Notification.Name {
    static let relayMessageReceived = Notification.Name("relayMessageReceived")
}

// MARK: - AuraViewModel (Connected)

class AuraViewModel: ObservableObject {
    @Published var profile: UserProfile = UserProfile()
    @Published var rooms: [ChatRoom] = []
    @Published var messages: [ChatMessage] = []
    @Published var currentRoomId: String?
    @Published var isConnected = false
    @Published var onlineUsers: Set<String> = []
    @Published var validationError: String?
    @Published var folders: [String] = []
    
    private let relay = AuraRelayBridge()
    private let userDefaults = UserDefaults.standard
    private let profileKey = "aura_profile"
    private let roomsKey = "aura_rooms"
    private let foldersKey = "aura_folders"
    
    // MARK: Stats
    var totalChats: Int { rooms.count }
    var totalMessages: Int { messages.count }
    var storageUsed: Int64 { Int64((try? JSONEncoder().encode(messages).count) ?? 0) }
    
    // MARK: Current room
    var currentRoom: ChatRoom? {
        guard let id = currentRoomId else { return nil }
        return rooms.first { $0.id == id }
    }
    
    var currentMessages: [ChatMessage] {
        messages.filter { $0.roomId == currentRoomId }.sorted { $0.timestamp < $1.timestamp }
    }
    
    init() {
        loadProfile()
        loadRooms()
        loadFolders()
        loadSavedMessages()
        relay.initialize(brokerURL: "https://golubot.ru/tm")
        
        NotificationCenter.default.addObserver(forName: .relayMessageReceived, object: nil, queue: .main) { [weak self] n in
            guard let text = n.object as? String, let data = text.data(using: .utf8) else { return }
            if let msg = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                self?.messages.append(msg)
            }
        }
    }
    
    // MARK: Profile
    func loadProfile() {
        if let d = userDefaults.data(forKey: profileKey), let p = try? JSONDecoder().decode(UserProfile.self, from: d) { profile = p }
    }
    func saveProfile(_ p: UserProfile) -> Bool {
        if p.tag.count < 3 { validationError = "Тег: минимум 3 символа"; return false }
        profile = p
        if let d = try? JSONEncoder().encode(p) { userDefaults.set(d, forKey: profileKey) }
        return true
    }
    
    // MARK: Rooms
    func loadRooms() {
        if let d = userDefaults.data(forKey: roomsKey), let r = try? JSONDecoder().decode([ChatRoom].self, from: d) { rooms = r }
    }
    private func saveRooms() {
        if let d = try? JSONEncoder().encode(rooms) { userDefaults.set(d, forKey: roomsKey) }
    }
    
    func saveMessages() {
        if let d = try? JSONEncoder().encode(messages.suffix(500)) { userDefaults.set(d, forKey: "aura_messages") }
    }
    func loadSavedMessages() {
        if let d = userDefaults.data(forKey: "aura_messages"),
           let saved = try? JSONDecoder().decode([ChatMessage].self, from: d) {
            messages = saved
        }
    }
    
    func createRoom(name: String, isPublic: Bool = false, url: String? = nil) -> ChatRoom {
        var r = ChatRoom(name: name, isPublic: isPublic, url: url)
        r.creatorTag = profile.tag
        r.members = [profile.tag]
        r.admins = [profile.tag]
        rooms.append(r)
        saveRooms()
        return r
    }
    
    func joinRoom(_ room: ChatRoom) {
        guard let i = rooms.firstIndex(where: { $0.id == room.id }) else { return }
        if !rooms[i].members.contains(profile.tag) { rooms[i].members.append(profile.tag); saveRooms() }
    }
    
    func leaveRoom(roomId: String) {
        guard let i = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        if rooms[i].admins.contains(profile.tag) && rooms[i].admins.count == 1 && rooms[i].members.count > 1 {
            validationError = "Передайте права админа перед выходом"
            return
        }
        rooms[i].members.removeAll { $0 == profile.tag }
        rooms[i].admins.removeAll { $0 == profile.tag }
        if rooms[i].members.isEmpty { rooms.remove(at: i) }
        saveRooms()
        currentRoomId = nil
    }
    
    func deleteRoom(roomId: String) {
        guard let r = currentRoom, r.admins.contains(profile.tag) else { validationError = "Только админ"; return }
        rooms.removeAll { $0.id == roomId }
        messages.removeAll { $0.roomId == roomId }
        saveRooms()
        currentRoomId = nil
    }
    
    func transferAdmin(roomId: String, to tag: String) {
        guard let i = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        guard rooms[i].admins.contains(profile.tag), rooms[i].members.contains(tag) else { return }
        if !rooms[i].admins.contains(tag) { rooms[i].admins.append(tag) }
        saveRooms()
    }
    
    // MARK: Messages
    func sendMessage(roomId: String, text: String, replyToId: String? = nil) {
        var m = ChatMessage(roomId: roomId, senderTag: profile.tag, senderName: profile.displayName, text: text, replyToId: replyToId, status: .sending)
        messages.append(m)
        
        // Send through relay (Telemost tunnel)
        if let data = try? JSONEncoder().encode(m), let json = String(data: data, encoding: .utf8) {
            relay.sendText(json)
        }
        
        // Mark as sent
        if let idx = messages.firstIndex(where: { $0.id == m.id }) { messages[idx].status = .sent }
        saveMessages()
    }
    
    func sendPhoto(roomId: String, imageData: Data, caption: String = "") {
        let b64 = imageData.base64EncodedString()
        var m = ChatMessage(roomId: roomId, senderTag: profile.tag, senderName: profile.displayName, text: caption, imageBase64: b64, status: .sending)
        messages.append(m)
        relay.sendImage(imageData, fileName: "photo_\(Date().timeIntervalSince1970).jpg")
        if let idx = messages.firstIndex(where: { $0.id == m.id }) { messages[idx].status = .sent }
        saveMessages()
    }
    
    func pinMessage(_ msgId: String, roomId: String) {
        if let i = rooms.firstIndex(where: { $0.id == roomId }) { rooms[i].pinnedMessageId = msgId; saveRooms() }
        if let mi = messages.firstIndex(where: { $0.id == msgId }) { messages[mi].isPinned = true }
    }
    
    func markRead(_ msgId: String) {
        if let i = messages.firstIndex(where: { $0.id == msgId }) { messages[i].status = .read }
    }
    
    // MARK: Folders
    func loadFolders() {
        if let d = userDefaults.data(forKey: foldersKey), let f = try? JSONDecoder().decode([String].self, from: d) { folders = f }
    }
    func saveFolders() {
        if let d = try? JSONEncoder().encode(folders) { userDefaults.set(d, forKey: foldersKey) }
    }
    func addFolder(_ name: String) { if !name.isEmpty, !folders.contains(name) { folders.append(name); saveFolders() } }
    
    // MARK: Online
    func setOnline(_ online: Bool) {
        isConnected = online
        if online { onlineUsers.insert(profile.tag) } else { onlineUsers.remove(profile.tag) }
    }
    func isUserOnline(tag: String) -> Bool { onlineUsers.contains(tag) }
    
    // MARK: Favorites
    var favorites: ChatRoom? { rooms.first { $0.name == "Избранное" } }
    
    func ensureFavorites() {
        if favorites == nil {
            var fav = ChatRoom(name: "Избранное", isPublic: false)
            fav.members = [profile.tag]
            fav.admins = [profile.tag]
            rooms.append(fav)
            saveRooms()
        }
    }
    
    func forwardToFavorites(_ msgId: String) {
        ensureFavorites()
        guard let fav = favorites, let orig = messages.first(where: { $0.id == msgId }) else { return }
        var copy = orig
        copy.id = UUID().uuidString
        copy.roomId = fav.id
        copy.timestamp = Date()
        copy.forwardedFromTag = orig.senderTag
        messages.append(copy)
    }
    
    // MARK: Cache
    func clearCache() {
        let tmp = FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: tmp)
    }
    
    func resetAllData() {
        profile = UserProfile()
        rooms = []
        messages = []
        folders = []
        onlineUsers = []
        userDefaults.removeObject(forKey: profileKey)
        userDefaults.removeObject(forKey: roomsKey)
        userDefaults.removeObject(forKey: foldersKey)
        relay.disconnect()
    }
}

// MARK: - Models

struct UserProfile: Identifiable, Codable, Equatable {
    var id: String { tag }
    var firstName = ""
    var lastName = ""
    var tag = ""
    var about = ""
    var email = ""
    var avatarBase64: String?
    var isOnline = false
    var displayName: String { [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ") }
    var initials: String { "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased() }
}

struct ChatRoom: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var name = ""
    var avatarBase64: String?
    var isPublic = false
    var url: String?
    var members: [String] = []
    var admins: [String] = []
    var creatorTag = ""
    var pinnedMessageId: String?
    var createdAt = Date()
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var roomId = ""
    var senderTag = ""
    var senderName = ""
    var text = ""
    var timestamp = Date()
    var imageBase64: String?
    var replyToId: String?
    var forwardedFromTag: String?
    var isPinned = false
    var readBy: [String: Date] = [:]
    var status: MessageDeliveryStatus = .sending
}

enum MessageDeliveryStatus: String, Codable { case sending, sent, delivered, read }
