import SwiftUI

struct RoomInfo: Identifiable {
    let id = UUID()
    var name: String
    var lastMessage: String
    var time: String
    var folder: String
}

struct ChatListView: View {
    @State var rooms: [RoomInfo] = [
        RoomInfo(name: "Семейный чат", lastMessage: "Привет!", time: "12:34", folder: "Семья"),
        RoomInfo(name: "Рабочая группа", lastMessage: "Файлы готовы", time: "09:15", folder: "Работа"),
    ]
    @State var selectedFolder = "Все чаты"
    @State var showingCreateRoom = false
    @State var showingNewFolder = false
    @State var newFolderName = ""
    
    let accentColor = Color(red: 0, green: 0.48, blue: 1.0)
    
    var folders: [String] {
        ["Все чаты"] + Set(rooms.map(\.folder)).sorted()
    }
    
    var filtered: [RoomInfo] {
        selectedFolder == "Все чаты" ? rooms : rooms.filter { $0.folder == selectedFolder }
    }
    
    var body: some View {
        NavigationStack {
            roomContent
                .navigationTitle("Чаты")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showingCreateRoom) { CreateRoomView() }
                .alert("Новая папка", isPresented: $showingNewFolder) {
                    TextField("Название", text: $newFolderName)
                    Button("Создать") {}
                    Button("Отмена", role: .cancel) {}
                }
        }
        .preferredColorScheme(.dark)
    }
    
    var roomContent: some View {
        VStack(spacing: 0) {
            folderBar
            chatList
        }
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
    
    var chatList: some View {
        List(filtered) { room in
            NavigationLink { ChatRoomView(roomName: room.name) } label: {
                chatRow(room)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    rooms.removeAll { $0.id == room.id }
                } label: { Label("Удалить", systemImage: "trash") }
            }
        }
        .listStyle(.plain)
    }
    
    func chatRow(_ room: RoomInfo) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accentColor.opacity(0.15)).frame(width: 44, height: 44)
                Text(String(room.name.prefix(1)).uppercased())
                    .font(.headline).foregroundColor(accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name).font(.body).foregroundColor(.primary)
                Text(room.lastMessage).font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Text(room.time).font(.caption2).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
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
}
