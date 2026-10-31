//
//  HabitEditorViewController.swift
//  NAMQ
//
//  إضافة عادة / تعديلها:
//  الاسم · النوع (للعادة اللي يكتبها المستخدم بس) ·
//  «كم مرة نذكّرك باليوم؟»
//     - مرة وحدة  ← الساعة
//     - أكثر من مرة ← كل كم ساعة + من الساعة + إلى الساعة
//  — وللعادة اللي يتركها (ما لها وقت يسويها فيه) نسأل «كيف نساعدك تتركها؟»:
//     وقت الإغراء · تحفيز الصباح · مراجعة آخر اليوم (يختار اللي يناسبه أو ولا شي)
//  · الأيام
//

import UIKit

final class HabitEditorViewController: PanelViewController {
    private var habit: Habit
    private let isNew: Bool
    /// وضع المسودة (مراجعة عادات الهدف قبل إضافتها): التعديل يرجع للي فتح المحرر بدل ما ينحفظ في الطاولة
    var onSave: ((Habit) -> Void)?
    var onDelete: (() -> Void)?

    private let titleField = UI.textField("اسم العادة (مثال: شرب الماء)")
    private let kindControl = UI.segmented([HabitKind.build.label, HabitKind.quit.label])
    private let freqControl = UI.segmented(["مرة وحدة", "أكثر من مرة"])

    // الأوقات
    private var startMinute = 9 * 60
    private var endMinute = 22 * 60
    private var everyHours = 0
    private var lastEvery = 2
    private let repeatOptions = [1, 2, 3, 4, 6]

    private let onceTimeButton = UIButton(type: .system)
    private let fromButton = UIButton(type: .system)
    private let toButton = UIButton(type: .system)
    private let repeatButton = UIButton(type: .system)
    private let onceBox = UIStackView()
    private let manyBox = UIStackView()
    private let buildBox = UIStackView()

    // عادة أتركها
    private var quit = QuitReminders()
    private let quitBox = UIStackView()
    private let quitHint = UILabel()
    private enum QuitSlot: CaseIterable { case craving, morning, checkIn }
    private var quitRows: [QuitSlot: (row: UIView, check: UIImageView, title: UILabel, sub: UILabel, time: UIButton)] = [:]
    private var lastQuit: [QuitSlot: Int] = [.craving: 13 * 60, .morning: 8 * 60, .checkIn: 21 * 60]

    // عجلة وحدة تتنقل تحت الزر اللي انضغط
    private enum WheelTarget: Equatable { case start, end, quit(QuitSlot) }
    private var wheelTarget: WheelTarget?
    private weak var wheelButton: UIButton?
    private let timeWheel = UIDatePicker()
    private let wheelBox = UIView()

    // الأيام
    private var days = Set(1...7)
    private var dayButtons: [UIButton] = []
    private let everyDayButton = UIButton(type: .system)

    override var fillsScreen: Bool { false }
    override var closesOnBackgroundTap: Bool { false }

    /// عادات المكتبة وعادات المساعد (لها خطة) نوعها معروف — النوع يطلع بس للعادة اللي يكتبها بنفسه
    private var isCustom: Bool { habit.templateID == nil && habit.plan == nil }

