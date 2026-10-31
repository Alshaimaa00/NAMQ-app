//
//  Components.swift
//  NAMQ
//
//  عناصر الواجهة القابلة لإعادة الاستخدام.
//

import UIKit
import AVFoundation

// MARK: - فيديو الخلفية (الغرفة)

final class VideoBackgroundView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    init(resource: String, ext: String = "mp4") {
        super.init(frame: .zero)
        backgroundColor = Theme.woodDark
        // الفيديو صامت وما يوقف موسيقى المستخدم
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else { return }
        let queue = AVQueuePlayer()
        queue.isMuted = true
        looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
        player = queue
        playerLayer.player = queue
        playerLayer.videoGravity = .resizeAspectFill
        queue.play()
        NotificationCenter.default.addObserver(self, selector: #selector(play),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc func play() { player?.play() }
}

/// تغميق دافي متدرّج فوق الخلفية (أخف بالنص، أغمق تحت) عشان النصوص تبان
final class GradientShadeView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        guard let g = layer as? CAGradientLayer else { return }
        let dark = UIColor(red: 0.12, green: 0.05, blue: 0.02, alpha: 1)
        g.colors = [dark.withAlphaComponent(0.35).cgColor, dark.withAlphaComponent(0.05).cgColor,
                    dark.withAlphaComponent(0.25).cgColor, dark.withAlphaComponent(0.75).cgColor]
        g.locations = [0, 0.35, 0.6, 1]
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// نجمة معلّقة بخيط من السقف وتتمرجح شوي
final class HangingStarView: UIView {
    private let inner = UIView()
    private let line = UIView()
    private let star = StarView()
    private let size: CGFloat
    init(size: CGFloat) {
        self.size = size
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        line.backgroundColor = Theme.gold.withAlphaComponent(0.6)
        star.layer.shadowColor = UIColor(red: 1, green: 0.84, blue: 0.4, alpha: 1).cgColor
        star.layer.shadowOpacity = 1
        star.layer.shadowRadius = size * 0.4
        star.layer.shadowOffset = .zero
        addSubview(inner); inner.addSubview(line); inner.addSubview(star)
        inner.layer.anchorPoint = CGPoint(x: 0.5, y: 0)   // تتمرجح من نقطة التعليق
        let a = CABasicAnimation(keyPath: "transform.rotation.z")
        a.fromValue = -0.05; a.toValue = 0.05
        a.duration = 2.2 + Double(size.truncatingRemainder(dividingBy: 7)) * 0.15
        a.autoreverses = true; a.repeatCount = .infinity
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        inner.layer.add(a, forKey: "swing")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width, h = bounds.height
        inner.bounds = bounds
        inner.layer.position = CGPoint(x: w / 2, y: 0)
        line.frame = CGRect(x: w / 2 - 0.75, y: 0, width: 1.5, height: h - size * 0.8)
        star.frame = CGRect(x: (w - size) / 2, y: h - size, width: size, height: size)
    }
}

// MARK: - غرض في الغرفة (مكتبة / دولاب / طاولة / الشخصية)

final class RoomObjectView: UIControl {
    let imageView = UIImageView()
    /// الملابس اللي فوق الشخصية (تتحرك معها في حركة التنفّس لأنها داخل imageView)
    private var outfitViews: [UIImageView] = []

    init(imageName: String, fallbackSymbol: String, label: String) {
        super.init(frame: .zero)
        imageView.image = UIImage(named: imageName) ?? UIImage(systemName: fallbackSymbol)
        imageView.tintColor = Theme.cream
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 8)
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var baseImageName: String?
    private var expressionToken = 0
    private(set) var expression: String?

    func setImage(named name: String, fallback: String) {
        let newBase = UIImage(named: name) != nil ? name : fallback
        if newBase == baseImageName && imageView.image != nil { return }   // نفس الشخصية: لا نقطع تعبير الوجه
        baseImageName = newBase
        imageView.image = UIImage(named: baseImageName ?? fallback)
        expression = nil
    }

    /// تعابير الوجه: "blink" رمشة، "happy" ضحكة، "wow" مندهش — nil يرجع للطبيعي
    func show(expression name: String?, for duration: TimeInterval? = nil) {
        guard let base = baseImageName else { return }
        expressionToken += 1
        let token = expressionToken
        expression = name
        imageView.image = name.flatMap { UIImage(named: "\(base)_\($0)") } ?? UIImage(named: base)
        if let duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self, self.expressionToken == token else { return }
                self.show(expression: nil)
            }
        }
    }

    /// يلبّس الشخصية القطع المختارة — كل قطعة صورة بنفس مقاس الشخصية فتنحط فوقها بالضبط
    func dress(_ items: [Reward], gender: Gender) {
        outfitViews.forEach { $0.removeFromSuperview() }
        outfitViews = items.compactMap { item -> UIImageView? in
            guard let img = UIImage(named: OutfitLayer.imageName(for: item, gender: gender)) else { return nil }
            let v = UIImageView(image: img)
            v.contentMode = .scaleToFill
            v.isUserInteractionEnabled = false
            v.frame = imageView.bounds
            v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.addSubview(v)
            return v
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
            }
        }
    }

    /// نبضة خفيفة تلفت الانتباه (مثلًا للمكتبة لما ما فيه عادات)
    func startPulse() {
        guard imageView.layer.animation(forKey: "pulse") == nil else { return }
        let a = CABasicAnimation(keyPath: "transform.scale")
        a.fromValue = 1.0
        a.toValue = 1.05
        a.duration = 0.8
        a.autoreverses = true
        a.repeatCount = .infinity
        a.isRemovedOnCompletion = false
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        imageView.layer.add(a, forKey: "pulse")
    }
    func stopPulse() { imageView.layer.removeAnimation(forKey: "pulse") }

    /// حركة تنفّس للشخصية
    func startBobbing() {
        guard imageView.layer.animation(forKey: "bob") == nil else { return }
        let a = CABasicAnimation(keyPath: "transform.translation.y")
        a.fromValue = 0
        a.toValue = -5
        a.duration = 1.2
        a.autoreverses = true
        a.repeatCount = .infinity
        a.isRemovedOnCompletion = false
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        imageView.layer.add(a, forKey: "bob")
    }
}

// MARK: - فقاعة كلام الشخصية

final class SpeechBubbleView: UIView {
    private let label = UILabel()
    private let tail = UIView()
    private let insets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
    /// لو محددة: الذيل يطلع من تحت الفقاعة عند هذي النقطة (يؤشر على الشخصية تحت)
    var tailBottomX: CGFloat? { didSet { setNeedsLayout() } }
    /// الذيل على يمين الفقاعة (الشخصية على يمينها)
    var tailRight = false { didSet { setNeedsLayout() } }

