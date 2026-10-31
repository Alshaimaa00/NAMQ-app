//
//  Theme.swift
//  NAMQ
//
//  الألوان والخطوط والعناصر المشتركة — مأخوذة من هوية NAMQ (خشب + كريمي + أخضر).
//  أي تعديل على الشكل العام يصير من هنا فقط.
//

import UIKit

// MARK: - الألوان والخطوط

enum Theme {
    static let wood       = UIColor(red: 0.47, green: 0.30, blue: 0.14, alpha: 1)
    static let woodDark   = UIColor(red: 0.29, green: 0.18, blue: 0.08, alpha: 1)
    static let cream      = UIColor(red: 0.98, green: 0.88, blue: 0.71, alpha: 1)
    static let creamLight = UIColor(red: 0.99, green: 0.92, blue: 0.80, alpha: 1)   // كريمي دافي (بدون أبيض)
    static let leaf       = UIColor(red: 0.33, green: 0.46, blue: 0.27, alpha: 1)
    static let gold       = UIColor(red: 0.95, green: 0.73, blue: 0.24, alpha: 1)
    static let ink        = UIColor(red: 0.27, green: 0.17, blue: 0.08, alpha: 1)
    static let terracotta = UIColor(red: 0.72, green: 0.33, blue: 0.20, alpha: 1)
    static var muted: UIColor { ink.withAlphaComponent(0.62) }

    // ===== النظام الموحّد لكل الشاشات =====
    // الأزرار والتبويبات والفلاتر وزر الإغلاق: نفس كبسولة «ولد / بنت» (بني غامق + نص كريمي، والمختار نصه ذهبي)
    static let pillBg      = UIColor.black.withAlphaComponent(0.40)
    static let pillBgOn    = UIColor.black.withAlphaComponent(0.55)
    static let pillDanger  = UIColor(red: 0.95, green: 0.64, blue: 0.49, alpha: 1)
    // البطاقات اللي داخل اللوحات: ورقي دافي بدل الأبيض
    static let parchment   = UIColor(red: 0.96, green: 0.86, blue: 0.68, alpha: 1)
    // أحجام الخطوط: عنوان ٢٤ · زر/تبويب ١٦ · فلتر ١٤ · نص ١٥ · وصف ١٣ · صغير ١٢

    static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let rounded = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: rounded, size: size)
    }
}

extension HabitKind {
    var color: UIColor { self == .build ? Theme.leaf : Theme.terracotta }
}

// MARK: - صيغة الكلام (ولد / بنت)

/// إذا اختار المستخدم بنت نكلّمها بصيغة المؤنث، وإذا ولد بصيغة المذكر.
/// (قبل ما يختار — في الترحيب وتسجيل الدخول — نستخدم الصيغة العامة)
var isGirl: Bool { GameStore.shared.profile?.gender == .girl }

/// يرجع الكلمة/الجملة المناسبة: g("اكتب", "اكتبي")
func g(_ boy: String, _ girl: String) -> String { isGirl ? girl : boy }

enum Gendered {
    /// كلمات الأمر والمخاطبة اللي تتكرر في الخطط والنصائح — تتحوّل للمؤنث لو بنت
    private static let words: [(String, String)] = [
        ("ولا تشتريها", "ولا تشترينها"), ("زِد", "زيدي"), ("وخلّ", "وخلّي"), ("خلّ", "خلّي"),
        ("ثبّتها", "ثبّتيها"), ("ثبّت", "ثبّتي"), ("واستبدل", "واستبدلي"), ("استبدلها", "استبدليها"), ("استبدل", "استبدلي"),
        ("نام", "نامي"), ("واصحَ", "واصحي"), ("وابعد", "وابعدي"), ("ابعد", "ابعدي"), ("طفّ", "طفّي"),
        ("وحدّد", "وحدّدي"), ("وقلّل", "وقلّلي"), ("قلّلها", "قلّليها"), ("قلّل", "قلّلي"), ("وبدّلها", "وبدّليها"),
        ("سجّل", "سجّلي"), ("أجّل", "أجّلي"), ("جرّب", "جرّبي"), ("واطلب", "واطلبي"), ("تثق", "تثقين"),
        ("واستخدم", "واستخدمي"), ("واكتب", "واكتبي"), ("اكتب", "اكتبي"), ("وخلّص", "وخلّصي"), ("وراجع", "وراجعي"),
        ("ذاكرته", "ذاكرتيه"), ("وكافئ", "وكافئي"), ("كافئ", "كافئي"), ("لاحظ", "لاحظي"), ("تسويها", "تسوينها"),
        ("وجهّز", "وجهّزي"), ("جهّز", "جهّزي"), ("ابدأ", "ابدئي"), ("واربطها", "واربطيها"), ("اربط", "اربطي"),
        ("تسويه", "تسوينه"), ("وحافظ", "وحافظي"), ("تحبه", "تحبينه"), ("تقدر", "تقدرين"), ("تقول", "تقولين"),
        ("ارجع", "ارجعي"), ("تبيه", "تبينه"), ("تبي", "تبين"), ("تتركه", "تتركينه"), ("تجمعها", "تجمعينها"),
        ("تفتح", "تفتحين"), ("انتظر", "انتظري"), ("وسوّ", "وسوّي"), ("تجيك", "تجيك"), ("ممتن", "ممتنة")
    ]
    /// يحوّل النص لصيغة المؤنث (كلمة كاملة بس) لو المستخدم بنت
    static func text(_ s: String) -> String {
        guard isGirl else { return s }
        var out = s
        for (m, f) in words where m != f {
            let pattern = "(?<![\\p{L}\\p{M}])" + NSRegularExpression.escapedPattern(for: m) + "(?![\\p{L}\\p{M}])"
            out = out.replacingOccurrences(of: pattern, with: f, options: .regularExpression)
        }
        return out
    }
}

