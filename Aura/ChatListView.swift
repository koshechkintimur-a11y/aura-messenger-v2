import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var vm: AuraViewModel
    @State private var showCreate = false
    @State private var showDeleteConfirm = false
    @State private var roomToDelete: ChatRoom?
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.rooms.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "message.badge.waveform.fill").font(.system(size: 50)).foregroundColor(.blue.opacity(0.4))
                        Text("Нет чатов").font(.title3).foregroundColor(.secondary)
                        Text("Нажмите + чтобы создать").font(.subheadline).foregroundColor(.secondary)
                        Button { showCreate = true } label: {
                            Label("Создать чат", systemImage: "plus").padding(.horizontal, 24).padding(.vertical, 12)
                                .background(Color.blue).foregroundColor(.white).cornerRadius(12)
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(vm.rooms) { room in
                            NavigationLink {
                                ChatRoomView().environmentObject(vm).onAppear { vm.currentRoomId = room.id }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color.blue.opacity(0.15)).frame(width: 44, height: 44)
                                        Text(String(room.name.prefix(1)).uppercased()).font(.headline).foregroundColor(.blue)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(room.name).font(.body).foregroundColor(.primary)
                                            if room.name == "Избранное" {
                                                Image(systemName: "star.fill").font(.caption2).foregroundColor(.yellow)
                                            }
                                        }
                                        Text("\(room.members.count) участников").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if room.isPublic {
                                        Image(systemName: "globe").font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { roomToDelete = room; showDeleteConfirm = true } label: { Label("Удалить", systemImage: "trash") }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Чаты")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreate = true } label: { Image(systemName: "plus").font(.title3).foregroundColor(.blue) }
                }
            }
            .sheet(isPresented: $showCreate) { CreateRoomView().environmentObject(vm) }
            .confirmationDialog("Удалить чат?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) { if let r = roomToDelete { vm.deleteRoom(roomId: r.id) } }
                Button("Отмена", role: .cancel) {}
            } message: { Text("Чат будет удалён безвозвратно") }
        }
        .preferredColorScheme(.dark)
    }
}