    var text: String? {
        get { label.text }
        set { label.text = newValue; setNeedsLayout() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.parchment
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
        tail.backgroundColor = Theme.parchment
        tail.transform = CGAffineTransform(rotationAngle: .pi / 4)
        addSubview(tail)
        label.font = Theme.font(14, .semibold)
        label.textColor = Theme.ink
        label.numberOfLines = 0
        label.textAlignment = .natural
        addSubview(label)
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxW = size.width - insets.left - insets.right
        let fit = label.sizeThatFits(CGSize(width: maxW, height: .greatestFiniteMagnitude))
        return CGSize(width: ceil(min(fit.width, maxW)) + insets.left + insets.right,
                      height: ceil(fit.height) + insets.top + insets.bottom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.inset(by: insets)
        tail.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        if tailRight {
            tail.center = CGPoint(x: bounds.width - 1, y: min(24, bounds.height / 2))
        } else if let x = tailBottomX {
            tail.center = CGPoint(x: min(max(x, 22), bounds.width - 22), y: bounds.height - 1)
        } else {
            tail.center = CGPoint(x: 1, y: min(24, bounds.height / 2))   // يؤشر على الشخصية (يسار الفقاعة)
        }
    }
}

// MARK: - لوحة اسم الشخصية

final class NameplateView: UIView {
    private let background = UIImageView()
    private let label = UILabel()
    private let badge = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // نفس كبسولة «ولد / بنت» وباقي الأزرار: بني غامق شفاف ونص كريمي
        background.backgroundColor = Theme.pillBg
        background.layer.cornerCurve = .continuous
        addSubview(background)
        label.font = Theme.font(13, .heavy)
        label.textColor = Theme.creamLight
        label.textAlignment = .center
        addSubview(label)
        badge.contentMode = .scaleAspectFit
        addSubview(badge)
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(name: String, equipped: Reward?) {
        label.text = name
        badge.image = equipped.flatMap { UIImage(named: $0.id) }
        badge.isHidden = badge.image == nil
        setNeedsLayout()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let l = label.sizeThatFits(size)
        return CGSize(width: ceil(l.width) + 32 + (badge.isHidden ? 0 : 26), height: 30)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        background.frame = bounds
        background.layer.cornerRadius = bounds.height / 2
        if badge.isHidden {
            label.frame = bounds.insetBy(dx: 16, dy: 0)
        } else {
            badge.frame = CGRect(x: 10, y: 5, width: 22, height: 20)
            label.frame = CGRect(x: 34, y: 0, width: bounds.width - 50, height: bounds.height)
        }
    }
}

// MARK: - صف عادة (في المكتبة وفي الطاولة)

final class HabitRowView: UIControl {
    init(icon: String, tint: UIColor, title: String, detail: String, meta: String?, accessory: UIView?) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.parchment
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.5
        layer.borderColor = Theme.wood.withAlphaComponent(0.18).cgColor

        let badge = UI.iconBadge(icon, color: tint, size: 46)
        var texts: [UIView] = [UI.label(title, size: 16, weight: .bold)]
        if !detail.isEmpty { texts.append(UI.label(detail, size: 13, color: Theme.muted, lines: 2)) }
        if let meta { texts.append(UI.label(meta, size: 12, weight: .bold, color: tint, lines: 2)) }
        let textStack = UIStackView(arrangedSubviews: texts)
        textStack.axis = .vertical
        textStack.spacing = 3
        let row = UIStackView(arrangedSubviews: [badge, textStack])
        row.spacing = 12
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        var cs = [
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
        ]
        if let accessory {
            accessory.translatesAutoresizingMaskIntoConstraints = false
            addSubview(accessory)
            cs += [
                accessory.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                accessory.centerYAnchor.constraint(equalTo: centerYAnchor),
                row.trailingAnchor.constraint(equalTo: accessory.leadingAnchor, constant: -8)
            ]
        } else {
            cs.append(row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12))
        }
        NSLayoutConstraint.activate(cs)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { UIView.animate(withDuration: 0.12) { self.alpha = self.isHighlighted ? 0.7 : 1 } }
    }
}

// MARK: - اختيار الشخصية في صفحة البداية

final class AvatarTile: UIControl {
    private let imageView = UIImageView()
    private let caption: UILabel

    init(imageName: String, fallbackImage: String, title: String) {
        caption = UI.label(title, size: 14, weight: .bold, color: Theme.muted, align: .center)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: imageName) ?? UIImage(named: fallbackImage)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = Theme.creamLight
        imageView.layer.cornerRadius = 38
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: [imageView, caption])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 76),
            imageView.heightAnchor.constraint(equalToConstant: 76),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        accessibilityLabel = title
        isAccessibilityElement = true
        accessibilityTraits = .button
        update()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isSelected: Bool { didSet { update() } }

    private func update() {
        imageView.layer.borderWidth = isSelected ? 3.5 : 1.5
        imageView.layer.borderColor = (isSelected ? Theme.leaf : Theme.wood.withAlphaComponent(0.3)).cgColor
        caption.textColor = isSelected ? Theme.leaf : Theme.muted
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5,
                       options: [], animations: {
            self.transform = self.isSelected ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
        })
    }
}

// MARK: - بطاقة جائزة في الدولاب

final class RewardTile: UIControl {
    enum Status { case locked, owned, equipped }

    init(reward: Reward, status: Status, affordable: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.parchment
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = status == .equipped ? 3 : 1.5
        layer.borderColor = (status == .equipped ? Theme.leaf : Theme.wood.withAlphaComponent(0.18)).cgColor

        let image = UIImageView(image: UIImage(named: reward.id) ?? UIImage(systemName: "tshirt.fill"))
        image.tintColor = Theme.wood
        image.contentMode = .scaleAspectFit
        image.alpha = status == .locked ? 0.4 : 1
        image.translatesAutoresizingMaskIntoConstraints = false

        let title = UI.label(reward.title, size: 12, weight: .bold, lines: 2, align: .center)

        let chip: ChipLabel
        switch status {
        case .locked:   chip = UI.chip("⭐ \(Fmt.num(reward.cost))", color: affordable ? Theme.leaf : Theme.wood)
        case .owned:    chip = UI.chip("ارتدِ", color: Theme.leaf)
        case .equipped: chip = UI.chip("✓ ترتديه", color: Theme.leaf, filled: true)
        }

        let stack = UIStackView(arrangedSubviews: [image, title, chip])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            image.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            image.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75),
            heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1.35)
        ])

        if status == .locked {
            let lock = UI.symbol("lock.fill", color: Theme.wood, size: 13)
            addSubview(lock)
            NSLayoutConstraint.activate([
                lock.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                lock.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])
        }
        accessibilityLabel = reward.title
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { UIView.animate(withDuration: 0.12) { self.alpha = self.isHighlighted ? 0.7 : 1 } }
    }
}

// MARK: - خلفية دافئة (السبلاش وتسجيل الدخول)