    init(habit: Habit, isNew: Bool) {
        self.habit = habit
        self.isNew = isNew
        let title = isNew ? (habit.title.isEmpty ? "عادة جديدة" : habit.title) : "تعديل العادة"
        super.init(title: title, subtitle: isNew ? "متى نذكّرك فيها؟" : nil, icon: habit.icon)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        titleField.text = habit.title
        titleField.returnKeyType = .done
        titleField.addAction(UIAction { _ in }, for: .editingDidEndOnExit)
        kindControl.selectedSegmentIndex = habit.kind == .build ? 0 : 1
        startMinute = habit.startMinute
        endMinute = habit.endMinute
        everyHours = habit.everyHours
        if everyHours > 0 { lastEvery = everyHours }
        if let w = habit.weekdays, !w.isEmpty { days = Set(w) }
        quit = habit.quitReminders
        if let m = quit.craving { lastQuit[.craving] = m } else { lastQuit[.craving] = habit.startMinute }
        if let m = quit.morning { lastQuit[.morning] = m }
        if let m = quit.checkIn { lastQuit[.checkIn] = m }
        kindControl.addAction(UIAction { [weak self] _ in self?.kindChanged() }, for: .valueChanged)

        // ===== كم مرة باليوم =====
        freqControl.selectedSegmentIndex = everyHours > 0 ? 1 : 0
        freqControl.addAction(UIAction { [weak self] _ in self?.frequencyChanged() }, for: .valueChanged)

        // ===== العجلة =====
        timeWheel.datePickerMode = .time
        timeWheel.preferredDatePickerStyle = .wheels
        timeWheel.locale = Fmt.locale
        timeWheel.minuteInterval = 5
        timeWheel.overrideUserInterfaceStyle = .dark
        timeWheel.setValue(Theme.creamLight, forKey: "textColor")
        timeWheel.translatesAutoresizingMaskIntoConstraints = false
        timeWheel.addAction(UIAction { [weak self] _ in self?.wheelChanged() }, for: .valueChanged)
        wheelBox.backgroundColor = Theme.pillBg
        wheelBox.layer.cornerRadius = 18
        wheelBox.layer.cornerCurve = .continuous
        wheelBox.clipsToBounds = true
        wheelBox.isHidden = true
        wheelBox.addSubview(timeWheel)
        NSLayoutConstraint.activate([
            timeWheel.topAnchor.constraint(equalTo: wheelBox.topAnchor),
            timeWheel.bottomAnchor.constraint(equalTo: wheelBox.bottomAnchor),
            timeWheel.leadingAnchor.constraint(equalTo: wheelBox.leadingAnchor),
            timeWheel.trailingAnchor.constraint(equalTo: wheelBox.trailingAnchor),
            timeWheel.heightAnchor.constraint(equalToConstant: 150)
        ])

        [onceTimeButton, fromButton, toButton, repeatButton].forEach(styleValueButton)
        onceTimeButton.addAction(UIAction { [weak self] _ in self?.toggleWheel(.start, under: self?.onceTimeButton) }, for: .touchUpInside)
        fromButton.addAction(UIAction { [weak self] _ in self?.toggleWheel(.start, under: self?.fromButton) }, for: .touchUpInside)
        toButton.addAction(UIAction { [weak self] _ in self?.toggleWheel(.end, under: self?.toButton) }, for: .touchUpInside)
        repeatButton.showsMenuAsPrimaryAction = true

        // مرة وحدة
        onceBox.axis = .vertical
        onceBox.spacing = 8
        onceBox.addArrangedSubview(row("الساعة", onceTimeButton))

        // أكثر من مرة
        manyBox.axis = .vertical
        manyBox.spacing = 10
        [row("كل", repeatButton), row("من الساعة", fromButton), row("إلى الساعة", toButton)]
            .forEach { manyBox.addArrangedSubview($0) }

        buildBox.axis = .vertical
        buildBox.spacing = 14
        [field("كم مرة نذكّرك باليوم؟", freqControl), onceBox, manyBox].forEach { buildBox.addArrangedSubview($0) }

        // ===== عادة أتركها: كيف نساعدك؟ =====
        quitBox.axis = .vertical
        quitBox.spacing = 8
        quitBox.addArrangedSubview(caption(g("كيف نساعدك تتركها؟", "كيف نساعدك تتركينها؟")))
        quitBox.setCustomSpacing(6, after: quitBox.arrangedSubviews[0])
        for slot in QuitSlot.allCases { quitBox.addArrangedSubview(makeQuitRow(slot)) }
        quitHint.font = Theme.font(12, .semibold)
        quitHint.textColor = Theme.cream.withAlphaComponent(0.7)
        quitHint.numberOfLines = 0
        quitHint.textAlignment = .natural
        quitHint.text = g("بدون تذكيرات — تقدر تسجّل نجاحك من الطاولة متى ما بغيت", "بدون تذكيرات — تقدرين تسجّلين نجاحك من الطاولة متى ما بغيتي")
        quitBox.addArrangedSubview(quitHint)

        // ===== الأيام =====
        let dayRow = UIStackView()
        dayRow.distribution = .fillEqually
        dayRow.spacing = 6
        for d in 1...7 {
            let b = UIButton(type: .system)
            b.setTitle(Fmt.weekdayShort[d - 1], for: .normal)
            b.titleLabel?.font = Theme.font(14, .heavy)
            b.layer.cornerRadius = 19
            b.layer.cornerCurve = .continuous
            b.accessibilityLabel = Fmt.weekdayName(d)
            b.heightAnchor.constraint(equalToConstant: 38).isActive = true
            b.addAction(UIAction { [weak self] _ in self?.toggleDay(d) }, for: .touchUpInside)
            dayButtons.append(b)
            dayRow.addArrangedSubview(b)
        }
        everyDayButton.titleLabel?.font = Theme.font(13, .heavy)
        everyDayButton.setTitle("كل يوم", for: .normal)
        everyDayButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        everyDayButton.layer.cornerRadius = 14
        everyDayButton.addAction(UIAction { [weak self] _ in
            self?.days = Set(1...7); self?.refreshDays()
        }, for: .touchUpInside)
        let daysHeader = UIStackView(arrangedSubviews: [caption("الأيام"), UIView(), everyDayButton])
        daysHeader.alignment = .center
        let daysField = UIStackView(arrangedSubviews: [daysHeader, dayRow])
        daysField.axis = .vertical
        daysField.spacing = 8

        // ===== الحفظ والحذف =====
        let saveTitle = onSave != nil ? (isNew ? g("أضف للخطة", "أضيفي للخطة") : "حفظ") : (isNew ? g("أضف إلى عاداتي", "أضيفي إلى عاداتي") : "حفظ التعديل")
        let save = UI.pill(saveTitle, icon: isNew ? "plus" : "checkmark") { [weak self] in self?.save() }

        var items: [UIView] = [field("الاسم", titleField)]
        if isCustom { items.append(field("نوع العادة", kindControl)) }
        items += [buildBox, quitBox, daysField, save]
        if !isNew {
            var c = UIButton.Configuration.plain()
            c.title = "حذف العادة"
            c.image = UIImage(systemName: "trash")
            c.imagePlacement = .trailing
            c.imagePadding = 6
            c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            c.baseForegroundColor = Theme.pillDanger
            c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = Theme.font(14, .bold)
                return out
            }
            items.append(UIButton(configuration: c, primaryAction: UIAction { [weak self] _ in self?.confirmDelete() }))
        }