// MARK: - تنسيق الأرقام والأوقات

enum Fmt {
    /// غيّريها إلى "en" لو تبين الأرقام الإنجليزية (1، 2، 3) بدل العربية (١، ٢، ٣).
    static let locale = Locale(identifier: "ar")

    static func num(_ n: Int) -> String {
        let f = NumberFormatter()
        f.locale = locale
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    static func time(_ minutes: Int) -> String {
        let date = Calendar.current.date(bySettingHour: (minutes / 60) % 24, minute: minutes % 60, second: 0, of: Date()) ?? Date()
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    static func days(_ n: Int) -> String {
        switch n {
        case 1: return "يوم واحد"
        case 2: return "يومان"
        case 3...10: return "\(num(n)) أيام"
        default: return "\(num(n)) يومًا"
        }
    }

    /// ١ = الأحد … ٧ = السبت
    static let weekdayNames = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
    static let weekdayShort = ["ح", "ن", "ث", "ر", "خ", "ج", "س"]
    static func weekdayName(_ d: Int) -> String { weekdayNames[(d - 1 + 7) % 7] }

    static func hours(_ n: Int) -> String {
        switch n {
        case 1: return "كل ساعة"
        case 2: return "كل ساعتين"
        default: return "كل \(num(n)) ساعات"
        }
    }
}

// MARK: - مصنع العناصر

enum PillStyle { case primary, secondary, destructive }

enum UI {
    static func label(_ text: String? = nil, size: CGFloat, weight: UIFont.Weight = .regular,
                      color: UIColor = Theme.ink, lines: Int = 1, align: NSTextAlignment = .natural) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = Theme.font(size, weight)
        l.textColor = color
        l.numberOfLines = lines
        l.textAlignment = align
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    static func pill(_ title: String, icon: String? = nil, style: PillStyle = .primary,
                     action: @escaping () -> Void) -> UIButton {
        var c = UIButton.Configuration.filled()
        c.cornerStyle = .capsule
        switch style {
        case .primary:
            c.baseBackgroundColor = Theme.leaf
            c.baseForegroundColor = Theme.creamLight
        case .secondary:
            c.baseBackgroundColor = Theme.pillBg
            c.baseForegroundColor = Theme.creamLight
        case .destructive:
            c.baseBackgroundColor = Theme.pillBg
            c.baseForegroundColor = Theme.pillDanger
        }
        c.title = title
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.font(17, .bold)
            return out
        }
        if let icon {
            c.image = UIImage(systemName: icon)
            c.imagePlacement = .trailing   // الأيقونة بعد النص (على اليسار)
            c.imagePadding = 8
            c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        }
        c.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 22, bottom: 14, trailing: 22)
        let b = UIButton(configuration: c, primaryAction: UIAction { _ in action() })
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    static func textField(_ placeholder: String) -> UITextField {
        let tf = PaddedTextField()
        // نفس خانة الاسم في صفحة اختيار الشخصية: غامقة بإطار ذهبي خفيف ونص كريمي
        tf.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                      attributes: [.foregroundColor: Theme.creamLight.withAlphaComponent(0.5)])
        tf.font = Theme.font(17, .medium)
        tf.textColor = Theme.creamLight
        tf.tintColor = Theme.gold
        tf.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        tf.layer.cornerRadius = 26
        tf.layer.cornerCurve = .continuous
        tf.layer.borderWidth = 1.5
        tf.layer.borderColor = Theme.gold.withAlphaComponent(0.45).cgColor
        tf.textAlignment = .natural
        tf.clearButtonMode = .whileEditing
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return tf
    }

