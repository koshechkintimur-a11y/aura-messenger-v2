import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = AuraViewModel()
    @State private var selectedTab = 0
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if viewModel.profile.tag.isEmpty || showOnboarding {
                OnboardingView(viewModel: viewModel, showOnboarding: $showOnboarding)
            } else {
                TabView(selection: $selectedTab) {
                    ChatListView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("Чаты", systemImage: "message.fill")
                        }
                        .tag(0)
                    
                    SettingsView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("Настройки", systemImage: "gear")
                        }
                        .tag(1)
                    
                    ProfileView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("Профиль", systemImage: "person.fill")
                        }
                        .tag(2)
                }
                .accentColor(Color(red: 0, green: 0.48, blue: 1.0))
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @ObservedObject var viewModel: AuraViewModel
    @Binding var showOnboarding: Bool
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var tag = ""
    @State private var about = ""
    @State private var email = ""
    @State private var selectedAvatar: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil
    @State private var avatarBase64: String? = nil
    @State private var errorMessage: String? = nil
    
    private let accent = Color(red: 0, green: 0.48, blue: 1.0)
    private let bgColor = Color(0x0A0A0F)
    private let cardColor = Color(0x1C1C24)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)
                        
                        // Avatar Picker
                        PhotosPicker(selection: $selectedAvatar, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(cardColor)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(accent.opacity(0.3), lineWidth: 2)
                                    )
                                
                                if let avatarImage = avatarImage {
                                    avatarImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(accent)
                                }
                                
                                // Camera overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Circle()
                                            .fill(accent)
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                                .frame(width: 80, height: 80)
                            }
                        }
                        .onChange(of: selectedAvatar) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    if let uiImage = UIImage(data: data) {
                                        avatarImage = Image(uiImage: uiImage)
                                        avatarBase64 = data.base64EncodedString()
                                    }
                                }
                            }
                        }
                        
                        Text("Добро пожаловать в Aura")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Защищённый мессенджер с P2P-шифрованием")
                            .font(.subheadline)
                            .foregroundColor(Color(0x8E8E93))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Form Fields
                        VStack(spacing: 16) {
                            labeledField(title: "Имя *", placeholder: "Ваше имя", text: $firstName)
                            labeledField(title: "Фамилия", placeholder: "Необязательно", text: $lastName)
                            labeledField(title: "@тег *", placeholder: "Уникальный тег", text: $tag)
                            
                            // О себе
                            VStack(alignment: .leading, spacing: 6) {
                                Text("О себе")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(0x8E8E93))
                                    .textCase(.uppercase)
                                
                                TextEditor(text: $about)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(cardColor)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            }
                            
                            labeledField(title: "Email", placeholder: "Для восстановления доступа", text: $email)
                        }
                        .padding(.horizontal, 24)
                        
                        // Validation Error
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Start Button
                        Button {
                            validateAndSave()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Начать")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isFormValid ? accent : Color.gray.opacity(0.5))
                            )
                        }
                        .disabled(!isFormValid)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Регистрация")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && tag.trimmingCharacters(in: .whitespaces).count >= 3
    }
    
    private func labeledField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(0x8E8E93))
                .textCase(.uppercase)
            
            TextField(placeholder, text: text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(0x1C1C24))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
    
    private func validateAndSave() {
        let trimmedTag = tag.trimmingCharacters(in: .whitespaces).lowercased()
        let trimmedName = firstName.trimmingCharacters(in: .whitespaces)
        
        if trimmedName.isEmpty {
            errorMessage = "Имя обязательно"
            return
        }
        if trimmedTag.isEmpty {
            errorMessage = "Тег обязателен"
            return
        }
        if trimmedTag.count < 3 {
            errorMessage = "Тег должен содержать минимум 3 символа"
            return
        }
        
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if trimmedTag.rangeOfCharacter(from: allowed.inverted) != nil {
            errorMessage = "Тег может содержать только латиницу, цифры и _"
            return
        }
        
        errorMessage = nil
        
        var profile = UserProfile()
        profile.firstName = trimmedName
        profile.lastName = lastName.trimmingCharacters(in: .whitespaces)
        profile.tag = trimmedTag
        profile.email = email.trimmingCharacters(in: .whitespaces)
        profile.avatarBase64 = avatarBase64
        
        viewModel.profile = profile
        viewModel.saveProfile(profile)
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