        let stack = UIStackView(arrangedSubviews: items)
        stack.axis = .vertical
        stack.spacing = 14
        stack.setCustomSpacing(22, after: daysField)
        stack.setCustomSpacing(6, after: save)
        stack.translatesAutoresizingMaskIntoConstraints = false

        // تمرير لو المحتوى طوّل (مثلًا لما تنفتح العجلة)
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        contentView.addSubview(scroll)
        let fit = scroll.heightAnchor.constraint(equalTo: stack.heightAnchor)
        fit.priority = UILayoutPriority(700)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: contentView.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor),
            fit
        ])
        refresh()
        refreshDays()
        refreshKind()
    }

    // MARK: - عادة أتركها

    private func quitText(_ slot: QuitSlot) -> (title: String, sub: String, icon: String) {
        switch slot {
        case .craving: return ("وقت الإغراء", g("نشجّعك بالوقت اللي تشتهيها فيه عادةً", "نشجّعك بالوقت اللي تشتهينها فيه عادةً"), "bolt.heart.fill")
        case .morning: return ("تحفيز الصباح", g("رسالة خفيفة تبدأ فيها يومك", "رسالة خفيفة تبدئين فيها يومك"), "sun.max.fill")
        case .checkIn: return ("مراجعة آخر اليوم", g("نسألك «قدرت اليوم؟» وتسجّل نجاحك", "نسألك «قدرتي اليوم؟» وتسجّلين نجاحك"), "moon.stars.fill")
        }
    }

    private func quitValue(_ slot: QuitSlot) -> Int? {
        switch slot { case .craving: return quit.craving; case .morning: return quit.morning; case .checkIn: return quit.checkIn }
    }

    private func setQuit(_ slot: QuitSlot, _ v: Int?) {
        switch slot { case .craving: quit.craving = v; case .morning: quit.morning = v; case .checkIn: quit.checkIn = v }
        if let v { lastQuit[slot] = v }
    }

    /// سطر خيار: ✓ + العنوان والشرح يمين، والوقت يسار (يطلع بس لما يكون مفعّل)
    private func makeQuitRow(_ slot: QuitSlot) -> UIView {
        let t = quitText(slot)
        let check = UIImageView()
        check.contentMode = .scaleAspectFit
        check.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        check.setContentHuggingPriority(.required, for: .horizontal)
        let title = UI.label(t.title, size: 15, weight: .heavy, color: Theme.creamLight)
        let sub = UI.label(t.sub, size: 11, weight: .semibold, color: Theme.cream, lines: 0)
        let text = UIStackView(arrangedSubviews: [title, sub])
        text.axis = .vertical
        text.spacing = 2
        let time = UIButton(type: .system)
        styleValueButton(time)
        time.addAction(UIAction { [weak self, weak time] _ in self?.toggleWheel(.quit(slot), under: time) }, for: .touchUpInside)
        let row = UIStackView(arrangedSubviews: [check, text, time])
        row.alignment = .center
        row.spacing = 10
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 10)
        row.layer.cornerRadius = 18
        row.layer.cornerCurve = .continuous
        row.layer.borderWidth = 1.5
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(quitRowTapped(_:))))
        row.accessibilityTraits = .button
        quitRows[slot] = (row, check, title, sub, time)
        return row
    }

    @objc private func quitRowTapped(_ tap: UITapGestureRecognizer) {
        guard let slot = quitRows.first(where: { $0.value.row === tap.view })?.key else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        setQuit(slot, quitValue(slot) == nil ? lastQuit[slot] : nil)
        if case .quit(let s)? = wheelTarget, s == slot, quitValue(slot) == nil { hideWheel() }
        UIView.animate(withDuration: 0.25) { self.refresh(); self.card.layoutIfNeeded() }
    }

    private var isQuit: Bool {
        isCustom ? kindControl.selectedSegmentIndex == 1 : habit.kind == .quit
    }

    private func kindChanged() {
        hideWheel()
        UIView.animate(withDuration: 0.25) { self.refreshKind(); self.card.layoutIfNeeded() }
    }

    private func refreshKind() {
        buildBox.isHidden = isQuit
        quitBox.isHidden = !isQuit
        refresh()
    }

    // MARK: - عناصر

    private func caption(_ text: String) -> UILabel {
        UI.label(text, size: 13, weight: .bold, color: Theme.cream)
    }

    private func field(_ title: String, _ control: UIView) -> UIView {
        let s = UIStackView(arrangedSubviews: [caption(title), control])
        s.axis = .vertical
        s.spacing = 6
        return s
    }

    /// سطر: العنوان يمين والقيمة يسار
    private func row(_ title: String, _ value: UIView) -> UIView {
        let s = UIStackView(arrangedSubviews: [caption(title), UIView(), value])
        s.alignment = .center
        return s
    }

    private func styleValueButton(_ b: UIButton) {
        var c = UIButton.Configuration.filled()
        c.cornerStyle = .capsule
        c.baseBackgroundColor = Theme.pillBg
        c.baseForegroundColor = Theme.creamLight
        c.image = UIImage(systemName: "chevron.down")
        c.imagePlacement = .trailing   // السهم بعد القيمة (على اليسار)
        c.imagePadding = 8
        c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .heavy)
        c.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 16, bottom: 9, trailing: 14)
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.font(15, .heavy)
            return out
        }
        b.configuration = c
        b.setContentHuggingPriority(.required, for: .horizontal)
    }

    // MARK: - التحديث

    private func refresh() {
        let many = everyHours > 0
        onceBox.isHidden = many
        manyBox.isHidden = !many
        onceTimeButton.configuration?.title = Fmt.time(startMinute)
        fromButton.configuration?.title = Fmt.time(startMinute)
        toButton.configuration?.title = Fmt.time(endMinute)
        repeatButton.configuration?.title = Fmt.hours(many ? everyHours : lastEvery)
        for slot in QuitSlot.allCases {
            guard let r = quitRows[slot] else { continue }
            let v = quitValue(slot)
            let on = v != nil
            r.row.backgroundColor = on ? Theme.pillBgOn : UIColor.black.withAlphaComponent(0.2)
            r.row.layer.borderColor = (on ? Theme.gold.withAlphaComponent(0.8) : UIColor.clear).cgColor
            r.check.image = UIImage(systemName: on ? "checkmark.circle.fill" : "circle")
            r.check.tintColor = on ? Theme.gold : Theme.creamLight.withAlphaComponent(0.35)
            r.title.textColor = on ? Theme.gold : Theme.creamLight.withAlphaComponent(0.6)
            r.sub.alpha = on ? 0.85 : 0.5
            r.time.isHidden = !on
            r.time.configuration?.title = Fmt.time(v ?? lastQuit[slot] ?? 0)
        }
        quitHint.isHidden = !quit.isEmpty
        for b in [onceTimeButton, fromButton, toButton] + quitRows.values.map(\.time) {
            b.configuration?.image = UIImage(systemName: b === wheelButton && !wheelBox.isHidden ? "chevron.up" : "chevron.down")
        }
        repeatButton.menu = UIMenu(title: "كل كم ساعة؟", options: .singleSelection, children: repeatOptions.map { h in
            UIAction(title: Fmt.hours(h), state: h == everyHours ? .on : .off) { [weak self] _ in
                self?.everyHours = h
                self?.lastEvery = h
                self?.refresh()
            }
        })
    }

    private func frequencyChanged() {
        if freqControl.selectedSegmentIndex == 0 {
            if everyHours > 0 { lastEvery = everyHours }
            everyHours = 0
        } else {
            everyHours = lastEvery
        }
        hideWheel()
        UIView.animate(withDuration: 0.25) { self.refresh(); self.card.layoutIfNeeded() }
    }

    private func toggleWheel(_ target: WheelTarget, under button: UIButton?) {
        guard let button else { return }
        view.endEditing(true)
        UISelectionFeedbackGenerator().selectionChanged()
        if !wheelBox.isHidden, wheelButton === button {
            hideWheel()
        } else {
            // ننقل العجلة تحت سطر الزر اللي انضغط
            wheelTarget = target
            wheelButton = button
            if let rowView = button.superview, let parent = rowView.superview as? UIStackView,
               let i = parent.arrangedSubviews.firstIndex(of: rowView) {
                wheelBox.removeFromSuperview()
                parent.insertArrangedSubview(wheelBox, at: i + 1)
            }
            let m: Int
            switch target {
            case .end: m = endMinute
            case .start: m = startMinute
            case .quit(let slot): m = quitValue(slot) ?? lastQuit[slot] ?? 9 * 60
            }
            timeWheel.date = Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
            wheelBox.isHidden = false
        }
        UIView.animate(withDuration: 0.25) { self.refresh(); self.card.layoutIfNeeded() }
    }

    private func hideWheel() {
        wheelBox.isHidden = true
        wheelButton = nil
        wheelTarget = nil
    }

    private func wheelChanged() {
        let t = Calendar.current.dateComponents([.hour, .minute], from: timeWheel.date)
        let m = (t.hour ?? 9) * 60 + (t.minute ?? 0)
        switch wheelTarget ?? .start {
        case .end: endMinute = m
        case .quit(let slot): setQuit(slot, m)
        default: startMinute = m
        }
        refresh()
    }

    private func toggleDay(_ d: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        if days.contains(d) {
            guard days.count > 1 else { dayButtons[d - 1].shake(); return }   // لازم يوم واحد على الأقل
            days.remove(d)
        } else {
            days.insert(d)
        }
        refreshDays()
    }

    private func refreshDays() {
        for (i, b) in dayButtons.enumerated() {
            // نفس ألوان أزرار الوقت: المختار غامق ونصه كريمي، والباقي باهت
            let on = days.contains(i + 1)
            b.backgroundColor = on ? Theme.pillBgOn : UIColor.black.withAlphaComponent(0.2)
            b.setTitleColor(on ? Theme.creamLight : Theme.creamLight.withAlphaComponent(0.4), for: .normal)
        }
        let all = days.count == 7
        everyDayButton.backgroundColor = all ? Theme.pillBgOn : Theme.pillBg
        everyDayButton.setTitleColor(Theme.creamLight.withAlphaComponent(all ? 1 : 0.7), for: .normal)
    }

    // MARK: - حفظ وحذف

    private func save() {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else {
            titleField.shake()
            titleField.becomeFirstResponder()
            return
        }
        if !isQuit, everyHours > 0, endMinute <= startMinute {
            toButton.shake()
            view.showToast(g("خلّ «إلى» بعد «من» ⏰", "خلّي «إلى» بعد «من» ⏰"))
            return
        }
        if isCustom {
            let kind: HabitKind = kindControl.selectedSegmentIndex == 0 ? .build : .quit
            habit.kind = kind
            habit.icon = kind == .build ? "leaf.fill" : "nosign"
        }
        habit.title = title
        habit.startMinute = startMinute
        habit.endMinute = endMinute
        habit.everyHours = everyHours
        habit.weekdays = days.count == 7 ? nil : days.sorted()
        if habit.kind == .quit {
            habit.quit = quit
            if let m = quit.craving { habit.startMinute = m }
        }

        if let onSave {
            view.endEditing(true)
            onSave(habit)
            dismiss(animated: true)
            return
        }
        store.upsert(habit)
        ReminderManager.requestPermission()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let message = isNew ? "أُضيفت «\(title)» إلى طاولتك ✨" : "تم حفظ التعديل ✓"
        let host = presentingViewController
        view.endEditing(true)
        dismiss(animated: true) { host?.view.showToast(message) }
    }

    private func confirmDelete() {
        let alert = WoodAlertViewController(title: g("تحذف", "تحذفين") + " «\(habit.title)»؟",
                                            message: onDelete != nil ? "بتنشال من خطة الهدف" : "بتنحذف العادة وتذكيراتها",
                                            confirm: "احذفها", destructive: true) { [weak self] in
            guard let self else { return }
            if let onDelete = self.onDelete { onDelete(); self.dismiss(animated: true); return }
            self.store.delete(self.habit)
            let host = self.presentingViewController
            self.dismiss(animated: true) { host?.view.showToast("تم حذف العادة") }
        }
        present(alert, animated: true)
    }
}
