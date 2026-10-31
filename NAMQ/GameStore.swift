//
//  GameStore.swift
//  NAMQ
//
//  مكان واحد يحفظ كل بيانات التطبيق (الشخصية، العادات، النقاط، الجوائز)
//  ويبلّغ الشاشات لما يتغير شيء عشان تتحدث تلقائيًا.
//

import Foundation
import UIKit

enum Gender: String, Codable {
    case boy, girl
    /// صورة الشخصية (كاملة) في الغرفة وصفحة إنشاء الشخصية
    var image: String { self == .boy ? "namq_boy" : "namq_girl" }
    /// نفس الصورة مع مساحة فوق الراس للقبعة — تُستخدم لما الشخصية تلبس (الغرفة، الدولاب، الصورة اللي فوق)
    var canvasImage: String { image + "_canvas" }
    /// نسبة المساحة الفاضية فوق الراس في صورة canvas
    static let canvasTopPadding: CGFloat = 0.123
}

/// حساب المستخدم (من تسجيل الدخول بـ Apple أو كضيف)
struct Account: Codable, Equatable {
    var userID: String
    var name: String
    var method: String      // "apple" أو "guest"
}

struct UserProfile: Codable, Equatable {
    var name: String
    var characterName: String
    var gender: Gender
}

/// مكان القطعة على الجسم — الترتيب هنا هو ترتيب الرسم (البنطال تحت، القبعة فوق)
enum OutfitSlot: String, Codable, CaseIterable {
    case pants, shirt, glasses, hat
}

struct Reward: Identifiable, Equatable {
    let id: String      // اسم الصورة في Assets
    let title: String
    let cost: Int
    let slot: OutfitSlot
}

/// كل قطعة لها صورة جاهزة بنفس مقاس الشخصية بالضبط (wear_boy_... / wear_girl_...)
/// التيشيرت والبنطال مرسومين على ملابس الشخصية نفسها بنفس الظلال، فتطلع لابستها فعلًا.
enum OutfitLayer {
    static func imageName(for reward: Reward, gender: Gender) -> String {
        "wear_\(gender.rawValue)_\(reward.id)"
    }
}

extension Reward {
    static let all: [Reward] = [
        Reward(id: "reward_cap_red", title: "كاب أحمر", cost: 30, slot: .hat),
        Reward(id: "reward_cap_purple", title: "كاب بنفسجي", cost: 30, slot: .hat),
        Reward(id: "reward_hat_bucket", title: "قبعة المغامر", cost: 40, slot: .hat),
        Reward(id: "reward_pants_khaki", title: "بنطال بيج", cost: 50, slot: .pants),
        Reward(id: "reward_pants_blue", title: "بنطال أزرق", cost: 50, slot: .pants),
        Reward(id: "reward_glasses", title: "نظارة شمسية", cost: 60, slot: .glasses),
        Reward(id: "reward_shirt_tuwaiq_gray", title: "تيشيرت همة طويق", cost: 80, slot: .shirt),
        Reward(id: "reward_shirt_tuwaiq_green", title: "همة طويق الأخضر", cost: 90, slot: .shirt),
        Reward(id: "reward_shirt_national", title: "تيشيرت اليوم الوطني", cost: 100, slot: .shirt),
        Reward(id: "reward_shirt_national_gold", title: "اليوم الوطني الذهبي", cost: 120, slot: .shirt),
        // ملابس جديدة
        Reward(id: "reward_beanie_green", title: "طاقية صوف خضرا", cost: 35, slot: .hat),
        Reward(id: "reward_beanie_red", title: "طاقية صوف حمرا", cost: 35, slot: .hat),
        Reward(id: "reward_cap_bear", title: "كاب الدبدوب", cost: 45, slot: .hat),
        Reward(id: "reward_bucket_blue", title: "قبعة الوردة", cost: 45, slot: .hat),
        Reward(id: "reward_pants_cargo", title: "بنطال كارجو", cost: 55, slot: .pants),
        Reward(id: "reward_pants_pink", title: "بنطال وردي", cost: 55, slot: .pants),
        Reward(id: "reward_pants_black", title: "بنطال أسود", cost: 55, slot: .pants),
        Reward(id: "reward_sweater_yellow", title: "بلوزة مقلّمة", cost: 70, slot: .shirt),
        Reward(id: "reward_sweater_bunny", title: "بلوزة الأرنب", cost: 75, slot: .shirt),
        Reward(id: "reward_hoodie_blue", title: "هودي أزرق", cost: 85, slot: .shirt),
        Reward(id: "reward_hoodie_red", title: "هودي أحمر", cost: 85, slot: .shirt)
    ]
}

