//
//  LoginViewController.swift
//  NAMQ
//
//  تسجيل الدخول — الأساس "تسجيل الدخول مع Apple"، وخيار "ضيف" للتجربة.
//  ⚠️ لازم تضيفين Sign in with Apple من Signing & Capabilities في Xcode.
//

import UIKit
import AuthenticationServices

final class LoginViewController: UIViewController {

    private let store = GameStore.shared
    private weak var helloKids: HelloKidsView?
    override var prefersStatusBarHidden: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let kids = helloKids else { return }
        // يلوّحون ويبتسمون وهم واقفين على الأرض (بدون نط عشان ما يبينون طايرين)
        kids.startWaving()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.woodDark
        // نفس خلفية السبلاش: غرفة دافية والنار تتحرك، مع تغميق خفيف تحت عشان الكلام يبان
        let bg = VideoBackgroundView(resource: "splash_background")
        bg.frame = view.bounds
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(bg)
        let shade = GradientShadeView(frame: view.bounds)
        shade.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(shade)
        buildLayout()
    }

    private func buildLayout() {
        // الشخصيات والنجمة
        let star = HangingStarView(size: 56)
        star.translatesAutoresizingMaskIntoConstraints = false
        // نجمتين صغار معلّقين على الجنبين
        for (x, len, size) in [(0.12, 0.09, 30.0), (0.9, 0.06, 26.0)] {
            let s = HangingStarView(size: CGFloat(size))
            s.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(s)
            NSLayoutConstraint.activate([
                s.topAnchor.constraint(equalTo: view.topAnchor),
                NSLayoutConstraint(item: s, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .right, multiplier: x, constant: 0),
                s.widthAnchor.constraint(equalToConstant: CGFloat(size) + 4),
                s.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: len)
            ])
        }
        // توهج خلف النجمة الكبيرة
                // الولد والبنت يلوّحون بيدهم "مرحبا!" ويتمايلون شوي
        let kids = HelloKidsView()
        kids.translatesAutoresizingMaskIntoConstraints = false
        helloKids = kids

        // النصوص مباشرة على الخلفية — بدون بطاقة
        let welcome = UI.label("مرحبًا بك في نَمَق", size: 34, weight: .heavy, color: Theme.cream, align: .center)
        welcome.layer.shadowColor = UIColor.black.cgColor
        welcome.layer.shadowOpacity = 0.35
        welcome.layer.shadowRadius = 6
        welcome.layer.shadowOffset = CGSize(width: 0, height: 3)
        let tagline = UI.label("كل عادة تبنيك، خطوة بخطوة", size: 17, weight: .medium,
                               color: Theme.cream.withAlphaComponent(0.85), lines: 0, align: .center)
        // "سجّل دخولك" بين خطّين
        let promptText = UI.label("سجّل دخولك", size: 18, weight: .bold, color: Theme.gold, align: .center)
        promptText.setContentHuggingPriority(.required, for: .horizontal)
        let line = { () -> UIView in
            let v = UIView()
            v.backgroundColor = Theme.cream.withAlphaComponent(0.35)
            v.heightAnchor.constraint(equalToConstant: 1.5).isActive = true
            return v
        }
        let lineA = line(), lineB = line()
        let prompt = UIStackView(arrangedSubviews: [lineA, promptText, lineB])
        prompt.spacing = 16
        prompt.alignment = .center
        lineA.widthAnchor.constraint(equalTo: lineB.widthAnchor).isActive = true

        let apple = ASAuthorizationAppleIDButton(authorizationButtonType: .continue, authorizationButtonStyle: .black)
        apple.cornerRadius = 29
        apple.semanticContentAttribute = .forceLeftToRight   // شعار Apple على اليسار
        apple.layer.borderWidth = 1.5
        apple.layer.borderColor = Theme.gold.withAlphaComponent(0.7).cgColor
        apple.layer.cornerRadius = 29
        apple.translatesAutoresizingMaskIntoConstraints = false
        apple.layer.shadowColor = UIColor.black.cgColor
        apple.layer.shadowOpacity = 0.35
        apple.layer.shadowRadius = 12
        apple.layer.shadowOffset = CGSize(width: 0, height: 6)
        apple.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)

        // الدخول كضيف: نص بس بدون مربع
        var guestConfig = UIButton.Configuration.plain()
        guestConfig.title = "الدخول كضيف"
        guestConfig.baseForegroundColor = Theme.cream
        guestConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.font(16, .bold)
            out.underlineStyle = .single
            return out
        }
        let guest = UIButton(configuration: guestConfig, primaryAction: UIAction { [weak self] _ in self?.continueAsGuest() })

        let terms = UI.label("بالمتابعة، أنت توافق على شروط الاستخدام وسياسة الخصوصية", size: 11,
                             color: Theme.cream.withAlphaComponent(0.7), lines: 0, align: .center)

        let form = UIStackView(arrangedSubviews: [welcome, tagline, prompt, apple, guest, terms])
        form.axis = .vertical
        form.spacing = 8
        form.setCustomSpacing(34, after: tagline)
        form.setCustomSpacing(24, after: prompt)
        form.setCustomSpacing(18, after: apple)
        form.setCustomSpacing(22, after: guest)
        form.translatesAutoresizingMaskIntoConstraints = false

        // نجوم صغيرة متناثرة تلمع
        let sparkles: [(CGFloat, CGFloat, CGFloat)] = [(0.28, 0.13, 14), (0.84, 0.15, 12), (0.86, 0.33, 14),
                                                       (0.16, 0.37, 12), (0.68, 0.07, 6), (0.38, 0.06, 5)]
        for (i, sp) in sparkles.enumerated() {
            let dot = StarView()
            dot.alpha = 0.55
            dot.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(dot)
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: sp.2),
                dot.heightAnchor.constraint(equalToConstant: sp.2),
                NSLayoutConstraint(item: dot, attribute: .centerX, relatedBy: .equal, toItem: view,
                                   attribute: .right, multiplier: sp.0, constant: 0),
                NSLayoutConstraint(item: dot, attribute: .centerY, relatedBy: .equal, toItem: view,
                                   attribute: .bottom, multiplier: sp.1, constant: 0)
            ])
            let tw = CABasicAnimation(keyPath: "opacity")
            tw.fromValue = 0.25
            tw.toValue = 0.8
            tw.duration = 1.2 + Double(i) * 0.25
            tw.autoreverses = true
            tw.repeatCount = .infinity
            dot.layer.add(tw, forKey: "twinkle")
        }

        [star, kids, form].forEach { view.addSubview($0) }
        // يصغر لحاله على الشاشات الصغيرة
        let kidsHeight = kids.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.30)   // الأطفال أصغر وأبعد — واقفين بنص الغرفة
        kidsHeight.priority = .defaultHigh
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // نجمة معلّقة من السقف (خيط + نجمة تتمرجح)
            star.topAnchor.constraint(equalTo: view.topAnchor),
            star.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            star.widthAnchor.constraint(equalToConstant: 60),
            star.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.13),

            kids.topAnchor.constraint(greaterThanOrEqualTo: star.bottomAnchor, constant: 30),
            kids.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            kidsHeight,
            kids.widthAnchor.constraint(equalTo: kids.heightAnchor, multiplier: kids.aspectRatio),

            form.topAnchor.constraint(greaterThanOrEqualTo: kids.bottomAnchor, constant: 20),
            // الأطفال قريبين من الكلام تحتهم — بدون فراغ كبير بينهم
            {
                let c = form.topAnchor.constraint(equalTo: kids.bottomAnchor, constant: 24)
                c.priority = .defaultHigh
                return c
            }(),
            form.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 28),
            form.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -28),
            form.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -16),
            apple.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    // MARK: - Apple

    @objc private func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - ضيف

    private func continueAsGuest() {
        askName { [weak self] name in
            self?.store.signIn(userID: "guest-\(UUID().uuidString)", name: name, method: "guest")
            self?.proceed()
        }
    }

    private func askName(_ completion: @escaping (String) -> Void) {
        let alert = WoodAlertViewController(title: "وش نناديك؟", message: "اكتب اسمك عشان نرحّب فيك",
                                            placeholder: "اسمك", confirm: "متابعة", cancel: nil) { name in
            completion(name.isEmpty ? "صديقنا" : name)
        }
        present(alert, animated: true)
    }

    private func proceed() {
        guard let nav = navigationController else { return }
        nav.view.layer.add(CATransition.fade, forKey: nil)
        nav.setViewControllers([OnboardingViewController()], animated: false)
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        let parts = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }
        let name = parts.isEmpty ? nil : parts.joined(separator: " ")
        store.signIn(userID: credential.user, name: name, method: "apple")
        proceed()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled { return }
        print("Sign in with Apple failed:", error)
        let alert = WoodAlertViewController(title: "ما قدرنا نسجّل الدخول", message: "جرّب مرة ثانية، أو ادخل كضيف",
                                            confirm: "حسنًا", cancel: nil) {}
        present(alert, animated: true)
    }
}
