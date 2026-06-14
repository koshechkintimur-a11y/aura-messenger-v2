import SwiftUI
import Combine
import Foundation

// MARK: - Models

struct UserProfile: Identifiable, Codable, Equatable {
    var id: String { tag }
    var firstName: String = ""
    var lastName: String = ""
    var tag: String = ""
    var email: String = ""
    var avatarBase64: String? = nil
    var isOnline: Bool = false
    var lastSeen: Date? = nil

    var displayName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? tag : name
    }

    var initials: String {
        let fn = firstName.prefix(1).uppercased()
        let ln = lastName.prefix(1).uppercased()
        return "\(fn)\(ln)"
    }
}

struct ChatRoom: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String = ""
    var avatarBase64: String? = nil
    var isPublic: Bool = false
    var url: String? = nil
    var members: [String] = [] // tags
    var admins: [String] = [] // tags
    var creatorTag: String = ""
    var pinnedMessageId: String? = nil
    var createdAt: Date = Date()
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var roomId: String = ""
    var senderTag: String = ""
    var senderName: String = ""
    var text: String = ""
    var timestamp: Date = Date()
    var imageBase64: String? = nil
    var replyToId: String? = nil
    var forwardedFromTag: String? = nil
    var isPinned: Bool = false
    var readBy: [String: Date] = [:] // tag -> read timestamp
    var deliveredTo: [String] = []

    var isReadByAll: Bool = false
    var status: MessageDeliveryStatus = .sending
}

enum MessageDeliveryStatus: String, Codable {
    case sending, sent, delivered, read
}

// MARK: - AuraViewModel

class AuraViewModel: ObservableObject {

    // MARK: Published
    @Published var profile: UserProfile = UserProfile()
    @Published var rooms: [ChatRoom] = []
    @Published var messages: [ChatMessage] = []
    @Published var currentRoomId: String? = nil
    @Published var isConnected: Bool = false
    @Published var onlineUsers: Set<String> = []
    @Published var validationError: String? = nil

    // MARK: AppStorage keys
    private let profileKey = "aura_profile"
    private let roomsKey = "aura_rooms"
    private let messagesKey = "aura_messages"
    private let userDefaults = UserDefaults.standard

    // MARK: Computed
    var currentRoom: ChatRoom? {
        guard let currentRoomId = currentRoomId else { return nil }
        return rooms.first { $0.id == currentRoomId }
    }

    var currentRoomMessages: [ChatMessage] {
        guard let currentRoomId = currentRoomId else { return [] }
        return messages.filter { $0.roomId == currentRoomId }
            .sorted { $0.timestamp < $1.timestamp }
    }

    init() {
        loadProfile()
        loadRooms()
    }

    // MARK: Profile

