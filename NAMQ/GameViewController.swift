//
//  GameViewController.swift
//  NAMQ
//
//  الغرفة الرئيسية: الشخصية + المكتبة + الطاولة + الدولاب،
//  وشريط علوي (الصورة والاسم والمستوى والنقاط وإنجاز اليوم).
//  الشخصية قدّام على اليمين، ورسايلها جنبها على الأرضية عشان ما تغطي الأغراض.
//  التنقل بالضغط على الأغراض نفسها.
//

import UIKit

final class GameViewController: UIViewController {

    private let store = GameStore.shared
    private let background = VideoBackgroundView(resource: "background")

    // أغراض الغرفة
    private let library   = RoomObjectView(imageName: "namq_library", fallbackSymbol: "books.vertical.fill", label: "مكتبة العادات")
    private let wardrobe  = RoomObjectView(imageName: "namq_wardrobe", fallbackSymbol: "cabinet.fill", label: "دولاب الجوائز")
    private let table     = RoomObjectView(imageName: "namq_table", fallbackSymbol: "table.furniture.fill", label: "طاولة عاداتي")
    private let character = RoomObjectView(imageName: "namq_boy_canvas", fallbackSymbol: "figure.stand", label: "شخصيتك")
    private let nameplate = NameplateView()
    private let aura = LevelAuraView()       // هالة المستوى حول الشخصية
    private let crown = StarView()           // نجمة فوق الراس لما يوصل أعلى مستوى
    private let bubble = SpeechBubbleView()

    // الشريط العلوي
    private let hud = UIView()
    private let avatarView = UIImageView()
    /// وسام المستوى على زاوية الصورة (يطلع لما يوصل المستوى ٢ وفوق)
    private let levelBadge = UIView()
    /// الشخصية مصغّرة داخل الدائرة اللي فوق — تبين بملابسها
    private let avatarCharacter = RoomObjectView(imageName: "namq_boy_canvas", fallbackSymbol: "person.fill", label: "")
    private let greetingLabel = UI.label(size: 15, weight: .heavy, color: Theme.creamLight)
    private let pointsLabel = UI.label(size: 14, weight: .heavy, color: Theme.creamLight, align: .center)
    private let coinBar = UIView()   // كبسولة النقاط: عملة ذهبية + الرقم
    private let progressLabel = UI.label(size: 12, weight: .bold, color: Theme.cream.withAlphaComponent(0.85))
    private let progressBar = UIProgressView(progressViewStyle: .bar)
    /// ظل على الأرض تحت رجلين الشخصية
    private let groundShadow = UIView()

    private var shownPoints: Int?

    override var prefersStatusBarHidden: Bool { true }
    private var blinkScheduled = false
    private var waveScheduled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.woodDark
        view.addSubview(background)
        [library, wardrobe, table].forEach { view.addSubview($0) }
        groundShadow.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        groundShadow.layer.shadowColor = UIColor.black.cgColor
        groundShadow.layer.shadowOpacity = 0.5
        groundShadow.layer.shadowRadius = 6
        groundShadow.layer.shadowOffset = .zero
        groundShadow.isUserInteractionEnabled = false
        view.addSubview(groundShadow)
        view.addSubview(aura)
        view.addSubview(character)
        view.addSubview(crown)
        view.addSubview(nameplate)
        buildHUD()
        view.addSubview(bubble)

