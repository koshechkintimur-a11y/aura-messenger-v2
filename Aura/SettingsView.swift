import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @State private var showResetAlert: Bool = false
    @State private var showLogoutAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showClearCookiesAlert: Bool = false
    @State private var navigateToProfile: Bool = false
    @State private var farcodeEnabled: Bool = false
    
    private let bgColor = Color(0x0A0A0F)
    private let cardColor = Color(0x1C1C24)
    private let accent = Color(red: 0, green: 0.48, blue: 1.0)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Profile Section
                        profileSection
                        
                        // Storage Section
                        storageSection
                        
                        // Security Section
                        securitySection
                        
                        // Farcode Section
                        farcodeSection
                        
                        // About Section
                        aboutSection
                        
                        // Data Section
                        dataSection
                        
                        // Footer
                        footerSection
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .alert("Сбросить всё?", isPresented: $showResetAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Сбросить", role: .destructive) {
                    viewModel.resetAllData()
                }
            } message: {
                Text("Все данные, включая чаты и сообщения, будут безвозвратно удалены.")
            }
            .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Выйти", role: .destructive) {
                    viewModel.setOnlineStatus(isOnline: false)
                }
            } message: {
                Text("Вы сможете войти снова в любой момент.")
            }
            .alert("Очистить куки?", isPresented: $showClearCookiesAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Очистить", role: .destructive) {
                    // Clear cookies logic
                }
            } message: {
                Text("Все временные данные будут удалены.")
            }
            .sheet(isPresented: $navigateToProfile) {
                ProfileView()
                    .environmentObject(viewModel)
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Профиль")
            
            Button(action: { navigateToProfile = true }) {
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(cardColor)
                            .frame(width: 44, height: 44)
                        
                        Text(viewModel.profile.initials.isEmpty ? "👤" : viewModel.profile.initials)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.profile.displayName.isEmpty ? "Настройте профиль" : viewModel.profile.displayName)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        
                        if !viewModel.profile.tag.isEmpty {
                            Text("@\(viewModel.profile.tag)")
                                .font(.system(size: 14))
                                .foregroundColor(Color(0x8E8E93))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(0x5C5C66))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Storage Section
    
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Хранилище")
            
            VStack(spacing: 0) {
                storageRow(icon: "bubble.left.and.bubble.right.fill", iconColor: Color(0x5A9FEE), title: "Чаты", value: "\(viewModel.rooms.count)")
                
                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 52)
                
                storageRow(icon: "photo.fill", iconColor: Color(0x34C759), title: "Медиа", value: "0 MB")
                
                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 52)
                
                Button(action: { showClearCookiesAlert = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(0xFF453A).opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "cookie")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(0xFF453A))
                        }
                        
                        Text("Очистить куки")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(0xFF453A))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func storageRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(Color(0x8E8E93))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Безопасность")
            
            VStack(spacing: 0) {
                securityRow(
                    icon: "lock.shield.fill",
                    iconColor: Color(0x34C759),
                    title: "ChaCha20",
                    subtitle: "Побайтовое шифрование сообщений",
                    isActive: true
                )
                
                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 52)
                
                securityRow(
                    icon: "network",
                    iconColor: Color(0x5A9FEE),
                    title: "P2P соединение",
                    subtitle: "Прямое соединение между устройствами",
                    isActive: true
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func securityRow(icon: String, iconColorColor: Color, title: String, subtitle: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColorColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColorColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Color(0x8E8E93))
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(isActive ? Color(0x34C759) : Color(0xFF453A))
                    .frame(width: 8, height: 8)
                
                Text(isActive ? "Включено" : "Выключено")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isActive ? Color(0x34C759) : Color(0xFF453A))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Farcode Section
    
    private var farcodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Farcode")
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(0xFF9500).opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "square.3.layers.3d.down.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(0xFF9500))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Сжатие Farcode")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(farcodeEnabled ? "Активно" : "Отключено")
                            .font(.system(size: 13))
                            .foregroundColor(Color(0x8E8E93))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $farcodeEnabled)
                        .tint(accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 52)
                
                Text("Farcode — собственная технология сжатия данных, оптимизированная для мессенджеров. Сокращает объем трафика до 60% при передаче текста и медиафайлов через P2P-соединения.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(0x8E8E93))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("О приложении")
            
            VStack(spacing: 0) {
                aboutRow(icon: "number", title: "Версия", value: "2.0.1")
                
                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 52)
                
                aboutRow(icon: "network", title: "Транспорт", value: "WebRTC / P2P")
                
                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 52)
                
                aboutRow(icon: "lock.shield", title: "Шифрование", value: "ChaCha20-Poly1305")
                
                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 52)
                
                aboutRow(icon: "chart.bar", title: "Статистика", value: "\(viewModel.messages.count) сообщ.")
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func aboutRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(0x5C5C66).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(0x8E8E93))
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(Color(0x8E8E93))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Данные")
            
            VStack(spacing: 0) {
                // Logout
                Button(action: { showLogoutAlert = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(0xFF453A).opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(0xFF453A))
                        }
                        
                        Text("Выйти из аккаунта")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(0xFF453A))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 52)
                
                // Reset
                Button(action: { showResetAlert = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(0xFF453A).opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "trash")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(0xFF453A))
                        }
                        
                        Text("Сбросить всё")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(0xFF453A))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Aura не хранит ваши сообщения")
                .font(.system(size: 12))
                .foregroundColor(Color(0x5C5C66))
                .multilineTextAlignment(.center)
            
            Text("Все данные хранятся локально на вашем устройстве")
                .font(.system(size: 11))
                .foregroundColor(Color(0x3C3C44))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .textCase(.uppercase)
            .foregroundColor(Color(0x5C5C66))
            .padding(.leading, 4)
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
