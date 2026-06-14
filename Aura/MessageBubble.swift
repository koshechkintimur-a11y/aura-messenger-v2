import SwiftUI

struct MessageBubble: View {
    let message: AuraMessage
    
    private var bubbleColor: Color {
        switch message.type {
        case .own:
            return Color(red: 0, green: 0.48, blue: 1.0)
        case .other:
            return Color.gray.opacity(0.3)
        case .system:
            return Color.gray.opacity(0.5)
        }
    }
    
    private var textColor: Color {
        switch message.type {
        case .own:
            return .white
        case .other:
            return .primary
        case .system:
            return .white
        }
    }
    
    private var alignment: HorizontalAlignment {
        switch message.type {
        case .own:
            return .trailing
        case .other:
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
            if message.type == .own {
                Spacer()
            }
            
            VStack(alignment: alignment == .trailing ? .trailing : (alignment == .leading ? .leading : .center), spacing: 2) {
                if let sender = message.senderName, message.type == .other {
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
            
            if message.type == .other || message.type == .system {
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
            MessageBubble(message: AuraMessage(text: "Привет! Это моё сообщение.", time: Date(), type: .own, senderName: nil))
            MessageBubble(message: AuraMessage(text: "Привет! Ответ собеседника.", time: Date(), type: .other, senderName: "Алексей"))
            MessageBubble(message: AuraMessage(text: "Пользователь вышел из комнаты", time: Date(), type: .system, senderName: nil))
        }
        .background(Color.black)
    }
}
