//
//  WardrobeViewController.swift
//  نمق
//
//  الدولاب 🎁 — شاشة كاملة مرسومة كدولاب خشب:
//  فوق لوحة العنوان والنقاط، بالنص الشخصية واقفة على السجادة لابسة ملابسها،
//  وتحت فلتر الأصناف والرفوف. الرفوف صفحات: تسحبين يمين ويسار عشان تشوفين باقي الملابس.
//

import UIKit

final class WardrobeViewController: PanelViewController, UIScrollViewDelegate {
    private var filter: OutfitSlot? = nil
    private let stage = UIImageView(image: UIImage(named: "namq_wardrobe_stage"))
    private let character = RoomObjectView(imageName: "namq_boy_canvas", fallbackSymbol: "figure.stand", label: "")
    private let caption = ChipLabel()
    private let chips = UIScrollView()
    private let chipRow = UIStackView()
    private let shelf = UIImageView(image: UIImage(named: "namq_wardrobe_shelf"))
    private let pages = UIScrollView()
    private let pageDots = UIPageControl()
    private var pageViews: [UIView] = []

    private static let perPage = 9
    private static let slots: [(OutfitSlot?, String)] = [
        (nil, "الكل"), (.hat, "قبعات"), (.glasses, "نظارات"), (.shirt, "تيشيرتات"), (.pants, "بناطيل")
    ]

    init() {
        super.init(title: "الدولاب", subtitle: nil, icon: "cabinet.fill")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildContent() {
        // فوق: الشخصية واقفة على السجادة في غرفة الدولاب
        stage.contentMode = .scaleToFill
        stage.layer.cornerRadius = 18
        stage.clipsToBounds = true
        character.isUserInteractionEnabled = false
        caption.font = Theme.font(13, .bold)
        caption.textColor = Theme.creamLight
        caption.textAlignment = .center
        caption.backgroundColor = UIColor(red: 0.2, green: 0.1, blue: 0.04, alpha: 0.82)
        caption.insets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        caption.clipsToBounds = true
        chips.showsHorizontalScrollIndicator = false
        chipRow.spacing = 8
        chips.addSubview(chipRow)
        // تحت: الرفوف صفحات
        shelf.contentMode = .scaleToFill
        shelf.isUserInteractionEnabled = true
        pages.isPagingEnabled = true
        pages.showsHorizontalScrollIndicator = false
        pages.delegate = self
        pages.semanticContentAttribute = .forceLeftToRight
        shelf.addSubview(pages)
        pageDots.currentPageIndicatorTintColor = Theme.gold
        pageDots.pageIndicatorTintColor = Theme.cream.withAlphaComponent(0.4)
        pageDots.isUserInteractionEnabled = false

        let scroll = WardrobeScrollView()
        scroll.onLayout = { [weak self] in self?.layoutWardrobe() }
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: contentView.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        [stage, character, caption, chips, shelf, pageDots].forEach { scroll.addSubview($0) }
        self.scroll = scroll
        reload()
    }
    private var scroll: UIScrollView?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutWardrobe()
    }

