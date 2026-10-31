//
//  MyHabitsViewController.swift
//  NAMQ
//
//  الطاولة 📖 — تبويبين: «عادات اليوم» و«عادات الأهداف».
//  عادات الأهداف = العادات اللي بناها المساعد لهدف معيّن، متجمّعة تحت «عاداتي لتحقيق هدف …».
//

import UIKit

final class MyHabitsViewController: PanelViewController {
    private var stack: UIStackView?
    private enum HabitsTab { case today, goals }
    private var selectedTab: HabitsTab = .today

    init() {
        super.init(title: "الطاولة", subtitle: nil, icon: "checklist")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        let add = UI.pill(g("اكتب عادة جديدة", "اكتبي عادة جديدة"), icon: "square.and.pencil") { [weak self] in
            self?.present(HabitEditorViewController(habit: .blank(), isNew: true), animated: true)
        }
        add.configuration?.imagePlacement = .trailing   // القلم بعد الكلام
        stack = installScrollingStack(footer: add)
        reload()
    }

    override func reload() {
        guard let stack else { return }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let progress = store.todayProgress
        subtitleLabel.text = progress.total == 0
            ? g("هنا تكتب عاداتك وتسجّل إنجازك كل يوم", "هنا تكتبين عاداتك وتسجّلين إنجازك كل يوم")
            : "أنجزت \(Fmt.num(progress.done)) من \(Fmt.num(progress.total)) عادات اليوم"

        guard !store.habits.isEmpty else {
            stack.addArrangedSubview(emptyState())
            return
        }

        // التبويبين
        let tabs = UIStackView(arrangedSubviews: [
            tabButton("عادات اليوم", selected: selectedTab == .today) { [weak self] in self?.switchTo(.today) },
            tabButton("عادات الأهداف", selected: selectedTab == .goals) { [weak self] in self?.switchTo(.goals) }
        ])
        tabs.distribution = .fillEqually
        tabs.spacing = 10
        stack.addArrangedSubview(tabs)
        stack.setCustomSpacing(18, after: tabs)

        let plain = store.habits.filter { $0.goal == nil }
        let goals = goalGroups()

        if selectedTab == .today {
            section("عادات اليوم")
            if plain.isEmpty {
                stack.addArrangedSubview(UI.label(g("ما عندك عادات لحالها للحين — اكتب وحدة أو اختر من المكتبة 📚", "ما عندك عادات لحالها للحين — اكتبي وحدة أو اختاري من المكتبة 📚"),
                                                  size: 13, color: Theme.cream.withAlphaComponent(0.85), lines: 0))
            }
            plain.forEach { stack.addArrangedSubview(row(for: $0)) }
        }
        if goals.isEmpty, selectedTab == .goals {
            stack.addArrangedSubview(goalsEmptyState())
        }
        for g in goals {
            if let last = stack.arrangedSubviews.last, last !== tabs { stack.setCustomSpacing(26, after: last) }
            section("عاداتي لتحقيق هدف «\(g.goal)»")
            g.habits.forEach { stack.addArrangedSubview(row(for: $0)) }
        }

        let hint = UI.label(g("اضغط على العادة لتعديلها، وعلى الدائرة لتسجيل إنجاز اليوم.", "اضغطي على العادة لتعديلها، وعلى الدائرة لتسجيل إنجاز اليوم."),
                            size: 12, color: Theme.cream.withAlphaComponent(0.85), lines: 0, align: .center)
        if let last = stack.arrangedSubviews.last { stack.setCustomSpacing(20, after: last) }
        stack.addArrangedSubview(hint)
    }

