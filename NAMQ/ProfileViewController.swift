//
//  ProfileViewController.swift
//  نمق
//
//  البروفايل — يطلع لما تضغط صورة الشخصية فوق:
//  ١) الشخصية + وسام المستوى + شريط التقدّم للمستوى الجاي
//  ٢) الأرقام: عادات مكتملة · نقاط · أيام متتالية
//  ٣) مسار تطورك (٨ مستويات) — «عرض الكل» يفتح المسار كامل
//  ٤) آخر إنجازاتك — «عرض الكل» يفتح كل الأوسمة (برونزي ← فضي ← ذهبي)
//  ٥) الإعدادات
//

import UIKit

// MARK: - الإنجازات

struct AchievementItem {
    let category: String
    let icon: String
    let ring: MedalView.Ring     // برونزي / فضي / ذهبي
    let title: String
    let detail: String
    let value: Int
    let goal: Int
    var unlocked: Bool { value >= goal }
    var progress: CGFloat { CGFloat(min(value, goal)) / CGFloat(max(goal, 1)) }
}

extension GameStore {
    /// كل مرة سجّل فيها إنجاز عادة
    var totalCompletions: Int { habits.reduce(0) { $0 + $1.completedDays.count } }

    /// أيام ورا بعض أنجز فيها عادة وحدة على الأقل (اليوم أو أمس لو لسا ما أنجز اليوم)
    var dayStreak: Int {
        let days = Set(habits.flatMap(\.completedDays))
        let cal = Calendar.current
        var d = Date()
        if !days.contains(Day.key(d)) { d = cal.date(byAdding: .day, value: -1, to: d) ?? d }
        var n = 0
        while days.contains(Day.key(d)) {
            n += 1
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return n
    }

    /// أطول سلسلة أيام ورا بعض (عشان الوسام ما يروح لو انقطعت السلسلة بعدين)
    var longestStreak: Int {
        let cal = Calendar.current
        let dates = Set(habits.flatMap(\.completedDays)).sorted()
        var best = 0, run = 0
        var prev: Date?
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        for k in dates {
            guard let d = f.date(from: k) else { continue }
            if let p = prev, let next = cal.date(byAdding: .day, value: 1, to: p), cal.isDate(next, inSameDayAs: d) { run += 1 } else { run = 1 }
            best = max(best, run)
            prev = d
        }
        return best
    }

    /// كم يوم أنجز فيه كل عاداته
    var perfectDays: Int {
        guard !habits.isEmpty else { return 0 }
        var count: [String: Int] = [:]
        habits.forEach { $0.completedDays.forEach { count[$0, default: 0] += 1 } }
        return count.values.filter { $0 >= habits.count }.count
    }

    /// الأوسمة — كل قسم ٢-٣ درجات (برونزي ← فضي ← ذهبي) مثل تطبيقات العادات
    var achievements: [AchievementItem] {
        let done = totalCompletions, ls = longestStreak, pd = perfectDays
        let goals = Set(habits.compactMap(\.goal)).count
        let own = state.unlockedRewards.count
        let xpTotal = xp
        let name = profile?.characterName ?? ""
        return [
            AchievementItem(category: "البداية", icon: "leaf.fill", ring: .bronze, title: "أول عادة", detail: g("أكملت", "أكملتِ") + " أول عادة", value: done, goal: 1),
            AchievementItem(category: "البداية", icon: "checkmark", ring: .silver, title: "٥٠ إنجاز", detail: g("سجّلت", "سجّلتِ") + " ٥٠ إنجاز", value: done, goal: 50),
            AchievementItem(category: "البداية", icon: "checkmark.seal.fill", ring: .gold, title: "٢٠٠ إنجاز", detail: g("سجّلت", "سجّلتِ") + " ٢٠٠ إنجاز", value: done, goal: 200),
            AchievementItem(category: "السلاسل", icon: "flame.fill", ring: .bronze, title: "سلسلة ٣ أيام", detail: g("أنجزت", "أنجزتِ") + " ٣ أيام متتالية", value: ls, goal: 3),
            AchievementItem(category: "السلاسل", icon: "calendar", ring: .silver, title: "تحدي الأسبوع", detail: "٧ أيام ورا بعض بدون توقف", value: ls, goal: 7),
            AchievementItem(category: "السلاسل", icon: "mountain.2.fill", ring: .gold, title: "شهر كامل", detail: "٣٠ يوم ورا بعض", value: ls, goal: 30),
            AchievementItem(category: "الأيام المثالية", icon: "star.fill", ring: .bronze, title: "يوم مثالي", detail: "كل عادات اليوم في يوم واحد", value: pd, goal: 1),
            AchievementItem(category: "الأيام المثالية", icon: "star.fill", ring: .silver, title: "٥ أيام مثالية", detail: "٥ أيام " + g("أنجزت", "أنجزتِ") + " فيها كل شي", value: pd, goal: 5),
            AchievementItem(category: "الأيام المثالية", icon: "sun.max.fill", ring: .gold, title: "٢٠ يوم مثالي", detail: "٢٠ يوم بدون ما تفوتك عادة", value: pd, goal: 20),
            AchievementItem(category: "الأهداف", icon: "target", ring: .bronze, title: g("صاحب هدف", "صاحبة هدف"), detail: g("بنيت", "بنيتِ") + " أول هدف مع \(name)", value: goals, goal: 1),
            AchievementItem(category: "الأهداف", icon: "target", ring: .silver, title: "٣ أهداف", detail: "٣ أهداف مختلفة", value: goals, goal: 3),
            AchievementItem(category: "الدولاب", icon: "tshirt.fill", ring: .bronze, title: g("المستكشف", "المستكشفة"), detail: g("فتحت", "فتحتِ") + " أول قطعة ملابس", value: own, goal: 1),
            AchievementItem(category: "الدولاب", icon: "tshirt.fill", ring: .silver, title: g("أنيق", "أنيقة"), detail: "٥ قطع في دولابك", value: own, goal: 5),
            AchievementItem(category: "الدولاب", icon: "crown.fill", ring: .gold, title: "دولاب كامل", detail: "كل الملابس", value: own, goal: Reward.all.count),
            AchievementItem(category: "النجوم", icon: "star.fill", ring: .bronze, title: "١٠٠ نجمة", detail: g("جمعت", "جمعتِ") + " ١٠٠ نجمة", value: xpTotal, goal: 100),
            AchievementItem(category: "النجوم", icon: "star.fill", ring: .silver, title: "٥٠٠ نجمة", detail: g("جمعت", "جمعتِ") + " ٥٠٠ نجمة", value: xpTotal, goal: 500),
            AchievementItem(category: "النجوم", icon: "sun.max.fill", ring: .gold, title: "١٥٠٠ نجمة", detail: g("جمعت", "جمعتِ") + " ١٥٠٠ نجمة", value: xpTotal, goal: 1500),
            AchievementItem(category: "المستوى", icon: "crown.fill", ring: .gold, title: Level.all.last?.title ?? "", detail: g("وصلت", "وصلتِ") + " لآخر مستوى", value: level.number, goal: Level.all.count)
        ]
    }
}

// MARK: - عناصر مشتركة بين صفحات البروفايل

enum ProfileUI {
    static let inset = UIColor.black.withAlphaComponent(0.22)
    static let track = UIColor(red: 0.29, green: 0.15, blue: 0.05, alpha: 0.85)
    static let fillGold = UIColor(red: 0.88, green: 0.68, blue: 0.27, alpha: 1)