final class WarmBackgroundView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    override init(frame: CGRect) {
        super.init(frame: frame)
        guard let g = layer as? CAGradientLayer else { return }
        g.type = .radial
        g.colors = [UIColor(red: 0.86, green: 0.62, blue: 0.27, alpha: 1).cgColor,
                    UIColor(red: 0.45, green: 0.27, blue: 0.10, alpha: 1).cgColor,
                    UIColor(red: 0.10, green: 0.06, blue: 0.03, alpha: 1).cgColor]
        g.locations = [0, 0.5, 1]
        g.startPoint = CGPoint(x: 0.5, y: 0.42)
        g.endPoint = CGPoint(x: 1.15, y: 1.0)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - النجمة

final class StarView: UIView {
    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        shape.fillColor = UIColor(red: 1.0, green: 0.86, blue: 0.42, alpha: 1).cgColor
        layer.addSublayer(shape)
        layer.shadowColor = UIColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1).cgColor
        layer.shadowRadius = 18
        layer.shadowOpacity = 0.7
        layer.shadowOffset = .zero
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        shape.frame = bounds
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let outer = min(bounds.width, bounds.height) / 2
        let inner = outer * 0.45
        let p = UIBezierPath()
        for i in 0..<10 {
            let r = i % 2 == 0 ? outer : inner
            let a = CGFloat(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.close()
        shape.path = p.cgPath
    }
}

// MARK: - اختيار الشخصية (صورة كاملة)

final class CharacterOption: UIControl {
    private let imageView = UIImageView()
    private let spinView = UIImageView()          // يعرض صور الدوران لما تنختار الشخصية
    private var spinFrames: [UIImage] = []
    private var normalImage: UIImage?
    private var happyImage: UIImage?
    private var isChosen = false
    private let spotlight = UIView()
    private let spotGradient = CAGradientLayer()
    private let groundShadow = UIView()
    private let caption: UILabel

    /// gender: "boy" أو "girl" — عشان صور الدوران والوجه الضاحك
    init(imageName: String, title: String, gender: String? = nil) {
        // اسم الخيار (ولد/بنت) في كبسولة غامقة تحت الرجلين
        let pill = ChipLabel()
        pill.text = title
        pill.font = Theme.font(17, .heavy)
        pill.textColor = Theme.creamLight
        pill.textAlignment = .center
        pill.insets = UIEdgeInsets(top: 7, left: 26, bottom: 7, right: 26)
        pill.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        pill.layer.cornerRadius = 19
        pill.layer.cornerCurve = .continuous
        pill.clipsToBounds = true
        pill.translatesAutoresizingMaskIntoConstraints = false
        caption = pill
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        spotGradient.type = .radial
        spotGradient.colors = [UIColor(red: 1, green: 0.84, blue: 0.45, alpha: 0.85).cgColor,
                               UIColor(red: 1, green: 0.84, blue: 0.45, alpha: 0).cgColor]
        spotGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        spotGradient.endPoint = CGPoint(x: 1, y: 1)
        spotlight.layer.addSublayer(spotGradient)
        spotlight.alpha = 0
        spotlight.translatesAutoresizingMaskIntoConstraints = false

        normalImage = UIImage(named: imageName)
        imageView.image = normalImage
        imageView.contentMode = .scaleAspectFit
        if let gender {
            happyImage = UIImage(named: "namq_\(gender)_happy")
            let f = (0...4).compactMap { UIImage(named: "turn_\(gender)_\($0)") }
            if f.count == 5 {
                let flip = { (i: Int) in f[i].withHorizontallyFlippedOrientation() }
                spinFrames = [f[0], f[1], f[2], f[4], f[3], flip(4), flip(2), flip(1), f[0]]
            }
        }
        spinView.contentMode = .scaleAspectFit
        spinView.isHidden = true
        spinView.isUserInteractionEnabled = false
        // ظل ملتصق بالأرض تحت الرجلين — يحسسك إنهم واقفين فعلًا
        groundShadow.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        groundShadow.layer.shadowColor = UIColor.black.cgColor
        groundShadow.layer.shadowOpacity = 0.6
        groundShadow.layer.shadowRadius = 6
        groundShadow.layer.shadowOffset = .zero
        groundShadow.isUserInteractionEnabled = false
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.25
        imageView.layer.shadowRadius = 4
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)

        [spotlight, groundShadow, imageView, caption].forEach { addSubview($0) }
        addSubview(spinView)
        [spotlight, imageView, caption].forEach { $0.isUserInteractionEnabled = false }

        NSLayoutConstraint.activate([
            caption.bottomAnchor.constraint(equalTo: bottomAnchor),
            caption.centerXAnchor.constraint(equalTo: centerXAnchor),
            spotlight.centerXAnchor.constraint(equalTo: centerXAnchor),
            spotlight.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.95),
            spotlight.heightAnchor.constraint(equalToConstant: 46),
            spotlight.centerYAnchor.constraint(equalTo: caption.topAnchor, constant: -16)
        ])
        accessibilityLabel = title
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        spotGradient.frame = spotlight.bounds
        // الصورة ملتصقة بالأرض (أسفلها على خط الأرضية) مو في نص المربع
        let floorY = caption.frame.minY - 16
        let aspect = normalImage.map { $0.size.width / max($0.size.height, 1) } ?? 0.5
        let h = max(0, min(floorY, (bounds.width - 8) / aspect))
        let w = h * aspect
        imageView.frame = CGRect(x: bounds.midX - w / 2, y: floorY - h, width: w, height: h)
        groundShadow.bounds = CGRect(x: 0, y: 0, width: w * 0.85, height: 14)
        groundShadow.center = CGPoint(x: bounds.midX, y: floorY - 3)
        groundShadow.layer.cornerRadius = 7
    }

    /// تلف لفّة كاملة (أمام ← جانب ← خلف ← أمام) وبعدها تضحك
    private func spinThenSmile() {
        guard !spinFrames.isEmpty, let img = imageView.image, img.size.height > 0 else {
            imageView.image = happyImage ?? normalImage
            return
        }
        // نفس ارتفاع الصورة المعروضة عشان ما يكبر ولا يصغر وهو يلف
        let b = imageView.bounds
        let h = min(b.height, b.width / (img.size.width / img.size.height))
        let maxAspect = spinFrames.map { $0.size.width / max($0.size.height, 1) }.max() ?? 0.6
        spinView.bounds = CGRect(x: 0, y: 0, width: h * maxAspect, height: h)
        spinView.center = imageView.center
        spinView.animationImages = spinFrames
        spinView.animationDuration = 0.75
        spinView.animationRepeatCount = 1
        spinView.image = spinFrames.last
        spinView.isHidden = false
        imageView.alpha = 0
        spinView.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            guard let self else { return }
            self.spinView.stopAnimating()
            self.spinView.isHidden = true
            self.imageView.alpha = 1
            if self.isChosen { self.imageView.image = self.happyImage ?? self.normalImage }
            self.imageView.pop()
        }
    }

    /// selected = هذي المختارة، otherSelected = المختارة هي الثانية
    func setState(selected: Bool, otherSelected: Bool) {
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5,
                       options: [.allowUserInteraction], animations: {
            self.transform = selected ? CGAffineTransform(scaleX: 1.06, y: 1.06)
                : otherSelected ? CGAffineTransform(scaleX: 0.86, y: 0.86) : .identity
            self.alpha = otherSelected ? 0.5 : 1
            self.spotlight.alpha = 0   // بدون ظل/توهج تحت الاسم
        })
        if selected && !isChosen { spinThenSmile() }
        if !selected { imageView.image = normalImage }
        isChosen = selected
        // بدون توهج: نفس الظل الخفيف للمختارة وغير المختارة
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.25
        imageView.layer.shadowRadius = 4
        caption.textColor = selected ? Theme.gold : Theme.creamLight
    }
}

