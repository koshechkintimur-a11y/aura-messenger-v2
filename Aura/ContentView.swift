import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = AuraViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if viewModel.profile.tag.isEmpty {
                OnboardingView(viewModel: viewModel)
            } else {
                mainTabs
            }
        }
        .preferredColorScheme(.dark)
    }
    
    var mainTabs: some View {
        TabView(selection: $selectedTab) {
            ChatListView()
                .environmentObject(viewModel)
                .tabItem { Label("Чаты", systemImage: "message.fill") }
                .tag(0)
            
            SettingsView()
                .environmentObject(viewModel)
                .tabItem { Label("Настройки", systemImage: "gear") }
                .tag(1)
            
            ProfileView()
                .environmentObject(viewModel)
                .tabItem { Label("Профиль", systemImage: "person.fill") }
                .tag(2)
        }
        .accentColor(Color(red: 0, green: 0.48, blue: 1.0))
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @ObservedObject var viewModel: AuraViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var tag = ""
    @State private var about = ""
    @State private var email = ""
    @State private var errorMessage: String?
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarData: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 50)
            
            // Avatar
            PhotosPicker(selection: $avatarItem, matching: .images) {
                ZStack {
                    if let data = avatarData, let img = UIImage(data: data) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 90, height: 90).clipShape(Circle())
                    } else {
                        Circle().fill(Color(.systemGray5)).frame(width: 90, height: 90)
                        Image(systemName: "camera.fill").font(.title).foregroundColor(.secondary)
                    }
                }
            }
            
            Text("Aura Messenger")
                .font(.largeTitle).fontWeight(.bold)
                .padding(.top, 20)
            Text("Защищённый мессенджер через Телемост")
                .font(.subheadline).foregroundColor(.secondary)
                .padding(.bottom, 30)
            
            // Fields
            VStack(spacing: 16) {
                fieldRow("Имя", placeholder: "Ваше имя", text: $firstName)
                fieldRow("Фамилия", placeholder: "Необязательно", text: $lastName)
                fieldRow("@тег", placeholder: "username", text: $tag)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                fieldRow("О себе", placeholder: "Расскажите о себе", text: $about)
                fieldRow("Email", placeholder: "для восстановления", text: $email)
                    .keyboardType(.emailAddress)
            }
            .padding(.horizontal, 24)
            
            if let err = errorMessage {
                Text(err).font(.caption).foregroundColor(.red).padding(.top, 8)
            }
            
            Button {
                let t = tag.trimmingCharacters(in: .whitespaces).lowercased()
                let n = firstName.trimmingCharacters(in: .whitespaces)
                if n.isEmpty { errorMessage = "Имя обязательно"; return }
                if t.count < 3 { errorMessage = "Минимум 3 символа в теге"; return }
                errorMessage = nil
                var p = UserProfile(firstName: n, lastName: lastName.trimmingCharacters(in: .whitespaces), tag: t, email: email.trimmingCharacters(in: .whitespaces))
                p.avatarBase64 = avatarData?.base64EncodedString()
                viewModel.profile = p
                viewModel.saveProfile(p)
            } label: {
                Text("Начать").fontWeight(.semibold).frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(tag.trimmingCharacters(in: .whitespaces).count >= 3 ? Color(red: 0, green: 0.48, blue: 1.0) : Color.gray)
                    .foregroundColor(.white).cornerRadius(14)
            }
            .disabled(tag.trimmingCharacters(in: .whitespaces).count < 3)
            .padding(.horizontal, 24).padding(.top, 24)
            
            Spacer()
        }
        .onChange(of: avatarItem) { _, item in
            Task { if let d = try? await item?.loadTransferable(type: Data.self) { avatarData = d } }
        }
    }
    
    func fieldRow(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.secondary).frame(width: 70, alignment: .leading)
            TextField(placeholder, text: text)
                .font(.body).foregroundColor(.white)
        }
        .padding(12).background(Color(.systemGray6)).cornerRadius(10)
    }
}