    /// صندوق خشب غامق "محفور" في اللوح
    static func tile(radius: CGFloat = 18) -> UIView {
        let v = UIView()
        v.backgroundColor = inset
        v.layer.cornerRadius = radius
        v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.black.withAlphaComponent(0.12).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    /// شريط محفور بتعبئة ذهبية من اليمين
    static func bar(_ progress: CGFloat, height: CGFloat = 12) -> UIView {
        let track = UIView()
        track.backgroundColor = Self.track
        track.layer.cornerRadius = height / 2
        track.clipsToBounds = true
        track.translatesAutoresizingMaskIntoConstraints = false
        let fill = UIView()
        fill.backgroundColor = fillGold
        fill.layer.cornerRadius = height / 2
        fill.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fill)
        NSLayoutConstraint.activate([
            track.heightAnchor.constraint(equalToConstant: height),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),   // RTL: يبدأ من اليمين
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: max(0.02, min(progress, 1)))
        ])
        return track
    }

    static func pin(_ v: UIView, in box: UIView, _ e: UIEdgeInsets) {
        v.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: box.topAnchor, constant: e.top),
            v.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -e.bottom),
            v.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: e.left),
            v.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -e.right)
        ])
    }

    /// عنوان القسم + «عرض الكل ‹»
    static func header(_ title: String, action: (() -> Void)?) -> UIView {
        var views: [UIView] = [UI.label(title, size: 16, weight: .heavy, color: Theme.creamLight), UIView()]
        if let action {
            var c = UIButton.Configuration.plain()
            c.title = "عرض الكل"
            c.image = UIImage(systemName: "chevron.left")
            c.imagePlacement = .leading   // مع forceLeftToRight: السهم يسار الكلام ويأشّر يسار ‹ عرض الكل
            c.imagePadding = 4
            c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .heavy)
            c.baseForegroundColor = Theme.gold
            c.contentInsets = .zero
            c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = Theme.font(13, .heavy)
                return out
            }
            let more = UIButton(configuration: c, primaryAction: UIAction { _ in action() })
            more.semanticContentAttribute = .forceLeftToRight
            views.append(more)
        }
        let row = UIStackView(arrangedSubviews: views)
        row.alignment = .center
        return row
    }
}