    /// العادات متجمّعة حسب الهدف (بنفس ترتيب إضافتها)
    private func goalGroups() -> [(goal: String, habits: [Habit])] {
        var order: [String] = []
        var map: [String: [Habit]] = [:]
        for h in store.habits {
            guard let g = h.goal else { continue }
            if map[g] == nil { order.append(g) }
            map[g, default: []].append(h)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    private func section(_ text: String) {
        guard let stack else { return }
        let l = UI.label(text, size: 16, weight: .heavy, color: Theme.creamLight, lines: 0)
        stack.addArrangedSubview(l)
        stack.setCustomSpacing(10, after: l)
    }

    private func row(for habit: Habit) -> UIView {
        let done = store.isDoneToday(habit)
        let streak = store.streak(habit)
        var meta = "+\(Fmt.num(habit.kind.points)) نقطة"
        if streak > 0 { meta = "🔥 سلسلة \(Fmt.days(streak)) · " + meta }
        if habit.kind == .quit { meta = "عادة أتركها · " + meta }

        let row = HabitRowView(icon: habit.icon, tint: habit.kind.color, title: habit.title,
                               detail: habit.planStepText.map { "📍 " + $0 } ?? "⏰ " + habit.scheduleText, meta: meta,
                               accessory: checkButton(for: habit, done: done))
        if done {
            // لون مصمت (مو شفاف) عشان زر الحذف اللي وراه ما يبان
            row.backgroundColor = UIColor(red: 0.88, green: 0.81, blue: 0.62, alpha: 1)
            row.layer.borderColor = Theme.leaf.withAlphaComponent(0.5).cgColor
        }
        // اسحب العادة يمين ← يطلع زر الحذف
        weak var swipe: SwipeToDeleteView?
        let wrapper = SwipeToDeleteView(content: row) { [weak self] in self?.confirmDelete(habit) }
        swipe = wrapper
        row.addAction(UIAction { [weak self] _ in
            guard swipe?.allowsTap ?? true else { return }
            self?.present(HabitEditorViewController(habit: habit, isNew: false), animated: true)
        }, for: .touchUpInside)
        return wrapper
    }

    private func confirmDelete(_ habit: Habit) {
        let alert = WoodAlertViewController(title: g("تحذف", "تحذفين") + " «\(habit.title)»؟", message: "بتنحذف العادة وتذكيراتها",
                                            confirm: "احذفها", destructive: true) { [weak self] in
            self?.store.delete(habit)
            self?.view.showToast("تم حذف العادة")
        }
        present(alert, animated: true)
    }

    private func switchTo(_ t: HabitsTab) {
        guard t != selectedTab else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        selectedTab = t
        reload()
    }

    private func tabButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> UIButton {
        UI.toggle(title, selected: selected, action: action)
    }

    private func goalsEmptyState() -> UIView {
        let name = store.profile?.characterName ?? "رفيقك"
        let title = UI.label("ما عندك هدف للحين", size: 17, weight: .heavy, color: Theme.creamLight, align: .center)
        let body = UI.label(g("اضغط على \(name) في الغرفة وقل له هدفك، ويبني لك العادات اللي توصلك له.", "اضغطي على \(name) في الغرفة وقولي لها هدفك، وتبني لك العادات اللي توصلك له."),
                            size: 14, color: Theme.cream.withAlphaComponent(0.85), lines: 0, align: .center)
        let open = UI.pill(g("كلّم \(name)", "كلّمي \(name)"), icon: "sparkles", style: .secondary) { [weak self] in
            self?.present(CoachViewController(), animated: true)
        }
        let s = UIStackView(arrangedSubviews: [title, body, open])
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 10
        s.isLayoutMarginsRelativeArrangement = true
        s.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 30, leading: 12, bottom: 10, trailing: 12)
        return s
    }

    private func checkButton(for habit: Habit, done: Bool) -> UIButton {
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: done ? "checkmark.circle.fill" : "circle")
        c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold)
        c.baseForegroundColor = done ? Theme.leaf : Theme.wood.withAlphaComponent(0.45)
        c.contentInsets = .zero
        let b = UIButton(configuration: c, primaryAction: UIAction { [weak self] _ in self?.toggle(habit) })
        b.accessibilityLabel = done ? "تم اليوم" : habit.kind.doneVerb
        b.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            b.widthAnchor.constraint(equalToConstant: 44),
            b.heightAnchor.constraint(equalToConstant: 44)
        ])
        return b
    }

    private func toggle(_ habit: Habit) {
        let delta = store.toggleToday(habit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if delta > 0 {
            view.showToast("+\(Fmt.num(delta)) نقطة ⭐ \(habit.kind.doneVerb)!")
        }
    }

    private func emptyState() -> UIView {
        let icon = UI.symbol("text.book.closed.fill", color: Theme.cream.withAlphaComponent(0.6), size: 44)
        let title = UI.label("طاولتك فاضية!", size: 18, weight: .heavy, color: Theme.creamLight, align: .center)
        let body = UI.label(g("اكتب عادة جديدة بنفسك، أو اختر عادة جاهزة من المكتبة.", "اكتبي عادة جديدة بنفسك، أو اختاري عادة جاهزة من المكتبة."),
                            size: 14, color: Theme.cream.withAlphaComponent(0.85), lines: 0, align: .center)
        let open = UI.pill("افتح المكتبة", icon: "books.vertical.fill", style: .secondary) { [weak self] in
            self?.present(HabitLibraryViewController(), animated: true)
        }
        let s = UIStackView(arrangedSubviews: [icon, title, body, open])
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 10
        s.setCustomSpacing(18, after: body)
        s.isLayoutMarginsRelativeArrangement = true
        s.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 40, leading: 12, bottom: 20, trailing: 12)
        return s
    }
}
