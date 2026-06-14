import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var tag: String = ""  
    @State private var email: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var tagError: String = ""  

    private var isTagValid: Bool {
        let validation = viewModel.validateTag(tag)
        return validation.isValid
    }

    private var tagValidationError: String? {
        let validation = viewModel.validateTag(tag)
        return validation.error
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Avatar
                avatarSection
                    .padding(.top, 20)
                    .padding(.bottom, 32)

                // Form
                formSection
                    .padding(.horizontal, 20)

                Spacer(minLength: 40)

                // Save Button
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .background(Color(0x0A0A0F))
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            firstName = viewModel.profile.firstName
            lastName = viewModel.profile.lastName
            tag = viewModel.profile.tag
            email = viewModel.profile.email
            if let base64 = viewModel.profile.avatarBase64 {
                loadAvatarFromBase64(base64)
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(0x1C1C24))
                        .frame(width: 100, height: 100)

                    if let avatarImage = avatarImage {
                        avatarImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Text(viewModel.profile.initials.isEmpty ? "👤" : viewModel.profile.initials)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(Color(0x8E8E93))
                    }

                    // Edit overlay
                    Circle()
                        .fill(Color(0x2C2C34))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(0x8E8E93))
                        )
                        .offset(x: 34, y: 34)
                }

                Text("Изменить фото")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(0x5A9FEE))
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        avatarImage = Image(uiImage: uiImage)
                        let base64 = data.base64EncodedString()
                        var updatedProfile = viewModel.profile
                        updatedProfile.avatarBase64 = base64
                        viewModel.saveProfile(updatedProfile)
                    }
                }
            }
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 0) {
            // Name
            profileTextField(
                title: "Имя",
                text: $firstName,
                placeholder: "Введите имя",
                icon: "person.fill"
            )

            Divider()
                .background(Color(0x2C2C34))
                .padding(.leading, 52)

            // Last name
            profileTextField(
                title: "Фамилия",
                text: $lastName,
                placeholder: "Не указана",
                icon: "person.fill"
            )

            Divider()
                .background(Color(0x2C2C34))
                .padding(.leading, 52)

            // Tag
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "at")
                        .font(.system(size: 17))
                        .foregroundColor(Color(0x8E8E93))
                        .frame(width: 24)

                    TextField("", text: $tag)
                        .placeholder(when: tag.isEmpty) {
                            Text("@тег")
                                .foregroundColor(Color(0x5C5C66))
                        }
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                }
                .padding(.vertical, 14)

                if let error = tagValidationError, !tag.isEmpty {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(0xFF453A))
                        .padding(.leading, 36)
                        .padding(.bottom, 6)
                }
            }

            Divider()
                .background(Color(0x2C2C34))
                .padding(.leading, 52)

            // Email
            profileTextField(
                title: "Email",
                text: $email,
                placeholder: "Для восстановления доступа",
                icon: "envelope.fill"
            )

            if showError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(Color(0xFF453A))
                    .padding(.top, 12)
                    .padding(.leading, 36)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(0x1C1C24))
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack {
                Spacer()
                Text("Сохранить")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isTagValid ? Color(0x5A9FEE) : Color(0x2C2C34))
            )
        }
        .disabled(!isTagValid)
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func profileTextField(title: String, text: Binding<String>, placeholder: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(Color(0x8E8E93))
                .frame(width: 24)

            TextField("", text: text)
                .placeholder(when: text.wrappedValue.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(Color(0x5C5C66))
                }
                .font(.system(size: 17))
                .foregroundColor(.white)
        }
        .padding(.vertical, 14)
    }

    private func saveProfile() {
        if !isTagValid {
            showError = true
            errorMessage = tagValidationError ?? "Неверный тег"
            return
        }

        var updatedProfile = viewModel.profile
        updatedProfile.firstName = firstName
        updatedProfile.lastName = lastName
        updatedProfile.tag = tag
        updatedProfile.email = email

        if viewModel.saveProfile(updatedProfile) {
            showError = false
            errorMessage = ""
            dismiss()
        } else {
            showError = true
            errorMessage = viewModel.validationError ?? "Ошибка сохранения"
        }
    }

    private func loadAvatarFromBase64(_ base64: String) {
        if let data = Data(base64Encoded: base64),
           let uiImage = UIImage(data: data) {
            avatarImage = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Extensions

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

extension Color {
    init(_ hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension Data {
    init?(base64Encoded: String) {
        self.init(base64Encoded: base64Encoded)
    }
}