// MARK: - الشاشة

final class ProfileViewController: PanelViewController {
    private var stack: UIStackView?
    private let onReset: () -> Void

    init(onReset: @escaping () -> Void) {
        self.onReset = onReset
        super.init(title: GameStore.shared.profile?.characterName ?? "البروفايل",
                   subtitle: nil, icon: "person.fill")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        stack = installScrollingStack(spacing: 12)
        reload()
    }

    override func reload() {
        guard let stack, let profile = store.profile else { return }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        titleLabel.text = profile.characterName
        subtitleLabel.text = store.level.title

        stack.addArrangedSubview(top(profile))
        stack.addArrangedSubview(stats())
        stack.addArrangedSubview(pathCard())
        stack.addArrangedSubview(latestCard())
        let s = UI.label("الإعدادات", size: 16, weight: .heavy, color: Theme.creamLight)
        stack.addArrangedSubview(s)
        stack.setCustomSpacing(8, after: s)
        stack.addArrangedSubview(settings(profile))
    }

    // ١) يمين: وسام المستوى والشريط — يسار: الشخصية
    private func top(_ profile: UserProfile) -> UIView {
        let lv = store.level
        let medal = MedalView(icon: lv.icon, size: 58, ring: .gold, current: true)
        let names = UIStackView(arrangedSubviews: [
            UI.label("المستوى \(Fmt.num(lv.number))", size: 18, weight: .heavy, color: Theme.creamLight),
            UI.label(lv.title, size: 13, weight: .heavy, color: Theme.gold)
        ])
        names.axis = .vertical
        names.spacing = 2
        let lvRow = UIStackView(arrangedSubviews: [medal, names])
        lvRow.spacing = 10
        lvRow.alignment = .center

        var progress: CGFloat = 1
        var left = "", right = "أعلى مستوى 👑"
        if let n = store.nextLevel {
            let inLv = store.xp - lv.minXP, span = n.minXP - lv.minXP
            progress = CGFloat(inLv) / CGFloat(max(span, 1))
            left = "\(Fmt.num(inLv))/\(Fmt.num(span))"
            right = "إلى المستوى \(Fmt.num(n.number))"
        }
        let labels = UIStackView(arrangedSubviews: [
            UI.label(right, size: 12, weight: .heavy, color: Theme.cream.withAlphaComponent(0.7)), UIView(),
            UI.label(left, size: 12, weight: .heavy, color: Theme.cream.withAlphaComponent(0.7))
        ])
        let info = UIStackView(arrangedSubviews: [lvRow, ProfileUI.bar(progress), labels])
        info.axis = .vertical
        info.spacing = 10
        info.alignment = .fill

        // الشخصية في صندوق، تكبر مع المرحلة، وحولها هالة
        let box = ProfileUI.tile()
        let aura = LevelAuraView()
        aura.translatesAutoresizingMaskIntoConstraints = false
        let char = RoomObjectView(imageName: profile.gender.canvasImage, fallbackSymbol: "figure.stand", label: "")
        char.isUserInteractionEnabled = false
        char.setImage(named: profile.gender.canvasImage, fallback: "namq_boy_canvas")
        char.dress(store.outfit, gender: profile.gender)
        char.show(expression: "happy", for: 1.5)
        char.translatesAutoresizingMaskIntoConstraints = false
        let ratio = char.imageView.image.map { $0.size.width / max($0.size.height, 1) } ?? 0.4
        let h: CGFloat = 118 + CGFloat(lv.stage - 1) * 6
        box.addSubview(aura)
        box.addSubview(char)
        NSLayoutConstraint.activate([
            char.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -8),
            char.topAnchor.constraint(equalTo: box.topAnchor, constant: 10),
            char.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            char.heightAnchor.constraint(equalToConstant: h),
            char.widthAnchor.constraint(equalTo: char.heightAnchor, multiplier: ratio),
            aura.centerXAnchor.constraint(equalTo: char.centerXAnchor),
            aura.centerYAnchor.constraint(equalTo: char.centerYAnchor),
            aura.widthAnchor.constraint(equalTo: char.heightAnchor, multiplier: 0.8),
            aura.heightAnchor.constraint(equalTo: char.heightAnchor, multiplier: 0.95)
        ])
        DispatchQueue.main.async { aura.apply(level: lv.number) }

