import SwiftUI

struct ReplyPreviewView: View {
    let senderName: String
    let messageText: String
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text(senderName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .lineLimit(1)

                Text(messageText)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct ReplyPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReplyPreviewView(
                senderName: "Алексей",
                messageText: "Привет! Как дела? Давно не виделись, надо встретиться.",
                onCancel: {}
            )
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