    private func layoutWardrobe() {
        guard let scroll else { return }
        let w = scroll.bounds.width
        guard w > 0 else { return }
        var y: CGFloat = 0
        let sh = w * 448 / 879
        stage.frame = CGRect(x: 0, y: y, width: w, height: sh)
        let ratio = character.imageView.image.map { $0.size.width / max($0.size.height, 1) } ?? 0.4
        let ch = sh * 0.73
        character.frame = CGRect(x: w / 2 - ch * ratio / 2, y: sh * 0.95 - ch, width: ch * ratio, height: ch)
        let cs = caption.intrinsicContentSize
        caption.frame = CGRect(x: (w - cs.width) / 2, y: sh - cs.height / 2, width: cs.width, height: cs.height)
        caption.layer.cornerRadius = cs.height / 2
        y = sh + cs.height / 2 + 12

        chips.frame = CGRect(x: 0, y: y, width: w, height: 38)
        let fit = chipRow.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        chipRow.frame = CGRect(x: max(0, w - fit.width), y: 0, width: fit.width, height: 38)
        chips.contentSize = CGSize(width: max(fit.width, w), height: 38)
        if fit.width > w, chips.contentOffset.x == 0 { chips.contentOffset = CGPoint(x: fit.width - w, y: 0) }
        y += 38 + 12

        let shH = w * 850 / 879
        shelf.frame = CGRect(x: 0, y: y, width: w, height: shH)
        // منطقة الرفوف داخل الصورة
        let inner = CGRect(x: w * 0.048, y: 0, width: w * 0.904, height: shH)
        pages.frame = inner
        let n = pageViews.count
        pages.contentSize = CGSize(width: inner.width * CGFloat(n), height: inner.height)
        for (i, pv) in pageViews.enumerated() {
            pv.frame = CGRect(x: inner.width * CGFloat(n - 1 - i), y: 0, width: inner.width, height: inner.height)   // الأولى يمين
            layoutPage(pv)
        }
        if n > 1, pages.contentOffset.x == 0, pageDots.currentPage == 0 {
            pages.contentOffset = CGPoint(x: inner.width * CGFloat(n - 1), y: 0)
        }
        y += shH + 4
        pageDots.frame = CGRect(x: 0, y: y, width: w, height: 22)
        y += 26
        scroll.contentSize = CGSize(width: w, height: y)
    }

    private func layoutPage(_ page: UIView) {
        let cols: [(CGFloat, CGFloat)] = [(0.667, 1), (0.333, 0.667), (0, 0.333)]   // من اليمين لليسار
        // كل صف: من سقف الخانة لين حافة الرف (نسبة من طول صورة الدولاب كاملة)
        let rows: [(CGFloat, CGFloat)] = [(0.09, 0.375), (0.378, 0.675), (0.686, 0.975)]   // كل قطعة واقفة على رفّها
        let w = page.bounds.width, h = page.bounds.height
        for (i, item) in page.subviews.enumerated() {
            let c = cols[i % 3], r = rows[i / 3]
            item.frame = CGRect(x: c.0 * w, y: r.0 * h, width: (c.1 - c.0) * w, height: (r.1 - r.0) * h)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === pages, pages.bounds.width > 0 else { return }
        let i = Int(round(pages.contentOffset.x / pages.bounds.width))
        pageDots.currentPage = max(0, pageViews.count - 1 - i)
    }

    override func reload() {
        guard let profile = store.profile else { return }
        subtitleLabel.text = "رصيدك \(Fmt.num(store.points)) نقطة ⭐"
        character.setImage(named: profile.gender.canvasImage, fallback: "namq_boy_canvas")
        character.dress(store.outfit, gender: profile.gender)
        caption.text = store.outfit.isEmpty ? g("افتح قطعة وشوفها على", "افتحي قطعة وشوفيها على") + " \(profile.characterName)"
                                            : "هذا شكل \(profile.characterName) الحين"

        chipRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (slot, title) in Self.slots {
            chipRow.addArrangedSubview(filterChip(title, selected: slot == filter) { [weak self] in
                self?.filter = slot
                self?.reload()
            })
        }

        pageViews.forEach { $0.removeFromSuperview() }
        let items = Reward.all.filter { filter == nil || $0.slot == filter }
        pageViews = stride(from: 0, to: max(items.count, 1), by: Self.perPage).map { start in
            let page = UIView()
            items[start..<min(start + Self.perPage, items.count)].forEach { page.addSubview(makeItem($0)) }
            pages.addSubview(page)
            return page
        }
        pageDots.numberOfPages = pageViews.count
        pageDots.isHidden = pageViews.count < 2
        pageDots.currentPage = 0
        pages.contentOffset = .zero
        view.setNeedsLayout()
        layoutWardrobe()
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> UIButton {
        UI.toggle(title, selected: selected, compact: true, action: action)
    }

    private func makeItem(_ reward: Reward) -> ShelfItemView {
        let status: RewardTile.Status = store.isEquipped(reward) ? .equipped
            : store.isUnlocked(reward) ? .owned : .locked
        let item = ShelfItemView(reward: reward, status: status, affordable: store.points >= reward.cost)
        item.addAction(UIAction { [weak self, weak item] _ in self?.tapped(reward, item: item) }, for: .touchUpInside)
        return item
    }

    private func tapped(_ reward: Reward, item: UIView?) {
        if store.isUnlocked(reward) {
            store.toggleEquip(reward)
            view.showToast(store.isEquipped(reward) ? "لبست \(reward.title) 😎" : "تم خلع \(reward.title)")
            return
        }
        let missing = reward.cost - store.points
        if missing > 0 {
            item?.shake()
            view.showToast(g("تحتاج", "تحتاجين") + " \(Fmt.num(missing)) نقطة إضافية — " + g("أنجز عاداتك! 💪", "أنجزي عاداتك! 💪"))
            return
        }
        let alert = WoodAlertViewController(title: g("تفتح", "تفتحين") + " «\(reward.title)»؟",
                                            message: "بيتخصم \(Fmt.num(reward.cost)) ⭐ من رصيدك",
                                            image: UIImage(named: reward.id), confirm: "افتحها") { [weak self] in
            guard let self else { return }
            if case .unlocked = self.store.buy(reward) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.view.showToast("🎉 فتحت \(reward.title)!")
            }
        }
        present(alert, animated: true)
    }
}

/// قطعة واقفة على الرف: الصورة + شارة السعر/البسها/لابسها على حافة الرف
final class ShelfItemView: UIControl {
    private let imageView = UIImageView()
    private let badge: ChipLabel

