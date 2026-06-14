import SwiftUI
import PhotosUI

struct CreateRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AuraViewModel

    @State private var roomName: String = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var isPublic: Bool = false
    @State private var roomURL: String = ""

    @State private var isCreated: Bool = false
    @State private var createdRoomId: String = ""
    @State private var generatedLink: String = ""
    @State private var tagInput: String = ""
    @State private var showCopied: Bool = false
    @State private var showInviteSheet: Bool = false

    private let accent = Color(hex: "#5A9FEE")
    private let background = Color(hex: "#0A0A0F")

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if !isCreated {
                            createForm
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Создать чат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(isPresented: $isCreated) {
                ChatRoomView()
                    .environmentObject(viewModel)
            }
        }
    }

    // MARK: - Форма создания

    private var createForm: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 60, height: 60)
                    if let avatarImage {
                        avatarImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22))
                            .foregroundColor(accent)
                    }
                }
            }
            .onChange(of: avatarItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        avatarImage = Image(uiImage: uiImage)
                    }
                }
            }

            // Название чата
            VStack(alignment: .leading, spacing: 6) {
                Text("Название чата")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                TextField("", text: $roomName)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            // Публичный чат toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Публичный чат", isOn: $isPublic)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .tint(accent)
                Text("Публичный чат доступен для поиска по URL. Приватный — только по приглашению.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(nil)
            }

            if isPublic {
                VStack(alignment: .leading, spacing: 6) {
                    Text("URL чата")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                    TextField("", text: $roomURL)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    Text("Уникальный адрес: aura.app/c/ВАШ-URL. Только латиница, цифры и дефис.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(nil)
                }
            }

            Button(action: createRoom) {
                Text("Создать чат")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accent)
                    .cornerRadius(12)
            }
        }
    }

    private func createRoom() {
        guard !roomName.isEmpty else { return }
        let slug = roomURL.isEmpty ? UUID().uuidString.prefix(8).lowercased() : roomURL
        generatedLink = "https://aura.app/c/\(slug)"
        let room = viewModel.createRoom(name: roomName, isPublic: isPublic, url: isPublic ? slug : nil)
        createdRoomId = room.id
        viewModel.currentRoomId = room.id
        withAnimation(.easeInOut(duration: 0.3)) {
            isCreated = true
        }
    }
}
