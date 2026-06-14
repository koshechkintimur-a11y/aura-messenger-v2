import SwiftUI

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

struct OnboardingView: View {
    @ObservedObject var viewModel: AuraViewModel
    @Binding var showOnboarding: Bool
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var tag = ""
    @State private var email = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)
                
                Image(systemName: "message.badge.waveform.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0, green: 0.48, blue: 1.0))
                
                Text("Добро пожаловать в Aura")
                    .font(.title2).fontWeight(.bold)
                
                Text("Защищённый мессенджер через Яндекс Телемост")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    TextField("Имя", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                    
                    TextField("Фамилия (необязательно)", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                    
                    HStack(spacing: 4) {
                        Text("@").foregroundColor(.secondary)
                        TextField("тег", text: $tag)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    TextField("Email (для восстановления)", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 32)
                
                Button {
                    let profile = UserProfile(
                        firstName: firstName.trimmingCharacters(in: .whitespaces),
                        lastName: lastName.trimmingCharacters(in: .whitespaces),
                        tag: tag.trimmingCharacters(in: .whitespaces).lowercased(),
                        email: email.trimmingCharacters(in: .whitespaces)
                    )
                    
                    if profile.tag.isEmpty {
                        errorMessage = "Тег обязателен"
                        return
                    }
                    if profile.tag.count < 3 {
                        errorMessage = "Тег должен содержать минимум 3 символа"
                        return
                    }
                    if profile.firstName.isEmpty {
                        errorMessage = "Имя обязательно"
                        return
                    }
                    
                    errorMessage = nil
                    viewModel.profile = profile
                    viewModel.saveProfile(profile)
                } label: {
                    Text("Начать")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(tag.trimmingCharacters(in: .whitespaces).count >= 3 ? Color(red: 0, green: 0.48, blue: 1.0) : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(tag.trimmingCharacters(in: .whitespaces).count < 3)
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .navigationTitle("Регистрация")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
