//
//  CoachViewController.swift
//  NAMQ
//
//  مساعد نمق 🤖 — يطلع لما تضغطين على الشخصية.
//  شغلته وحدة: تقولين له هدفك، ويبني لك العادات اللي توصلك له، وتنضاف لطاولتك تحت «عادات الأهداف».
//

import UIKit

final class CoachViewController: PanelViewController {

    private var chat: UIStackView?
    private var scroll: UIScrollView?
    private let input = UI.textField(g("اكتب هدفك هنا…", "اكتبي هدفك هنا…"))
    private lazy var sendButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.image = UIImage(systemName: "arrow.up")
        c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        c.baseBackgroundColor = Theme.leaf
        c.cornerStyle = .capsule
        let b = UIButton(configuration: c, primaryAction: UIAction { [weak self] _ in self?.send() })
        b.accessibilityLabel = "إرسال"
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private var pendingPlan: GoalPlan?
    /// عادات الخطة (يقدر المستخدم يعدّلها ويضيف عليها قبل ما تنضاف للطاولة)
    private var pendingHabits: [Habit] = []
    private var planCard: UIView?

    init() {
        let name = GameStore.shared.profile?.characterName ?? "نمق"
        super.init(title: g("مساعد", "مساعدة") + " \(name)", subtitle: g("قلّه هدفك ويبني لك عاداته", "قوليلها هدفك وتبني لك عاداتها"), icon: "sparkles")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        // الأزرار السريعة + خانة الكتابة
        // أمثلة أهداف (صفين × اثنين) — الضغط عليها يرسلها مباشرة
        func pair(_ a: UIButton, _ b: UIButton) -> UIStackView {
            let r = UIStackView(arrangedSubviews: [a, b])
            r.spacing = 8
            r.distribution = .fillEqually
            return r
        }
        let quickScroll = UIStackView(arrangedSubviews: [
            pair(quickButton("أبي أصير أصح") { [weak self] in self?.send("أبي أصير أصح") },
                 quickButton("أتفوق بدراستي") { [weak self] in self?.send("أبي أتفوق بدراستي") }),
            pair(quickButton("أنام أحسن") { [weak self] in self?.send("أبي أنام أحسن") },
                 quickButton("أقلل الجوال") { [weak self] in self?.send("أبي أقلل الجوال") })
        ])
        quickScroll.axis = .vertical
        quickScroll.spacing = 8

        input.returnKeyType = .send
        input.addAction(UIAction { [weak self] _ in self?.send() }, for: .editingDidEndOnExit)
        let inputRow = UIStackView(arrangedSubviews: [input, sendButton])
        inputRow.spacing = 8
        inputRow.alignment = .center
        NSLayoutConstraint.activate([
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        let footer = UIStackView(arrangedSubviews: [quickScroll, inputRow])
        footer.axis = .vertical
        footer.spacing = 10

        chat = installScrollingStack(spacing: 10, footer: footer)
        scroll = chat?.superview as? UIScrollView

        // التحية
        let p = store.profile
        coachSays("هلا \(p?.name ?? "")! أنا \(p?.characterName ?? "رفيقك") 👋\nوش الهدف اللي ودّك تحققه؟ " + g("قلّي", "قوليلي") + " إياه بكلامك، وأبني لك العادات اللي توصلك له 🎯")
    }

    // MARK: - المحادثة

    private func quickButton(_ title: String, _ action: @escaping () -> Void) -> UIButton {
        var c = UIButton.Configuration.filled()
        c.title = title
        c.baseBackgroundColor = Theme.pillBg
        c.baseForegroundColor = Theme.creamLight
        c.cornerStyle = .capsule
        c.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.font(14, .heavy)
            return out
        }
        return UIButton(configuration: c, primaryAction: UIAction { _ in action() })
    }

    private func bubble(_ text: String, fromUser: Bool) -> UIView {
        let label = UI.label(text, size: 15, weight: fromUser ? .semibold : .medium,
                             color: fromUser ? Theme.creamLight : Theme.ink, lines: 0)
        let box = UIView()
        box.backgroundColor = fromUser ? Theme.leaf : Theme.parchment
        box.layer.cornerRadius = 18
        box.layer.cornerCurve = .continuous
        if !fromUser {
            box.layer.borderWidth = 1.5
            box.layer.borderColor = Theme.wood.withAlphaComponent(0.15).cgColor
        }
        box.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: box.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14)
        ])
        return wrap(box, fromUser: fromUser)
    }

    /// يحط الفقاعة يمين (المساعد) أو يسار (المستخدم) — التطبيق من اليمين لليسار
    private func wrap(_ content: UIView, fromUser: Bool) -> UIView {
        let row = UIView()
        row.addSubview(content)
        var cs = [
            content.topAnchor.constraint(equalTo: row.topAnchor),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            content.widthAnchor.constraint(lessThanOrEqualTo: row.widthAnchor, multiplier: 0.85)
        ]
        cs.append(fromUser ? content.trailingAnchor.constraint(equalTo: row.trailingAnchor)
                           : content.leadingAnchor.constraint(equalTo: row.leadingAnchor))
        NSLayoutConstraint.activate(cs)
        return row
    }

    private func append(_ v: UIView) {
        guard let chat else { return }
        v.alpha = 0
        chat.addArrangedSubview(v)
        UIView.animate(withDuration: 0.3) { v.alpha = 1 }
        DispatchQueue.main.async { [weak self] in self?.scrollToBottom() }
    }

    private func scrollToBottom() {
        guard let scroll else { return }
        scroll.layoutIfNeeded()
        let y = max(0, scroll.contentSize.height - scroll.bounds.height + scroll.contentInset.bottom)
        scroll.setContentOffset(CGPoint(x: 0, y: y), animated: true)
    }

    private func coachSays(_ text: String) { append(bubble(text, fromUser: false)) }
    private func userSays(_ text: String) { append(bubble(text, fromUser: true)) }

    // MARK: - الأفعال

    private func send(_ preset: String? = nil) {
        let text = (preset ?? input.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if preset == nil { input.text = "" }
        view.endEditing(true)
        userSays(text)

        let typing = bubble(g("يفكّر… ✍️", "تفكّر… ✍️"), fromUser: false)
        append(typing)
        Task { @MainActor [weak self] in
            let plan = await Coach.buildGoalPlan(for: text)
            try? await Task.sleep(nanoseconds: 700_000_000)   // لحظة "تفكير" عشان تحسين إنه يبني
            guard let self else { return }
            typing.removeFromSuperview()
            self.showPlan(plan)
        }
    }

    private func showPlan(_ plan: GoalPlan) {
        pendingPlan = plan
        pendingHabits = plan.makeHabits()
        coachSays("هدفك: «\(plan.goal)» 🎯\nجهّزت لك \(Fmt.num(plan.habits.count)) عادات توصلك له. كل وحدة تبدأ صغيرة وتكبر معك أسبوع بأسبوع 🌱")
        let card = buildPlanCard(plan)
        planCard = card
        append(card)
    }

    /// يعيد رسم بطاقة الخطة بعد ما يعدّل المستخدم عليها
    private func refreshPlanCard() {
        guard let plan = pendingPlan, let old = planCard, let chat,
              let i = chat.arrangedSubviews.firstIndex(of: old) else { return }
        let card = buildPlanCard(plan)
        old.removeFromSuperview()
        chat.insertArrangedSubview(card, at: i)
        planCard = card
    }

    private func buildPlanCard(_ plan: GoalPlan) -> UIView {

        // بطاقة الهدف: العادات تحت بعض
        let card = UIView()
        card.backgroundColor = Theme.parchment
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 2
        card.layer.borderColor = Theme.gold.withAlphaComponent(0.6).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        var rows: [UIView] = [UI.label(plan.goal, size: 17, weight: .heavy, color: Theme.ink, lines: 0)]
        for habit in pendingHabits {
            var lines: [UIView] = [UI.label(habit.title, size: 15, weight: .heavy, color: Theme.ink)]
            if let first = habit.plan?.first {
                lines.append(UI.label("الأسبوع ١: " + Gendered.text(first), size: 13, color: Theme.ink, lines: 0))
            }
            lines.append(UI.label("⏰ " + habit.scheduleText, size: 12, weight: .semibold, color: Theme.muted, lines: 0))
            let texts = UIStackView(arrangedSubviews: lines)
            texts.axis = .vertical
            texts.spacing = 2
            let r = UIStackView(arrangedSubviews: [UI.iconBadge(habit.icon, color: habit.kind.color, size: 36), texts])
            r.spacing = 10
            r.alignment = .top
            rows.append(r)
        }
        if plan.poweredByAI {
            rows.append(UI.label("✨ اقترحها الذكاء الاصطناعي على جهازك", size: 11, weight: .semibold, color: Theme.muted))
        }
        let add = UI.pill(g("أضف العادات لطاولتي", "أضيفي العادات لطاولتي"), icon: "plus") { [weak self] in self?.addPlan() }
        // راجع العادات: يعدّل كل عادة، يحذف، أو يضيف عادة من عنده لنفس الهدف
        let review = UI.pill(g("راجع العادات وعدّلها", "راجعي العادات وعدّليها"), icon: "pencil") { [weak self] in self?.openReview() }
        // على البطاقة الفاتحة: بني خشب مصمت (الشفاف يطلع رمادي فوق الورقي)
        review.configuration?.baseBackgroundColor = UIColor(red: 0.42, green: 0.27, blue: 0.13, alpha: 1)
        review.configuration?.baseForegroundColor = Theme.creamLight
        var link = UIButton.Configuration.plain()
        link.title = g("غيّر الهدف", "غيّري الهدف")
        link.baseForegroundColor = Theme.wood
        link.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.font(15, .bold)
            return out
        }
        let redo = UIButton(configuration: link, primaryAction: UIAction { [weak self] _ in
            self?.coachSays(g("تمام، اكتب هدف ثاني 👇", "تمام، اكتبي هدف ثاني 👇"))
            self?.input.becomeFirstResponder()
        })
        rows += [add, review, redo]

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)
        ])
        stack.setCustomSpacing(4, after: review)
        return card
    }

    private func openReview() {
        guard let plan = pendingPlan else { return }
        let vc = GoalReviewViewController(goal: plan.goal, habits: pendingHabits)
        vc.onChange = { [weak self] habits in
            self?.pendingHabits = habits
            self?.refreshPlanCard()
        }
        vc.onConfirm = { [weak self] habits in
            self?.pendingHabits = habits
            self?.addPlan()
        }
        present(vc, animated: true)
    }

    private func addPlan() {
        guard pendingPlan != nil, !pendingHabits.isEmpty else { return }
        pendingPlan = nil
        pendingHabits.forEach { store.upsert($0) }
        pendingHabits = []
        ReminderManager.requestPermission()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        userSays(g("أضف العادات ✅", "أضيفي العادات ✅"))
        coachSays("أضفتها لطاولتك تحت «عادات الأهداف» 🎉 بذكّرك فيها كل يوم، وكل أسبوع تكبر خطوة. أنا معك!")
    }
}


