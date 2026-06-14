import SwiftUI

struct CreateRoomView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomName: String = ""
    @State private var tag: String = ""
    @State private var createdRoomId: String? = nil
    @State private var inviteLink: String = ""
    @State private var showingShareSheet = false
    
    private var isValidRoomName: Bool {
        !roomName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var generatedLink: String {
        if inviteLink.isEmpty {
            return "https://aura.app/j/\(createdRoomId ?? "xxx")"
        }
        return inviteLink
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if createdRoomId == nil {
                        createRoomSection
                    } else {
                        roomCreatedSection
                    }
                }
                .padding()
            }
            .navigationTitle("Создать чат")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var createRoomSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Название чата")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Введите название", text: $roomName)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .foregroundColor(.primary)
            }
            
            Button {
                createRoom()
            } label: {
                Text("Создать")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidRoomName ? Color(red: 0, green: 0.48, blue: 1.0) : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!isValidRoomName)
        }
    }
    
    private var roomCreatedSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                
                Text("Чат создан!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(roomName)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Ссылка-приглашение")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Text(generatedLink)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = generatedLink
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Поделиться")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0, green: 0.48, blue: 1.0))
                .cornerRadius(12)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [generatedLink])
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Пригласить по @тегу")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    TextField("@username", text: $tag)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .foregroundColor(.primary)
                    
                    Button {
                        sendInviteByTag()
                    } label: {
                        Text("Отправить")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color(red: 0, green: 0.48, blue: 1.0))
                            .cornerRadius(12)
                    }
                }
            }
            
            Button {
                dismiss()
            } label: {
                Text("Войти в чат")
                    .font(.headline)
                    .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0, green: 0.48, blue: 1.0), lineWidth: 2)
                    )
            }
        }
    }
    
    private func createRoom() {
        let newId = UUID().uuidString.prefix(8).uppercased()
        createdRoomId = String(newId)
        inviteLink = "https://aura.app/j/\(createdRoomId ?? "xxx")"
    }
    
    private func sendInviteByTag() {
        guard !tag.isEmpty else { return }
        tag = ""
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CreateRoomView()
}
