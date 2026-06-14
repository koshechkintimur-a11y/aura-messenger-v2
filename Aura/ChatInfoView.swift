import SwiftUI

struct ChatInfoView: View {
    let aura: AuraChat
    let onClose: () -> Void

    @State private var tag: String = ""

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(aura.name)
                            .font(.title)
                            .foregroundColor(.white)
                        if let description = aura.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section {
                    Button("Копировать ссылку") {
                        UIPasteboard.general.string = aura.inviteLink
                    }
                    .foregroundColor(.blue)

                    ShareLink(item: URL(string: aura.inviteLink)!) {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    .foregroundColor(.blue)
                }

                Section(header: Text("QR-код").foregroundColor(.gray)) {
                    Text(aura.inviteLink)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .listRowBackground(Color.clear)

                Section(header: Text("Пригласить участника").foregroundColor(.gray)) {
                    HStack {
                        TextField("@тег", text: $tag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                        Button("Отправить приглашение") {
                            // TODO: отправка приглашения по тегу
                        }
                        .disabled(tag.isEmpty)
                    }
                }

                Section(header: Text("Участники").foregroundColor(.gray)) {
                    ForEach(aura.participants) { participant in
                        HStack {
                            Text(participant.name)
                                .foregroundColor(.white)
                            Spacer()
                            if participant.isAdmin {
                                Text("Админ")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Информация о чате", displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        onClose()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct AuraChat {
    let name: String
    let description: String?
    let inviteLink: String
    let participants: [AuraParticipant]
}

struct AuraParticipant: Identifiable {
    let id = UUID()
    let name: String
    let isAdmin: Bool
}

struct ChatInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ChatInfoView(
            aura: AuraChat(
                name: "Aura Team",
                description: "Официальный чат команды Aura Messenger",
                inviteLink: "https://aura.app/join/abc123",
                participants: [
                    AuraParticipant(name: "Алексей", isAdmin: true),
                    AuraParticipant(name: "Мария", isAdmin: false),
                    AuraParticipant(name: "Дмитрий", isAdmin: false)
                ]
            ),
            onClose: {}
        )
    }
}
