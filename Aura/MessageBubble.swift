import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    let isOutgoing: Bool
    let onReply: () -> Void
    let onForward: () -> Void
    let onPin: () -> Void
    
    var body: some View {
        VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 2) {
            if message.isPinned {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill").font(.system(size: 8))
                    Text("Закреплено").font(.system(size: 10))
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
            }
            
            if let replyId = message.replyToId, !replyId.isEmpty {
                Text("↩ Ответ").font(.system(size: 10)).foregroundColor(.secondary)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                if isOutgoing { Spacer(minLength: 60) }
                
                VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 2) {
                    if !isOutgoing && !message.senderName.isEmpty {
                        Text(message.senderName)
                            .font(.system(size: 11)).foregroundColor(.secondary)
                    }
                    
                    if let imageB64 = message.imageBase64, !imageB64.isEmpty,
                       let data = Data(base64Encoded: imageB64),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable().scaledToFit()
                            .frame(maxWidth: 200).cornerRadius(12)
                    } else {
                        Text(message.text)
                            .font(.body)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(isOutgoing ? Color(red: 0, green: 0.48, blue: 1.0) : Color(.systemGray5))
                            .foregroundColor(isOutgoing ? .white : .primary)
                            .cornerRadius(16)
                    }
                    
                    HStack(spacing: 4) {
                        Text(message.timestamp, style: .time)
                            .font(.system(size: 10)).foregroundColor(.secondary)
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
                    Button { UIPasteboard.general.string = message.text } label: {
                        Label("Копировать", systemImage: "doc.on.doc")
                    }
                    Button { onReply() } label: {
                        Label("Ответить", systemImage: "arrowshape.turn.up.left")
                    }
                    Button { onForward() } label: {
                        Label("Переслать", systemImage: "arrowshape.turn.up.right")
                    }
                    Button { onPin() } label: {
                        Label(message.isPinned ? "Открепить" : "Закрепить", systemImage: message.isPinned ? "pin.slash" : "pin")
                    }
                }
                
                if !isOutgoing { Spacer(minLength: 60) }
            }
        }
        .padding(.vertical, 2)
    }
}