// MARK: - احتفال (قصاصات ملونة تنزل من فوق)

enum Celebration {
    static func confetti(in view: UIView, duration: TimeInterval = 1.4) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -20)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        let colors: [UIColor] = [Theme.gold, Theme.leaf, Theme.terracotta, Theme.cream,
                                 UIColor(red: 0.98, green: 0.58, blue: 0.22, alpha: 1)]
        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.contents = piece(color).cgImage
            cell.birthRate = 7
            cell.lifetime = 6
            cell.velocity = 190
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 5
            cell.yAcceleration = 130
            cell.spin = 3
            cell.spinRange = 5
            cell.scale = 0.7
            cell.scaleRange = 0.35
            return cell
        }
        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { emitter.birthRate = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 6) { emitter.removeFromSuperlayer() }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// بطاقة كبيرة في نص الشاشة (مثلًا: ترقّيت!) تختفي لحالها
    static func banner(in view: UIView, emoji: String, title: String, subtitle: String, imageName: String? = nil) {
        let card = CardView(color: Theme.parchment, radius: 28, border: 3)
        var top: UIView = UI.label(emoji, size: 54, align: .center)
        if let imageName, let img = UIImage(named: imageName) {
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.heightAnchor.constraint(equalToConstant: 150).isActive = true
            let jump = CAKeyframeAnimation(keyPath: "transform.translation.y")
            jump.values = [0, -14, 0]
            jump.duration = 0.6
            jump.repeatCount = 3
            iv.layer.add(jump, forKey: "jump")
            top = iv
        }
        let stack = UIStackView(arrangedSubviews: [
            top,
            UI.label(title, size: 22, weight: .heavy, color: Theme.wood, lines: 0, align: .center),
            UI.label(subtitle, size: 15, weight: .medium, color: Theme.muted, lines: 0, align: .center)
        ])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            card.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18)
        ])
        card.alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6,
                       options: [], animations: {
            card.alpha = 1
            card.transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.35, delay: 1.9, options: [], animations: {
                card.alpha = 0
                card.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }, completion: { _ in card.removeFromSuperview() })
        })
    }

    private static func piece(_ color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 10, height: 14)).image { _ in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 10, height: 14), cornerRadius: 3).fill()
        }
    }
}

// MARK: - هالة المستوى حول الشخصية

/// كل ما ارتفع المستوى: هالة أقوى، ونجوم صغيرة تطلع حول الشخصية
final class LevelAuraView: UIView {
    private let glow = CAGradientLayer()
    private let sparkles = CAEmitterLayer()
    private let cell = CAEmitterCell()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        glow.type = .radial
        glow.colors = [UIColor(red: 1, green: 0.95, blue: 0.7, alpha: 0.95).cgColor,
                       UIColor(red: 1, green: 0.85, blue: 0.45, alpha: 0.6).cgColor,
                       UIColor(red: 1, green: 0.85, blue: 0.45, alpha: 0).cgColor]
        glow.locations = [0, 0.45, 1]
        glow.compositingFilter = "screenBlendMode"
        glow.startPoint = CGPoint(x: 0.5, y: 0.5)
        glow.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(glow)

        cell.contents = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
            UIColor(red: 1, green: 0.9, blue: 0.55, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 12, height: 12)).fill()
        }.cgImage
        cell.lifetime = 2.6
        cell.velocity = 18
        cell.velocityRange = 10
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 3
        cell.scale = 0.5
        cell.scaleRange = 0.25
        cell.alphaSpeed = -0.35
        cell.birthRate = 0
        sparkles.emitterCells = [cell]
        sparkles.emitterShape = .rectangle
        sparkles.renderMode = .additive
        layer.addSublayer(sparkles)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        glow.frame = bounds
        sparkles.frame = bounds
        sparkles.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        sparkles.emitterSize = CGSize(width: bounds.width * 0.6, height: bounds.height * 0.7)
    }

    func apply(level: Int) {
        // المستوى ١ بدون هالة، وبعدها تقوى شوي شوي
        let glowAlpha: [Float] = [0, 0.35, 0.55, 0.75, 1.0]
        let sparkleRate: [Float] = [0, 0, 3, 6, 10]
        // ٨ مستويات تتوزّع على ٥ مراحل للهالة
        let stage = min(5, Int((Double(max(level, 1) - 1) * 4 / 7).rounded()) + 1)
        let i = stage - 1
        glow.opacity = glowAlpha[i]
        cell.birthRate = sparkleRate[i]
        sparkles.emitterCells = [cell]   // نعيد تعيينها عشان يطبّق الرقم الجديد
    }
}


// MARK: - الولد والبنت يلوّحون "مرحبا!"

/// صورة "مرحبا" مع يد البنت مقصوصة لحالها — تتأرجح من الرسغ كأنها تلوّح
final class HelloKidsView: UIView {
    private let base = UIImageView(image: UIImage(named: "hello_base"))
    /// الاثنين يبتسمون ويغمضون عيونهم (^ ^) ويرجعون يفتحونها
    private let smile = UIImageView(image: UIImage(named: "hello_girl_smile"))
    private let boySmile = UIImageView(image: UIImage(named: "hello_boy_smile"))
    /// ظلال على الأرض تحت الرجلين — عشان يبينون واقفين مو طايرين
    private let shadows: [(view: UIView, center: CGPoint, width: CGFloat)] = [
        (UIView(), CGPoint(x: 0.2581, y: 0.9867), 0.17),
        (UIView(), CGPoint(x: 0.7133, y: 0.9856), 0.30)
    ]
    // الاثنين يلوّحون: اليد تتمرجح من الرسغ (الكم يغطي طرفها)
    private let hands: [(view: UIImageView, pivot: CGPoint, angle: CGFloat, delay: CFTimeInterval)] = [
        (UIImageView(image: UIImage(named: "hello_hand_girl")), CGPoint(x: 0.1031, y: 0.3469), -0.32, 0),
        (UIImageView(image: UIImage(named: "hello_hand_boy")), CGPoint(x: 0.9038, y: 0.4441), 0.32, 0.16)
    ]