        library.addAction(UIAction { [weak self] _ in self?.openLibrary() }, for: .touchUpInside)
        table.addAction(UIAction { [weak self] _ in self?.openTable() }, for: .touchUpInside)
        wardrobe.addAction(UIAction { [weak self] _ in self?.openWardrobe() }, for: .touchUpInside)
        character.addAction(UIAction { [weak self] _ in self?.openCoach() }, for: .touchUpInside)   // الشخصية = المساعد

        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: GameStore.didChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(celebrate(_:)), name: GameStore.celebrate, object: nil)
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        background.play()
        // الشخصية ثابتة (بدون تنطيط) — بس ترمش، ومرات تلوّح وتضحك
        scheduleBlink()
        scheduleWave()
    }

    /// الشخصية ترمش كل كم ثانية — تحسّين إنها حيّة
    private func scheduleBlink() {
        guard !blinkScheduled else { return }
        blinkScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 2.5...5)) { [weak self] in
            guard let self else { return }
            self.blinkScheduled = false
            guard self.view.window != nil else { return }
            if self.character.expression == nil {
                self.character.show(expression: "blink", for: 0.16)
            }
            self.scheduleBlink()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bubble.pop()
    }

    // MARK: - توزيع الغرفة (نِسب من حجم الشاشة عشان يضبط على كل الأجهزة)

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        background.frame = view.bounds
        let w = view.bounds.width, h = view.bounds.height
        // ترتيب الغرفة: الدولاب على الجدار جنب الدفاية، المكتبة يمين جنب الشباك،
        // الطاولة على الأرضية يسار شوي، والشخصية قدّام على اليمين بعيد عن الأغراض
        place(wardrobe,  in: CGRect(x: w * 0.19, y: h * 0.385, width: w * 0.38, height: h * 0.225))
        place(library,   in: CGRect(x: w * 0.60, y: h * 0.32,  width: w * 0.34, height: h * 0.315))
        place(table,     in: CGRect(x: w * 0.14, y: h * 0.60, width: w * 0.48, height: h * 0.16))
        // صورة الشخصية فيها مساحة فوق الراس للقبعة، فنكبّر المربع بنفس النسبة
        // الشخصية: أقرب (أكبر) وعلى اليمين قدّام، بعيد عن باقي الأغراض
        place(character, in: CGRect(x: w * 0.64, y: h * 0.57, width: w * 0.34, height: h * 0.33))
        let feet = character.frame
        groundShadow.bounds = CGRect(x: 0, y: 0, width: feet.width * 0.62, height: 16)
        groundShadow.center = CGPoint(x: feet.midX, y: feet.maxY - 4)
        groundShadow.layer.cornerRadius = 8

        let tag = nameplate.sizeThatFits(CGSize(width: w * 0.5, height: 30))
        nameplate.bounds = CGRect(origin: .zero, size: tag)
        nameplate.center = CGPoint(x: min(feet.midX, w - tag.width / 2 - 8),
                                   y: feet.maxY + tag.height / 2 + 8)   // تحت الرجلين

        // فقاعة الكلام: يسار الشخصية على الأرضية الفاضية (تحت الطاولة) — ما تغطي شي
        let headTop = feet.minY + feet.height * Gender.canvasTopPadding
        let maxWidth = min(feet.minX - 20, 230)
        let size = bubble.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        bubble.bounds = CGRect(origin: .zero, size: size)
        let tableBottom = table.frame.maxY
        let chestY = feet.minY + feet.height * 0.45
        bubble.center = CGPoint(x: feet.minX + 6 - size.width / 2,
                                y: max(chestY, tableBottom + 14 + size.height / 2))
        bubble.tailRight = true

        let body = character.frame
        aura.frame = CGRect(x: body.midX - body.width * 0.85, y: headTop - body.height * 0.05,
                            width: body.width * 1.7, height: body.maxY - headTop + body.height * 0.08)
        crown.frame = CGRect(x: body.midX - 15, y: headTop - 40, width: 30, height: 30)
        view.bringSubviewToFront(hud)
    }

    /// يحط الصورة داخل المربع محافظًا على نسبتها، وملتصقة بالأرض (أسفل المربع)
    private func place(_ object: RoomObjectView, in box: CGRect) {
        guard let s = object.imageView.image?.size, s.width > 0, s.height > 0 else {
            object.bounds = CGRect(origin: .zero, size: box.size)
            object.center = CGPoint(x: box.midX, y: box.midY)
            return
        }
        let scale = min(box.width / s.width, box.height / s.height)
        let size = CGSize(width: s.width * scale, height: s.height * scale)
        object.bounds = CGRect(origin: .zero, size: size)
        object.center = CGPoint(x: box.midX, y: box.maxY - size.height / 2)
    }

    // MARK: - الشريط العلوي

    private func buildHUD() {
        // لوح خشب بأطراف مدوّرة ومسمارين (نفس الصورة اللي اخترتيها)
        hud.backgroundColor = .clear
        hud.layer.shadowColor = UIColor(red: 0.16, green: 0.05, blue: 0.01, alpha: 1).cgColor
        hud.layer.shadowOpacity = 0.25
        hud.layer.shadowRadius = 2
        hud.layer.shadowOffset = CGSize(width: 0, height: 3)
        if let plank = UIImage(named: "namq_hud_plank") {
            // الأطراف ثابتة والنص يتمدد
            let wood = UIImageView(image: plank.resizableImage(
                withCapInsets: UIEdgeInsets(top: 20, left: 44, bottom: 20, right: 44), resizingMode: .stretch))
            wood.translatesAutoresizingMaskIntoConstraints = false
            hud.addSubview(wood)
            NSLayoutConstraint.activate([
                wood.topAnchor.constraint(equalTo: hud.topAnchor),
                wood.bottomAnchor.constraint(equalTo: hud.bottomAnchor),
                wood.leadingAnchor.constraint(equalTo: hud.leadingAnchor),
                wood.trailingAnchor.constraint(equalTo: hud.trailingAnchor)
            ])
        }
        hud.translatesAutoresizingMaskIntoConstraints = false

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 21
        avatarView.layer.borderWidth = 3
        avatarView.layer.borderColor = UIColor(red: 0.91, green: 0.81, blue: 0.63, alpha: 1).cgColor   // حلقة كريمية هادية
        avatarView.backgroundColor = UIColor(red: 0.97, green: 0.80, blue: 0.55, alpha: 1)   // خلفية دافية
        avatarCharacter.isUserInteractionEnabled = false
        avatarCharacter.layer.shadowOpacity = 0
        avatarView.addSubview(avatarCharacter)
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        // الضغط على الصورة يفتح البروفايل (الإنجازات والإعدادات)
        let menuButton = UIButton(type: .custom, primaryAction: UIAction { [weak self] _ in self?.openProfile() })
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.accessibilityLabel = "البروفايل"

        // الاسم والمستوى وإنجاز اليوم (يمين، جنب الصورة)
        let names = UIStackView(arrangedSubviews: [greetingLabel, progressLabel])
        names.axis = .vertical
        names.spacing = 3
        names.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // كبسولة النقاط: خشب غامق محفور فيها نجمة (نفس نجمة أسعار الملابس) + الرقم
        let inset = UIColor(red: 0.29, green: 0.15, blue: 0.05, alpha: 0.85)
        coinBar.backgroundColor = inset
        coinBar.layer.cornerRadius = 15
        coinBar.layer.borderWidth = 1
        coinBar.layer.borderColor = UIColor.black.withAlphaComponent(0.25).cgColor
        coinBar.translatesAutoresizingMaskIntoConstraints = false
        let coin = StarView()
        coin.layer.shadowRadius = 4
        coin.translatesAutoresizingMaskIntoConstraints = false
        pointsLabel.translatesAutoresizingMaskIntoConstraints = false
        pointsLabel.adjustsFontSizeToFitWidth = true
        pointsLabel.minimumScaleFactor = 0.6
        coinBar.addSubview(coin)
        coinBar.addSubview(pointsLabel)

        // شريط إنجاز اليوم تحت الكبسولة (يسار)
        progressBar.progressTintColor = UIColor(red: 0.88, green: 0.68, blue: 0.27, alpha: 1)   // ذهبي هادي
        progressBar.trackTintColor = inset
        progressBar.layer.cornerRadius = 5
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false


        let row = UIStackView(arrangedSubviews: [avatarView, names, coinBar])   // النقاط بمحاذاة الكلام
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        hud.addSubview(row)
        hud.addSubview(progressBar)
        hud.addSubview(menuButton)
        levelBadge.translatesAutoresizingMaskIntoConstraints = false
        levelBadge.isUserInteractionEnabled = false
        hud.addSubview(levelBadge)
        view.addSubview(hud)

        NSLayoutConstraint.activate([
            // على الجدار (تحت السقف الغامق) عشان تندمج مع الغرفة
            NSLayoutConstraint(item: hud, attribute: .top, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 0.185, constant: 0),
            hud.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 48),
            hud.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -48),
            row.topAnchor.constraint(equalTo: hud.topAnchor, constant: 11),
            // شريط الإنجاز تحت بعرض البطاقة كله
            progressBar.topAnchor.constraint(equalTo: row.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: hud.leadingAnchor, constant: 26),
            progressBar.trailingAnchor.constraint(equalTo: hud.trailingAnchor, constant: -26),
            progressBar.bottomAnchor.constraint(equalTo: hud.bottomAnchor, constant: -13),
            row.leadingAnchor.constraint(equalTo: hud.leadingAnchor, constant: 24),
            row.trailingAnchor.constraint(equalTo: hud.trailingAnchor, constant: -24),
            avatarView.widthAnchor.constraint(equalToConstant: 42),
            avatarView.heightAnchor.constraint(equalToConstant: 42),
            levelBadge.widthAnchor.constraint(equalToConstant: 22),
            levelBadge.heightAnchor.constraint(equalToConstant: 22),
            levelBadge.centerXAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: -3),
            levelBadge.centerYAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: -3),
            menuButton.topAnchor.constraint(equalTo: avatarView.topAnchor),
            menuButton.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
            menuButton.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            menuButton.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),

            coinBar.heightAnchor.constraint(equalToConstant: 30),
            coinBar.widthAnchor.constraint(equalToConstant: 80),
            coin.leftAnchor.constraint(equalTo: coinBar.leftAnchor, constant: 6),
            coin.centerYAnchor.constraint(equalTo: coinBar.centerYAnchor),
            coin.widthAnchor.constraint(equalToConstant: 20),
            coin.heightAnchor.constraint(equalToConstant: 20),
            pointsLabel.leftAnchor.constraint(equalTo: coin.rightAnchor, constant: 4),
            pointsLabel.rightAnchor.constraint(equalTo: coinBar.rightAnchor, constant: -10),
            pointsLabel.centerYAnchor.constraint(equalTo: coinBar.centerYAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    // MARK: - تحديث البيانات

    @objc private func refresh() {
        guard let profile = store.profile else { return }
        character.setImage(named: profile.gender.canvasImage, fallback: "namq_boy_canvas")
        avatarCharacter.setImage(named: profile.gender.canvasImage, fallback: "namq_boy_canvas")
        avatarCharacter.dress(store.outfit, gender: profile.gender)
        // نكبّر الشخصية داخل الدائرة عشان يبان الراس (مع القبعة والنظارة)
        let ratio = avatarCharacter.imageView.image.map { $0.size.width / max($0.size.height, 1) } ?? 0.45
        // صورة وجه قريبة: الراس والكتوف يعبّون الدائرة (مثل صور الشيت)
        // نعرض من أعلى الشعر لين الكتوف (~٣٩٠ بكسل من صورة طولها ٩٠٠)
        let hairTop: CGFloat = profile.gender == .girl ? 182 : 115
        let miniH: CGFloat = 42 * 900 / 390
        avatarCharacter.frame = CGRect(x: (42 - miniH * ratio) / 2, y: -hairTop * miniH / 900 + 3,
                                       width: miniH * ratio, height: miniH)
        nameplate.configure(name: "\(profile.characterName) · \(store.level.title)", equipped: nil)
        aura.apply(level: store.level.number)
        levelBadge.subviews.forEach { $0.removeFromSuperview() }
        if store.level.number >= 2 {
            let m = MedalView(icon: store.level.icon, size: 22, ring: .gold)
            levelBadge.addSubview(m)
            NSLayoutConstraint.activate([m.centerXAnchor.constraint(equalTo: levelBadge.centerXAnchor),
                                         m.centerYAnchor.constraint(equalTo: levelBadge.centerYAnchor)])
        }
        crown.isHidden = store.level.number < Level.all.count
        character.dress(store.outfit, gender: profile.gender)

        greetingLabel.text = "أهلًا، \(profile.name)"
        let p = store.todayProgress
        progressLabel.text = p.total == 0 ? g("أضف أول عادة لك", "أضيفي أول عادة لك") : "إنجاز اليوم \(Fmt.num(p.done)) / \(Fmt.num(p.total))"
        progressBar.setProgress(p.total == 0 ? 0 : Float(p.done) / Float(p.total), animated: true)

        updatePoints(store.points)
        bubble.text = statusMessage(done: p.done, total: p.total)
        if p.total == 0 { library.startPulse() } else { library.stopPulse() }
        view.setNeedsLayout()
    }

    private func updatePoints(_ points: Int) {
        pointsLabel.text = Fmt.num(points)
        if let old = shownPoints, old != points { coinBar.pop() }
        shownPoints = points
    }

    private func statusMessage(done: Int, total: Int) -> String {
        if total == 0 { return g("هلا! اضغط عليّ وأبني لك خطة ✨ أو اختر من المكتبة 📚", "هلا! اضغطي عليّ وأبني لك خطة ✨ أو اختاري من المكتبة 📚") }
        if done == total { return g("أحسنت! أنجزت كل عادات اليوم 🎉", "أحسنتِ! أنجزتِ كل عادات اليوم 🎉") }
        let left = total - done
        return left == 1 ? g("باقي عادة وحدة اليوم، تقدر! 💪", "باقي عادة وحدة اليوم، تقدرين! 💪") : "باقي \(Fmt.num(left)) عادات اليوم 🌱"
    }

    private func openCoach() {
        // تضحك لما تضغطين عليها، وبعدها يفتح المساعد
        character.show(expression: "happy", for: 1.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.present(CoachViewController(), animated: true)
        }
    }

    /// احتفال لما يخلص عادات اليوم أو يترقّى لمستوى جديد
    @objc private func celebrate(_ note: Notification) {
        let kind = note.userInfo?["kind"] as? String
        // الشخصية في الغرفة تضحك من الفرحة، وتطلع شاشة الاحتفال
        character.show(expression: "happy", for: 3)
        let vc: CelebrationViewController
        if kind == "levelUp", let level = note.userInfo?["level"] as? Level {
            vc = CelebrationViewController(kind: .levelUp(level)) { [weak self] in self?.openProfile() }
        } else {
            vc = CelebrationViewController(kind: .allDone)
        }
        // تطلع فوق أي لوحة مفتوحة (مثل الطاولة)
        var top: UIViewController = self
        while let p = top.presentedViewController { top = p }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { top.present(vc, animated: true) }
    }

    // MARK: - تعابير الوجه

    /// كل كم ثانية تسوي تعبير مثل شيت التعبيرات: تضحك، أو تغمز، أو تستغرب (وهي واقفة ثابتة)
    private func scheduleWave() {
        guard !waveScheduled else { return }
        waveScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 5...9)) { [weak self] in
            guard let self else { return }
            self.waveScheduled = false
            guard self.view.window != nil else { return }
            if self.presentedViewController == nil, self.character.expression == nil {
                switch Int.random(in: 0..<3) {
                case 0:  self.character.show(expression: "happy", for: 1.6)
                case 1:  self.character.show(expression: "wink", for: 0.9)
                default: self.character.show(expression: "wow", for: 1.2)
                }
            }
            self.scheduleWave()
        }
    }

    // MARK: - التنقل

    private func openLibrary()  { present(HabitLibraryViewController(), animated: true) }
    private func openTable()    { present(MyHabitsViewController(), animated: true) }
    private func openWardrobe() { present(WardrobeViewController(), animated: true) }
    private func openProfile() {
        present(ProfileViewController(onReset: { [weak self] in self?.resetAll() }), animated: true)
    }

    private func resetAll() {
        GameStore.shared.reset()
        guard let nav = navigationController else { return }
        nav.view.layer.add(CATransition.fade, forKey: nil)
        nav.setViewControllers([SplashViewController()], animated: false)
    }
}

/// عملة ذهبية مرسومة (دائرة بتدرّج ولمعة)
private final class CoinView: UIView {
    private let gradient = CAGradientLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.type = .radial
        gradient.colors = [UIColor(red: 1, green: 0.93, blue: 0.55, alpha: 1).cgColor,
                           UIColor(red: 0.98, green: 0.72, blue: 0.12, alpha: 1).cgColor,
                           UIColor(red: 0.85, green: 0.52, blue: 0.05, alpha: 1).cgColor]
        gradient.locations = [0, 0.6, 1]
        gradient.startPoint = CGPoint(x: 0.35, y: 0.3)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)
        layer.shadowColor = UIColor(red: 1, green: 0.8, blue: 0.3, alpha: 1).cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 5
        layer.shadowOffset = .zero
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        gradient.cornerRadius = bounds.width / 2
    }
}