        let row = UIStackView(arrangedSubviews: [info, box])
        row.spacing = 12
        row.alignment = .center
        box.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.42).isActive = true
        return row
    }

    // ٢) الأرقام في بطاقة وحدة بفواصل
    private func stats() -> UIView {
        let items: [(String, UIColor, String, String)] = [
            ("checkmark", UIColor(red: 0.62, green: 0.79, blue: 0.48, alpha: 1), Fmt.num(store.totalCompletions), "عادات مكتملة"),
            ("star.fill", Theme.gold, Fmt.num(store.points), "نقطة"),
            ("flame.fill", UIColor(red: 0.95, green: 0.60, blue: 0.32, alpha: 1), Fmt.num(store.dayStreak), "أيام متتالية")
        ]
        let card = ProfileUI.tile()
        let row = UIStackView()
        row.distribution = .fillEqually
        for (i, (symbol, color, value, title)) in items.enumerated() {
            let col = UIStackView(arrangedSubviews: [
                UI.symbol(symbol, color: color, size: 17),
                UI.label(value, size: 22, weight: .heavy, color: Theme.creamLight, align: .center),
                UI.label(title, size: 12, weight: .bold, color: Theme.cream.withAlphaComponent(0.7), align: .center)
            ])
            col.axis = .vertical
            col.alignment = .center
            col.spacing = 2
            if i > 0 {
                let line = UIView()
                line.backgroundColor = Theme.cream.withAlphaComponent(0.12)
                line.translatesAutoresizingMaskIntoConstraints = false
                col.addSubview(line)
                NSLayoutConstraint.activate([
                    line.widthAnchor.constraint(equalToConstant: 1.5),
                    line.topAnchor.constraint(equalTo: col.topAnchor, constant: 4),
                    line.bottomAnchor.constraint(equalTo: col.bottomAnchor, constant: -4),
                    line.trailingAnchor.constraint(equalTo: col.trailingAnchor, constant: 0)
                ])
            }
            row.addArrangedSubview(col)
        }
        ProfileUI.pin(row, in: card, UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0))
        return card
    }

    // ٣) مسار تطورك — ٥ أوسمة حول المستوى الحالي + نقاط تحت
    private func pathCard() -> UIView {
        let all = Level.all, cur = store.level.number
        let start = max(1, min(cur - 1, all.count - 4))
        let window = Array(all[(start - 1)..<min(start + 4, all.count)])
        let medals = UIStackView()
        medals.distribution = .fillEqually
        medals.alignment = .top
        let dots = UIStackView()
        dots.distribution = .fillEqually
        for l in window {
            let reached = l.number <= cur, isCur = l.number == cur
            let m = MedalView(icon: l.icon, size: 48, ring: reached ? .gold : .off, current: isCur)
            let t = UI.label(l.title, size: 11, weight: .heavy,
                             color: isCur ? Theme.gold : (reached ? Theme.cream : Theme.cream.withAlphaComponent(0.4)),
                             lines: 2, align: .center)
            let col = UIStackView(arrangedSubviews: [m, t])
            col.axis = .vertical
            col.alignment = .center
            col.spacing = 6
            medals.addArrangedSubview(col)
            let d = UIView()
            let size: CGFloat = isCur ? 11 : 7
            d.backgroundColor = isCur ? Theme.creamLight : (reached ? Theme.gold : UIColor(red: 0.35, green: 0.23, blue: 0.12, alpha: 1))
            d.layer.cornerRadius = size / 2
            if isCur { d.layer.borderWidth = 2.5; d.layer.borderColor = Theme.gold.cgColor }
            d.translatesAutoresizingMaskIntoConstraints = false
            let holder = UIView()
            holder.addSubview(d)
            NSLayoutConstraint.activate([
                d.widthAnchor.constraint(equalToConstant: size), d.heightAnchor.constraint(equalToConstant: size),
                d.centerXAnchor.constraint(equalTo: holder.centerXAnchor), d.centerYAnchor.constraint(equalTo: holder.centerYAnchor),
                holder.heightAnchor.constraint(equalToConstant: 14)
            ])
            dots.addArrangedSubview(holder)
        }
        let line = UIView()
        line.backgroundColor = Theme.cream.withAlphaComponent(0.18)
        line.translatesAutoresizingMaskIntoConstraints = false
        dots.insertSubview(line, at: 0)
        NSLayoutConstraint.activate([
            line.heightAnchor.constraint(equalToConstant: 2), line.centerYAnchor.constraint(equalTo: dots.centerYAnchor),
            line.widthAnchor.constraint(equalTo: dots.widthAnchor, multiplier: 0.8), line.centerXAnchor.constraint(equalTo: dots.centerXAnchor)
        ])
        let body = UIStackView(arrangedSubviews: [
            ProfileUI.header("مسار تطورك") { [weak self] in self?.present(LevelsViewController(), animated: true) },
            medals, dots
        ])
        body.axis = .vertical
        body.spacing = 12
        let card = ProfileUI.tile()
        ProfileUI.pin(body, in: card, UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        return card
    }

    // ٤) آخر إنجازاتك — المفتوحة أول، وبعدها الأقرب للفتح
    private func latestCard() -> UIView {
        let all = store.achievements
        let got = Array(all.filter(\.unlocked).suffix(4).reversed())
        let next = all.filter { !$0.unlocked }.sorted { $0.progress > $1.progress }
        let show = Array((got + next).prefix(4))
        let row = UIStackView()
        row.distribution = .fillEqually
        row.alignment = .fill
        row.spacing = 6
        for a in show {
            let cell = ProfileUI.tile(radius: 14)
            cell.backgroundColor = UIColor.black.withAlphaComponent(0.15)
            cell.layer.borderWidth = 0
            let m = MedalView(icon: a.icon, size: 46, ring: a.unlocked ? a.ring : .off, locked: !a.unlocked)
            let t = UI.label(a.title + (a.unlocked ? " ★" : ""), size: 11, weight: .heavy,
                             color: a.unlocked ? Theme.creamLight : Theme.cream.withAlphaComponent(0.5), lines: 2, align: .center)
            let d = UI.label(a.unlocked ? a.detail : "\(Fmt.num(min(a.value, a.goal)))/\(Fmt.num(a.goal))",
                             size: 10, weight: .bold, color: Theme.cream.withAlphaComponent(0.5), lines: 3, align: .center)
            let col = UIStackView(arrangedSubviews: [m, t, d, UIView()])
            col.axis = .vertical
            col.alignment = .center
            col.spacing = 4
            ProfileUI.pin(col, in: cell, UIEdgeInsets(top: 10, left: 3, bottom: 8, right: 3))
            row.addArrangedSubview(cell)
        }
        let body = UIStackView(arrangedSubviews: [
            ProfileUI.header("آخر إنجازاتك") { [weak self] in self?.present(AchievementsViewController(), animated: true) },
            row
        ])
        body.axis = .vertical
        body.spacing = 12
        let card = ProfileUI.tile()
        ProfileUI.pin(body, in: card, UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        return card
    }

    private func tile() -> UIView { ProfileUI.tile() }

    private func settings(_ profile: UserProfile) -> UIView {
        let card = tile()
        let list = UIStackView()
        list.axis = .vertical
        list.translatesAutoresizingMaskIntoConstraints = false

        let sw = UISwitch()
        sw.isOn = store.remindersOn
        sw.onTintColor = Theme.leaf
        sw.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        sw.layer.cornerRadius = 16
        sw.thumbTintColor = Theme.creamLight
        sw.addAction(UIAction { [weak self] _ in
            self?.store.setReminders(on: sw.isOn)
            if sw.isOn { ReminderManager.requestPermission() }
        }, for: .valueChanged)
        list.addArrangedSubview(settingRow("bell", "التذكيرات", accessory: sw))

        list.addArrangedSubview(divider())
        list.addArrangedSubview(settingRow("pencil", "اسم شخصيتك", value: profile.characterName) { [weak self] in self?.rename() })

        // ولد / بنت: كبسولة صغيرة، المختار غامق ونصه ذهبي
        list.addArrangedSubview(divider())
        let pills = UIStackView()
        pills.spacing = 2
        pills.isLayoutMarginsRelativeArrangement = true
        pills.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3)
        pills.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        pills.layer.cornerRadius = 18
        for (g, t) in [(Gender.boy, "ولد"), (Gender.girl, "بنت")] {
            let on = profile.gender == g
            var c = UIButton.Configuration.filled()
            c.title = t
            c.cornerStyle = .capsule
            c.baseBackgroundColor = on ? UIColor.black.withAlphaComponent(0.42) : .clear
            c.baseForegroundColor = on ? Theme.gold : Theme.cream.withAlphaComponent(0.7)
            c.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
            c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = Theme.font(14, .heavy)
                return out
            }
            pills.addArrangedSubview(UIButton(configuration: c, primaryAction: UIAction { [weak self] _ in
                guard let self, var p = self.store.profile, p.gender != g else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                p.gender = g
                self.store.saveProfile(p)
            }))
        }
        list.addArrangedSubview(settingRow("person", "شخصيتك", accessory: pills))

        list.addArrangedSubview(divider())
        let method = store.account?.method == "apple" ? "Apple" : "ضيف"
        list.addArrangedSubview(settingRow("person.crop.circle", "الحساب", value: "\(store.account?.name ?? "") · \(method)"))

        card.addSubview(list)
        NSLayoutConstraint.activate([
            list.topAnchor.constraint(equalTo: card.topAnchor, constant: 2),
            list.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -2),
            list.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            list.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)
        ])

        // البدء من جديد: نص صغير تحت بدل زر كبير
        var c = UIButton.Configuration.plain()
        c.title = "البدء من جديد"
        c.image = UIImage(systemName: "arrow.counterclockwise")
        c.imagePlacement = .trailing
        c.imagePadding = 6
        c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        c.baseForegroundColor = Theme.pillDanger
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.font(14, .bold)
            return out
        }
        let reset = UIButton(configuration: c, primaryAction: UIAction { [weak self] _ in self?.confirmReset() })
        let wrap = UIStackView(arrangedSubviews: [card, reset])
        wrap.axis = .vertical
        wrap.spacing = 10
        return wrap
    }

    private func divider() -> UIView {
        let v = UIView()
        v.backgroundColor = Theme.cream.withAlphaComponent(0.1)
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func settingRow(_ symbol: String, _ title: String, value: String? = nil, accessory: UIView? = nil,
                            action: (() -> Void)? = nil) -> UIView {
        let icon = UI.symbol(symbol, color: Theme.gold, size: 16)
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
        var views: [UIView] = [icon, UI.label(title, size: 15, weight: .heavy, color: Theme.creamLight)]
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        views.append(spacer)
        if let value { views.append(UI.label(value, size: 14, weight: .bold, color: Theme.cream.withAlphaComponent(0.7))) }
        if let accessory { views.append(accessory) }
        if action != nil { views.append(UI.symbol("chevron.left", color: Theme.cream.withAlphaComponent(0.5), size: 12)) }
        let row = UIStackView(arrangedSubviews: views)
        row.spacing = 10
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        if let action {
            let b = UIButton(type: .custom)
            b.addAction(UIAction { _ in action() }, for: .touchUpInside)
            b.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(b)
            NSLayoutConstraint.activate([
                b.topAnchor.constraint(equalTo: row.topAnchor), b.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                b.leadingAnchor.constraint(equalTo: row.leadingAnchor), b.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])
        }
        return row
    }

    private func rename() {
        let alert = WoodAlertViewController(title: "اسم شخصيتك", message: nil, placeholder: g("سمّ شخصيتك", "سمّي شخصيتك"),
                                            text: store.profile?.characterName, confirm: "حفظ") { [weak self] name in
            guard let self, !name.isEmpty, var p = self.store.profile else { return }
            p.characterName = name
            self.store.saveProfile(p)
        }
        present(alert, animated: true)
    }

    private func confirmReset() {
        let wood = WoodAlertViewController(title: g("تبدأ من جديد؟", "تبدئين من جديد؟"),
                                           message: "بيتم تسجيل الخروج وحذف الشخصية والعادات والنقاط",
                                           confirm: g("ابدأ من جديد", "ابدئي من جديد"), destructive: true) { [weak self] in
            guard let self else { return }
            let done = self.onReset
            self.dismiss(animated: true) { done() }
        }
        present(wood, animated: true)
    }
}

