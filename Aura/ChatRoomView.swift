import SwiftUI

struct ChatRoomView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @State private var messageText: String = ""
    @State private var replyToMessage: ChatMessage? = nil
    @State private var selectedMessage: ChatMessage? = nil
    @State private var showActionSheet: Bool = false
    @State private var showLinkAlert: Bool = false
    @State private var linkUrl: String = ""
    @State private var scrollToBottom: Bool = false
    
    var room: ChatRoom? {
        viewModel.currentRoom
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            roomHeader
            
            // Messages
            messagesList
            
            // Reply indicator
            if let replyTo = replyToMessage {
                replyIndicator
            }
            
            // Input area
            inputArea
        }
        .background(Color(hex: "0A0A0F"))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Действия"),
                buttons: actionSheetButtons
            )
        }
        .alert("Открыть ссылку?", isPresented: $showLinkAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Открыть") {
                if let url = URL(string: linkUrl) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(linkUrl)
        }
    }

    // MARK: - Header

    private var roomHeader: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: { /* pop */ }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "5A9FEE"))
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "1C1C24"))
                    .frame(width: 40, height: 40)

                Text(room?.name.prefix(1).uppercased() ?? "?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(room?.name ?? "Чат")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    let memberCount = room?.members.count ?? 0
                    Text("\(memberCount) \(memberCount == 1 ? "участник" : "участников")")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8E8E93"))

                    // Online status
                    if let firstMember = room?.members.first,
                       viewModel.isUserOnline(tag: firstMember) {
                        Circle()
                            .fill(Color(hex: "34C759"))
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(Color(0xFF453A))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background((Color(hex: "0A0A0F") as Color).opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(0x2C2C34)),
            alignment: .bottom
        )
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    let groupedMessages = groupMessagesByDate(viewModel.currentRoomMessages)
                    ForEach(groupedMessages) { group in
                        if let dateHeader = group.dateHeader {
                            dateSeparator(dateHeader)
                        }

                        ForEach(group.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                                .onLongPressGesture {
                                    selectedMessage = message
                                    showActionSheet = true
                                }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.currentRoomMessages.count) { _ in
                scrollToBottom = true
            }
            .onAppear {
                scrollToBottom = true
            }
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isOutgoing = message.senderTag == viewModel.profile.tag
        let showAvatar = !isOutgoing

        return HStack(alignment: .bottom, spacing: 8) {
            if showAvatar {
                // Sender avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "1C1C24"))
                        .frame(width: 28, height: 28)

                    Text(message.senderName.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            } else {
                Spacer(minLength: 36)
            }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 2) {
                if !isOutgoing {
                    Text(message.senderName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .padding(.horizontal, 4)
                }

                // Reply indicator
                if let replyToId = message.replyToId,
                   let repliedMessage = viewModel.messages.first(where: { $0.id == replyToId }) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color(0x5A9FEE))
                            .frame(width: 3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(repliedMessage.senderName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "5A9FEE"))

                            Text(repliedMessage.text)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "8E8E93"))
                                .lineLimit(2)
                        }
                    }
                    .padding(8)
                    .background(Color(0x1C1C24))
                    .cornerRadius(8)
                }

                // Photo
                if let imageBase64 = message.imageBase64,
                   let data = Data(base64Encoded: imageBase64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Text
                if !message.text.isEmpty {
                    HStack(alignment: .bottom, spacing: 6) {
                        messageContent(message.text, isOutgoing: isOutgoing)
                            .foregroundColor(isOutgoing ? .white : Color(0xE5E5EA))

                        // Timestamp & status
                        HStack(spacing: 2) {
                            Text(formattedTime(message.timestamp))
                                .font(.system(size: 11))
                                .foregroundColor(isOutgoing ? Color(0xFFFFFF).opacity(0.7) : Color(0x8E8E93))

                            if isOutgoing {
                                messageStatusIcon(message)
                            }
                        }
                        .padding(.trailing, 2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isOutgoing ? Color(0x5A9FEE) : Color(0x2C2C34))
                    )
                }

                // Forwarded indicator
                if message.forwardedFromTag != nil {
                    Text("Переслано")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .padding(.horizontal, 4)
                }
            }

            if isOutgoing {
                Spacer(minLength: 36)
            }
        }
        .padding(.vertical, 2)
    }

    private func messageContent(_ text: String, isOutgoing: Bool) -> Text {
        let attributed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnly
            )
        )
        return Text(attributed ?? AttributedString(text))
    }

    private func messageStatusIcon(_ message: ChatMessage) -> some View {
        Group {
            switch message.status {
            case .sent:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(0xFFFFFF).opacity(0.7))
            case .delivered:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(0xFFFFFF).opacity(0.7))
            case .read:
                HStack(spacing: 0) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(0x34C759))
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(0x34C759))
                        .offset(x: -4)
                }
            default:
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(0xFFFFFF).opacity(0.5))
            }
        }
    }

    // MARK: - Date Separator

    private func dateSeparator(_ date: Date) -> some View {
        HStack {
            Spacer()
            Text(formattedDate(date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(0x5C5C66))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(0x1C1C24).opacity(0.8))
                )
            Spacer()
        }
        .padding(.vertical, 12)
    }

    // MARK: - Reply Indicator

    private var replyIndicator: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(0x5A9FEE))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(replyToMessage?.senderName ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "5A9FEE"))

                Text(replyToMessage?.text ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { replyToMessage = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(0x1C1C24))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(0x2C2C34)),
            alignment: .top
        )
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(0x2C2C34))

            HStack(spacing: 12) {
                // Paperclip
                Button(action: { /* Attach file */ }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(hex: "8E8E93"))
                }

                // Text field
                TextField("", text: $messageText)
                    .placeholder(when: messageText.isEmpty) {
                        Text("Сообщение...")
                            .foregroundColor(Color(0x5C5C66))
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "1C1C24"))
                    )

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(messageText.isEmpty ? Color(0x5C5C66) : Color(0x5A9FEE))
                        .rotationEffect(.degrees(45))
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(hex: "0A0A0F"))
    }

    // MARK: - Actions

    private var actionSheetButtons: [ActionSheet.Button] {
        guard let message = selectedMessage else { return [.cancel()] }
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("Копировать")) {
            UIPasteboard.general.string = message.text
        })

        buttons.append(.default(Text("Ответить")) {
            replyToMessage = message
        })

        buttons.append(.default(Text("Переслать")) {
            // Forward logic
            if let roomId = viewModel.currentRoomId {
                _ = viewModel.forwardMessage(messageId: message.id, fromRoomId: roomId, toRoomId: roomId)
            }
        })

        if message.isPinned {
            buttons.append(.default(Text("Открепить")) {
                viewModel.unpinMessage(roomId: message.roomId)
            })
        } else {
            buttons.append(.default(Text("Закрепить")) {
                viewModel.pinMessage(messageId: message.id, roomId: message.roomId)
            })
        }

        buttons.append(.cancel(Text("Отмена")))
        return buttons
    }

    private func sendMessage() {
        guard let roomId = viewModel.currentRoomId, !messageText.isEmpty else { return }
        viewModel.sendMessage(roomId: roomId, text: messageText, replyToId: replyToMessage?.id)
        messageText = ""
        replyToMessage = nil
    }

    // MARK: - Helpers

    private struct MessageGroup: Identifiable {
        var id = UUID()
        var dateHeader: Date?
        var messages: [ChatMessage]
    }

    private func groupMessagesByDate(_ messages: [ChatMessage]) -> [MessageGroup] {
        let calendar = Calendar.current
        var groups: [MessageGroup] = []
        var currentGroup: [ChatMessage] = []
        var lastDate: Date?

        for message in messages {
            let messageDate = calendar.startOfDay(for: message.timestamp)
            if let last = lastDate, !calendar.isDate(messageDate, inSameDayAs: last) {
                groups.append(MessageGroup(dateHeader: last, messages: currentGroup))
                currentGroup = []
            }
            lastDate = messageDate
            currentGroup.append(message)
        }

        if !currentGroup.isEmpty {
            groups.append(MessageGroup(dateHeader: nil, messages: currentGroup))
        }

        return groups
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        if Calendar.current.isDateInToday(date) {
            return "Сегодня"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Вчера"
        } else {
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: date)
        }
    }
}
