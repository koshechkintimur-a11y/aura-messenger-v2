import SwiftUI
import Combine

enum MessageType: String {
    case own
    case other
    case system
}

struct AuraMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let time: Date
    let type: MessageType
    let senderName: String?
}

class AuraViewModel: ObservableObject {
    @Published var messages: [AuraMessage] = []
    @Published var connected: Bool = false
    @Published var connecting: Bool = false
    @Published var error: String? = nil
    @Published var roomName: String = ""
    @Published var participants: [String] = []
    @Published var replyTo: AuraMessage? = nil
    
    func connect() {
        print("[AuraViewModel] connect() called")
        connecting = true
        error = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.connecting = false
            self.connected = true
            print("[AuraViewModel] connected")
        }
    }
    
    func disconnect() {
        print("[AuraViewModel] disconnect() called")
        connected = false
        connecting = false
    }
    
    func sendMessage(text: String) {
        print("[AuraViewModel] sendMessage(\"\(text)\") called")
        let message = AuraMessage(text: text, time: Date(), type: .own, senderName: nil)
        messages.append(message)
        print("[AuraViewModel] message appended: \(text)")
    }
    
    func joinRoom(name: String) {
        print("[AuraViewModel] joinRoom(\"\(name)\") called")
        roomName = name
    }
    
    func leaveRoom() {
        print("[AuraViewModel] leaveRoom() called")
        roomName = ""
        participants.removeAll()
    }
    
    func setReplyTo(_ message: AuraMessage?) {
        print("[AuraViewModel] setReplyTo called")
        replyTo = message
    }
    
    func clearReply() {
        print("[AuraViewModel] clearReply() called")
        replyTo = nil
    }
    
    func fetchParticipants() {
        print("[AuraViewModel] fetchParticipants() called")
    }
    
    func uploadPhoto() {
        print("[AuraViewModel] uploadPhoto() called")
    }
}
