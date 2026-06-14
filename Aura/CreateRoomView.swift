import SwiftUI
import PhotosUI

struct CreateRoomView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var roomName: String = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var isPublic: Bool = false
    @State private var roomURL: String = ""

    @State private var isCreated: Bool = false
    @State private var generatedLink: String = ""
    @State private var tagInput: String = ""
    @State private var showCopied: Bool = false

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
                        } else {
                            createdView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Создать чат", displayMode: .inline)
            .toolbarBackground(background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

            CustomTextField(title: "Название чата", text: $roomName)

            Toggle("Публичный чат", isOn: $isPublic)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .tint(accent)

            if isPublic {
                CustomTextField(title: "URL (латиница, цифры, '-')", text: $roomURL)
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
        generatedLink = "https://aura.chat/j/\(roomURL.isEmpty ? UUID().uuidString.prefix(8).lowercased() : roomURL)"
        withAnimation(.easeInOut(duration: 0.3)) {
            isCreated = true
        }
    }

    // MARK: - После создания

    private var createdView: some View {
        VStack(spacing: 24) {
            // QR
            VStack(spacing: 8) {
                Text("QR-код приглашения")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                QRView(data: generatedLink)
                    .frame(width: 180, height: 180)
            }

            // Ссылка
            VStack(alignment: .leading, spacing: 6) {
                Text("Ссылка приглашения")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                HStack(spacing: 12) {
                    Text(generatedLink)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = generatedLink
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showCopied = false }
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accent)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }

            if showCopied {
                Text("Скопировано!")
                    .font(.system(size: 13))
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            // Тег + отправить
            VStack(alignment: .leading, spacing: 6) {
                Text("Отправить по тегу")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                HStack(spacing: 12) {
                    Text("@")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    TextField("", text: $tagInput)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                    Button(action: {}) {
                        Text("Отправить")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(accent)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }

            Spacer(minLength: 40)
        }
    }
}

// MARK: - Вспомогательные компоненты

struct CustomTextField: View {
    let title: String
    @Binding var text: String

    private let accent = Color(hex: "#5A9FEE")

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
            TextField("", text: $text)
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
    }
}

struct QRView: View {
    let data: String
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .overlay(
                Image(systemName: "qrcode")
                    .font(.system(size: 80))
                    .foregroundColor(.black)
            )
    }
}

extension Color {
    init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitesAndNewlines)
        let clean = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        var rgb: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&rgb)
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}
