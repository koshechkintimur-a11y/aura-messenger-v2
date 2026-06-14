import SwiftUI
import CoreImage.CIFilterBuiltins

struct ChatRoomView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @State private var messageText: String = ""
    @State private var replyToMessage: ChatMessage? = nil
    @State private var selectedMessage: ChatMessage? = nil
    @State private var showActionSheet: Bool = false
    @State private var showLinkAlert: Bool = false
    @State private var linkUrl: String = ""
    @State private var scrollToBottom: Bool = false
    @State private var showInviteSheet: Bool = false
    @State private var showWeightPopup: Bool = false
    @State private var weightPopupMessage: ChatMessage? = nil

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
        .background(Color(.systemGray6))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .sheet(isPresented: $showInviteSheet) {
            inviteSheet
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Действия"),
                buttons: actionSheetButtons
            )
        }
        .alert("Вес сообщения", isPresented: $showWeightPopup) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = weightPopupMessage {
                let originalSize = msg.text.utf8.count / 1024
                let compressedSize = max(1, originalSize / 4)
                Text("Исходный: \(originalSize)KB → Отправлено: \(compressedSize)KB")
            } else {
                Text("")
            }
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
            Button(action: { /* pop */ }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 40, height: 40)

                Text(room?.name.prefix(1).uppercased() ?? "?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
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
                        .foregroundColor(.gray)

                    if let firstMember = room?.members.first,
                       viewModel.isUserOnline(tag: firstMember) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                    }
                }
            }

            Spacer()

            // Invite button
            Button(action: { showInviteSheet = true }) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray6).opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }

    // MARK: - Invite Sheet

    private var inviteSheet: some View {
        VStack(spacing: 24) {
            Text("Пригласить в чат")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top)

            // QR
            VStack(spacing: 8) {
                Text("QR-код приглашения")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                QRView(data: inviteLink)
                    .frame(width: 180, height: 180)
            }

            // Link
            VStack(alignment: .leading, spacing: 6) {
                Text("Ссылка приглашения")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                HStack(spacing: 12) {
                    Text(inviteLink)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = inviteLink
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.systemGray6))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }

            // Tag
            VStack(alignment: .leading, spacing: 6) {
                Text("Отправить по тегу")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                HStack(spacing: 12) {
                    Text("@")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    TextField("", text: .constant(""))
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                    Button(action: {}) {
                        Text("Отправить")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var inviteLink: String {
        if let room = room {
            return "https://aura.app/c/\(room.id)"
        }
        return "https://aura.app/c/invite"
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
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 28, height: 28)

                    Text(message.senderName.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            } else {
                Spacer(minLength: 36)
            }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 2) {
                if !isOutgoing {
                    Text(message.senderName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }

                if let replyToId = message.replyToId,
                   let repliedMessage = viewModel.messages.first(where: { $0.id == replyToId }) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(repliedMessage.senderName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)

                            Text(repliedMessage.text)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }

                if let imageBase64 = message.imageBase64,
                   let data = Data(base64Encoded: imageBase64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !message.text.isEmpty {
                    HStack(alignment: .bottom, spacing: 6) {
                        messageContent(message.text, isOutgoing: isOutgoing)
                            .foregroundColor(isOutgoing ? .white : .white)

                        HStack(spacing: 2) {
                            Text(formattedTime(message.timestamp))
                                .font(.system(size: 11))
                                .foregroundColor(isOutgoing ? Color.white.opacity(0.7) : Color.gray)

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
                            .fill(isOutgoing ? Color(.systemGray6) : Color.white.opacity(0.08))
                    )
                }

                if message.forwardedFromTag != nil {
                    Text("Переслано")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
            }

            if isOutgoing {
                Spacer(minLength: 36)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(action: {
                weightPopupMessage = message
                showWeightPopup = true
            }) {
                Text("Показать вес")
                Image(systemName: "scalemass")
            }
        }
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
                    .foregroundColor(Color.white.opacity(0.7))
            case .delivered:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.7))
            case .read:
                HStack(spacing: 0) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: -4)
                }
            default:
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
    }

    // MARK: - Date Separator

    private func dateSeparator(_ date: Date) -> some View {
        HStack {
            Spacer()
            Text(formattedDate(date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                )
            Spacer()
        }
        .padding(.vertical, 12)
    }

    // MARK: - Reply Indicator

    private var replyIndicator: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(replyToMessage?.senderName ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)

                Text(replyToMessage?.text ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { replyToMessage = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .top
        )
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                Button(action: { /* Attach file */ }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.gray)
                }

                TextField("", text: $messageText)
                    .placeholder(when: messageText.isEmpty) {
                        Text("Сообщение...")
                            .foregroundColor(.gray)
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.06))
                    )

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(messageText.isEmpty ? .gray : Color(.systemGray6))
                        .rotationEffect(.degrees(45))
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGray6))
    }

    // MARK: - Actions

    private var actionSheetButtons: [ActionSheet.Button] {
        guard let message = selectedMessage else { return [.cancel()] }
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("Показать вес")) {
            weightPopupMessage = message
            showWeightPopup = true
        })

        buttons.append(.default(Text("Копировать")) {
            UIPasteboard.general.string = message.text
        })

        buttons.append(.default(Text("Ответить")) {
            replyToMessage = message
        })

        buttons.append(.default(Text("Переслать")) {
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

// MARK: - Placeholder Extension

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        overlay(
            Group {
                if shouldShow {
                    placeholder()
                }
            }
        )
    }
}

struct QRView: View {
    let data: String
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .overlay(
                Image(systemName: "qrcode")
                    .font(.system(size: 80))
                    .foregroundColor(.black)
            )
    }
}
