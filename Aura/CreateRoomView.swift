import SwiftUI
import PhotosUI

struct CreateRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: AuraViewModel
    
    @State private var name = ""
    @State private var isPublic = false
    @State private var roomURL = ""
    @State private var created = false
    @State private var createdRoom: ChatRoom?
    @State private var tagInput = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if created, let room = createdRoom {
                    createdView(room)
                } else {
                    formView
                }
            }
            .navigationTitle(created ? "Чат создан" : "Новый чат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { if !created { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } } }
        }
        .preferredColorScheme(.dark)
    }
    
    var formView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 10)
            Image(systemName: "plus.bubble.fill").font(.system(size: 44)).foregroundColor(.blue)
            
            TextField("Название чата", text: $name)
                .textFieldStyle(.roundedBorder).padding(.horizontal, 24)
            
            Toggle(isOn: $isPublic) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Публичный чат").font(.body)
                    Text("Доступен для поиска по URL").font(.caption).foregroundColor(.secondary)
                }
            }.padding(.horizontal, 24)
            
            if isPublic {
                VStack(alignment: .leading, spacing: 4) {
                    Text("URL чата").font(.caption).foregroundColor(.secondary)
                    HStack {
                        Text("aura.app/c/").foregroundColor(.secondary)
                        TextField("vash-url", text: $roomURL)
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                    }
                    .padding(10).background(Color(.systemGray6)).cornerRadius(8)
                }.padding(.horizontal, 24)
            }
            
            Button {
                let n = name.trimmingCharacters(in: .whitespaces)
                guard !n.isEmpty else { return }
                let url = isPublic ? "aura.app/c/\(roomURL)" : nil
                let room = vm.createRoom(name: n, isPublic: isPublic, url: url)
                createdRoom = room; created = true
            } label: {
                Text("Создать чат").fontWeight(.semibold).frame(maxWidth: .infinity)
                    .padding(.vertical, 14).background(name.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white).cornerRadius(14)
            }.disabled(name.isEmpty).padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    func createdView(_ room: ChatRoom) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 44)).foregroundColor(.green).padding(.top, 20)
                Text(room.name).font(.title3).fontWeight(.bold)
                
                // Invite link
                VStack(spacing: 4) {
                    Text("Ссылка-приглашение").font(.caption).foregroundColor(.secondary)
                    let link = "https://golubot.ru/j/\(String(room.id.prefix(12)))"
                    Text(link).font(.caption2.monospaced()).padding(8).background(Color(.systemGray6)).cornerRadius(8)
                    Button { UIPasteboard.general.string = link } label: {
                        Label("Копировать ссылку", systemImage: "doc.on.doc").frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.blue).foregroundColor(.white).cornerRadius(12)
                    }
                }.padding(.horizontal, 20)
                
                // QR placeholder
                VStack(spacing: 4) {
                    Text("QR-код").font(.caption).foregroundColor(.secondary)
                    Image(systemName: "qrcode").font(.system(size: 80)).foregroundColor(.secondary)
                    Text("Отсканируйте чтобы присоединиться").font(.caption2).foregroundColor(.secondary)
                }.padding().background(Color(.systemGray6)).cornerRadius(12)
                
                // Tag invite
                VStack(spacing: 8) {
                    Text("Пригласить по @тегу").font(.subheadline).fontWeight(.medium)
                    HStack {
                        TextField("@username", text: $tagInput).autocorrectionDisabled().textInputAutocapitalization(.never)
                            .padding(10).background(Color(.systemGray6)).cornerRadius(8)
                        Button("Отправить") {}.font(.subheadline).fontWeight(.semibold)
                            .padding(.horizontal, 14).padding(.vertical, 10).background(Color.orange).foregroundColor(.white).cornerRadius(8)
                    }
                }.padding(.horizontal, 20)
                
                Divider().padding(.horizontal, 20)
                
                Button {
                    vm.currentRoomId = room.id
                    dismiss()
                } label: {
                    Label("Войти в чат", systemImage: "bubble.left.and.bubble.right.fill")
                        .fontWeight(.semibold).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.green).foregroundColor(.white).cornerRadius(14)
                }.padding(.horizontal, 20)
                
                Spacer(minLength: 30)
            }
        }
    }
}
