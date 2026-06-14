import SwiftUI

struct SettingsView: View {
    @AppStorage("profileName") private var profileName: String = ""
    @AppStorage("profileTag") private var profileTag: String = ""
    @AppStorage("profileAvatarData") private var profileAvatarData: Data = Data()

    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Секция «О приложении»
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "О приложении")

                        InfoRow(label: "Версия", value: "1.0")
                        InfoRow(label: "Транспорт", value: "VP8 через Яндекс Телемост")
                    }

                    // Секция «Данные»
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Данные")

                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            HStack {
                                Text("Сбросить все данные")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(10)
                        }
                        .confirmationDialog(
                            "Вы уверены, что хотите сбросить все данные? Это действие нельзя отменить.",
                            isPresented: $showResetConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Сбросить", role: .destructive) {
                                resetAllData()
                            }
                            Button("Отмена", role: .cancel) {}
                        }
                    }

                    // Секция «Безопасность»
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Безопасность")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Шифрование")
                                .foregroundColor(.white)
                                .font(.subheadline)
                            Text("Все сообщения защищены алгоритмом ChaCha20 — современным потоковым шифром, обеспечивающим высокую скорость и надёжность.")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .lineSpacing(2)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(10)
                    }

                    Spacer(minLength: 40)

                    // Дисклеймер
                    Text("Aura Messenger не хранит сообщения на серверах. Все данные хранятся локально на устройстве. Мы не можем восстановить удалённые данные.")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
    }

    private func resetAllData() {
        profileName = ""
        profileTag = ""
        profileAvatarData = Data()
    }
}

// MARK: - Вспомогательные компоненты

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.white)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
