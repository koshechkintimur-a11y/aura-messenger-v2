import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var tag: String = ""
    @State private var about: String = ""
    @State private var email: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    
    private let accent = Color(red: 0, green: 0.48, blue: 1.0)
    private let bgColor = Color(0x0A0A0F)
    private let cardColor = Color(0x1C1C24)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Avatar
                        avatarSection
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                        
                        // Form
                        formSection
                            .padding(.horizontal, 20)
                        
                        // Statistics
                        statsSection
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        
                        Spacer(minLength: 40)
                        
                        // Save Button
                        saveButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                firstName = viewModel.profile.firstName
                lastName = viewModel.profile.lastName
                tag = viewModel.profile.tag
                email = viewModel.profile.email
                about = ""
                if let base64 = viewModel.profile.avatarBase64 {
                    loadAvatarFromBase64(base64)
                }
            }
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
            ZStack {
                Circle()
                    .fill(cardColor)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(accent.opacity(0.3), lineWidth: 2)
                    )
                
                if let avatarImage = avatarImage {
                    avatarImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Text(viewModel.profile.initials.isEmpty ? "👤" : viewModel.profile.initials)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(accent)
                }
                
                // Camera overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(accent)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 100, height: 100)
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        avatarImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 0) {
            profileRow(title: "Имя", value: $firstName, placeholder: "Введите имя")
            
            Divider()
                .background(cardColor)
                .padding(.leading, 20)
            
            profileRow(title: "Фамилия", value: $lastName, placeholder: "Не указана")
            
            Divider()
                .background(cardColor)
                .padding(.leading, 20)
            
            // Tag with validation
            HStack(alignment: .top, spacing: 0) {
                Text("@тег")
                    .font(.system(size: 15))
                    .foregroundColor(Color(0x8E8E93))
                    .frame(width: 100, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("", text: $tag)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                    
                    if !isTagValid && !tag.isEmpty {
                        Text(tagValidationError ?? "Неверный тег")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            
            Divider()
                .background(cardColor)
                .padding(.leading, 20)
            
            // О себе
            HStack(alignment: .top, spacing: 0) {
                Text("О себе")
                    .font(.system(size: 15))
                    .foregroundColor(Color(0x8E8E93))
                    .frame(width: 100, alignment: .leading)
                    .padding(.top, 14)
                
                TextEditor(text: $about)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            if about.isEmpty {
                                HStack {
                                    Text("Расскажите о себе...")
                                        .foregroundColor(Color(0x8E8E93))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                    )
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            
            Divider()
                .background(cardColor)
                .padding(.leading, 20)
            
            profileRow(title: "Email", value: $email, placeholder: "Для восстановления")
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor)
        )
    }
    
    private func profileRow(title: String, value: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Color(0x8E8E93))
                .frame(width: 100, alignment: .leading)
            
            TextField(placeholder, text: value)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .placeholder(when: value.wrappedValue.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(Color(0x8E8E93))
                }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика")
                .font(.system(size: 13, weight: .semibold))
                .textCase(.uppercase)
                .foregroundColor(Color(0x5C5C66))
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                statCard(
                    icon: "bubble.left.fill",
                    value: "\(viewModel.rooms.count)",
                    label: "Чатов создано"
                )
                
                statCard(
                    icon: "paperplane.fill",
                    value: "\(viewModel.messages.count)",
                    label: "Сообщений"
                )
            }
        }
    }
    
    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(accent)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(0x8E8E93))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                . fill(cardColor)
        )
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack {
                Spacer()
                if showSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Сохранить")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(accent)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Validation
    
    private var isTagValid: Bool {
        tag.trimmingCharacters(in: .whitespaces).isEmpty || tag.trimmingCharacters(in: .whitespaces).count >= 3
    }
    
    private var tagValidationError: String? {
        let trimmed = tag.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        if trimmed.count < 3 { return "Тег должен содержать минимум 3 символа" }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            return "Тег может содержать только латиницу, цифры и _"
        }
        return nil
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        if let error = tagValidationError {
            showError = true
            errorMessage = error
            return
        }
        
        var updatedProfile = viewModel.profile
        updatedProfile.firstName = firstName.trimmingCharacters(in: .whitespaces)
        updatedProfile.lastName = lastName.trimmingCharacters(in: .whitespaces)
        updatedProfile.tag = tag.trimmingCharacters(in: .whitespaces).lowercased()
        updatedProfile.email = email.trimmingCharacters(in: .whitespaces)
        
        if viewModel.saveProfile(updatedProfile) {
            showError = false
            errorMessage = ""
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSuccess = false
            }
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

// MARK: - Placeholder Extension

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