    func loadProfile() {
        if let data = userDefaults.data(forKey: profileKey),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = saved
        }
    }

    func saveProfile(_ newProfile: UserProfile) -> Bool {
        let tagValidation = validateTag(newProfile.tag)
        if !tagValidation.isValid {
            validationError = tagValidation.error
            return false
        }
        validationError = nil
        profile = newProfile
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: profileKey)
        }
        return true
    }

    func validateTag(_ tag: String) -> (isValid: Bool, error: String?) {
        if tag.isEmpty {
            return (false, "Тег не может быть пустым")
        }
        if tag.count < 3 {
            return (false, "Тег должен содержать минимум 3 символа")
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if tag.rangeOfCharacter(from: allowed.inverted) != nil {
            return (false, "Тег может содержать только латиницу, цифры и _")
        }
        // Check uniqueness locally (in real app would check server)
        return (true, nil)
    }

    // MARK: Rooms

    func loadRooms() {
        if let data = userDefaults.data(forKey: roomsKey),
           let saved = try? JSONDecoder().decode([ChatRoom].self, from: data) {
            rooms = saved
        }
    }

    private func persistRooms() {
        if let data = try? JSONEncoder().encode(rooms) {
            userDefaults.set(data, forKey: roomsKey)
        }
    }

    func createRoom(name: String, isPublic: Bool = false) -> ChatRoom {
        var room = ChatRoom()
        room.name = name
        room.isPublic = isPublic
        room.creatorTag = profile.tag
        room.members = [profile.tag]
        room.admins = [profile.tag]
        rooms.append(room)
        persistRooms()
        return room
    }

    func joinRoom(roomId: String) {
        guard let index = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        if !rooms[index].members.contains(profile.tag) {
            rooms[index].members.append(profile.tag)
            persistRooms()
        }
    }

    func leaveRoom(roomId: String) {
        guard let index = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        // Check admin transfer requirement
        if rooms[index].admins.contains(profile.tag) && rooms[index].admins.count == 1 {
            validationError = "Перед выходом передайте права администратора другому участнику"
            return
        }
        rooms[index].members.removeAll { $0 == profile.tag }
        rooms[index].admins.removeAll { $0 == profile.tag }
        if rooms[index].members.isEmpty {
            rooms.remove(at: index)
        }
        persistRooms()
        validationError = nil
    }

    func deleteRoom(roomId: String) {
        guard let room = rooms.first(where: { $0.id == roomId }) else { return }
        if !room.admins.contains(profile.tag) {
            validationError = "Удаление доступно только администратору"
            return
        }
        rooms.removeAll { $0.id == roomId }
        messages.removeAll { $0.roomId == roomId }
        persistRooms()
        persistMessages()
        validationError = nil
    }

    func transferAdmin(roomId: String, to newAdminTag: String) -> Bool {
        guard let index = rooms.firstIndex(where: { $0.id == roomId }) else { return false }
        guard rooms[index].admins.contains(profile.tag) else {
            validationError = "Передача прав доступна только администратору"
            return false
        }
        guard rooms[index].members.contains(newAdminTag) else {
            validationError = "Пользователь не является участником чата"
            return false
        }
        if !rooms[index].admins.contains(newAdminTag) {
            rooms[index].admins.append(newAdminTag)
        }
        verificationError = nil
        persistRooms()
        return true
    }

    // MARK: Messages

    func loadMessages() {
        if let data = userDefaults.data(forKey: messagesKey),
           let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = saved
        }
    }

    private func persistMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            userDefaults.set(data, forKey: messagesKey)
        }
    }

    func sendMessage(roomId: String, text: String, replyToId: String? = nil) -> ChatMessage {
        var msg = ChatMessage()
        msg.roomId = roomId
        msg.senderTag = profile.tag
        msg.senderName = profile.displayName
        msg.text = text
        msg.replyToId = replyToId
        msg.status = .sent
        messages.append(msg)
        persistMessages()
        return msg
    }

    func sendPhoto(roomId: String, imageBase64: String, caption: String = "") -> ChatMessage {
        var msg = ChatMessage()
        msg.roomId = roomId
        msg.senderTag = profile.tag
        msg.senderName = profile.displayName
        msg.text = caption
        msg.imageBase64 = imageBase64
        msg.status = .sent
        messages.append(msg)
        persistMessages()
        return msg
    }

    func replyTo(messageId: String, roomId: String, text: String) -> ChatMessage {
        return sendMessage(roomId: roomId, text: text, replyToId: messageId)
    }

    func pinMessage(messageId: String, roomId: String) {
        if let index = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[index].pinnedMessageId = messageId
            persistRooms()
        }
        if let msgIndex = messages.firstIndex(where: { $0.id == messageId }) {
            messages[msgIndex].isPinned = true
            persistMessages()
        }
    }

    func unpinMessage(roomId: String) {
        if let index = rooms.firstIndex(where: { $0.id == roomId }) {
            let msgId = rooms[index].pinnedMessageId
            rooms[index].pinnedMessageId = nil
            persistRooms()
            if let msgId = msgId, let msgIndex = messages.firstIndex(where: { $0.id == msgId }) {
                messages[msgIndex].isPinned = false
                persistMessages()
            }
        }
    }

    func forwardMessage(messageId: String, fromRoomId: String, toRoomId: String) -> ChatMessage? {
        guard let original = messages.first(where: { $0.id == messageId && $0.roomId == fromRoomId }) else { return nil }
        var forwarded = original
        forwarded.id = UUID().uuidString
        forwarded.roomId = toRoomId
        forwarded.forwardedFromTag = original.senderTag
        forwarded.timestamp = Date()
        forwarded.status = .sent
        messages.append(forwarded)
        persistMessages()
        return forwarded
    }

    func markAsRead(messageId: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            if messages[index].readBy[profile.tag] == nil {
                messages[index].readBy[profile.tag] = Date()
                messages[index].status = .read
                persistMessages()
            }
        }
    }

    func deleteMessage(messageId: String) {
        messages.removeAll { $0.id == messageId }
        persistMessages()
    }

    // MARK: Online Status

    func setOnlineStatus(isOnline: Bool) {
        if isOnline {
            onlineUsers.insert(profile.tag)
        } else {
            onlineUsers.remove(profile.tag)
        }
        isConnected = isOnline
    }

    func isUserOnline(tag: String) -> Bool {
        return onlineUsers.contains(tag)
    }

    // MARK: Reset

    func resetAllData() {
        profile = UserProfile()
        rooms = []
        messages = []
        onlineUsers = []
        userDefaults.removeObject(forKey: profileKey)
        userDefaults.removeObject(forKey: roomsKey)
        userDefaults.removeObject(forKey: messagesKey)
    }
}

// NOTE: Fix for validationError assignment
extension AuraViewModel {
    private var verificationError: String? {
        get { validationError }
        set { validationError = newValue }
    }
}
