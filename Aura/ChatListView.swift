import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @State private var selectedFolder = "Избранное"
    @State private var showingCreateRoom = false
    @State private var showingNewFolder = false
    @State private var newFolderName = ""
    @State private var roomToDelete: ChatRoom?
    @State private var showDeleteConfirm = false
    
    let accentColor = Color(red: 0, green: 0.48, blue: 1.0)
    
    var folders: [String] {
        ["Избранное"] + viewModel.folders
    }
    
    var filteredRooms: [ChatRoom] {
        if selectedFolder == "Избранное" { return viewModel.rooms }
        return viewModel.rooms.filter { $0.name == selectedFolder }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                folderBar
                roomContent
            }
            .navigationTitle("Чаты")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingNewFolder = true } label: {
                        Image(systemName: "folder.badge.plus").foregroundColor(accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCreateRoom = true } label: {
                        Image(systemName: "plus").font(.title3).foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoom) {
                CreateRoomView().environmentObject(viewModel)
            }
            .alert("Новая папка", isPresented: $showingNewFolder) {
                TextField("Название", text: $newFolderName)
                Button("Создать") {
                    let name = newFolderName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { viewModel.folders.append(name); viewModel.saveFolders() }
                    newFolderName = ""
                }
                Button("Отмена", role: .cancel) {}
            }
            .confirmationDialog("Удалить чат?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    if let room = roomToDelete { viewModel.deleteRoom(roomId: room.id) }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Чат будет удалён безвозвратно")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    var folderBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(folders, id: \.self) { f in
                    Button { selectedFolder = f } label: {
                        Text(f).font(.subheadline)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(f == selectedFolder ? accentColor : Color(.systemGray5))
                            .foregroundColor(f == selectedFolder ? .white : .secondary)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
    }
    
    var roomContent: some View {
        Group {
            if filteredRooms.isEmpty && selectedFolder != "Избранное" {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray").font(.system(size: 40)).foregroundColor(.secondary)
                    Text("Нет чатов").font(.title3).foregroundColor(.secondary)
                    Text("Создайте новый чат").font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                }
            } else if viewModel.rooms.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "message.badge.waveform.fill").font(.system(size: 50)).foregroundColor(accentColor.opacity(0.5))
                    Text("Нет чатов").font(.title3).foregroundColor(.secondary)
                    Text("Нажмите + чтобы создать").font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredRooms) { room in
                        NavigationLink {
                            ChatRoomView()
                                .environmentObject(viewModel)
                                .onAppear { viewModel.currentRoomId = room.id }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(accentColor.opacity(0.15)).frame(width: 44, height: 44)
                                    Text(String(room.name.prefix(1)).uppercased()).font(.headline).foregroundColor(accentColor)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(room.name).font(.body).foregroundColor(.primary)
                                    Text("\(room.members.count) участников").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                roomToDelete = room; showDeleteConfirm = true
                            } label: { Label("Удалить", systemImage: "trash") }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
