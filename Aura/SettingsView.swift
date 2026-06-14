import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @State private var showResetConfirm = false
    @State private var farcodeEnabled = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section {
                    NavigationLink {
                        ProfileView().environmentObject(viewModel)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle").font(.title3).foregroundColor(.blue).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Профиль").font(.body)
                                Text("\(viewModel.profile.displayName)").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Storage
                Section("Хранилище") {
                    row(icon: "text.bubble", color: .blue, title: "Чаты", detail: "\(viewModel.totalChats)")
                    row(icon: "message", color: .green, title: "Сообщений", detail: "\(viewModel.totalMessages)")
                    row(icon: "photo", color: .purple, title: "Медиа", detail: "\(viewModel.storageUsed / 1024) KB")
                    row(icon: "shield", color: .orange, title: "Куки", detail: "")
                    Button { viewModel.clearCache() } label: {
                        row(icon: "trash", color: .red, title: "Очистить кеш", detail: "")
                    }
                }
                
                // Farcode
                Section {
                    Toggle(isOn: $farcodeEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "compress").font(.title3).foregroundColor(.indigo).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Сжатие Farcode").font(.body)
                                Text("Уменьшает размер сообщений и медиа перед отправкой").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Farcode")
                } footer: {
                    Text("Технология фрактального сжатия. Уменьшает трафик и ускоряет передачу в условиях ограниченной пропускной способности туннеля.")
                }
                
                // Security
                Section("Безопасность") {
                    row(icon: "lock.shield", color: .green, title: "Шифрование", detail: "ChaCha20-Poly1305")
                    row(icon: "point.3.connected.trianglepath.dotted", color: .blue, title: "Транспорт", detail: "P2P WebRTC")
                    row(icon: "shield.checkered", color: .teal, title: "Туннель", detail: "VP8 через Телемост")
                }
                
                // Info
                Section("О приложении") {
                    row(icon: "app.badge", color: .indigo, title: "Версия", detail: "2.0")
                    row(icon: "cpu", color: .purple, title: "Основа", detail: "kulikov0/whitelist-bypass")
                }
                
                // Data
                Section {
                    Button(role: .destructive) { showResetConfirm = true } label: {
                        HStack {
                            Spacer(); Text("Сбросить все данные"); Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Настройки")
            .confirmationDialog("Сбросить всё?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Сбросить", role: .destructive) { viewModel.resetAllData() }
                Button("Отмена", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func row(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundColor(color).frame(width: 24)
            Text(title).font(.body)
            Spacer()
            Text(detail).font(.caption).foregroundColor(.secondary)
        }
    }
}
