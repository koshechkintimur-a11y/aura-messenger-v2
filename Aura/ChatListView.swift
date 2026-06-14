import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @State private var selectedFolder = "Избранное"
    @State private var showingCreateRoom = false
    @State private var showingNewFolder = false
    @State private var newFolderName = ""
    @State private var showDeleteConfirmation: ChatRoom? = nil
    @State private var folders: [String] = ["Избранное"]
    
    private let accent = Color(red: 0, green: 0.48, blue: 1.0)
    private let bgColor = Color(0x0A0A0F)
    private let cardColor = Color(0x1C1C24)
    
    private var filteredRooms: [ChatRoom] {
        if selectedFolder == "Избранное" {
            return viewModel.rooms
        }
        return viewModel.rooms
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                if viewModel.rooms.isEmpty {
                    emptyStateView
                } else {
                    roomContent
                }
            }
            .navigationTitle("Чаты")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingCreateRoom) { CreateRoomView() }
            .alert("Новая папка", isPresented: $showingNewFolder) {
                TextField("Название папки", text: $newFolderName)
                Button("Создать") {
                    if !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty {
                        folders.append(newFolderName.trimmingCharacters(in: .whitespaces))
                        newFolderName = ""
                    }
                }
                Button("Отмена", role: .cancel) {
                    newFolderName = ""
                }
            }
            .alert("Точно удалить?", isPresented: .init(
                get: { showDeleteConfirmation != nil },
                set: { if !$0 { showDeleteConfirmation = nil } }
            )) {
                Button("Отмена", role: .cancel) {
                    showDeleteConfirmation = nil
                }
                Button("Удалить", role: .destructive) {
                    if let room = showDeleteConfirmation {
                        deleteRoom(room)
                    }
                }
            } message: {
                if let room = showDeleteConfirmation {
                    Text("Чат '\(room.name)' будет удалён безвозвратно.")
                        .font(.system(size: 14))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Ensure folders always has "Избранное"
            if !folders.contains("Избранное") {
                folders.insert("Избранное", at: 0)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "message.badge.plus")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(accent.opacity(0.4))
            
            Text("Нет чатов")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Создайте новый")
                .font(.system(size: 15))
                .foregroundColor(Color(0x8E8E93))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Room Content
    
    private var roomContent: some View {
        VStack(spacing: 0) {
            folderBar
            chatList
        }
    }
    
    // MARK: - Folder Bar
    
    private var folderBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(folders, id: \\.self) { folder in
                    Button { selectedFolder = folder } label: {
                        HStack(spacing: 6) {
                            if folder == "Избранное" {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                            }
                            Text(folder)
                                .font(.system(size: 14, weight: folder == selectedFolder ? .semibold : .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(folder == selectedFolder ? accent : cardColor)
                        )
                        .foregroundColor(folder == selectedFolder ? .white : Color(0x8E8E93))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Chat List
    
    private var chatList: some View {
        List(filteredRooms) { room in
            roomRow(room)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = room
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
                .listRowBackground(bgColor)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .background(bgColor)
    }
    
    // MARK: - Room Row
    
    private func roomRow(_ room: ChatRoom) -> some View {
        NavigationLink {
            ChatRoomView()
                .environmentObject(viewModel)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Text(room.name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(room.members.count) участников")
                        .font(.system(size: 14))
                        .foregroundColor(Color(0x8E8E93))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(0x5C5C66))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { showingNewFolder = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(accent)
                }
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingCreateRoom = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accent)
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteRoom(_ room: ChatRoom) {
        if let index = viewModel.rooms.firstIndex(where: { $0.id == room.id }) {
            viewModel.rooms.remove(at: index)
            viewModel.persistenceGuard()
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(_ hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Persistence Extension (for ChatListView)

extension AuraViewModel {
    func persistenceGuard() {
        persistRooms()
    }
}