// MARK: - مسار التطور كامل (طريق عمودي)

final class LevelsViewController: PanelViewController {
    init() {
        super.init(title: "مسار تطورك", subtitle: "كل مستوى يكبّر \(GameStore.shared.profile?.characterName ?? "") أكثر", icon: "")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        let stack = installScrollingStack(spacing: 0)
        let all = Level.all, cur = store.level.number
        for (i, l) in all.enumerated() {
            let reached = l.number < cur, isCur = l.number == cur
            // السكة: خط فوق + وسام + خط تحت
            let up = UIView(), down = UIView()
            for (v, on) in [(up, l.number <= cur), (down, l.number < cur)] {
                v.backgroundColor = on ? Theme.gold : UIColor.black.withAlphaComponent(0.28)
                v.translatesAutoresizingMaskIntoConstraints = false
                v.widthAnchor.constraint(equalToConstant: 4).isActive = true
            }
            up.alpha = i == 0 ? 0 : 1
            down.alpha = i == all.count - 1 ? 0 : 1
            let medal = MedalView(icon: l.icon, size: 56, ring: l.number <= cur ? .gold : .off, current: isCur, locked: l.number > cur)
            let rail = UIStackView(arrangedSubviews: [up, medal, down])
            rail.axis = .vertical
            rail.alignment = .center
            up.heightAnchor.constraint(equalTo: down.heightAnchor).isActive = true
            rail.widthAnchor.constraint(equalToConstant: 60).isActive = true

            var lines: [UIView] = [
                UI.label("المستوى \(Fmt.num(l.number)) · \(l.title)", size: 15, weight: .heavy,
                         color: isCur ? Theme.gold : (reached ? Theme.creamLight : Theme.cream.withAlphaComponent(0.5)), lines: 0),
                UI.label(l.perk, size: 12, weight: .bold, color: Theme.cream.withAlphaComponent(0.6), lines: 0)
            ]
            if isCur, let n = store.nextLevel {
                let inLv = store.xp - l.minXP, span = n.minXP - l.minXP
                lines.append(ProfileUI.bar(CGFloat(inLv) / CGFloat(max(span, 1)), height: 7))
                lines.append(UI.label("\(Fmt.num(inLv))/\(Fmt.num(span)) إلى المستوى \(Fmt.num(n.number))", size: 11, weight: .heavy,
                                      color: Theme.cream.withAlphaComponent(0.5)))
            } else {
                let t = reached ? "✓ " + g("وصلته", "وصلتيه") : (isCur ? g("وصلت أعلى مستوى", "وصلتِ أعلى مستوى") : "يفتح عند \(Fmt.num(l.minXP)) ⭐")
                lines.append(UI.label(t, size: 11, weight: .heavy,
                                      color: reached ? UIColor(red: 0.62, green: 0.79, blue: 0.48, alpha: 1) : Theme.cream.withAlphaComponent(0.5)))
            }
            let text = UIStackView(arrangedSubviews: lines)
            text.axis = .vertical
            text.spacing = 3
            text.isLayoutMarginsRelativeArrangement = true
            text.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
            let row = UIStackView(arrangedSubviews: [rail, text])
            row.spacing = 12
            row.alignment = .fill
            stack.addArrangedSubview(row)
        }
    }
}

