//
//  ReminderManager.swift
//  NAMQ
//
//  التذكيرات — فكرة التطبيق الأساسية: نذكّر المستخدم بعاداته في وقتها.
//

import Foundation
import UserNotifications

enum ReminderManager {
    private static var center: UNUserNotificationCenter { .current() }

    static func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// تذكير واحد خلال اليوم: الوقت + النص
    private struct Slot { let minute: Int; let title: String; let body: String }

    private static func slots(_ habit: Habit, buddy: String) -> [Slot] {
        let t = habit.title
        if habit.kind == .build {
            return habit.reminderMinutes.map {
                Slot(minute: $0, title: "نمق · \(t)", body: "\(buddy) بانتظارك! حان وقت \(t) 🌱")
            }
        }
        // عادة نتركها: ما نقول «حان وقتها» — نشجّعه قبل ما يضعف ونسأله آخر اليوم
        let q = habit.quitReminders
        var out: [Slot] = []
        if let m = q.morning {
            out.append(Slot(minute: m, title: "نمق · صباح الخير ☀️",
                            body: "يوم جديد بدون \(t) — \(buddy) " + g("معك", "معكِ") + " خطوة بخطوة"))
        }
        if let m = q.craving {
            let tip = habit.note.isEmpty ? g("خذ نفس عميق واشغل نفسك بشي ثاني", "خذي نفس عميق واشغلي نفسك بشي ثاني") : Gendered.text(habit.note)
            out.append(Slot(minute: m, title: "نمق · " + g("تقدر عليها 💪", "تقدرين عليها 💪"),
                            body: g("هذا الوقت اللي تشتهي فيه ", "هذا الوقت اللي تشتهين فيه ") + "\(t)… \(tip)"))
        }
        if let m = q.checkIn {
            out.append(Slot(minute: m, title: "نمق · كيف كان يومك؟",
                            body: g("قدرت", "قدرتي") + " اليوم بدون \(t)؟ " + g("سجّل نجاحك وخذ نجومك ⭐", "سجّلي نجاحك وخذي نجومك ⭐")))
        }
        return out
    }

    static func schedule(_ habit: Habit, characterName: String?) {
        cancel(habit)
        let buddy = characterName ?? "رفيقك"
        // كل يوم = تذكير يومي، وإلا تذكير أسبوعي لكل يوم مختار
        let days: [Int?] = habit.everyDay ? [nil] : (habit.weekdays ?? []).sorted().map { Optional($0) }
        var i = 0
        for day in days {
            for slot in slots(habit, buddy: buddy) {
                let content = UNMutableNotificationContent()
                content.title = slot.title
                content.body = slot.body
                content.sound = .default
                content.threadIdentifier = habit.id.uuidString   // تذكيرات العادة الوحدة تتجمّع مع بعض

                var time = DateComponents()
                time.hour = slot.minute / 60
                time.minute = slot.minute % 60
                if let day { time.weekday = day }
                let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
                center.add(UNNotificationRequest(identifier: id(habit, i), content: content, trigger: trigger))
                i += 1
            }
        }
    }

    static func cancel(_ habit: Habit) {
        center.removePendingNotificationRequests(withIdentifiers: (0..<100).map { id(habit, $0) })
    }

    private static func id(_ habit: Habit, _ index: Int) -> String {
        "\(habit.id.uuidString)-\(index)"
    }
}
