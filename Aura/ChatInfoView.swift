import SwiftUI
import PhotosUI

struct ChatInfoView: View {
    @Environment(\.dismiss) private var dismiss

    // Данные чата (в реальности — ViewModel)
    @State private var roomName: String = "Aura Team"
    @State private var roomDescription: String = "Основной чат команды разработки Aura."
    @State private var isPublic: Bool = true
    @State private var roomURL: String = "aura-team"

    // Права
    @State private var isAdmin: Bool = true

    // Состояния UI
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var showTransferSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showLeaveAlert: Bool = false

    private let accent = Color(.systemGray6)
    private let background = Color(.systemGray6)

    // Участники (заглушка)
    @State private var members: [ChatMember] = [
        ChatMember(id: "1", name: "Алексей Н.", tag: "@aleksey", isOnline: true, isAdmin: false, avatar: "A"),
        ChatMember(id: "2", name: "Мария С.", tag: "@masha", isOnline: false, isAdmin: false, avatar: "M"),
        ChatMember(id: "3", name: "Игорь К.", tag: "@igor", isOnline: true, isAdmin: false, avatar: "I"),
        ChatMember(id: "4", name: "Елена В.", tag: "@elena", isOnline: true, isAdmin: false, avatar: "E")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        infoSection
                        membersSection
                        adminActionsSection
                        dangerSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Информация о чате")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showTransferSheet) {
                TransferOwnershipSheet(members: members, accent: accent, background: background) { selected in
                    // Передать правы selected
                }
            }
            .alert("Покинуть чат?", isPresented: $showLeaveAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Покинуть", role: .destructive) {
                    // Покинуть чат
                }
            } message: {
                Text(isAdmin ? "Вы админ. Передасте права перед выходом." : "Вы уверены, что хотите покинуть чат?")
            }
            .confirmationDialog("Удалить чат?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    // Удалить чат
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Это действие необратимо. Все сообщения и участники будут удалены.")
            }
        }
    }

    // MARK: - Шапка

    private var headerSection: some View {
        HStack(spacing: 16) {
            if isAdmin {
                PhotosPicker(selection: $avatarItem, matching: .images) {
                    avatarView
                }
            } else {
                avatarView
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(roomName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text(roomDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.15))
                .frame(width: 60, height: 60)
            if let avatarImage {
                avatarImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Text("A")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(accent)
                if isAdmin {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(accent)
                        .offset(x: 18, y: 18)
                }
            }
        }
    }

    // MARK: - Информация о чате

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            InfoRow(label: "Название", value: roomName)
            InfoRow(label: "Описание", value: roomDescription)
            if isPublic {
                InfoRow(label: "URL", value: "aura.chat/\(roomURL)")
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

    // MARK: - Участники

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Участники — \(members.count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            ForEach(members) { member in
                MemberRow(member: member, accent: accent)
            }
        }
    }

    // MARK: - Админ-панель

    private var adminActionsSection: some View {
        VStack(spacing: 12) {
            if isAdmin {
                Button(action: { showTransferSheet = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(accent)
                        Text("Передать права")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
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

            Button(action: { showLeaveAlert = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.backward.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.orange)
                    Text("Покинуть чат")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }

            if isAdmin {
                Button(action: { showDeleteConfirmation = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "trash.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                        Text("Удалить чат")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
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
        }
    }

    @ViewBuilder
    private var dangerSection: some View {
        EmptyView()
    }
}

// MARK: - InfoRow

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
            Spacer()
        }
    }
}

// MARK: - MemberRow

struct MemberRow: View {
    let member: ChatMember
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Text(member.avatar)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accent)
                }
                if member.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(member.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(member.tag)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - TransferOwnershipSheet

struct TransferOwnershipSheet: View {
    let members: [ChatMember]
    let accent: Color
    let background: Color
    let onSelect: (ChatMember) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                List {
                    ForEach(members) { member in
                        Button(action: {
                            onSelect(member)
                            dismiss()
                        }) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(accent.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Text(member.avatar)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(accent)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(member.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(member.tag)
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Передать права")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - ChatMember

struct ChatMember: Identifiable {
    let id: String
    let name: String
    let tag: String
    let isOnline: Bool
    let isAdmin: Bool
    let avatar: String
}
