//
//  HabitLibraryViewController.swift
//  نمق
//
//  مكتبة العادات 📚 — تبويبين بنفس الشكل: «ابنيها» و«اتخلّص منها»،
//  وتحتها بطاقات العادات الجاهزة وكل بطاقة فيها زر ＋ للإضافة.
//

import UIKit

final class HabitLibraryViewController: PanelViewController {
    private var stack: UIStackView?
    private var kind: HabitKind = .build

    init() {
        super.init(title: "مكتبة العادات", subtitle: g("اختر عادة جاهزة وعدّل وقتها", "اختاري عادة جاهزة وعدّلي وقتها"), icon: "books.vertical.fill")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        stack = installScrollingStack()
        reload()
    }

    override func reload() {
        guard let stack else { return }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // التبويبين — نفس الشكل والحجم
        let tabs = UIStackView(arrangedSubviews: [
            tab("أبنيها", selected: kind == .build) { [weak self] in self?.switchTo(.build) },
            tab("أتخلّص منها", selected: kind == .quit) { [weak self] in self?.switchTo(.quit) }
        ])
        tabs.distribution = .fillEqually
        tabs.spacing = 10
        stack.addArrangedSubview(tabs)
        stack.setCustomSpacing(16, after: tabs)

        for template in Habit.library where template.kind == kind {
            let added = store.hasHabit(fromTemplate: template.templateID)
            let accessory: UIView = added
                ? UI.chip("مضافة ✓", color: Theme.leaf)
                : UI.symbol("plus.circle.fill", color: kind.color)
            let row = HabitRowView(icon: template.icon, tint: kind.color, title: template.title,
                                   detail: "", meta: "⏰ " + template.scheduleText, accessory: accessory)
            row.addAction(UIAction { [weak self] _ in self?.select(template, alreadyAdded: added) }, for: .touchUpInside)
            stack.addArrangedSubview(row)
        }
    }

    private func switchTo(_ k: HabitKind) {
        guard k != kind else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        kind = k
        reload()
    }

    private func tab(_ title: String, selected: Bool, action: @escaping () -> Void) -> UIButton {
        UI.toggle(title, selected: selected, action: action)
    }

    private func select(_ template: Habit, alreadyAdded: Bool) {
        if alreadyAdded {
            view.showToast("هذه العادة موجودة في طاولتك ✓")
            return
        }
        var habit = template
        habit.id = UUID()
        present(HabitEditorViewController(habit: habit, isNew: true), animated: true)
    }
}
