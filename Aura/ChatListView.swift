import SwiftUI

struct RoomInfo: Identifiable, Hashable {
    let id: String
    var name: String
    var lastMessage: String
    var time: String
    var folder: String
    var avatarLetter: String
}

struct ChatListView: View {
    @State private var rooms: [RoomInfo] = [
        RoomInfo(id: "1", name: "Общий чат", lastMessage: "Привет всем! Как дела?", time: "10:42", folder: "Все чаты", avatarLetter: "О"),
        RoomInfo(id: "2", name: "Разработка", lastMessage: "Обновили зависимости", time: "09:15", folder: "Все чаты", avatarLetter: "Р"),
        RoomInfo(id: "3", name: "Дизайн", lastMessage: "Новые макеты готовы", time: "Вчера", folder: "Все чаты", avatarLetter: "Д"),
        RoomInfo(id: "4", name: "Тестировщики", lastMessage: "Баг воспроизводится", time: "Вчера", folder: "Работа", avatarLetter: "Т"),
        RoomInfo(id: "5", name: "HR", lastMessage: "Встреча в пятницу", time: "Пн", folder: "Работа", avatarLetter: "H"),
        RoomInfo(id: "6", name: "Семья", lastMessage: "Ужин в 19:00", time: "Вс", folder: "Личное", avatarLetter: "С"),
    ]
    
    @State private var selectedFolder: String = "Все чаты"
    @State private var showingCreateRoom = false
    @State private var showingNewFolder = false
    @State private var newFolderName: String = ""
    
    private var folders: [String] {
        let allFolders = rooms.map { $0.folder }
        let uniqueFolders = Set(allFolders)
        return Array(uniqueFolders).sorted()
    }
    
    private var filteredRooms: [RoomInfo] {
        if selectedFolder == "Все чаты" {
            return rooms
        }
        return rooms.filter { $0.folder == selectedFolder }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRooms) { room in
                    NavigationLink(value: room) {
                        ChatRow(room: room)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                rooms.removeAll { $0.id == room.id }
                            }
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            .navigationTitle("Чаты")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateRoom = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingNewFolder = true
                    } label: {
                        Text("Новая папка")
                            .font(.subheadline)
                            .foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoom) {
                CreateRoomView()
            }
            .alert("Новая папка", isPresented: $showingNewFolder) {
                TextField("Название папки", text: $newFolderName)
                Button("Отмена", role: .cancel) { newFolderName = "" }
                Button("Создать") {
                    if !newFolderName.isEmpty {
                        newFolderName = ""
                    }
                }
            } message: {
                Text("Введите название новой папки")
            }
            .navigationDestination(for: RoomInfo.self) { room in
                ChatRoomView(room: room)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var accentColor: Color {
        Color(red: 0, green: 0.48, blue: 1.0)
    }
}

struct ChatRow: View {
    let room: RoomInfo
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(red: 0, green: 0.48, blue: 1.0).opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(room.avatarLetter)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(room.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(room.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(room.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ChatListView()
}
