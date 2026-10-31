//
//  SplashViewController.swift
//  نمق
//
//  السبلاش — النجمة تتحرك وعيون الأطفال تلحقها (نفس الشيت):
//  ١) واقفين يبتسمون، و«نمق» تطلع فوقهم وتلمع
//  ٢) ينتبهون والكلمة تتحول لنجوم تلف وتصير نجمة — يندهشون
//  ٣) النجمة تروح يمين — يطالعون يمين
//  ٤) تلف ورا يسار — يلفون ويطالعونها، وبعدين تعدّي ورا لليمين — يطالعون يمين من ورا
//  ٥) تطلع فوق — يطالعون فوق
//  ٦) ترجع قدامهم — يلفون ويأشرون عليها فوق ويضحكون
//  ٧) النجمة تكبر وتغطي الشاشة — وينفتح التطبيق
//  (اضغطي على الشاشة لتخطيه)
//

import UIKit

final class SplashViewController: UIViewController {

    private let background = VideoBackgroundView(resource: "splash_background")
    private let shade = GradientShadeView()
    /// الاثنين مع بعض في صورة وحدة (كل لقطة من الشيت)
    private let pair = UIImageView()
    private let word = UI.label("نمق", size: 84, weight: .heavy, color: Theme.gold, align: .center)
    private let sparkles = UIView()
    private let star = StarView()
    private let rays = UIView()

    private var laidOutFor: CGSize = .zero
    private var started = false
    private var finished = false
    private var baseline: CGFloat = 0
    private var pxToPt: CGFloat = 1
    private var starHome: CGPoint = .zero
    private var trailTimer: Timer?

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.woodDark
        for v in [background, shade] as [UIView] {
            v.frame = view.bounds
            v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(v)
        }
        pair.contentMode = .scaleAspectFit
        pair.layer.shadowColor = UIColor.black.cgColor
        pair.layer.shadowOpacity = 0.3
        pair.layer.shadowRadius = 6
        pair.layer.shadowOffset = CGSize(width: 0, height: 4)

        word.translatesAutoresizingMaskIntoConstraints = true
        word.layer.shadowColor = UIColor(red: 1, green: 0.72, blue: 0.2, alpha: 1).cgColor
        word.layer.shadowRadius = 20
        word.layer.shadowOpacity = 1
        word.layer.shadowOffset = .zero

        star.layer.shadowColor = UIColor(red: 1, green: 0.8, blue: 0.3, alpha: 1).cgColor
        star.layer.shadowRadius = 16
        star.layer.shadowOpacity = 1
        star.layer.shadowOffset = .zero

