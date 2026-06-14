import SwiftUI

struct JoinRoomView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var inviteLink: String = ""
    @State private var isJoining = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var pendingInvites: [PendingInvite] = [
        PendingInvite(id: "1", fromUser: "@alex", roomName: "Разработка"),
        PendingInvite(id: "2", fromUser: "@maria", roomName: "Дизайн-команда"),
    ]
    
    private var isValidLink: Bool {
        !inviteLink.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    joinLinkSection
                    
                    scanQRSection
                    
                    pendingInvitesSection
                }
                .padding()
            }
            .navigationTitle("Вступить в чат")
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
    
    private var joinLinkSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ссылка или /j/...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Введите ссылку-приглашение", text: $inviteLink)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .foregroundColor(.primary)
            }
            
            Button {
                joinRoom()
            } label: {
                HStack {
                    if isJoining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Войти")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidLink ? Color(red: 0, green: 0.48, blue: 1.0) : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isValidLink || isJoining)
        }
    }
    
    private var scanQRSection: some View {
        Button {
            scanQRCode()
        } label: {
            HStack {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                Text("Сканировать QR")
                    .font(.headline)
            }
            .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0, green: 0.48, blue: 1.0), lineWidth: 2)
            )
        }
    }
    
    private var pendingInvitesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Приглашения по @тегу")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if pendingInvites.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "envelope.open")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Нет ожидающих приглашений")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(pendingInvites) { invite in
                    PendingInviteRow(invite: invite) {
                        acceptInvite(invite)
                    }
                }
            }
        }
    }
    
    private func joinRoom() {
        guard !inviteLink.isEmpty else { return }
        
        isJoining = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isJoining = false
            dismiss()
        }
    }
    
    private func scanQRCode() {
        // Здесь будет логика сканирования QR-кода
    }
    
    private func acceptInvite(_ invite: PendingInvite) {
        withAnimation {
            pendingInvites.removeAll { $0.id == invite.id }
        }
        dismiss()
    }
}

struct PendingInvite: Identifiable {
    let id: String
    let fromUser: String
    let roomName: String
}

struct PendingInviteRow: View {
    let invite: PendingInvite
    let onAccept: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(red: 0, green: 0.48, blue: 1.0).opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(invite.fromUser.dropFirst().prefix(1).uppercased()))
                        .font(.headline)
                        .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(invite.roomName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("от \(invite.fromUser)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                onAccept()
            } label: {
                Text("Принять")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0, green: 0.48, blue: 1.0))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}

#Preview {
    JoinRoomView()
}
