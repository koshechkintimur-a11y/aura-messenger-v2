import SwiftUI

struct JoinRoomView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var joinLink: String = ""
    @State private var invitations: [Invitation] = [
        Invitation(id: "1", roomName: "Дизайн-команда", sender: "Анна М.", avatar: "A"),
        Invitation(id: "2", roomName: "iOS Dev Chat", sender: "Игорь К.", avatar: "I"),
        Invitation(id: "3", roomName: "Общий проект", sender: "Мария С.", avatar: "M")
    ]

    private let accent = Color(.systemGray6)
    private let background = Color(.systemGray6)

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        joinSection
                        scanSection
                        invitationsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Вступить в чат", )
            .toolbarBackground(background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Вступить по ссылке

    private var joinSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ссылка на чат")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            HStack(spacing: 12) {
                TextField("/j/...", text: $joinLink)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                Button(action: joinByLink) {
                    Text("Войти")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(accent)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func joinByLink() {
        // Обработка ссылки
    }

    // MARK: - Сканировать QR

    private var scanSection: some View {
        Button(action: {
            // Открыть сканер QR
        }) {
            HStack(spacing: 10) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                Text("Сканировать QR")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Приглашения

    private var invitationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Приглашения")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 8)

            if invitations.isEmpty {
                Text("Новых приглашений нет")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(invitations) { invitation in
                    InvitationRow(
                        invitation: invitation,
                        onAccept: { acceptInvitation(invitation) },
                        onReject: { rejectInvitation(invitation) }
                    )
                }
            }
        }
    }

    private func acceptInvitation(_ invitation: Invitation) {
        withAnimation(.easeInOut(duration: 0.25)) {
            invitations.removeAll { $0.id == invitation.id }
        }
    }

    private func rejectInvitation(_ invitation: Invitation) {
        withAnimation(.easeInOut(duration: 0.25)) {
            invitations.removeAll { $0.id == invitation.id }
        }
    }
}

// MARK: - Модели

struct Invitation: Identifiable {
    let id: String
    let roomName: String
    let sender: String
    let avatar: String
}

// MARK: - InvitationRow

struct InvitationRow: View {
    let invitation: Invitation
    let onAccept: () -> Void
    let onReject: () -> Void

    private let accent = Color(.systemGray6)

    var body: some View {
        HStack(spacing: 12) {
            // Аватар
            ZStack {
                Circle()
                    .fill(accent.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(invitation.avatar)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(invitation.roomName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("От: \(invitation.sender)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Text("Принять")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accent)
                        .cornerRadius(8)
                }

                Button(action: onReject) {
                    Text("Отклонить")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