    var aspectRatio: CGFloat {
        guard let s = base.image?.size, s.height > 0 else { return 1.13 }
        return s.width / s.height
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        for sh in shadows {
            sh.view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
            sh.view.layer.shadowColor = UIColor.black.cgColor
            sh.view.layer.shadowOpacity = 0.6
            sh.view.layer.shadowRadius = 8
            sh.view.layer.shadowOffset = .zero
            addSubview(sh.view)
        }
        base.contentMode = .scaleToFill
        for h in hands {
            h.view.contentMode = .scaleToFill
            h.view.layer.anchorPoint = h.pivot   // يدور من الرسغ
            addSubview(h.view)                   // اليد تحت الجسم
        }
        addSubview(base)
        for s in [smile, boySmile] {
            s.contentMode = .scaleToFill
            s.alpha = 0
            addSubview(s)
        }
        base.layer.shadowColor = UIColor.black.cgColor
        base.layer.shadowOpacity = 0.25
        base.layer.shadowRadius = 4
        base.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        base.frame = bounds
        smile.frame = bounds
        boySmile.frame = bounds
        for h in hands {
            h.view.bounds = bounds
            h.view.center = CGPoint(x: bounds.width * h.pivot.x, y: bounds.height * h.pivot.y)
        }
        for sh in shadows {
            let w = bounds.width * sh.width, hgt = max(10, bounds.height * 0.035)
            sh.view.bounds = CGRect(x: 0, y: 0, width: w, height: hgt)
            sh.view.center = CGPoint(x: bounds.width * sh.center.x, y: bounds.height * sh.center.y)
            sh.view.layer.cornerRadius = hgt / 2
        }
    }

    func startWaving() {
        for h in hands where h.view.layer.animation(forKey: "wave") == nil {
            let wave = CABasicAnimation(keyPath: "transform.rotation.z")
            wave.fromValue = 0
            wave.toValue = h.angle
            wave.duration = 0.32
            wave.autoreverses = true
            wave.repeatCount = .infinity
            wave.isRemovedOnCompletion = false
            wave.beginTime = CACurrentMediaTime() + h.delay
            wave.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            h.view.layer.add(wave, forKey: "wave")
        }
        // عيون مفتوحة ← يغمضون ويضحكون شوي ← يرجعون يفتحونها (كل واحد بوقته)
        for (s, delay, period) in [(smile, 0.0, 2.6), (boySmile, 1.1, 3.0)] where s.layer.animation(forKey: "smile") == nil {
            let a = CAKeyframeAnimation(keyPath: "opacity")
            a.values = [0, 0, 1, 1, 0]
            a.keyTimes = [0, 0.46, 0.49, 0.86, 0.89]
            a.duration = period
            a.beginTime = CACurrentMediaTime() + delay
            a.repeatCount = .infinity
            a.isRemovedOnCompletion = false
            s.layer.add(a, forKey: "smile")
        }
    }
}


// MARK: - سحب العادة يمين ← يطلع زر الحذف (مثل تطبيق التذكيرات)

final class SwipeToDeleteView: UIView, UIGestureRecognizerDelegate {
    private let content: UIControl
    private let deleteButton = UIButton(type: .system)
    private let openWidth: CGFloat = 84
    private var shift: NSLayoutConstraint!
    private var startOffset: CGFloat = 0
    private(set) var isOpen = false

    init(content: UIControl, onDelete: @escaping () -> Void) {
        self.content = content
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous

        var c = UIButton.Configuration.filled()
        c.image = UIImage(systemName: "trash")
        c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        c.baseBackgroundColor = UIColor(red: 0.72, green: 0.27, blue: 0.18, alpha: 1)   // أحمر طوبي دافي
        c.baseForegroundColor = Theme.creamLight
        c.background.cornerRadius = 18
        deleteButton.configuration = c
        deleteButton.accessibilityLabel = "حذف"
        deleteButton.addAction(UIAction { _ in onDelete() }, for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(deleteButton)

        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        shift = content.leftAnchor.constraint(equalTo: leftAnchor)
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: topAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            deleteButton.leftAnchor.constraint(equalTo: leftAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: openWidth - 6),
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.widthAnchor.constraint(equalTo: widthAnchor),
            shift
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        pan.delegate = self
        content.addGestureRecognizer(pan)
        // لو مفتوح، الضغطة على العادة تسكّره (والتعديل يشيك على allowsTap)
        content.addTarget(self, action: #selector(contentTapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// يبدأ بس لو السحب أفقي (عشان التمرير لفوق وتحت يشتغل عادي)
    override func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
        guard let pan = g as? UIPanGestureRecognizer else { return true }
        let v = pan.velocity(in: self)
        return abs(v.x) > abs(v.y)
    }

    @objc private func panned(_ g: UIPanGestureRecognizer) {
        switch g.state {
        case .began:
            startOffset = shift.constant
        case .changed:
            shift.constant = min(max(0, startOffset + g.translation(in: self).x), openWidth + 20)
        default:
            setOpen(shift.constant > openWidth / 2 || g.velocity(in: self).x > 500)
        }
    }

    @objc private func contentTapped() {
        if isOpen { setOpen(false) }
    }

    /// العادة تفتح التعديل؟ (لا، لو زر الحذف ظاهر)
    var allowsTap: Bool { !isOpen }

    func setOpen(_ open: Bool) {
        if open != isOpen { UISelectionFeedbackGenerator().selectionChanged() }
        isOpen = open
        shift.constant = open ? openWidth : 0
        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3,
                       options: [.allowUserInteraction]) { self.layoutIfNeeded() }
    }
}

// MARK: - رسالة تأكيد بنفس شكل التطبيق (بدل نافذة النظام البيضاء)

/// لوح خشب صغير (نفس إطار اللوحات) فيه صورة اختيارية + عنوان + وصف + زرين:
/// «إلغاء» كبسولة غامقة، والتأكيد أخضر (أو أحمر طوبي للحذف).
final class WoodAlertViewController: UIViewController {
    private let titleText: String
    private let message: String?
    private let image: UIImage?
    private let confirmTitle: String
    private let destructive: Bool
    private let cancelTitle: String?
    private let onConfirm: () -> Void
    private let card = UIView()
    /// خانة كتابة اختيارية (مثل «وش نناديك؟» أو تغيير اسم الشخصية)
    private var field: UITextField?
    private var onText: ((String) -> Void)?

    /// رسالة فيها خانة كتابة
    convenience init(title: String, message: String?, placeholder: String, text: String? = nil,
                     confirm: String, cancel: String? = "إلغاء", onText: @escaping (String) -> Void) {
        self.init(title: title, message: message, confirm: confirm, cancel: cancel, onConfirm: {})
        let f = UI.textField(placeholder)
        f.text = text
        f.textAlignment = .center
        field = f
        self.onText = onText
    }
    private var fillEdge: CAGradientLayer?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let e = fillEdge, let host = e.superlayer { e.frame = host.bounds }
    }