// MARK: - كل الإنجازات (مقسّمة، وكل وسام عليه شريط تقدّم)

final class AchievementsViewController: PanelViewController {
    init() {
        let all = GameStore.shared.achievements
        super.init(title: "إنجازاتك",
                   subtitle: g("فتحت", "فتحتِ") + " \(Fmt.num(all.filter(\.unlocked).count)) من \(Fmt.num(all.count)) وسام", icon: "")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        let stack = installScrollingStack(spacing: 10)
        let all = store.achievements
        var cats: [String] = []
        all.forEach { if !cats.contains($0.category) { cats.append($0.category) } }
        for cat in cats {
            let h = UI.label(cat, size: 16, weight: .heavy, color: Theme.creamLight)
            stack.addArrangedSubview(h)
            let list = UIStackView()
            list.axis = .vertical
            for (i, a) in all.filter({ $0.category == cat }).enumerated() {
                if i > 0 {
                    let line = UIView()
                    line.backgroundColor = Theme.cream.withAlphaComponent(0.1)
                    line.heightAnchor.constraint(equalToConstant: 1).isActive = true
                    list.addArrangedSubview(line)
                }
                let m = MedalView(icon: a.icon, size: 50, ring: a.unlocked ? a.ring : .off, locked: !a.unlocked)
                let text = UIStackView(arrangedSubviews: [
                    UI.label(a.title, size: 14, weight: .heavy, color: a.unlocked ? Theme.creamLight : Theme.cream.withAlphaComponent(0.6)),
                    UI.label(a.detail, size: 12, weight: .bold, color: Theme.cream.withAlphaComponent(0.5), lines: 0),
                    ProfileUI.bar(a.progress, height: 7)
                ])
                text.axis = .vertical
                text.spacing = 4
                text.setCustomSpacing(6, after: text.arrangedSubviews[1])
                let state = a.unlocked
                    ? UI.symbol("checkmark", color: UIColor(red: 0.62, green: 0.79, blue: 0.48, alpha: 1), size: 15)
                    : UI.label("\(Fmt.num(min(a.value, a.goal)))/\(Fmt.num(a.goal))", size: 12, weight: .heavy, color: Theme.cream.withAlphaComponent(0.5))
                state.setContentHuggingPriority(.required, for: .horizontal)
                let row = UIStackView(arrangedSubviews: [m, text, state])
                row.spacing = 12
                row.alignment = .center
                row.isLayoutMarginsRelativeArrangement = true
                row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
                list.addArrangedSubview(row)
            }
            let card = ProfileUI.tile()
            ProfileUI.pin(list, in: card, UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12))
            stack.addArrangedSubview(card)
            stack.setCustomSpacing(16, after: card)
        }
    }
}