        rays.isUserInteractionEnabled = false
        sparkles.isUserInteractionEnabled = false
        // النجمة تقدر تصير ورا الأطفال (لما تلف من ورا) أو قدامهم
        [sparkles, word, star, pair, rays].forEach { view.addSubview($0) }
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(skip)))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard laidOutFor != view.bounds.size else { return }
        laidOutFor = view.bounds.size
        layoutScene()
    }

    // MARK: - التوزيع

    private func layoutScene() {
        let w = view.bounds.width, h = view.bounds.height
        rays.frame = view.bounds
        baseline = h * 0.80
        let kidH = h * 0.30
        pxToPt = kidH / (UIImage(named: "sp4_front")?.size.height ?? 285)
        pose("sp4_front")

        starHome = CGPoint(x: w / 2, y: baseline - kidH - h * 0.13)
        word.bounds = CGRect(x: 0, y: 0, width: w, height: 110)
        word.center = starHome
        star.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
        star.center = starHome

        sparkles.subviews.forEach { $0.removeFromSuperview() }
        sparkles.frame = CGRect(x: w / 2 - 130, y: starHome.y - 80, width: 260, height: 160)
        let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.1, 0.2, 14), (0.3, 0.02, 10), (0.55, 0.0, 16), (0.82, 0.1, 12), (0.96, 0.42, 10),
                                                   (0.88, 0.8, 14), (0.62, 0.96, 10), (0.35, 0.92, 12), (0.04, 0.7, 12), (0.0, 0.42, 9)]
        for (i, sp) in spots.enumerated() {
            let st = StarView()
            st.frame = CGRect(x: sp.0 * 260 - sp.2 / 2, y: sp.1 * 160 - sp.2 / 2, width: sp.2, height: sp.2)
            st.layer.shadowColor = UIColor(red: 1, green: 0.8, blue: 0.3, alpha: 1).cgColor
            st.layer.shadowOpacity = 1
            st.layer.shadowRadius = 4
            st.layer.shadowOffset = .zero
            let tw = CABasicAnimation(keyPath: "opacity")
            tw.fromValue = 0.25
            tw.toValue = 1
            tw.duration = 0.5 + Double(i % 4) * 0.15
            tw.autoreverses = true
            tw.repeatCount = .infinity
            tw.beginTime = CACurrentMediaTime() + Double(i) * 0.09
            st.layer.add(tw, forKey: "tw")
            sparkles.addSubview(st)
        }
    }

    /// يغيّر اللقطة — نفس المقياس لكل اللقطات، والرجول على نفس الخط
    private func pose(_ name: String) {
        guard let img = UIImage(named: name) else { return }
        let size = CGSize(width: img.size.width * pxToPt, height: img.size.height * pxToPt)
        let apply = {
            self.pair.image = img
            self.pair.bounds = CGRect(origin: .zero, size: size)
            self.pair.center = CGPoint(x: self.view.bounds.midX, y: self.baseline - size.height / 2)
        }
        if pair.image == nil { apply() } else {
            UIView.transition(with: pair, duration: 0.12, options: [.transitionCrossDissolve, .allowAnimatedContent], animations: apply)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }
        started = true
        runAnimation()
    }

    // MARK: - الحركة

    private func after(_ t: TimeInterval, _ block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, !self.finished else { return }
            block()
        }
    }

    private func runAnimation() {
        let w = view.bounds.width, h = view.bounds.height
        pair.alpha = 0
        word.alpha = 0
        sparkles.alpha = 0
        star.alpha = 0
        rays.alpha = 0

        // ١) واقفين يبتسمون، و«نمق» تطلع فوقهم
        UIView.animate(withDuration: 0.6) { self.pair.alpha = 1 }
        after(0.45) {
            self.word.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.4,
                           options: [], animations: {
                self.word.alpha = 1
                self.sparkles.alpha = 1
                self.word.transform = .identity
            })
            self.burst(at: self.starHome, count: 12, speed: 60)
        }
        // ٢) ينتبهون والكلمة تصير نجمة — يندهشون
        after(1.4) { self.pose("sp4_alert"); self.spiralToStar() }
        after(2.35) { self.pose("sp4_wow") }
        // ٣) يمين — يطالعون يمين
        after(3.1) {
            self.trail(true)
            self.fly(to: CGPoint(x: w * 0.80, y: self.starHome.y + h * 0.03), scale: 0.85, duration: 0.75, behind: false)
        }
        after(3.3) { self.pose("sp4_wowL") }
        after(3.65) { self.pose("sp4_wowR") }
        // ٤) تلف ورا يسار — يلفون يطالعونها
        after(4.05) { self.fly(to: CGPoint(x: w * 0.22, y: self.starHome.y + h * 0.06), scale: 0.55, duration: 0.8, behind: true) }
        after(4.15) { self.pose("sp4_side") }
        // ثم تعدّي ورا لليمين — يطالعون يمين من ورا
        after(4.75) { self.fly(to: CGPoint(x: w * 0.76, y: self.starHome.y + h * 0.04), scale: 0.5, duration: 0.8, behind: true) }
        after(4.95) { self.pose("sp4_backL") }
        // ٥) فوق — يطالعون فوق
        after(5.5) { self.fly(to: CGPoint(x: w / 2, y: self.starHome.y - h * 0.08), scale: 0.5, duration: 0.65, behind: true) }
        after(5.65) { self.pose("sp4_backUp") }
        // ٦) ترجع قدامهم — يلفون ويأشرون ويضحكون
        after(6.25) {
            self.fly(to: self.starHome, scale: 1.15, duration: 0.65, behind: false)
            self.pose("sp4_back34")
        }
        after(6.65) {
            self.trail(false)
            self.pose("sp4_cheer")
            self.burst(at: self.starHome, count: 18, speed: 90)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            let twinkle = CABasicAnimation(keyPath: "transform.scale")
            twinkle.fromValue = 1.05
            twinkle.toValue = 1.25
            twinkle.duration = 0.5
            twinkle.autoreverses = true
            twinkle.repeatCount = .infinity
            self.star.layer.add(twinkle, forKey: "twinkle")
        }
        // ٧) تكبر وتغطي الشاشة
        after(7.65) { self.growStar() }
    }

    /// تحريك النجمة لمكان جديد — behind = تصير ورا الأطفال (كأنها بعيدة)
    private func fly(to p: CGPoint, scale: CGFloat, duration: TimeInterval, behind: Bool) {
        star.layer.removeAnimation(forKey: "twinkle")
        if behind { view.insertSubview(star, belowSubview: pair) } else { view.insertSubview(star, aboveSubview: pair) }
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            self.star.center = p
            self.star.transform = CGAffineTransform(scaleX: scale, y: scale)
        })
    }

    /// نجوم صغيرة تتساقط ورا النجمة وهي تتحرك
    private func trail(_ on: Bool) {
        trailTimer?.invalidate()
        guard on else { return }
        trailTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, !self.finished else { self?.trailTimer?.invalidate(); return }
            let c = self.star.layer.presentation()?.position ?? self.star.center
            let d = CALayer()
            let sz = CGFloat.random(in: 6...12)
            d.contents = Self.starImage(UIColor(red: 1, green: 0.88, blue: 0.5, alpha: 1)).cgImage
            d.frame = CGRect(x: c.x - sz / 2 + .random(in: -8...8), y: c.y - sz / 2 + .random(in: -8...8), width: sz, height: sz)
            self.view.layer.insertSublayer(d, below: self.star.layer)
            let f = CABasicAnimation(keyPath: "opacity")
            f.fromValue = 1
            f.toValue = 0
            f.duration = 0.7
            let m = CABasicAnimation(keyPath: "position.y")
            m.byValue = 14
            m.duration = 0.7
            d.opacity = 0
            d.add(f, forKey: "f")
            d.add(m, forKey: "m")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { d.removeFromSuperlayer() }
        }
    }

    /// الكلمة تذوب لنجوم صغيرة تلف وتتجمع في نجمة
    private func spiralToStar() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.5) {
            self.word.alpha = 0
            self.sparkles.alpha = 0
            self.word.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        let c = starHome
        for i in 0..<34 {
            let dot = CALayer()
            let sz = CGFloat.random(in: 7...15)
            dot.contents = Self.starImage(UIColor(red: 1, green: CGFloat.random(in: 0.8...0.95), blue: 0.45, alpha: 1)).cgImage
            dot.bounds = CGRect(x: 0, y: 0, width: sz, height: sz)
            dot.position = c
            view.layer.insertSublayer(dot, below: rays.layer)
            let path = UIBezierPath()
            let phase = CGFloat(i) / 34 * .pi * 2
            let startX = c.x + CGFloat.random(in: -90...90)
            path.move(to: CGPoint(x: startX, y: c.y + CGFloat.random(in: -20...20)))
            for k in 1...40 {
                let t = CGFloat(k) / 40
                let r = (1 - t) * 90 + 4
                let a = phase + t * 1.7 * .pi * 2
                path.addLine(to: CGPoint(x: c.x + (startX - c.x) * (1 - t) * 0.3 + cos(a) * r, y: c.y + sin(a) * r * 0.35))
            }
            let move = CAKeyframeAnimation(keyPath: "position")
            move.path = path.cgPath
            move.calculationMode = .paced
            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 1, 1, 0]
            fade.keyTimes = [0, 0.1, 0.85, 1]
            let g = CAAnimationGroup()
            g.animations = [move, fade]
            g.duration = 1.0
            g.beginTime = CACurrentMediaTime() + Double(i) * 0.012
            g.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            g.fillMode = .forwards
            g.isRemovedOnCompletion = false
            dot.opacity = 0
            dot.add(g, forKey: "spiral")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dot.removeFromSuperlayer() }
        }
        after(0.95) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self.burst(at: c, count: 24, speed: 120)
            self.star.alpha = 1
            self.star.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.8,
                           options: [], animations: { self.star.transform = .identity })
        }
    }

    /// النجمة تكبر لين تغطي الشاشة، الأطفال يصغرون تحتها، وبعدين أشعة نور ذهبي
    private func growStar() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        star.layer.removeAnimation(forKey: "twinkle")
        star.layer.shadowRadius = 40
        burst(at: starHome, count: 40, speed: 220)
        view.insertSubview(star, belowSubview: pair)
        let w = view.bounds.width, h = view.bounds.height
        UIView.animate(withDuration: 1.1, delay: 0, options: [.curveEaseIn], animations: {
            self.star.center = CGPoint(x: w / 2, y: h * 0.48)
            self.star.transform = CGAffineTransform(scaleX: 10, y: 10)
            self.pair.transform = CGAffineTransform(translationX: 0, y: h * 0.1).scaledBy(x: 0.6, y: 0.6)
        })
        buildRays()
        UIView.animate(withDuration: 0.6, delay: 0.85, options: [.curveEaseIn], animations: {
            self.rays.alpha = 1
            self.pair.alpha = 0
        }, completion: { _ in
            self.after(0.35) { self.finish() }
        })
    }

    private func buildRays() {
        rays.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let b = view.bounds
        let glow = CAGradientLayer()
        glow.type = .radial
        glow.frame = b
        glow.colors = [UIColor(red: 1, green: 0.96, blue: 0.82, alpha: 1).cgColor,
                       UIColor(red: 1, green: 0.84, blue: 0.48, alpha: 1).cgColor,
                       UIColor(red: 0.93, green: 0.66, blue: 0.3, alpha: 1).cgColor]
        glow.locations = [0, 0.45, 1]
        glow.startPoint = CGPoint(x: 0.5, y: 0.45)
        glow.endPoint = CGPoint(x: 1.25, y: 1.1)
        rays.layer.addSublayer(glow)
        let c = CGPoint(x: b.midX, y: b.height * 0.45)
        let beams = CAShapeLayer()
        beams.frame = b
        let path = UIBezierPath()
        let r = max(b.width, b.height) * 1.2
        for i in 0..<16 {
            let a = CGFloat(i) / 16 * .pi * 2
            let spread: CGFloat = i % 2 == 0 ? 0.07 : 0.04
            path.move(to: c)
            path.addLine(to: CGPoint(x: c.x + cos(a - spread) * r, y: c.y + sin(a - spread) * r))
            path.addLine(to: CGPoint(x: c.x + cos(a + spread) * r, y: c.y + sin(a + spread) * r))
            path.close()
        }
        beams.path = path.cgPath
        beams.fillColor = UIColor(red: 1, green: 0.98, blue: 0.88, alpha: 0.35).cgColor
        rays.layer.addSublayer(beams)
    }

    /// نجوم صغيرة ذهبية تطير في كل اتجاه
    private func burst(at point: CGPoint, count: Int, speed: CGFloat) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.renderMode = .additive
        let colors = [UIColor(red: 1, green: 0.86, blue: 0.42, alpha: 1),
                      UIColor(red: 1, green: 0.95, blue: 0.75, alpha: 1),
                      UIColor(red: 0.98, green: 0.62, blue: 0.25, alpha: 1)]
        emitter.emitterCells = colors.map { color in
            let c = CAEmitterCell()
            c.contents = Self.starImage(color).cgImage
            c.birthRate = Float(count) / 0.12 / Float(colors.count)
            c.lifetime = 1.8
            c.lifetimeRange = 0.5
            c.velocity = speed
            c.velocityRange = speed * 0.5
            c.emissionRange = .pi * 2
            c.yAcceleration = 90
            c.spin = 2
            c.spinRange = 4
            c.scale = 0.45
            c.scaleRange = 0.25
            c.alphaSpeed = -0.5
            return c
        }
        view.layer.insertSublayer(emitter, below: rays.layer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { emitter.birthRate = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { emitter.removeFromSuperlayer() }
    }

    private static func starImage(_ color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { _ in
            let p = UIBezierPath()
            let c = CGPoint(x: 12, y: 12)
            for i in 0..<10 {
                let r: CGFloat = i % 2 == 0 ? 12 : 5
                let a = CGFloat(i) * .pi / 5 - .pi / 2
                let pt = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.close()
            color.setFill()
            p.fill()
        }
    }

    @objc private func skip() { finish() }

    private func finish() {
        guard !finished else { return }
        finished = true
        trailTimer?.invalidate()
        guard let nav = navigationController else { return }
        nav.view.layer.add(CATransition.fade, forKey: nil)
        nav.setViewControllers([GameStore.shared.nextScreenAfterSplash()], animated: false)
    }
}