    init(title: String, message: String?, image: UIImage? = nil, confirm: String,
         cancel: String? = "إلغاء", destructive: Bool = false, onConfirm: @escaping () -> Void) {
        titleText = title
        self.message = message
        self.image = image
        confirmTitle = confirm
        cancelTitle = cancel
        self.destructive = destructive
        self.onConfirm = onConfirm
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.09, green: 0.05, blue: 0.03, alpha: 0.6)

        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        // نفس إطار اللوحات بس أصغر (٧٠٪) عشان يناسب حجم الرسالة — الزوايا وأوراق الشجر ما تتمدد
        var small: UIImage?
        if let src = UIImage(named: "namq_alert_frame"), let cg = src.cgImage {   // الإطار بس (الداخل شفاف)
            small = UIImage(cgImage: cg, scale: src.scale / 0.7, orientation: .up)
                .resizableImage(withCapInsets: UIEdgeInsets(top: 105, left: 80, bottom: 28, right: 80), resizingMode: .stretch)
        }
        let board = UIImageView(image: small)
        board.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(board)
        // داخل الإطار قطعة خشب وحدة (عشان ما تبان خطوط تقسيم الإطار لما يتمدد)
        let fill = UIImageView(image: UIImage(named: "namq_panel_fill"))
        fill.contentMode = .scaleToFill
        fill.layer.cornerRadius = 16
        // ظل داخلي غامق عشان يندمج مع حافة الإطار
        let edge = CAGradientLayer()
        edge.type = .radial
        edge.startPoint = CGPoint(x: 0.5, y: 0.5)
        edge.endPoint = CGPoint(x: 1.15, y: 1.15)
        edge.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor(red: 0.23, green: 0.08, blue: 0.02, alpha: 0.45).cgColor]
        edge.locations = [0, 0.7, 1]
        fill.layer.addSublayer(edge)
        fillEdge = edge
        fill.layer.cornerCurve = .continuous
        fill.clipsToBounds = true
        fill.translatesAutoresizingMaskIntoConstraints = false
        card.insertSubview(fill, belowSubview: board)
        NSLayoutConstraint.activate([
            fill.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            fill.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            fill.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            fill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])

        var items: [UIView] = []
        if let image {
            // القطعة في دائرة ورقية
            let circle = UIView()
            circle.backgroundColor = Theme.parchment
            circle.layer.cornerRadius = 46
            circle.layer.borderWidth = 3
            circle.layer.borderColor = Theme.gold.withAlphaComponent(0.7).cgColor
            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(iv)
            circle.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                circle.widthAnchor.constraint(equalToConstant: 92),
                circle.heightAnchor.constraint(equalToConstant: 92),
                iv.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                iv.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
                iv.widthAnchor.constraint(equalToConstant: 64),
                iv.heightAnchor.constraint(equalToConstant: 64)
            ])
            let holder = UIView()
            holder.addSubview(circle)
            NSLayoutConstraint.activate([
                circle.topAnchor.constraint(equalTo: holder.topAnchor),
                circle.bottomAnchor.constraint(equalTo: holder.bottomAnchor),
                circle.centerXAnchor.constraint(equalTo: holder.centerXAnchor)
            ])
            items.append(holder)
        }
        let t = UI.label(titleText, size: 21, weight: .heavy, color: Theme.creamLight, lines: 0, align: .center)
        t.layer.shadowColor = UIColor.black.cgColor
        t.layer.shadowOpacity = 0.3
        t.layer.shadowRadius = 3
        t.layer.shadowOffset = CGSize(width: 0, height: 1)
        items.append(t)
        if let message {
            items.append(UI.label(message, size: 15, weight: .medium, color: Theme.cream.withAlphaComponent(0.9), lines: 0, align: .center))
        }

        if let field { items.append(field) }
        let ok = UI.pill(confirmTitle) { [weak self] in
            guard let self else { return }
            let action = self.onConfirm
            let text = self.field?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let textAction = self.onText
            self.view.endEditing(true)
            self.dismiss(animated: true) { action(); textAction?(text) }
        }
        if destructive { ok.configuration?.baseBackgroundColor = UIColor(red: 0.72, green: 0.27, blue: 0.18, alpha: 1) }
        var buttons: [UIView] = [ok]
        if let cancelTitle {
            let cancel = UI.pill(cancelTitle, style: .secondary) { [weak self] in self?.dismiss(animated: true) }
            buttons.append(cancel)
        }
        let row = UIStackView(arrangedSubviews: buttons)   // من اليمين: التأكيد ثم الإلغاء
        row.spacing = 10
        row.distribution = .fillEqually
        items.append(row)

        let stack = UIStackView(arrangedSubviews: items)
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(20, after: items[items.count - 2])
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.insertSubview(stack, belowSubview: board)   // الإطار فوق المحتوى

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor).withPriority(.defaultHigh),
            card.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -16),
            card.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            board.topAnchor.constraint(equalTo: card.topAnchor, constant: -18),
            board.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            board.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            board.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 40),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 34),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -34),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 170)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        field?.becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        card.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
                       options: [], animations: { self.card.transform = .identity })
    }
}


extension NSLayoutConstraint {
    func withPriority(_ p: UILayoutPriority) -> NSLayoutConstraint { priority = p; return self }
}

// MARK: - شاشة الاحتفال (خلّص كل عادات اليوم / ترقّى لمستوى جديد)

/// لوح خشب صغير فوق أشعة ذهبية تلف وقصاصات: الشخصية تضحك وتنط،
/// وتحتها أرقام اليوم وأيام الأسبوع (أو المستوى الجديد)، وزر للإغلاق.
final class CelebrationViewController: UIViewController {
    enum Kind { case allDone, levelUp(Level) }
    private let kind: Kind
    private let onProfile: (() -> Void)?
    private let store = GameStore.shared
    private let card = UIView()
    private let rays = CAShapeLayer()

