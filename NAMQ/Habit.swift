//
//  Habit.swift
//  NAMQ
//
//  نموذج العادة + العادات الجاهزة اللي تطلع في المكتبة.
//

import Foundation

enum HabitKind: String, Codable {
    case build   // عادة أبنيها (مثل شرب الماء)
    case quit    // عادة أتركها (مثل الجوال قبل النوم)

    var label: String { self == .build ? "عادة أبنيها" : "عادة أتركها" }
    /// النقاط اللي ياخذها المستخدم كل يوم ينجزها
    var points: Int { self == .build ? 10 : 15 }
    var doneVerb: String { self == .build ? "أنجزتها" : "تجنّبتها" }
}

/// تذكيرات العادة اللي نتركها — ما لها «وقت تسويها فيه»، فنساعده بطرق ثانية:
/// وقت الإغراء (قبل ما يضعف) · تحفيز الصباح · مراجعة آخر اليوم (قدرت اليوم؟)
struct QuitReminders: Codable, Equatable {
    var craving: Int? = nil   // الوقت اللي يشتهيها فيه عادةً
    var morning: Int? = nil   // رسالة خفيفة يبدأ فيها يومه
    var checkIn: Int? = nil   // سؤال آخر اليوم وتسجيل النجاح
    var isEmpty: Bool { craving == nil && morning == nil && checkIn == nil }
}

struct Habit: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var note: String
    var icon: String              // اسم أيقونة SF Symbol
    var kind: HabitKind
    var startMinute: Int          // وقت أول تذكير (دقائق من منتصف الليل)
    var everyHours: Int           // 0 = مرة واحدة يوميًا
    var endMinute: Int = 22 * 60  // آخر تذكير لو التكرار كل كم ساعة
    var completedDays: [String] = []
    var templateID: String? = nil
    /// خطة المساعد: خطوة لكل أسبوع (اختياري)
    var plan: [String]? = nil
    var planStart: Date? = nil
    /// الهدف اللي بنى المساعد هذي العادة عشانه (مثال: «أصير أصح») — العادات اللي لها نفس الهدف تنعرض مع بعض في الطاولة
    var goal: String? = nil
    /// أيام التذكير (١ = الأحد … ٧ = السبت حسب Calendar). nil = كل يوم
    var weekdays: [Int]? = nil
    /// تذكيرات «عادة أتركها» (nil = الافتراضي: وقت الإغراء + مراجعة الساعة ٩ م)
    var quit: QuitReminders? = nil

    /// تذكيرات الترك الفعلية
    var quitReminders: QuitReminders {
        quit ?? QuitReminders(craving: startMinute, morning: nil, checkIn: startMinute < 21 * 60 ? 21 * 60 : nil)
    }

    /// كل يوم؟ (nil أو كل الأيام السبعة)
    var everyDay: Bool { weekdays == nil || Set(weekdays ?? []).count == 7 }

    /// هل العادة مطلوبة في هذا اليوم؟
    func isDue(on date: Date = Date()) -> Bool {
        everyDay || (weekdays ?? []).contains(Calendar.current.component(.weekday, from: date))
    }

    /// «كل يوم» أو «الأحد، الثلاثاء، الخميس»
    var daysText: String {
        guard !everyDay, let w = weekdays, !w.isEmpty else { return "كل يوم" }
        return w.sorted().map { Fmt.weekdayName($0) }.joined(separator: "، ")
    }

    /// كل أوقات التذكير خلال اليوم
    var reminderMinutes: [Int] {
        guard everyHours > 0 else { return [startMinute] }
        var result: [Int] = []
        var m = startMinute
        while m <= max(endMinute, startMinute) && result.count < 12 {
            result.append(m)
            m += everyHours * 60
        }
        return result
    }

    var scheduleText: String {
        let start = Fmt.time(startMinute)
        let days = everyDay ? "يوميًا" : daysText
        if kind == .quit {
            let q = quitReminders
            if q.isEmpty { return "بدون تذكير" }
            var parts: [String] = []
            if let m = q.morning { parts.append("الصباح \(Fmt.time(m))") }
            if let m = q.craving { parts.append("وقت الإغراء \(Fmt.time(m))") }
            if let m = q.checkIn { parts.append("المراجعة \(Fmt.time(m))") }
            return "\(days) · " + parts.joined(separator: " · ")
        }
        if everyHours == 0 { return "\(days) الساعة \(start)" }
        return "\(days) · \(Fmt.hours(everyHours)) من \(start) إلى \(Fmt.time(endMinute))"
    }

    /// رقم الخطوة الحالية في الخطة (أسبوع لكل خطوة)
    var planStepIndex: Int? {
        guard let plan, !plan.isEmpty, let planStart else { return nil }
        let days = Calendar.current.dateComponents([.day], from: planStart, to: Date()).day ?? 0
        return min(max(days / 7, 0), plan.count - 1)
    }

    var planStepText: String? {
        guard let i = planStepIndex, let plan else { return nil }
        return "الخطوة \(Fmt.num(i + 1)) من \(Fmt.num(plan.count)): \(Gendered.text(plan[i]))"
    }

    static func blank() -> Habit {
        Habit(title: "", note: "", icon: "leaf.fill", kind: .build, startMinute: 9 * 60, everyHours: 0)
    }
}

// MARK: - العادات الجاهزة في المكتبة

extension Habit {
    static let library: [Habit] = [
        Habit(title: "شرب الماء", note: "كوب ماء كل ساعتين طوال اليوم",
              icon: "drop.fill", kind: .build, startMinute: 8 * 60, everyHours: 2, templateID: "water"),
        Habit(title: "المشي", note: "٤٥ دقيقة مشي يوميًا",
              icon: "figure.walk", kind: .build, startMinute: 6 * 60, everyHours: 0, templateID: "walk"),
        Habit(title: "النوم المبكر", note: "٨ ساعات نوم — من ١١ مساءً إلى ٧ صباحًا",
              icon: "moon.zzz.fill", kind: .build, startMinute: 22 * 60 + 30, everyHours: 0, templateID: "sleep"),
        Habit(title: "القراءة", note: "١٠ صفحات قبل النوم",
              icon: "book.fill", kind: .build, startMinute: 21 * 60, everyHours: 0, templateID: "read"),
        Habit(title: "الامتنان", note: "اكتب ٣ أشياء ممتن لها اليوم",
              icon: "heart.text.square.fill", kind: .build, startMinute: 9 * 60, everyHours: 0, templateID: "gratitude"),
        Habit(title: "الجوال قبل النوم", note: "ابعد الجوال قبل النوم بساعة",
              icon: "iphone.slash", kind: .quit, startMinute: 22 * 60, everyHours: 0, templateID: "phone"),
        Habit(title: "المشروبات الغازية", note: "استبدلها بالماء أو العصير الطبيعي",
              icon: "takeoutbag.and.cup.and.straw.fill", kind: .quit, startMinute: 13 * 60, everyHours: 0, templateID: "soda"),
        Habit(title: "الحلويات", note: "قلّلها لمرة وحدة في الأسبوع",
              icon: "birthday.cake.fill", kind: .quit, startMinute: 16 * 60, everyHours: 0, templateID: "sweets"),
        Habit(title: "تصفّح السوشال ميديا", note: "ساعة وحدة باليوم وبس",
              icon: "bubble.left.and.bubble.right.fill", kind: .quit, startMinute: 18 * 60, everyHours: 0, templateID: "social")
    ]
}
