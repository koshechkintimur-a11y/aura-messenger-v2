import SwiftUI
import PhotosUI

struct ProfileView: View {
    @AppStorage("profileName") private var profileName: String = ""
    @AppStorage("profileTag") private var profileTag: String = ""
    @AppStorage("profileAvatarData") private var profileAvatarData: Data = Data()

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil
    @State private var name: String = ""
    @State private var tag: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Аватар
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let avatarImage = avatarImage {
                        avatarImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 32))
                            )
                    }
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            profileAvatarData = data
                            if let uiImage = UIImage(data: data) {
                                avatarImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }

                // Поле Имя
                VStack(alignment: .leading, spacing: 8) {
                    Text("Имя")
                        .foregroundColor(.gray)
                        .font(.caption)
                    TextField("", text: $name)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }

                // Поле @тег
                VStack(alignment: .leading, spacing: 8) {
                    Text("Тег")
                        .foregroundColor(.gray)
                        .font(.caption)
                    HStack(spacing: 0) {
                        Text("@")
                            .foregroundColor(.gray)
                            .padding(.leading)
                        TextField("", text: $tag)
                            .foregroundColor(.white)
                            .padding(.vertical)
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }

                Spacer()

                // Кнопка сохранения
                Button(action: saveProfile) {
                    Text("Сохранить профиль")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .onAppear {
            name = profileName
            tag = profileTag
            if !profileAvatarData.isEmpty, let uiImage = UIImage(data: profileAvatarData) {
                avatarImage = Image(uiImage: uiImage)
            }
        }
    }

    private func saveProfile() {
        profileName = name
        profileTag = tag
    }
}

// Простые Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
