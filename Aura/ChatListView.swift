import SwiftUI

struct RoomInfo: Identifiable {
    let id = UUID()
    var name: String
    var lastMessage: String
    var time: String
    var folder: String
}

struct ChatListView: View {
    @State private var rooms: [RoomInfo] = [
        RoomInfo(name: "Семейный чат", lastMessage: "Привет!", time: "12:34", folder: "Семья"),
        RoomInfo(name: "Рабочая группа", lastMessage: "Файлы готовы", time: "09:15", folder: "Работа"),
    ]
    @State private var selectedFolder = "Все чаты"
    @State private var showingCreateRoom = false
    @State private var showingNewFolder = false
    @State private var newFolderName = ""
    
    let accentColor = Color(red: 0, green: 0.48, blue: 1.0)
    
    private var folders: [String] {
        var result = ["Все чаты"]
        let names = Set(rooms.map { $0.folder })
        result.append(contentsOf: names.sorted())
        return result
    }
    
    private var filteredRooms: [RoomInfo] {
        if selectedFolder == "Все чаты" { return rooms }
        return rooms.filter { $0.folder == selectedFolder }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Folder picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(folders, id: \.self) { folder in
                            Button {
                                selectedFolder = folder
                            } label: {
                                Text(folder)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(selectedFolder == folder ? accentColor : Color(.systemGray5))
                                    .foregroundColor(selectedFolder == folder ? .white : .secondary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Chat list
                List {
                    ForEach(filteredRooms) { room in
                        NavigationLink {
                            ChatRoomView(roomName: room.name)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(accentColor.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Text(String(room.name.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(accentColor)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(room.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(room.lastMessage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(room.time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                rooms.removeAll { $0.id == room.id }
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
            .navigationTitle("Чаты")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCreateRoom = true } label: {
                        Image(systemName: "plus").font(.title3).foregroundColor(accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingNewFolder = true } label: {
                        Image(systemName: "folder.badge.plus").foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoom) { CreateRoomView() }
            .alert("Новая папка", isPresented: $showingNewFolder) {
                TextField("Название", text: $newFolderName)
                Button("Создать") { showingNewFolder = false }
                Button("Отмена", role: .cancel) { }
            }
        }
        .preferredColorScheme(.dark)
    }
}
