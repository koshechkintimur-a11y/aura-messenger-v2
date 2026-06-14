import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var vm = AuraViewModel()
    @State private var tab = 0
    
    var body: some View {
        if vm.profile.tag.isEmpty {
            OnboardingView(vm: vm)
        } else {
            TabView(selection: $tab) {
                ChatListView().environmentObject(vm)
                    .tabItem { Label("Чаты", systemImage: "message.fill") }.tag(0)
                SettingsView().environmentObject(vm)
                    .tabItem { Label("Настройки", systemImage: "gear") }.tag(1)
                ProfileView().environmentObject(vm)
                    .tabItem { Label("Профиль", systemImage: "person.fill") }.tag(2)
            }
            .accentColor(Color(red: 0, green: 0.48, blue: 1.0))
            .onAppear { vm.ensureFavorites() }
        }
    }
}

struct OnboardingView: View {
    @ObservedObject var vm: AuraViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var tag = ""
    @State private var about = ""
    @State private var email = ""
    @State private var err: String?
    @State private var photo: PhotosPickerItem?
    @State private var avatar: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 50)
            
            PhotosPicker(selection: $photo, matching: .images) {
                ZStack {
                    if let d = avatar, let img = UIImage(data: d) {
                        Image(uiImage: img).resizable().scaledToFill().frame(width: 90, height: 90).clipShape(Circle())
                    } else {
                        Circle().fill(Color(.systemGray5)).frame(width: 90, height: 90)
                        Image(systemName: "camera.fill").font(.title).foregroundColor(.secondary)
                    }
                }
            }
            
            Text("Aura Messenger").font(.largeTitle).fontWeight(.bold).padding(.top, 20)
            Text("Защищённый мессенджер через Телемост").font(.subheadline).foregroundColor(.secondary).padding(.bottom, 30)
            
            VStack(spacing: 14) {
                row("Имя", "Ваше имя", $firstName)
                row("Фамилия", "Необязательно", $lastName)
                HStack(spacing: 0) {
                    Text("@").foregroundColor(.secondary).frame(width: 70, alignment: .leading)
                    TextField("тег", text: $tag).autocorrectionDisabled().textInputAutocapitalization(.never)
                }.padding(12).background(Color(.systemGray6)).cornerRadius(10)
                row("О себе", "Расскажите о себе", $about)
                row("Email", "для восстановления", $email).keyboardType(.emailAddress)
            }.padding(.horizontal, 24)
            
            if let e = err { Text(e).font(.caption).foregroundColor(.red).padding(.top, 8) }
            
            Button {
                let t = tag.trimmingCharacters(in: .whitespaces).lowercased()
                let n = firstName.trimmingCharacters(in: .whitespaces)
                if n.isEmpty { err = "Имя обязательно"; return }
                if t.count < 3 { err = "Тег: минимум 3 символа"; return }
                var p = UserProfile(firstName: n, lastName: lastName.trimmingCharacters(in: .whitespaces), tag: t, about: about, email: email.trimmingCharacters(in: .whitespaces))
                p.avatarBase64 = avatar?.base64EncodedString()
                vm.profile = p
                _ = vm.saveProfile(p)
            } label: {
                Text("Начать").fontWeight(.semibold).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(tag.trimmingCharacters(in: .whitespaces).count >= 3 ? Color.blue : Color.gray)
                    .foregroundColor(.white).cornerRadius(14)
            }.disabled(tag.count < 3).padding(.horizontal, 24).padding(.top, 24)
            Spacer()
        }
        .preferredColorScheme(.dark)
        .onChange(of: photo) { _, item in
            Task { if let d = try? await item?.loadTransferable(type: Data.self) { avatar = d } }
        }
    }
    
    func row(_ label: String, _ placeholder: String, _ text: Binding<String>) -> some View {
        HStack(spacing: 0) {
            Text(label).font(.subheadline).foregroundColor(.secondary).frame(width: 70, alignment: .leading)
            TextField(placeholder, text: text).font(.body).foregroundColor(.white)
        }.padding(12).background(Color(.systemGray6)).cornerRadius(10)
    }
}
