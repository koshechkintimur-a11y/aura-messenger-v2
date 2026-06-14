import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AuraViewModel()
    
    var body: some View {
        TabView {
            ChatRoomView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Чаты", systemImage: "message.fill")
                }
            
            Text("Настройки")
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
            
            Text("Профиль")
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
        }
        .accentColor(Color(red: 0, green: 0.48, blue: 1.0))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