    /// دائرة ملونة فيها أيقونة
    static func iconBadge(_ symbol: String, color: UIColor, size: CGFloat) -> UIView {
        let v = UIView()
        v.backgroundColor = color
        v.layer.cornerRadius = size / 2
        v.translatesAutoresizingMaskIntoConstraints = false
        let iv = UIImageView(image: UIImage(systemName: symbol) ?? UIImage(systemName: "star.fill"))
        iv.tintColor = Theme.creamLight
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: size * 0.42, weight: .semibold)
        iv.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(iv)
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: size),
            v.heightAnchor.constraint(equalToConstant: size),
            iv.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        v.setContentHuggingPriority(.required, for: .horizontal)
        return v
    }

    static func symbol(_ name: String, color: UIColor, size: CGFloat = 28) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: name))
        iv.tintColor = color
        iv.contentMode = .scaleAspectFit
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        return iv
    }

    static func chip(_ text: String, color: UIColor, filled: Bool = false) -> ChipLabel {
        let c = ChipLabel()
        c.text = text
        c.font = Theme.font(12, .bold)
        c.textColor = filled ? Theme.creamLight : color
        c.backgroundColor = filled ? color : color.withAlphaComponent(0.14)
        c.textAlignment = .center
        c.layer.cornerRadius = 11
        c.layer.cornerCurve = .continuous
        c.clipsToBounds = true
        c.translatesAutoresizingMaskIntoConstraints = false
        c.setContentHuggingPriority(.required, for: .horizontal)
        c.setContentCompressionResistancePriority(.required, for: .horizontal)
        return c
    }

    static func sectionHeader(_ text: String) -> UILabel {
        label(text, size: 15, weight: .heavy, color: Theme.creamLight)
    }

    static func segmented(_ items: [String]) -> UISegmentedControl {
        let s = UISegmentedControl(items: items)
        s.selectedSegmentTintColor = Theme.pillBgOn
        s.backgroundColor = Theme.pillBg
        s.setTitleTextAttributes([.font: Theme.font(14, .heavy), .foregroundColor: Theme.gold], for: .selected)
        s.setTitleTextAttributes([.font: Theme.font(14, .bold), .foregroundColor: Theme.creamLight], for: .normal)
        s.translatesAutoresizingMaskIntoConstraints = false
        s.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return s
    }

    /// تبويب / فلتر بنفس كبسولة «ولد / بنت» — compact للفلاتر الصغيرة
    static func toggle(_ title: String, selected: Bool, compact: Bool = false,
                       action: @escaping () -> Void) -> UIButton {
        var c = UIButton.Configuration.filled()
        c.title = title
        c.cornerStyle = .capsule
        c.baseBackgroundColor = selected ? Theme.pillBgOn : Theme.pillBg
        c.baseForegroundColor = selected ? Theme.gold : Theme.creamLight
        c.contentInsets = compact ? NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                                  : NSDirectionalEdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10)
        let size: CGFloat = compact ? 14 : 16
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.font(size, .heavy)
            return out
        }
        if compact && selected {
            // الفلتر المختار: إطار ذهبي خفيف
            c.background.strokeColor = Theme.gold.withAlphaComponent(0.8)
            c.background.strokeWidth = 1.5
        }
        return UIButton(configuration: c, primaryAction: UIAction { _ in
            UISelectionFeedbackGenerator().selectionChanged()
            action()
        })
    }

    /// زر الإغلاق: دائرة غامقة بنفس لون الكبسولات
    static func closeButton(action: @escaping () -> Void) -> UIButton {
        var c = UIButton.Configuration.filled()
        c.image = UIImage(systemName: "xmark")
        c.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .heavy)
        c.baseBackgroundColor = Theme.pillBg
        c.baseForegroundColor = Theme.creamLight
        c.cornerStyle = .capsule
        c.contentInsets = .zero
        let b = UIButton(configuration: c, primaryAction: UIAction { _ in action() })
        b.accessibilityLabel = "إغلاق"
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(equalToConstant: 36).isActive = true
        b.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return b
    }
}

// MARK: - عناصر صغيرة مشتركة

/// بطاقة كريمية بإطار خشبي — أساس كل النوافذ في التطبيق
final class CardView: UIView {
    init(color: UIColor = Theme.cream, radius: CGFloat = 28, border: CGFloat = 3) {
        super.init(frame: .zero)
        backgroundColor = color
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        layer.borderWidth = border
        layer.borderColor = Theme.wood.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 8)
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class ChipLabel: UILabel {
    var insets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right, height: s.height + insets.top + insets.bottom)
    }
}

final class PaddedTextField: UITextField {
    private let inset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: inset) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: inset) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: inset) }
}

// MARK: - رسائل منبثقة وحركات

extension UIView {
    /// رسالة قصيرة تطلع تحت الشاشة وتختفي لحالها
    func showToast(_ text: String) {
        let card = CardView(color: Theme.woodDark, radius: 22, border: 0)
        let label = UI.label(text, size: 16, weight: .bold, color: Theme.creamLight, lines: 0, align: .center)
        card.addSubview(label)
        addSubview(card)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),
            card.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -48)
        ])
        card.alpha = 0
        card.transform = CGAffineTransform(translationX: 0, y: 24)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
                       options: [], animations: {
            card.alpha = 1
            card.transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.8, options: [], animations: {
                card.alpha = 0
            }, completion: { _ in card.removeFromSuperview() })
        })
    }

    func shake() {
        let a = CAKeyframeAnimation(keyPath: "transform.translation.x")
        a.values = [-10, 10, -8, 8, -4, 4, 0]
        a.duration = 0.4
        layer.add(a, forKey: "shake")
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func pop() {
        transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8,
                       options: [.allowUserInteraction], animations: { self.transform = .identity })
    }
}

extension CATransition {
    static var fade: CATransition {
        let t = CATransition()
        t.type = .fade
        t.duration = 0.35
        return t
    }
}