    init(kind: Kind, onProfile: (() -> Void)? = nil) {
        self.kind = kind
        self.onProfile = onProfile
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let gold = UIColor(red: 0.88, green: 0.68, blue: 0.27, alpha: 1)
    private func inset(_ v: UIView, radius: CGFloat = 14) {
        v.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        v.layer.cornerRadius = radius
        v.layer.cornerCurve = .continuous
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.09, green: 0.05, blue: 0.03, alpha: 0.65)

        // أشعة ذهبية تلف ببطء
        let path = UIBezierPath()
        let r: CGFloat = 520
        for i in 0..<16 {
            let a = CGFloat(i) / 16 * .pi * 2
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: cos(a - 0.06) * r, y: sin(a - 0.06) * r))
            path.addLine(to: CGPoint(x: cos(a + 0.06) * r, y: sin(a + 0.06) * r))
            path.close()
        }
        rays.path = path.cgPath
        rays.fillColor = UIColor(red: 1, green: 0.84, blue: 0.48, alpha: 0.16).cgColor
        view.layer.addSublayer(rays)
        let spin = CABasicAnimation(keyPath: "transform.rotation")
        spin.toValue = CGFloat.pi * 2
        spin.duration = 18
        spin.repeatCount = .infinity
        rays.add(spin, forKey: "spin")

        // الإطار (نفس رسائل التأكيد)
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        let fill = UIImageView(image: UIImage(named: "namq_panel_fill"))
        fill.layer.cornerRadius = 16
        fill.clipsToBounds = true
        fill.translatesAutoresizingMaskIntoConstraints = false
        var frameImg: UIImage?
        if let src = UIImage(named: "namq_alert_frame"), let cg = src.cgImage {
            frameImg = UIImage(cgImage: cg, scale: src.scale / 0.7, orientation: .up)
                .resizableImage(withCapInsets: UIEdgeInsets(top: 105, left: 80, bottom: 28, right: 80), resizingMode: .stretch)
        }
        let frame = UIImageView(image: frameImg)
        frame.translatesAutoresizingMaskIntoConstraints = false

        // الشخصية تضحك (بملابسها) ووراها توهّج
        let glow = CAGradientLayer()
        glow.type = .radial
        glow.colors = [UIColor(red: 1, green: 0.84, blue: 0.48, alpha: 0.55).cgColor, UIColor.clear.cgColor]
        glow.startPoint = CGPoint(x: 0.5, y: 0.5)
        glow.endPoint = CGPoint(x: 1, y: 1)
        let glowView = UIView()
        glowView.layer.addSublayer(glow)
        glowView.translatesAutoresizingMaskIntoConstraints = false
        let charBox = UIView()
        charBox.translatesAutoresizingMaskIntoConstraints = false
        charBox.heightAnchor.constraint(equalToConstant: 165).isActive = true
        charBox.addSubview(glowView)
        let char = RoomObjectView(imageName: "namq_girl_canvas", fallbackSymbol: "figure.stand", label: "")
        char.isUserInteractionEnabled = false
        char.translatesAutoresizingMaskIntoConstraints = false
        if let p = store.profile {
            char.setImage(named: p.gender.canvasImage, fallback: "namq_boy_canvas")
            char.dress(store.outfit, gender: p.gender)
        }
        char.show(expression: "happy", for: 4)
        charBox.addSubview(char)
        let ratio = char.imageView.image.map { $0.size.width / max($0.size.height, 1) } ?? 0.4
        NSLayoutConstraint.activate([
            char.centerXAnchor.constraint(equalTo: charBox.centerXAnchor),
            char.bottomAnchor.constraint(equalTo: charBox.bottomAnchor),
            char.heightAnchor.constraint(equalToConstant: 165),
            char.widthAnchor.constraint(equalTo: char.heightAnchor, multiplier: ratio),
            glowView.centerXAnchor.constraint(equalTo: charBox.centerXAnchor),
            glowView.centerYAnchor.constraint(equalTo: charBox.centerYAnchor),
            glowView.widthAnchor.constraint(equalToConstant: 190),
            glowView.heightAnchor.constraint(equalToConstant: 190)
        ])
        glowView.layoutIfNeeded()
        glow.frame = CGRect(x: 0, y: 0, width: 190, height: 190)
        let jump = CAKeyframeAnimation(keyPath: "transform.translation.y")
        jump.values = [0, -16, -16, 0]
        jump.keyTimes = [0, 0.4, 0.6, 1]
        jump.duration = 0.7
        jump.repeatCount = 3
        char.layer.add(jump, forKey: "jump")

        let name = store.profile?.characterName ?? ""
        var items: [UIView] = [charBox]
        let title: String, sub: String, okTitle: String
        switch kind {
        case .allDone:
            title = "يوم كامل!"
            sub = g("أنجزت كل عادات اليوم، و\(name) فخور فيك", "أنجزتِ كل عادات اليوم، و\(name) فخورة فيك")
            okTitle = "نشوفك بكرة"
        case .levelUp(let lv):
            title = "ترقّيت لمستوى «\(lv.title)»"
            sub = g("\(name) كبر شوي، وصار حوله هالة تلمع", "\(name) كبرت شوي، وصار حولها هالة تلمع")
            okTitle = "يا سلام!"
            // وسام المستوى الجديد
            let badge = MedalView(icon: lv.icon, size: 64, ring: .gold, current: true)
            badge.translatesAutoresizingMaskIntoConstraints = false
            charBox.addSubview(badge)
            NSLayoutConstraint.activate([badge.topAnchor.constraint(equalTo: charBox.topAnchor),
                                         badge.trailingAnchor.constraint(equalTo: charBox.trailingAnchor, constant: -4)])
        }
        let t = UI.label(title, size: 24, weight: .heavy, color: Theme.gold, lines: 0, align: .center)
        let s = UI.label(sub, size: 15, weight: .medium, color: Theme.cream.withAlphaComponent(0.9), lines: 0, align: .center)
        items += [t, s]

        // صناديق الأرقام
        func statBox(_ value: String, _ label: String) -> UIView {
            let v = UIView()
            inset(v)
            let col = UIStackView(arrangedSubviews: [
                UI.label(value, size: 18, weight: .heavy, color: Theme.creamLight, align: .center),
                UI.label(label, size: 11, weight: .bold, color: Theme.cream.withAlphaComponent(0.7), align: .center)
            ])
            col.axis = .vertical
            col.spacing = 2
            col.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(col)
            NSLayoutConstraint.activate([
                col.topAnchor.constraint(equalTo: v.topAnchor, constant: 10), col.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -10),
                col.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 4), col.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -4)
            ])
            return v
        }
        let stats = UIStackView()
        stats.distribution = .fillEqually
        stats.spacing = 8
        switch kind {
        case .allDone:
            let due = store.habits.filter { $0.isDue() }
            let done = due.filter { store.isDoneToday($0) }
            let earned = done.reduce(0) { $0 + $1.kind.points }
            let streak = store.dayStreak
            stats.addArrangedSubview(statBox("\(Fmt.num(done.count))/\(Fmt.num(due.count))", "عادات"))
            stats.addArrangedSubview(statBox("+\(Fmt.num(earned)) ⭐", "نجوم اليوم"))
            stats.addArrangedSubview(statBox("\(Fmt.num(streak)) 🔥", streak == 1 ? "يوم ورا بعض" : "أيام ورا بعض"))
            items.append(stats)
            items.append(weekRow())
        case .levelUp(let lv):
            stats.addArrangedSubview(statBox(Fmt.num(lv.number), "المستوى"))
            stats.addArrangedSubview(statBox("\(Fmt.num(store.points)) ⭐", "رصيدك"))
            items.append(stats)
        }

        let ok = UI.pill(okTitle) { [weak self] in self?.dismiss(animated: true) }
        var buttons: [UIView] = [ok]
        if case .levelUp = kind, onProfile != nil {
            buttons.append(UI.pill(g("شوف شخصيتك", "شوفي شخصيتك"), style: .secondary) { [weak self] in
                let go = self?.onProfile
                self?.dismiss(animated: true) { go?() }
            })
        }
        let row = UIStackView(arrangedSubviews: buttons)
        row.spacing = 10
        row.distribution = .fillEqually
        items.append(row)

        let stack = UIStackView(arrangedSubviews: items)
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(16, after: items[items.count - 2])
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(fill)
        card.addSubview(stack)
        card.addSubview(frame)
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            frame.topAnchor.constraint(equalTo: card.topAnchor, constant: -18),
            frame.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            frame.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            frame.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            fill.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            fill.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            fill.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            fill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -30)
        ])
    }

    /// آخر ٧ أيام كسلسلة: دوائر متساوية يربطها خط، والخط يصير ذهبي بين يومين متتاليين منجزين، واليوم عليه حلقة داخلية
    private func weekRow() -> UIView {
        let all = Set(store.habits.flatMap(\.completedDays))
        let cal = Calendar.current
        let days: [(date: Date, on: Bool)] = (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i - 6, to: Date()) ?? Date()
            return (d, all.contains(Day.key(d)))
        }
        let row = UIStackView()
        row.spacing = 0
        row.distribution = .fillEqually
        row.alignment = .top
        var dots: [UIView] = []
        for (i, day) in days.enumerated() {
            let isToday = i == 6
            let dot = UIView()
            dot.backgroundColor = day.on ? gold : UIColor(red: 0.35, green: 0.23, blue: 0.11, alpha: 1)
            dot.layer.cornerRadius = 15
            if isToday { dot.layer.borderWidth = 2.5; dot.layer.borderColor = Theme.creamLight.cgColor }
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 30).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 30).isActive = true
            if day.on {
                let check = UI.symbol("checkmark", color: Theme.ink, size: 12)
                check.translatesAutoresizingMaskIntoConstraints = false
                dot.addSubview(check)
                NSLayoutConstraint.activate([check.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                                             check.centerYAnchor.constraint(equalTo: dot.centerYAnchor)])
            }
            let wd = cal.component(.weekday, from: day.date)
            let l = UI.label(Fmt.weekdayShort[wd - 1], size: 11, weight: .heavy,
                             color: isToday ? Theme.gold : Theme.cream.withAlphaComponent(0.7), align: .center)
            let col = UIStackView(arrangedSubviews: [dot, l])
            col.axis = .vertical
            col.alignment = .center
            col.spacing = 6
            row.addArrangedSubview(col)
            dots.append(dot)
        }
        // خطوط السلسلة خلف الدوائر
        let box = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(row)
        NSLayoutConstraint.activate([row.topAnchor.constraint(equalTo: box.topAnchor),
                                     row.bottomAnchor.constraint(equalTo: box.bottomAnchor),
                                     row.leadingAnchor.constraint(equalTo: box.leadingAnchor),
                                     row.trailingAnchor.constraint(equalTo: box.trailingAnchor)])
        for i in 0..<6 {
            let bar = UIView()
            let linked = days[i].on && days[i + 1].on
            bar.backgroundColor = linked ? gold : UIColor.black.withAlphaComponent(0.22)
            bar.layer.cornerRadius = 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            box.insertSubview(bar, belowSubview: row)
            NSLayoutConstraint.activate([bar.heightAnchor.constraint(equalToConstant: 4),
                                         bar.centerYAnchor.constraint(equalTo: dots[i].centerYAnchor),
                                         bar.leadingAnchor.constraint(equalTo: dots[i].centerXAnchor),
                                         bar.trailingAnchor.constraint(equalTo: dots[i + 1].centerXAnchor)])
        }
        // الحلقة الذهبية فوق الخط
        dots.forEach { $0.superview?.bringSubviewToFront($0) }
        return box
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        rays.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY * 0.9)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Celebration.confetti(in: view)
        view.bringSubviewToFront(card)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        card.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        card.alpha = 0
        UIView.animate(withDuration: 0.55, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6,
                       options: [], animations: { self.card.transform = .identity; self.card.alpha = 1 })
    }
}


