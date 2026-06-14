import SwiftUI
import PhotosUI

struct ChatRoomView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var replyTo: ChatMessage?
    @State private var showInfo = false
    @State private var showInvite = false
    @State private var photoItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var showPreview = false
    @AppStorage("farcodeEnabled") private var farcodeEnabled = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            messagesScroll
            if let rep = replyTo { replyBar(rep) }
            inputBar
        }
        .background(Color.black)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .gesture(DragGesture().onEnded { g in if g.translation.width > 100 { dismiss() } })
        .sheet(isPresented: $showInfo) { ChatInfoView().environmentObject(viewModel) }
        .sheet(isPresented: $showInvite) { inviteSheet }
        .sheet(isPresented: $showPreview) {
            if let img = previewImage {
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: img).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
                    HStack {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        } label: {
                            Image(systemName: "square.and.arrow.down").font(.title2).foregroundColor(.white).padding()
                        }
                        Spacer()
                        Button { showPreview = false; previewImage = nil } label: {
                            Image(systemName: "xmark.circle.fill").font(.largeTitle).foregroundColor(.white).padding()
                        }
                    }
                }
            }
        }
        .onAppear { viewModel.setOnline(true) }
        .onDisappear { viewModel.setOnline(false) }
    }
    
    var header: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.title3).foregroundColor(.white) }
            Button { showInfo = true } label: {
                HStack(spacing: 10) {
                    Group {
                        if let b64 = viewModel.currentRoom?.avatarBase64, let d = Data(base64Encoded: b64), let img = UIImage(data: d) {
                            Image(uiImage: img).resizable().scaledToFill().frame(width: 36, height: 36).clipShape(Circle())
                        } else {
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.2)).frame(width: 36, height: 36)
                                Text(String(viewModel.currentRoom?.name.prefix(1) ?? "?")).font(.subheadline).foregroundColor(.blue)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(viewModel.currentRoom?.name ?? "Чат").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                        HStack(spacing: 4) {
                            Circle().fill(viewModel.isConnected ? Color.green : Color.red).frame(width: 6, height: 6)
                            Text(viewModel.isConnected ? "онлайн" : "офлайн").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
            Spacer()
            Button { showInvite = true } label: { Image(systemName: "person.badge.plus").font(.title3).foregroundColor(.white) }
        }
        .padding(.horizontal, 12).padding(.vertical, 8).background(Color(.systemGray6).opacity(0.95))
    }
    
    var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.currentMessages) { msg in
                        MessageBubble(
                            message: msg,
                            isOutgoing: msg.senderTag == viewModel.profile.tag,
                            onReply: { replyTo = msg },
                            onForward: { viewModel.forwardToFavorites(msg.id) },
                            onPin: { viewModel.pinMessage(msg.id, roomId: msg.roomId) },
                            onImageTap: { img in previewImage = img; showPreview = true },
                            farcodeEnabled: farcodeEnabled
                        ).id(msg.id).padding(.horizontal, 8)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
            }
            .onChange(of: viewModel.currentMessages.count) { _ in withAnimation { proxy.scrollTo("bottom") } }
            .onAppear { proxy.scrollTo("bottom") }
        }
    }
    
    var inputBar: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "paperclip").font(.body).foregroundColor(.secondary)
            }.onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self), let rid = viewModel.currentRoomId {
                        viewModel.sendPhoto(roomId: rid, imageData: data)
                        photoItem = nil
                    }
                }
            }
            TextField("Сообщение...", text: $text, axis: .vertical).lineLimit(1...5)
                .padding(.horizontal, 12).padding(.vertical, 8).background(Color(.systemGray5)).cornerRadius(20)
                .submitLabel(.send).onSubmit { send() }
            Button { send() } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
                    .foregroundColor(text.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .blue)
            }.disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 8).padding(.vertical, 6).background(Color(.systemGray6))
    }
    
    func send() {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, let rid = viewModel.currentRoomId else { return }
        viewModel.sendMessage(roomId: rid, text: t, replyToId: replyTo?.id)
        text = ""; replyTo = nil
    }
    
    func replyBar(_ msg: ChatMessage) -> some View {
        HStack {
            Rectangle().fill(Color.blue).frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(msg.senderName).font(.caption).fontWeight(.bold).foregroundColor(.blue)
                Text(msg.text).font(.caption2).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Button { replyTo = nil } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
        }.padding(.horizontal, 12).padding(.vertical, 8).background(Color(.systemGray6))
    }
    
    var inviteSheet: some View {
        NavigationStack {
            List {
                Section("Ссылка") {
                    HStack {
                        Text(viewModel.currentRoom?.url ?? "Создайте чат...").font(.caption.monospaced()).lineLimit(1)
                        Spacer()
                        Button { UIPasteboard.general.string = viewModel.currentRoom?.url } label: { Image(systemName: "doc.on.doc") }
                    }
                }
                Section("QR") { Text("QR-код").font(.caption).foregroundColor(.secondary) }
                Section("Пригласить по @тегу") {
                    HStack { TextField("@username", text: .constant("")); Button("Отправить") {} }
                }
            }.navigationTitle("Пригласить").navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: ChatMessage
    let isOutgoing: Bool
    var onReply: () -> Void = {}
    var onForward: () -> Void = {}
    var onPin: () -> Void = {}
    var onImageTap: (UIImage) -> Void = { _ in }
    var farcodeEnabled: Bool = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isOutgoing { Spacer(minLength: 60) }
            if !isOutgoing {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.2)).frame(width: 28, height: 28)
                    Text(String(message.senderName.prefix(1)).uppercased()).font(.caption2).foregroundColor(.blue)
                }
            }
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 2) {
                if !isOutgoing && !message.senderName.isEmpty {
                    Text(message.senderName).font(.caption2).foregroundColor(.secondary)
                }
                if let img = message.imageBase64, let d = Data(base64Encoded: img), let ui = UIImage(data: d) {
                    Image(uiImage: ui).resizable().scaledToFit().frame(maxWidth: 200).cornerRadius(12)
                        .onTapGesture { onImageTap(ui) }
                }
                if !message.text.isEmpty {
                    Text(message.text).font(.body).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(isOutgoing ? Color.blue : Color(.systemGray5))
                        .foregroundColor(isOutgoing ? .white : .primary).cornerRadius(16)
                }
                HStack(spacing: 3) {
                    Text(message.timestamp, style: .time).font(.system(size: 10)).foregroundColor(.secondary)
                    if isOutgoing {
                        switch message.status {
                        case .sending: Image(systemName: "clock").font(.system(size: 8))
                        case .sent: Image(systemName: "checkmark").font(.system(size: 8))
                        case .delivered: Image(systemName: "checkmark.circle").font(.system(size: 8))
                        case .read: Image(systemName: "checkmark.circle.fill").font(.system(size: 8)).foregroundColor(.green)
                        }
                    }
                }
            }
            .contextMenu {
                Button { UIPasteboard.general.string = message.text } label: { Label("Копировать", systemImage: "doc.on.doc") }
                Button { onReply() } label: { Label("Ответить", systemImage: "arrowshape.turn.up.left") }
                Button { onForward() } label: { Label("В Избранное", systemImage: "star") }
                Button { onPin() } label: { Label(message.isPinned ? "Открепить" : "Закрепить", systemImage: "pin") }
                if let imgB64 = message.imageBase64, let d = Data(base64Encoded: imgB64), let img = UIImage(data: d) {
                    Button { UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil) } label: { Label("Сохранить фото", systemImage: "square.and.arrow.down") }
                }
                if farcodeEnabled {
                    Text("Вес: \(max(1, (message.text.utf8.count + (message.imageBase64?.utf8.count ?? 0)) / 1024))KB").font(.caption2).foregroundColor(.secondary)
                }
            }
            if !isOutgoing { Spacer(minLength: 60) }
        }.padding(.vertical, 1)
    }
}