// MARK: - مراجعة عادات الهدف (قبل ما تنضاف للطاولة)

/// يعرض العادات اللي بناها المساعد للهدف: يضغط على أي عادة يعدّلها، يحذفها،
/// أو يضيف عادة من عنده تحقق نفس الهدف — وبعدين يضيفها كلها للطاولة.
final class GoalReviewViewController: PanelViewController {
    private let goal: String
    private var habits: [Habit]
    var onChange: (([Habit]) -> Void)?
    var onConfirm: (([Habit]) -> Void)?
    private let stack = UIStackView()
    private var addButton: UIButton?

    init(goal: String, habits: [Habit]) {
        self.goal = goal
        self.habits = habits
        super.init(title: "عادات هدفك", subtitle: g("عدّل عاداتك أو أضف وحدة", "عدّلي عاداتك أو أضيفي وحدة"),
                   icon: "target")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        let add = UI.pill(g("أضف العادات لطاولتي", "أضيفي العادات لطاولتي"), icon: "plus") { [weak self] in self?.confirm() }
        addButton = add
        contentView.addSubview(scroll)
        contentView.addSubview(add)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: contentView.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: add.topAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor),
            add.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            add.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            add.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        rebuild()
    }

    private func rebuild() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, h) in habits.enumerated() {
            let pencil = UI.symbol("pencil", color: Theme.wood, size: 15)
            let detail = h.plan?.first.map { "الأسبوع ١: " + Gendered.text($0) } ?? (h.kind == .build ? "عادة أبنيها" : "عادة أتركها")
            let row = HabitRowView(icon: h.icon, tint: h.kind.color, title: h.title, detail: detail,
                                   meta: "⏰ " + h.scheduleText, accessory: pencil)
            row.addAction(UIAction { [weak self] _ in self?.edit(at: i) }, for: .touchUpInside)
            stack.addArrangedSubview(row)
        }
        // عادة من عنده تحقق نفس الهدف
        var c = UIButton.Configuration.filled()
        c.title = g("أضف عادة من عندك", "أضيفي عادة من عندك")
        c.image = UIImage(systemName: "plus.circle.fill")
        c.imagePlacement = .trailing
        c.imagePadding = 8
        c.cornerStyle = .large
        c.baseBackgroundColor = Theme.pillBg
        c.baseForegroundColor = Theme.creamLight
        c.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12)
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.font(15, .heavy)
            return out
        }
        let own = UIButton(configuration: c, primaryAction: UIAction { [weak self] _ in self?.addOwn() })
        own.layer.borderWidth = 1.5
        own.layer.borderColor = Theme.gold.withAlphaComponent(0.45).cgColor
        own.layer.cornerRadius = 14
        stack.addArrangedSubview(own)

        addButton?.configuration?.title = habits.isEmpty ? g("أضف عادة وحدة على الأقل", "أضيفي عادة وحدة على الأقل")
            : g("أضف", "أضيفي") + " \(Fmt.num(habits.count)) عادات لطاولتي"
        addButton?.isEnabled = !habits.isEmpty
    }

    private func edit(at i: Int) {
        let vc = HabitEditorViewController(habit: habits[i], isNew: false)
        vc.onSave = { [weak self] h in self?.update { $0[i] = h } }
        vc.onDelete = { [weak self] in self?.update { $0.remove(at: i) } }
        present(vc, animated: true)
    }

    private func addOwn() {
        var h = Habit.blank()
        h.goal = goal
        let vc = HabitEditorViewController(habit: h, isNew: true)
        vc.onSave = { [weak self] h in self?.update { $0.append(h) } }
        present(vc, animated: true)
    }

    private func update(_ change: (inout [Habit]) -> Void) {
        change(&habits)
        rebuild()
        onChange?(habits)
    }

    private func confirm() {
        guard !habits.isEmpty else { return }
        let list = habits
        dismiss(animated: true) { [onConfirm] in onConfirm?(list) }
    }
}
