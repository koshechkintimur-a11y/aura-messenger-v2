import SwiftUI

struct ChatRoomView: View {
    @ObservedObject var viewModel: AuraViewModel
    @State private var inputText: String = ""
    @State private var showImagePicker: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Room info
            if !viewModel.roomName.isEmpty {
                HStack {
                    Text(viewModel.roomName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Участников: \(viewModel.participants.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.black.opacity(0.3))
            }
            
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .onChange(of: viewModel.messages) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Reply indicator
            if let reply = viewModel.replyTo {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ответ на:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(reply.text)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: {
                        viewModel.clearReply()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
            }
            
            // Input area
            HStack(spacing: 8) {
                Button(action: {
                    showImagePicker = true
                    viewModel.uploadPhoto()
                }) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                }
                
                TextField("Сообщение...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .background(Color.black.opacity(0.5))
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            viewModel.connect()
            if viewModel.roomName.isEmpty {
                viewModel.joinRoom(name: "Общий чат")
            }
            // Демо сообщения для отображения
            if viewModel.messages.isEmpty {
                viewModel.messages.append(AuraMessage(text: "Добро пожаловать в Aura Messenger!", time: Date().addingTimeInterval(-3600), type: .system, senderName: nil))
                viewModel.messages.append(AuraMessage(text: "Привет всем! 👋", time: Date().addingTimeInterval(-1800), type: .other, senderName: "Алексей"))
                viewModel.messages.append(AuraMessage(text: "Привет, Алексей!", time: Date().addingTimeInterval(-1700), type: .own, senderName: nil))
            }
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
    
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.sendMessage(text: trimmed)
        inputText = ""
        isInputFocused = true
    }
}

struct ChatRoomView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = AuraViewModel()
        vm.roomName = "Тестовая комната"
        vm.messages = [
            AuraMessage(text: "Добро пожаловать!", time: Date(), type: .system, senderName: nil),
            AuraMessage(text: "Привет!", time: Date(), type: .other, senderName: "Алексей"),
            AuraMessage(text: "Привет, Алексей!", time: Date(), type: .own, senderName: nil)
        ]
        return ChatRoomView(viewModel: vm)
    }
}
