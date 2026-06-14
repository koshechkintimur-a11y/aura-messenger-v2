import SwiftUI
import PhotosUI

struct ChatInfoView: View {
    @EnvironmentObject var vm: AuraViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showTransfer = false
    @State private var showDeleteConfirm = false
    @State private var showLeaveAlert = false
    @State private var avatarItem: PhotosPickerItem?
    
    var room: ChatRoom? { vm.currentRoom }
    
    var body: some View {
        NavigationStack {
            List {
                // Avatar + name
                Section {
                    HStack(spacing: 16) {
                        if let room = room, room.admins.contains(vm.profile.tag) {
                            PhotosPicker(selection: $avatarItem, matching: .images) {
                                avatarView
                            }
                        } else {
                            avatarView
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(room?.name ?? "Чат").font(.headline)
                            if let desc = room?.url, !desc.isEmpty {
                                Text(desc).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .onChange(of: avatarItem) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let idx = vm.rooms.firstIndex(where: { $0.id == vm.currentRoomId }) {
                                vm.rooms[idx].avatarBase64 = data.base64EncodedString()
                                vm.saveAll()
                            }
                        }
                    }
                }
                
                // Info
                Section("Информация") {
                    if room?.isPublic == true {
                        HStack { Text("URL"); Spacer(); Text(room?.url ?? "-").foregroundColor(.secondary).font(.caption) }
                    }
                    HStack { Text("Участников"); Spacer(); Text("\(room?.members.count ?? 0)").foregroundColor(.secondary) }
                    HStack { Text("Создан"); Spacer(); Text(room?.createdAt ?? Date(), style: .date).foregroundColor(.secondary).font(.caption) }
                }
                
                // Members
                Section("Участники (\(room?.members.count ?? 0))") {
                    ForEach(room?.members ?? [], id: \.self) { tag in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.15)).frame(width: 32, height: 32)
                                Text(String(tag.prefix(1)).uppercased()).font(.caption).foregroundColor(.blue)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("@\(tag)").font(.subheadline)
                                    if room?.admins.contains(tag) == true {
                                        Text("Админ").font(.caption2).foregroundColor(.orange).padding(.horizontal, 6).padding(.vertical, 1)
                                            .background(Color.orange.opacity(0.15)).cornerRadius(4)
                                    }
                                }
                                HStack(spacing: 4) {
                                    Circle().fill(vm.onlineUsers.contains(tag) ? Color.green : Color.gray).frame(width: 6, height: 6)
                                    Text(vm.onlineUsers.contains(tag) ? "онлайн" : "офлайн").font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Admin actions
                if let room = room, room.admins.contains(vm.profile.tag) {
                    Section("Управление") {
                        Button { showTransfer = true } label: { Label("Передать права", systemImage: "arrow.right.circle") }
                        Button(role: .destructive) { showDeleteConfirm = true } label: { Label("Удалить чат", systemImage: "trash") }
                    }
                }
                
                Section {
                    Button { showLeaveAlert = true } label: { Label("Покинуть чат", systemImage: "arrow.right.square").foregroundColor(.red) }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Информация")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Удалить чат?", isPresented: $showDeleteConfirm) {
                Button("Удалить", role: .destructive) {
                    if let id = vm.currentRoomId { vm.deleteRoom(roomId: id); dismiss() }
                }
            }
            .alert("Покинуть чат?", isPresented: $showLeaveAlert) {
                Button("Покинуть", role: .destructive) {
                    if let id = vm.currentRoomId { vm.leaveRoom(roomId: id); dismiss() }
                }
                Button("Отмена", role: .cancel) {}
            }
            .alert("Передать права", isPresented: $showTransfer) {
                if let members = room?.members.filter({ $0 != vm.profile.tag }) {
                    ForEach(members, id: \.self) { tag in
                        Button("@\(tag)") { vm.transferAdmin(roomId: vm.currentRoomId ?? "", to: tag) }
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: { Text("Выберите нового администратора") }
        }
        .preferredColorScheme(.dark)
    }
    
    var avatarView: some View {
        Group {
            if let b64 = room?.avatarBase64, let d = Data(base64Encoded: b64), let img = UIImage(data: d) {
                Image(uiImage: img).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(Circle())
            } else {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.15)).frame(width: 60, height: 60)
                    Text(String(room?.name.prefix(1) ?? "?").uppercased()).font(.title2).foregroundColor(.blue)
                }
            }
        }
    }
}