    init(reward: Reward, status: RewardTile.Status, affordable: Bool) {
        switch status {
        case .locked:   badge = UI.chip("⭐ \(Fmt.num(reward.cost))", color: affordable ? Theme.leaf : Theme.leaf.withAlphaComponent(0.75), filled: true)
        case .owned:    badge = UI.chip(g("البسها", "البسيها"), color: Theme.leaf, filled: true)
        case .equipped: badge = UI.chip(g("✓ لابسها", "✓ لابستها"), color: Theme.gold, filled: true)
        }
        super.init(frame: .zero)
        imageView.image = UIImage(named: reward.id) ?? UIImage(systemName: "tshirt.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.4
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        if status == .equipped {
            imageView.layer.shadowColor = Theme.gold.cgColor
            imageView.layer.shadowOpacity = 1
            imageView.layer.shadowRadius = 8
            imageView.layer.shadowOffset = .zero
        }
        badge.font = Theme.font(12, .heavy)
        badge.layer.borderWidth = 1.5
        badge.layer.borderColor = Theme.gold.withAlphaComponent(0.6).cgColor
        addSubview(imageView)
        addSubview(badge)
        if status == .locked {
            let lock = UI.symbol("lock.fill", color: Theme.creamLight, size: 13)
            lock.translatesAutoresizingMaskIntoConstraints = true
            lock.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
            lock.tag = 99
            addSubview(lock)
        }
        accessibilityLabel = reward.title
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width, h = bounds.height
        let b = badge.intrinsicContentSize
        badge.translatesAutoresizingMaskIntoConstraints = true
        badge.frame = CGRect(x: (w - b.width) / 2, y: h - b.height, width: b.width, height: b.height)
        badge.layer.cornerRadius = b.height / 2
        let box = CGSize(width: w * 0.78, height: h * 0.72)
        let img = imageView.image?.size ?? box
        let k = min(box.width / max(img.width, 1), box.height / max(img.height, 1))
        let fit = CGSize(width: img.width * k, height: img.height * k)
        // القطعة تقعد على سطح الرف، والسعر قدّامها على حافة الرف
        imageView.frame = CGRect(x: (w - fit.width) / 2, y: h * 0.85 - fit.height, width: fit.width, height: fit.height)
        bringSubviewToFront(badge)
        viewWithTag(99)?.center = CGPoint(x: w - 14, y: 14)
    }

    override var isHighlighted: Bool {
        didSet { UIView.animate(withDuration: 0.12) { self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity } }
    }
}

/// سكرول يبلّغ الدولاب كل ما تغيّر مقاسه — عشان الترتيب يتحسب بعد ما يعرف عرضه الحقيقي
final class WardrobeScrollView: UIScrollView {
    var onLayout: (() -> Void)?
    private var lastSize: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width != lastSize.width {
            lastSize = bounds.size
            onLayout?()
        }
    }
}
