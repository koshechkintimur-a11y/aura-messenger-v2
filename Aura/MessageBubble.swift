import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    private var bubbleColor: Color {
        switch message.type {
        case .outgoing:
            return Color(red: 0, green: 0.48, blue: 1.0)
        case .incoming:
            return Color.gray.opacity(0.3)
        case .system:
            return Color.gray.opacity(0.5)
        }
    }
    
    private var textColor: Color {
        switch message.type {
        case .outgoing:
            return .white
        case .incoming:
            return .primary
        case .system:
            return .white
        }
    }
    
    private var alignment: HorizontalAlignment {
        switch message.type {
        case .outgoing:
            return .trailing
        case .incoming:
            return .leading
        case .system:
            return .center
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            if message.type == .outgoing {
                Spacer()
            }
            
            VStack(alignment: alignment == .trailing ? .trailing : (alignment == .leading ? .leading : .center), spacing: 2) {
                if let sender = message.senderName, message.type == .incoming {
                    Text(sender)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(message.text)
                    .font(.body)
                    .foregroundColor(textColor)
                    .padding(10)
                    .background(bubbleColor)
                    .cornerRadius(12)
                
                Text(timeFormatter.string(from: message.time))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if message.type == .incoming || message.type == .system {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            MessageBubble(message: ChatMessage(text: "Привет! Это моё сообщение.", time: Date(), type: .outgoing, senderName: nil))
            MessageBubble(message: ChatMessage(text: "Привет! Ответ собеседника.", time: Date(), type: .incoming, senderName: "Алексей"))
            MessageBubble(message: ChatMessage(text: "Пользователь вышел из комнаты", time: Date(), type: .system, senderName: nil))
        }
        .background(Color.black)
    }
}
