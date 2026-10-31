//
//  PanelViewController.swift
//  NAMQ
//
//  النافذة الموحدة اللي تطلع فوق الغرفة (المكتبة، الطاولة، الدولاب، تعديل العادة).
//  بدل ما نضيف ونشيل عناصر يدويًا من الشاشة — كل نافذة شاشة مستقلة تنفتح وتنقفل بنظافة.
//

import UIKit

class PanelViewController: UIViewController {
    let store = GameStore.shared
    let card = CardView()
    let contentView = UIView()
    let titleLabel = UI.label(size: 24, weight: .heavy, color: Theme.creamLight)
    let subtitleLabel = UI.label(size: 14, color: Theme.cream.withAlphaComponent(0.8), lines: 0)
    /// خلفية النافذة: لوح خشب بإطار، وأوراق شجر وكتب فوق (يتمدد من النص بدون ما تتشوّه الزوايا)
    private let boardView = UIImageView(image: UIImage(named: "namq_panel")?
        .resizableImage(withCapInsets: UIEdgeInsets(top: 150, left: 115, bottom: 40, right: 115), resizingMode: .stretch))
    private let headerIcon: String
    private var didAnimateIn = false

    /// النوافذ اللي فيها قوائم تاخذ الشاشة، والنماذج الصغيرة تكون بحجم محتواها
    var fillsScreen: Bool { true }
    var closesOnBackgroundTap: Bool { true }

    init(title: String, subtitle: String? = nil, icon: String) {
        headerIcon = icon
        super.init(nibName: nil, bundle: nil)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let dim = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
        dim.frame = view.bounds
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dim.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundTapped)))
        view.addSubview(dim)
        // طبقة غامقة فوق الضبابية عشان ما يبان شي من الغرفة (أو اللوحة اللي ورا) جنب إطار الخشب
        let shade = UIView(frame: view.bounds)
        shade.backgroundColor = UIColor(red: 0.09, green: 0.05, blue: 0.03, alpha: 0.55)
        shade.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        shade.isUserInteractionEnabled = false
        dim.contentView.addSubview(shade)
        view.addSubview(card)
        card.backgroundColor = .clear
        card.layer.borderWidth = 0
        card.clipsToBounds = false
        boardView.translatesAutoresizingMaskIntoConstraints = false
        card.insertSubview(boardView, at: 0)

        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.3
        titleLabel.layer.shadowRadius = 3
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center
        let titles = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titles.axis = .vertical
        titles.spacing = 2
        titles.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let closeButton = UI.closeButton { [weak self] in self?.close() }

        // العنوان والوصف في النص بالضبط، وزر الإغلاق في الزاوية
        let header = titles
        header.alignment = .fill
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(header)
        card.addSubview(closeButton)
        card.addSubview(contentView)

        let g = view.safeAreaLayoutGuide
        var cs: [NSLayoutConstraint] = [
            card.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -16),
            card.topAnchor.constraint(greaterThanOrEqualTo: g.topAnchor, constant: 16),
            card.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -12),
            boardView.topAnchor.constraint(equalTo: card.topAnchor, constant: -26),   // أوراق الشجر والكتب طالعة فوق الإطار
            boardView.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            boardView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            boardView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 34),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 72),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -72),
            closeButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -34),
            contentView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 34),   // بعيد عن إطار الخشب
            contentView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -34),
            contentView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ]
        if fillsScreen {
            let top = card.topAnchor.constraint(equalTo: g.topAnchor, constant: 24)
            let bottom = card.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -16)
            bottom.priority = .defaultHigh
            cs += [top, bottom]
        } else {
            let center = card.centerYAnchor.constraint(equalTo: g.centerYAnchor)
            center.priority = .defaultHigh
            cs.append(center)
        }
        NSLayoutConstraint.activate(cs)

        buildContent()
        NotificationCenter.default.addObserver(self, selector: #selector(storeDidChange),
                                               name: GameStore.didChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !didAnimateIn else { return }
        didAnimateIn = true
        card.transform = CGAffineTransform(translationX: 0, y: 40).scaledBy(x: 0.94, y: 0.94)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.4,
                       options: [], animations: { self.card.transform = .identity })
    }

    // للأبناء: يبنون المحتوى هنا ويحدثونه في reload()
    func buildContent() {}
    func reload() {}

    @objc private func storeDidChange() { reload() }

    @objc private func backgroundTapped() {
        if view.window?.firstResponder != nil || !closesOnBackgroundTap {
            view.endEditing(true)
        } else {
            close()
        }
    }

    func close() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    /// قائمة قابلة للتمرير، ومعها زر ثابت تحتها (اختياري)
    func installScrollingStack(spacing: CGFloat = 12, footer: UIView? = nil) -> UIStackView {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .onDrag
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scroll)
        scroll.addSubview(stack)

        var cs: [NSLayoutConstraint] = [
            scroll.topAnchor.constraint(equalTo: contentView.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ]
        if let footer {
            footer.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(footer)
            cs += [
                footer.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 12),
                footer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                footer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                footer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ]
        } else {
            cs.append(scroll.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
        }
        NSLayoutConstraint.activate(cs)
        return stack
    }
}

private extension UIView {
    var firstResponder: UIView? {
        if isFirstResponder { return self }
        for sub in subviews { if let r = sub.firstResponder { return r } }
        return nil
    }
}