final class GameStore {
    static let shared = GameStore()
    static let didChange = Notification.Name("NAMQ.GameStoreDidChange")
    /// احتفال: userInfo["kind"] = "allDone" أو "levelUp"، و userInfo["level"] = Level
    static let celebrate = Notification.Name("NAMQ.Celebrate")
    /// نقاط هدية أول ما ينشئ المستخدم شخصيته (عشان يقدر يجرب الدولاب بسرعة)
    static let welcomeBonus = 30

    struct State: Codable {
        var account: Account?
        var profile: UserProfile?
        var habits: [Habit] = []
        var points: Int = 0
        var unlockedRewards: [String] = []
        var equippedReward: String?          // قديم — ما عاد يُستخدم
        var outfit: [String: String]?        // المكان ← القطعة اللي يلبسها (قطعة وحدة لكل مكان)
        var xp: Int?                         // كل النقاط اللي كسبها من عاداته (ما تنقص لما يشتري)
        var remindersOff: Bool?              // المستخدم طفّى التذكيرات من الإعدادات
    }

    private(set) var state: State
    private let storageKey = "NAMQ.state.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(State.self, from: data) {
            state = saved
        } else {
            state = State()
        }
    }

    private func commit() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }

    // MARK: الحساب

    var account: Account? { state.account }

    /// Apple ما ترسل الاسم إلا أول مرة، فلو رجع نفس المستخدم نستخدم الاسم المحفوظ
    func signIn(userID: String, name: String?, method: String) {
        let saved = state.account?.userID == userID ? state.account?.name : nil
        state.account = Account(userID: userID, name: name ?? saved ?? "صديقنا", method: method)
        commit()
    }

    /// الشاشة اللي بعد السبلاش
    func nextScreenAfterSplash() -> UIViewController {
        if state.account == nil { return LoginViewController() }
        if state.profile == nil { return OnboardingViewController() }
        return GameViewController()
    }

    // MARK: الشخصية

    var profile: UserProfile? { state.profile }
    var points: Int { state.points }

    func createCharacter(name characterName: String, gender: Gender) {
        saveProfile(UserProfile(name: state.account?.name ?? "صديقنا", characterName: characterName, gender: gender))
    }

    func saveProfile(_ profile: UserProfile) {
        let isNew = state.profile == nil
        state.profile = profile
        if isNew { state.points += Self.welcomeBonus }
        commit()
    }

    // MARK: الإعدادات

    var remindersOn: Bool { state.remindersOff != true }

    func setReminders(on: Bool) {
        state.remindersOff = on ? nil : true
        let name = state.profile?.characterName
        state.habits.forEach { on ? ReminderManager.schedule($0, characterName: name) : ReminderManager.cancel($0) }
        commit()
    }

    /// يمسح كل شيء — مفيد أثناء العرض عشان تبدين من البداية
    func reset() {
        state.habits.forEach(ReminderManager.cancel)
        state = State()
        commit()
    }

    // MARK: العادات

    var habits: [Habit] { state.habits }

    func hasHabit(fromTemplate templateID: String?) -> Bool {
        guard let templateID else { return false }
        return state.habits.contains { $0.templateID == templateID }
    }

    func upsert(_ habit: Habit) {
        if let i = state.habits.firstIndex(where: { $0.id == habit.id }) {
            state.habits[i] = habit
        } else {
            state.habits.append(habit)
        }
        if remindersOn { ReminderManager.schedule(habit, characterName: state.profile?.characterName) }
        commit()
    }

    func delete(_ habit: Habit) {
        state.habits.removeAll { $0.id == habit.id }
        ReminderManager.cancel(habit)
        commit()
    }

    func isDoneToday(_ habit: Habit) -> Bool {
        habit.completedDays.contains(Day.today)
    }

    /// يسجّل الإنجاز لليوم (أو يلغيه لو كان مسجّل). يرجع فرق النقاط.
    @discardableResult
    func toggleToday(_ habit: Habit) -> Int {
        guard let i = state.habits.firstIndex(where: { $0.id == habit.id }) else { return 0 }
        let today = Day.today
        let delta: Int
        if let d = state.habits[i].completedDays.firstIndex(of: today) {
            state.habits[i].completedDays.remove(at: d)
            delta = -min(habit.kind.points, state.points)
        } else {
            state.habits[i].completedDays.append(today)
            delta = habit.kind.points
        }
        let levelBefore = level
        state.points += delta
        state.xp = max(0, (state.xp ?? 0) + (delta > 0 ? habit.kind.points : -habit.kind.points))
        commit()

        if delta > 0 {
            let p = todayProgress
            if level.number > levelBefore.number {
                NotificationCenter.default.post(name: Self.celebrate, object: self,
                                                userInfo: ["kind": "levelUp", "level": level])
            } else if p.total > 0 && p.done == p.total {
                NotificationCenter.default.post(name: Self.celebrate, object: self, userInfo: ["kind": "allDone"])
            }
        }
        return delta
    }

    // MARK: المستويات — الشخصية تتطور مع التزامك

    var xp: Int { state.xp ?? 0 }
    var level: Level { Level.all.last { xp >= $0.minXP } ?? Level.all[0] }
    var nextLevel: Level? { Level.all.first { $0.minXP > xp } }

    /// عدد الأيام المتتالية اللي أنجز فيها العادة
    func streak(_ habit: Habit) -> Int {
        let done = Set(habit.completedDays)
        let cal = Calendar.current
        var day = Date()
        if !done.contains(Day.key(day)) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var count = 0
        while done.contains(Day.key(day)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    var todayProgress: (done: Int, total: Int) {
        let due = state.habits.filter { $0.isDue() }   // بس العادات المطلوبة اليوم
        return (due.filter { isDoneToday($0) }.count, due.count)
    }

    // MARK: الجوائز

    enum PurchaseResult { case unlocked, alreadyOwned, notEnough(missing: Int) }

    func isUnlocked(_ reward: Reward) -> Bool { state.unlockedRewards.contains(reward.id) }
    func isEquipped(_ reward: Reward) -> Bool { state.outfit?[reward.slot.rawValue] == reward.id }

    /// كل اللي تلبسه الشخصية الحين، بترتيب الرسم
    var outfit: [Reward] {
        OutfitSlot.allCases.compactMap { slot in
            guard let id = state.outfit?[slot.rawValue] else { return nil }
            return Reward.all.first { $0.id == id }
        }
    }

    private func wear(_ reward: Reward?, in slot: OutfitSlot) {
        var o = state.outfit ?? [:]
        o[slot.rawValue] = reward?.id
        state.outfit = o
    }

    func buy(_ reward: Reward) -> PurchaseResult {
        if isUnlocked(reward) { return .alreadyOwned }
        guard state.points >= reward.cost else { return .notEnough(missing: reward.cost - state.points) }
        state.points -= reward.cost
        state.unlockedRewards.append(reward.id)
        wear(reward, in: reward.slot)   // يلبسها على طول
        commit()
        return .unlocked
    }

    func toggleEquip(_ reward: Reward) {
        guard isUnlocked(reward) else { return }
        wear(isEquipped(reward) ? nil : reward, in: reward.slot)
        commit()
    }
}

/// مستويات الشخصية — كل ما زاد التزامك تتطور (هالة، نجوم، تاج)
struct Level: Equatable {
    let number: Int
    let title: String
    let minXP: Int
    /// أيقونة الوسام (SF Symbol)
    var icon: String = "leaf.fill"
    /// وش يتغيّر في الشخصية لما توصل له
    var perk: String = ""

    /// مرحلة الهالة/الحجم (١-٥) — ٨ مستويات تتوزّع على ٥ مراحل
    var stage: Int { min(5, Int((Double(number - 1) * 4 / 7).rounded()) + 1) }

    /// مسار التطور: ٨ مستويات بصيغة الولد أو البنت
    static var all: [Level] { [
        Level(number: 1, title: "بداية التغيير", minXP: 0, icon: "leaf.fill", perk: "أول خطوة في رحلتك"),
        Level(number: 2, title: g("مستكشف", "مستكشفة"), minXP: 60, icon: "safari.fill", perk: "هالة خفيفة حول شخصيتك"),
        Level(number: 3, title: g("ملتزم", "ملتزمة"), minXP: 150, icon: "checkmark.seal.fill", perk: "الهالة تكبر شوي"),
        Level(number: 4, title: g("متوازن", "متوازنة"), minXP: 300, icon: "scalemass.fill", perk: "نجوم صغيرة تلمع حول شخصيتك"),
        Level(number: 5, title: g("مثابر", "مثابرة"), minXP: 500, icon: "flame.fill", perk: "شخصيتك تكبر وتلمع أكثر"),
        Level(number: 6, title: g("صانع الاستمرار", "صانعة الاستمرار"), minXP: 800, icon: "mountain.2.fill", perk: "هالة ذهبية قوية"),
        Level(number: 7, title: g("ملهم", "ملهمة"), minXP: 1200, icon: "sun.max.fill", perk: "شخصيتك تصير أكبر وأوضح"),
        Level(number: 8, title: g("صانع التغيير", "صانعة التغيير"), minXP: 1700, icon: "crown.fill", perk: "تاج ذهبي فوق شخصيتك 👑")
    ] }
}


/// مفتاح اليوم بصيغة ثابتة (2026-10-16) لتسجيل الإنجاز
enum Day {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static func key(_ date: Date) -> String { formatter.string(from: date) }
    static var today: String { key(Date()) }
}
