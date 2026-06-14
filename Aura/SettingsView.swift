import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AuraViewModel
    @State private var showResetAlert: Bool = false
    @State private var showLogoutAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var navigateToProfile: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Profile Section
                    profileSection

                    // Security Section
                    securitySection

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
            .background(Color(0x0A0A0F))
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
                            .fill(Color(0x1C1C24))
                            .frame(width: 44, height: 44)

                        Text(viewModel.profile.initials.isEmpty ? "👤" : viewModel.profile.initials)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(0x8E8E93))
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
                        .fill(Color(0x1C1C24))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Security Section

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Безопасность")

            VStack(spacing: 0) {
                // ChaCha20
                securityRow(
                    icon: "lock.shield.fill",
                    iconColor: Color(0x34C759),
                    title: "ChaCha20 шифрование",
                    subtitle: "Побайтовое шифрование сообщений",
                    isActive: true
                )

                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 60)

                // P2P
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
                    .fill(Color(0x1C1C24))
            )
        }
        .padding(.horizontal, 20)
    }

    private func securityRow(icon: String, iconColor: Color, title: String, subtitle: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
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

                Text(isActive ? "ON鸡蛋清" : "Выключено")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isActive ? Color(0x34C759) : Color(0xFF453A))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("О приложении")

            VStack(spacing: 0) {
                aboutRow(title: "Версия", value: "2.0.1")

                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 16)

                aboutRow(title: "Транспорт", value: "WebRTC / P2P")

                Divider()
                    .background(Color(0x2C2C34))
                    .padding(.leading, 16)

                aboutRow(title: "Шифрование", value: "ChaCha20-Poly1305")
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(0x1C1C24))
            )
        }
        .padding(.horizontal, 20)
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()

            Text(value)
                .font(.system(size: 16))
                .foregroundColor(Color(0x8E8E93))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Данные")

            VStack(spacing: 0) {
                // Logout
                Button(action: { showLogoutAlert = true }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .font(.system(size: 17))
                            .foregroundColor(Color(0xFF453A))
                            .frame(width: 24)

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
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 17))
                            .foregroundColor(Color(0xFF453A))
                            .frame(width: 24)

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
                    .fill(Color(0x1C1C24))
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
