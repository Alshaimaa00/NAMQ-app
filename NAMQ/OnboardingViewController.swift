//
//  OnboardingViewController.swift
//  NAMQ
//
//  ابنِ شخصيتك: اختيار ولد/بنت (الشخصية كاملة) + اسم الشخصية فقط.
//  اسم المستخدم جاي من تسجيل الدخول.
//

import UIKit

final class OnboardingViewController: UIViewController {

    private let store = GameStore.shared
    private let background = VideoBackgroundView(resource: "background")
    private let boyOption = CharacterOption(imageName: Gender.boy.image, title: "ولد", gender: "boy")
    private let girlOption = CharacterOption(imageName: Gender.girl.image, title: "بنت", gender: "girl")
    private let nameField = UI.textField("سمّ شخصيتك")
    /// العنوان يتغيّر مع الاسم اللي يكتبه المستخدم («مرحبًا بك في نمق» قلناها في صفحة الترحيب)
    private let titleLabel = UI.label("أهلًا فيك ✨", size: 30, weight: .heavy, color: Theme.cream, align: .center)
    private lazy var startButton: UIButton = {
        let b = UI.pill("ابدأ رحلتك", icon: "sparkles") { [weak self] in self?.start() }
        b.configuration?.imagePlacement = .trailing   // النجوم بعد الكلام
        return b
    }()

    private var gender: Gender? {
        didSet {
            boyOption.setState(selected: gender == .boy, otherSelected: gender == .girl)
            girlOption.setState(selected: gender == .girl, otherSelected: gender == .boy)
            validate()
        }
    }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.woodDark
        background.frame = view.bounds
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(background)
        let dim = UIView(frame: view.bounds)
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.38)
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(dim)

        buildLayout()

        nameField.returnKeyType = .done
        nameField.addAction(UIAction { _ in }, for: .editingDidEndOnExit)
        nameField.addAction(UIAction { [weak self] _ in self?.validate() }, for: .editingChanged)
        boyOption.addAction(UIAction { [weak self] _ in self?.choose(.boy) }, for: .touchUpInside)
        girlOption.addAction(UIAction { [weak self] _ in self?.choose(.girl) }, for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        validate()
    }

    private func buildLayout() {
        let title = titleLabel
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.6
        title.layer.shadowColor = UIColor.black.cgColor
        title.layer.shadowOpacity = 0.4
        title.layer.shadowRadius = 6
        title.layer.shadowOffset = CGSize(width: 0, height: 3)
        let subtitle = UI.label("اختر اسم شخصيتك وشكلها، وخلّها رفيقك في رحلتك نحو التغيير للأفضل", size: 15,
                                weight: .medium, color: Theme.creamLight, lines: 0, align: .center)

        // المسرح: الشخصيتين واقفين على أرضية الغرفة
        let stage = UIStackView(arrangedSubviews: [boyOption, girlOption])
        stage.distribution = .fillEqually
        stage.spacing = 18
        stage.translatesAutoresizingMaskIntoConstraints = false

        // اسم الشخصية تحت: عنوان صغير، حقل شفاف بإطار ذهبي، وزر البدء
        let caption = UI.label("اسم شخصيتك", size: 16, weight: .bold, color: Theme.creamLight)
        nameField.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        nameField.layer.borderColor = Theme.gold.withAlphaComponent(0.75).cgColor
        nameField.layer.cornerRadius = 26
        nameField.textColor = Theme.creamLight
        nameField.tintColor = Theme.gold
        nameField.attributedPlaceholder = NSAttributedString(string: "سمّ شخصيتك",
            attributes: [.foregroundColor: Theme.cream.withAlphaComponent(0.55)])
        let form = UIStackView(arrangedSubviews: [caption, nameField, startButton])
        form.axis = .vertical
        form.spacing = 10
        form.setCustomSpacing(16, after: nameField)
        form.translatesAutoresizingMaskIntoConstraints = false
        let card = form   // (مافي بطاقة — العناصر مباشرة على الخلفية)

        let header = UIStackView(arrangedSubviews: [title, subtitle])
        header.axis = .vertical
        header.spacing = 10
        header.translatesAutoresizingMaskIntoConstraints = false

        [header, stage, card].forEach { view.addSubview($0) }

        let g = view.safeAreaLayoutGuide
        let stageH = stage.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.46)
        stageH.priority = .defaultHigh
        NSLayoutConstraint.activate([
            // العنوان نازل شوي عن أعلى الشاشة
            header.topAnchor.constraint(equalTo: g.topAnchor, constant: 64),
            header.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),

            stage.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20),
            stage.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20),
            stage.topAnchor.constraint(greaterThanOrEqualTo: header.bottomAnchor, constant: 12),
            stage.bottomAnchor.constraint(lessThanOrEqualTo: card.topAnchor, constant: -22),
            stageH,

            card.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -24),
            card.bottomAnchor.constraint(lessThanOrEqualTo: g.bottomAnchor, constant: -20),
            card.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -12),

        ])
        // الفورم تحت، والشخصيات واقفين فوقه مباشرة
        let pinBottom = card.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -20)
        pinBottom.priority = .defaultHigh
        pinBottom.isActive = true
        let snug = stage.bottomAnchor.constraint(equalTo: card.topAnchor, constant: -22)
        snug.priority = .defaultHigh
        snug.isActive = true
    }

    private func choose(_ g: Gender) {
        UISelectionFeedbackGenerator().selectionChanged()
        gender = g
    }

    private var trimmedName: String {
        nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func validate() {
        titleLabel.text = trimmedName.isEmpty ? "أهلًا فيك ✨" : "أهلًا \(trimmedName) ✨"
        startButton.isEnabled = !trimmedName.isEmpty && gender != nil
    }

    private func start() {
        guard let gender, !trimmedName.isEmpty else { return }
        store.createCharacter(name: trimmedName, gender: gender)
        ReminderManager.requestPermission()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        guard let nav = navigationController else { return }
        nav.view.layer.add(CATransition.fade, forKey: nil)
        nav.setViewControllers([GameViewController()], animated: false)
    }
}
