import Foundation
import UserNotifications

final class NotificationHelper {
    
    private init() {}
    
    /// Запрашивает разрешение на отправку локальных уведомлений.
    static func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Ошибка при запросе разрешения на уведомления: \(error.localizedDescription)")
                return
            }
            if granted {
                print("Разрешение на уведомления получено")
            } else {
                print("Разрешение на уведомления отклонено")
            }
        }
    }
    
    /// Показывает локальное пуш-уведомление с указанным заголовком и текстом.
    static func notify(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Уникальный идентификатор на основе временной метки
        let identifier = "aura-notification-\(Date().timeIntervalSince1970)"
        
        // Запуск немедленно (для iOS 15+)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Ошибка при отправке уведомления: \(error.localizedDescription)")
            } else {
                print("Уведомление отправлено: \"\(title)\" — \"\(body)\"")
            }
        }
    }
}