// MARK: - وسام (ميدالية) — للمستويات والإنجازات

/// دائرة بحلقة معدنية (ذهبي / فضي / برونزي) وداخلها خشب غامق وأيقونة.
/// المقفل: حلقة باهتة وقفل. الحالي: يلمع.
final class MedalView: UIView {
    enum Ring { case gold, silver, bronze, off }
    private let ringLayer = CAGradientLayer()
    private let inner = CAGradientLayer()
    private let iconView = UIImageView()
    private let size: CGFloat

    init(icon: String, size: CGFloat, ring: Ring, current: Bool = false, locked: Bool = false) {
        self.size = size
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        isUserInteractionEnabled = false
        let colors: [UIColor]
        let tint: UIColor
        switch ring {
        case .gold:   colors = [UIColor(red: 1, green: 0.88, blue: 0.54, alpha: 1), UIColor(red: 0.79, green: 0.54, blue: 0.18, alpha: 1), UIColor(red: 0.54, green: 0.35, blue: 0.11, alpha: 1)]
                      tint = UIColor(red: 1, green: 0.84, blue: 0.48, alpha: 1)
        case .silver: colors = [UIColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1), UIColor(red: 0.70, green: 0.67, blue: 0.62, alpha: 1), UIColor(red: 0.47, green: 0.44, blue: 0.37, alpha: 1)]
                      tint = UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1)
        case .bronze: colors = [UIColor(red: 0.95, green: 0.71, blue: 0.49, alpha: 1), UIColor(red: 0.69, green: 0.42, blue: 0.19, alpha: 1), UIColor(red: 0.43, green: 0.23, blue: 0.09, alpha: 1)]
                      tint = UIColor(red: 0.96, green: 0.75, blue: 0.54, alpha: 1)
        case .off:    colors = [UIColor(red: 0.43, green: 0.35, blue: 0.26, alpha: 1), UIColor(red: 0.29, green: 0.22, blue: 0.15, alpha: 1)]
                      tint = Theme.cream.withAlphaComponent(0.32)
        }
        ringLayer.colors = colors.map(\.cgColor)
        ringLayer.startPoint = CGPoint(x: 0.15, y: 0)
        ringLayer.endPoint = CGPoint(x: 0.85, y: 1)
        ringLayer.cornerRadius = size / 2
        layer.addSublayer(ringLayer)
        inner.type = .radial
        inner.colors = ring == .off
            ? [UIColor(red: 0.18, green: 0.10, blue: 0.04, alpha: 1).cgColor, UIColor(red: 0.18, green: 0.10, blue: 0.04, alpha: 1).cgColor]
            : [UIColor(red: 0.48, green: 0.31, blue: 0.14, alpha: 1).cgColor, UIColor(red: 0.24, green: 0.14, blue: 0.05, alpha: 1).cgColor]
        inner.startPoint = CGPoint(x: 0.4, y: 0.35)
        inner.endPoint = CGPoint(x: 1.1, y: 1.1)
        inner.cornerRadius = (size - 6) / 2
        inner.masksToBounds = true
        layer.addSublayer(inner)
        iconView.image = UIImage(systemName: locked ? "lock.fill" : icon) ?? UIImage(systemName: "star.fill")
        iconView.tintColor = tint
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: size * 0.36, weight: .bold)
        addSubview(iconView)
        layer.shadowColor = (current ? Theme.gold : UIColor.black).cgColor
        layer.shadowOpacity = ring == .off ? 0 : (current ? 0.7 : 0.35)
        layer.shadowRadius = current ? 9 : 2
        layer.shadowOffset = current ? .zero : CGSize(width: 0, height: 2)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: size).isActive = true
        heightAnchor.constraint(equalToConstant: size).isActive = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        ringLayer.frame = bounds
        inner.frame = bounds.insetBy(dx: 3, dy: 3)
        iconView.frame = bounds.insetBy(dx: size * 0.24, dy: size * 0.24)
    }
}
