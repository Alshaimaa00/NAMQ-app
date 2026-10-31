//
//  Coach.swift
//  NAMQ
//
//  عقل "مساعد نمق" — فكرته وحدة: المستخدم يعطيه هدف يبي يحققه،
//  والمساعد يبني له مجموعة عادات توصله لهذا الهدف (كل عادة تبدأ صغيرة وتكبر أسبوع بأسبوع).
//
//  على الأجهزة اللي فيها Apple Intelligence (iOS 26+) يستخدم الذكاء الاصطناعي اللي داخل الجهاز
//  لصياغة الخطة. وإذا ما كان متوفر، يستخدم خطط جاهزة مبنية على الهدف — فالتطبيق يشتغل دايمًا.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct CoachPlan {
    var title: String
    var kind: HabitKind
    var icon: String
    var startMinute: Int
    var everyHours: Int
    var steps: [String]
    var poweredByAI = false

    func makeHabit() -> Habit {
        var h = Habit(title: title, note: steps.first ?? "", icon: icon, kind: kind,
                      startMinute: startMinute, everyHours: everyHours)
        h.plan = steps
        h.planStart = Date()
        return h
    }
}

/// خطة هدف كامل: الهدف + العادات اللي تحققه
struct GoalPlan {
    var goal: String
    var habits: [CoachPlan]
    var poweredByAI = false

    func makeHabits() -> [Habit] {
        habits.map { p in
            var h = p.makeHabit()
            h.goal = goal
            return h
        }
    }
}

enum Coach {

    // MARK: - هدف ← عادات

    /// أهداف كبيرة معروفة، وكل هدف له العادات (القوالب) اللي تحققه
    private static let goalMap: [(keywords: [String], habits: [String])] = [
        (["صح", "صحي", "صحة", "صحه", "وزن", "انحف", "أنحف", "رشاقة", "رشاقه", "جسم", "لياقة", "لياقه", "نشاط", "نشيط"],
         ["شرب الماء", "الحركة اليومية", "تقليل السكر"]),
        (["دراس", "تفوق", "أتفوق", "اتفوق", "اختبار", "معدل", "جامعة", "جامعه", "مدرسة", "مدرسه", "ذاكر"],
         ["المذاكرة", "النوم بدري", "تقليل الجوال"]),
        (["تركيز", "انتاج", "إنتاج", "وقت", "منظم", "تنظيم", "كسل", "نشاط"],
         ["تقليل الجوال", "النوم بدري", "القراءة"]),
        (["نوم", "انام", "أنام", "سهر", "تعب", "اصحى", "أصحى"],
         ["النوم بدري", "تقليل الجوال", "الحركة اليومية"]),
        (["هدوء", "راحة", "راحه", "توتر", "قلق", "سعادة", "سعاده", "نفسيت", "مزاج"],
         ["الحركة اليومية", "القراءة", "تقليل الجوال"]),
        (["قرآن", "قران", "روح", "دين", "عباد", "ورد"],
         ["الورد اليومي", "النوم بدري", "تقليل الجوال"]),
        (["ثقاف", "معرف", "اتعلم", "أتعلم", "تعلم", "قراءة", "قراءه", "كتب"],
         ["القراءة", "تقليل الجوال", "النوم بدري"])
    ]

    /// يبني عادات توصل المستخدم لهدفه (الذكاء الاصطناعي على الجهاز لو متوفر، وإلا قوالب جاهزة)
    static func buildGoalPlan(for goal: String) async -> GoalPlan {
        let cleaned = cleanGoal(goal)
        var plan = templateGoalPlan(for: goal, cleaned: cleaned)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), let habits = try? await aiHabits(goal: cleaned) {
            plan.habits = habits
            plan.poweredByAI = true
        }
        #endif
        return plan
    }

    private static func cleanGoal(_ goal: String) -> String {
        var t = " " + goal.trimmingCharacters(in: .whitespacesAndNewlines) + " "
        for w in fillerWords { t = t.replacingOccurrences(of: " " + w + " ", with: " ") }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".!؟?")))
        if t.isEmpty { t = goal }
        return t.count > 40 ? String(t.prefix(40)) : t
    }

    private static func plan(named title: String) -> CoachPlan? {
        templates.first { $0.title == title }.map {
            CoachPlan(title: $0.title, kind: $0.kind, icon: $0.icon, startMinute: $0.startMinute,
                      everyHours: $0.everyHours, steps: $0.steps)
        }
    }

    static func templateGoalPlan(for goal: String, cleaned: String) -> GoalPlan {
        let text = goal
        var names: [String] = []
        // ١) هدف كبير معروف
        if let g = goalMap.first(where: { $0.keywords.contains { text.contains($0) } }) {
            names = g.habits
        }
        // ٢) لو ذكر عادة معيّنة بكلامه نحطها أول وحدة
        let single = templatePlan(for: goal)
        if templates.contains(where: { $0.title == single.title }) {
            names.removeAll { $0 == single.title }
            names.insert(single.title, at: 0)
        }
        var habits = names.prefix(3).compactMap { plan(named: $0) }
        // ٣) هدف جديد ما نعرفه: عادة مبنية على كلامه + عادتين تساعد أي هدف
        if habits.isEmpty {
            habits = [single] + ["النوم بدري", "تقليل الجوال"].compactMap { plan(named: $0) }
        }
        if habits.count < 3 {
            for extra in ["النوم بدري", "شرب الماء", "تقليل الجوال"] where habits.count < 3 && !habits.contains(where: { $0.title == extra }) {
                if let p = plan(named: extra) { habits.append(p) }
            }
        }
        return GoalPlan(goal: cleaned, habits: habits)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func aiHabits(goal: String) async throws -> [CoachPlan]? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let session = LanguageModelSession(instructions: """
        أنت مدرّب عادات لطيف في تطبيق اسمه نمق. تكتب بالعربي البسيط. \(isGirl ? "المستخدمة بنت، خاطبها بصيغة المؤنث." : "المستخدم ولد، خاطبه بصيغة المذكر.")
        المستخدم يعطيك هدف، وأنت تقترح ٣ عادات يومية صغيرة توصله لهذا الهدف.
        اكتب كل عادة في سطر بهذا الشكل بالضبط:
        اسم العادة | خطوة أسبوع ١ | خطوة أسبوع ٢ | خطوة أسبوع ٣ | خطوة أسبوع ٤
        اسم العادة كلمتين أو ثلاث، وكل خطوة جملة قصيرة تبدأ سهلة وتكبر. بدون ترقيم وبدون مقدمة.
        لا تعطي نصائح طبية أو أرقام أكل أو أوزان.
        """)
        let response = try await session.respond(to: "الهدف: \(goal)")
        var out: [CoachPlan] = []
        for line in response.content.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "|").map {
                $0.trimmingCharacters(in: CharacterSet(charactersIn: " -•*0123456789٠١٢٣٤٥٦٧٨٩.)(:"))
            }.filter { !$0.isEmpty }
            guard parts.count >= 3 else { continue }
            let base = templatePlan(for: parts[0])   // نستعير الأيقونة والوقت لو العادة معروفة
            out.append(CoachPlan(title: String(parts[0].prefix(24)), kind: base.kind, icon: base.icon,
                                 startMinute: base.startMinute, everyHours: base.everyHours,
                                 steps: Array(parts.dropFirst().prefix(4)), poweredByAI: true))
        }
        return out.count >= 2 ? Array(out.prefix(3)) : nil
    }
    #endif

    // MARK: - بناء الخطة

    static func buildPlan(for goal: String) async -> CoachPlan {
        var plan = templatePlan(for: goal)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), let steps = try? await aiSteps(goal: goal, kind: plan.kind) {
            plan.steps = steps
            plan.poweredByAI = true
        }
        #endif
        return plan
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func aiSteps(goal: String, kind: HabitKind) async throws -> [String]? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let session = LanguageModelSession(instructions: """
        أنت مدرّب عادات لطيف في تطبيق اسمه نمق. تكتب بالعربي البسيط. \(isGirl ? "المستخدمة بنت، خاطبها بصيغة المؤنث." : "المستخدم ولد، خاطبه بصيغة المذكر.")
        تبني خطة من ٤ خطوات، كل خطوة لمدة أسبوع، تبدأ صغيرة وسهلة وتكبر تدريجيًا.
        اكتب كل خطوة في سطر لوحدها، جملة قصيرة وعملية (أقل من ١٢ كلمة)، بدون ترقيم وبدون مقدمة.
        لا تعطي نصائح طبية أو أرقام أكل أو أوزان.
        """)
        let prompt = kind == .quit
            ? "الهدف: أترك أو أقلل هذي العادة: \(goal). اكتب ٤ خطوات تدريجية."
            : "الهدف: \(goal). اكتب ٤ خطوات تدريجية."
        let response = try await session.respond(to: prompt)
        let lines = response.content
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " -•*0123456789٠١٢٣٤٥٦٧٨٩.)(:")) }
            .filter { !$0.isEmpty }
        return lines.count >= 3 ? Array(lines.prefix(4)) : nil
    }
    #endif

    // MARK: - خطط جاهزة (تشتغل بدون إنترنت وعلى كل الأجهزة)

    private struct Template {
        let keywords: [String]
        let title: String
        let kind: HabitKind
        let icon: String
        let startMinute: Int
        let everyHours: Int
        let steps: [String]
    }

    private static let templates: [Template] = [
        Template(keywords: ["ماء", "مويه", "موية", "موي", "اشرب", "أشرب"], title: "شرب الماء", kind: .build,
                 icon: "drop.fill", startMinute: 9 * 60, everyHours: 2, steps: [
                    "٤ أكواب يوميًا: كوب الصبح وكوب مع كل وجبة",
                    "٦ أكواب: زِد كوب بين الوجبات",
                    "٨ أكواب: خلّ قارورة ماء جنبك طول اليوم",
                    "ثبّت ٨ أكواب، واستبدل مشروب سكري واحد بالماء"]),
        Template(keywords: ["نوم", "انام", "أنام", "سهر", "اصحى", "أصحى"], title: "النوم بدري", kind: .build,
                 icon: "moon.zzz.fill", startMinute: 22 * 60, everyHours: 0, steps: [
                    "نام أبكر بربع ساعة، واصحَ بنفس الوقت كل يوم",
                    "ابعد الجوال قبل النوم بنص ساعة",
                    "نام أبكر بنص ساعة عن عادتك القديمة",
                    "ثبّت ٧ إلى ٨ ساعات نوم كل ليلة"]),
        Template(keywords: ["جوال", "جوالي", "سوشال", "تيك", "سناب", "انستا", "شاشة", "شاشه", "يوتيوب"],
                 title: "تقليل الجوال", kind: .quit, icon: "iphone.slash", startMinute: 21 * 60, everyHours: 0, steps: [
                    "طفّ الإشعارات اللي مو مهمة، وحدّد وقت الشاشة ٣ ساعات",
                    "ساعتين ونص، والجوال برا غرفة النوم",
                    "ساعتين، وأول ساعة بعد الصحيان بدون جوال",
                    "ساعة ونص، واستبدل التصفح بشي تحبه"]),
        Template(keywords: ["سكر", "حلا", "حلويات", "شوكولا", "غاز", "غازي", "غازية", "بيبسي", "مشروبات"],
                 title: "تقليل السكر", kind: .quit, icon: "takeoutbag.and.cup.and.straw.fill", startMinute: 15 * 60, everyHours: 0, steps: [
                    "قلّل الكمية للنص، ولا تشتريها للبيت",
                    "يوم إيه ويوم لا",
                    "مرتين بالأسبوع بس، وبدّلها بفاكهة",
                    "مرة بالأسبوع كمكافأة لنفسك"]),
        Template(keywords: ["دخان", "تدخين", "سيجار", "سجاير", "شيشة", "شيشه", "فيب"], title: "ترك التدخين", kind: .quit,
                 icon: "nosign", startMinute: 10 * 60, everyHours: 0, steps: [
                    "سجّل كل مرة، وقلّل مرة وحدة يوميًا",
                    "أجّل أول مرة بالصبح ساعة كاملة",
                    "نص الكمية، وابعد عن المواقف اللي تذكّرك فيه",
                    "جرّب يوم كامل بدونه، واطلب دعم من أحد تثق فيه"]),
        Template(keywords: ["مشي", "امشي", "أمشي", "رياضة", "رياضه", "تمارين", "تمرين", "جيم", "لياقة", "لياقه"],
                 title: "الحركة اليومية", kind: .build, icon: "figure.walk", startMinute: 17 * 60, everyHours: 0, steps: [
                    "١٠ دقائق مشي يوميًا",
                    "٢٠ دقيقة، واستخدم الدرج بدل المصعد",
                    "٣٠ دقيقة مشي، أو تمرين خفيف في البيت",
                    "٤٥ دقيقة، أو ٣ أيام تمارين بالأسبوع"]),
        Template(keywords: ["قراءة", "قراءه", "اقرأ", "أقرأ", "اقرا", "كتاب", "كتب"], title: "القراءة", kind: .build,
                 icon: "book.fill", startMinute: 21 * 60, everyHours: 0, steps: [
                    "٥ صفحات قبل النوم",
                    "١٠ صفحات، وخلّ الكتاب جنب سريرك",
                    "١٥ صفحة، واكتب جملة عجبتك",
                    "٢٠ صفحة، وخلّص أول كتاب لك 🎉"]),
        Template(keywords: ["مذاكرة", "مذاكره", "ذاكر", "أذاكر", "دراسة", "دراسه", "اختبار", "اختبارات"],
                 title: "المذاكرة", kind: .build, icon: "graduationcap.fill", startMinute: 17 * 60, everyHours: 0, steps: [
                    "٢٥ دقيقة تركيز يوميًا والجوال بعيد",
                    "جلستين ٢٥ دقيقة، وبينهم ٥ دقائق راحة",
                    "٣ جلسات، وراجع اللي ذاكرته أمس",
                    "خطة أسبوعية، وكافئ نفسك آخر الأسبوع"]),
        Template(keywords: ["قرآن", "قران", "ورد", "تلاوة", "حفظ"], title: "الورد اليومي", kind: .build,
                 icon: "book.closed.fill", startMinute: 6 * 60, everyHours: 0, steps: [
                    "صفحة وحدة يوميًا بعد الفجر",
                    "صفحتين يوميًا",
                    "٣ صفحات، ومراجعة اللي قريته",
                    "ثبّت ورد يومي يناسبك"])
    ]

    private static let quitWords = ["اترك", "أترك", "ابطل", "أبطل", "اوقف", "أوقف", "اقلل", "أقلل", "اقلّل", "أقلّل", "بطّل", "وقف", "ترك"]
    private static let fillerWords = ["ابي", "أبي", "ابغى", "أبغى", "ابغا", "أبغا", "اريد", "أريد", "ودي", "نفسي", "ان", "أن"]

    static func templatePlan(for goal: String) -> CoachPlan {
        let text = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        let isQuit = quitWords.contains { text.contains($0) }
        // لو الجملة فيها أكثر من موضوع (مثل: أترك الجوال قبل النوم) نفضّل اللي يناسب نية الترك أو البناء
        let matches = templates.filter { t in t.keywords.contains { text.contains($0) } }
        if let t = matches.first(where: { $0.kind == (isQuit ? .quit : .build) }) ?? matches.first {
            return CoachPlan(title: t.title, kind: t.kind, icon: t.icon, startMinute: t.startMinute,
                             everyHours: t.everyHours, steps: t.steps)
        }
        // هدف جديد ما عندنا له قالب: نبني خطة عامة تدريجية
        var title = text
        for w in fillerWords + quitWords {
            title = title.replacingOccurrences(of: w + " ", with: "")
        }
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty { title = isQuit ? "عادة أتركها" : "عادتي الجديدة" }
        if title.count > 24 { title = String(title.prefix(24)) }
        let steps = isQuit ? [
            "لاحظ متى تسويها ووش اللي يحفّزك لها",
            "قلّلها للنص، وجهّز بديل بسيط",
            "خلّ يومين بالأسبوع بدونها",
            "أسبوع كامل بدونها، وكافئ نفسك من الدولاب 🎁"
        ] : [
            "ابدأ صغير: ٥ دقائق يوميًا بنفس الوقت",
            "١٠ دقائق، واربطها بعادة تسويها كل يوم",
            "١٥ دقيقة، وحافظ على سلسلتك 🔥",
            "ثبّتها كجزء من يومك، وكافئ نفسك"
        ]
        return CoachPlan(title: title, kind: isQuit ? .quit : .build, icon: isQuit ? "nosign" : "leaf.fill",
                         startMinute: 18 * 60, everyHours: 0, steps: steps)
    }

    // MARK: - ملاحظات على تقدّم المستخدم

    static func insights(_ store: GameStore) -> [String] {
        let habits = store.habits
        guard !habits.isEmpty else {
            return ["طاولتك فاضية للحين. " + g("قلّي", "قوليلي") + " وش الهدف اللي ودّك توصل له، وأبني لك خطة خطوة بخطوة 👇"]
        }
        var out: [String] = []
        let p = store.todayProgress
        if p.done == p.total {
            out.append(g("أنجزت كل عادات اليوم 🎉 فخور فيك!", "أنجزتِ كل عادات اليوم 🎉 فخورة فيك!"))
        } else {
            out.append("اليوم أنجزت \(Fmt.num(p.done)) من \(Fmt.num(p.total)). باقي \(Fmt.num(p.total - p.done)) " + g("وتختم يومك 💪", "وتختمين يومك 💪"))
        }

        if let best = habits.max(by: { store.streak($0) < store.streak($1) }), store.streak(best) >= 2 {
            out.append("🔥 «\(best.title)» صار لها \(Fmt.days(store.streak(best))) ورا بعض. " + g("لا تكسر السلسلة!", "لا تكسرين السلسلة!"))
        }

        let yesterday = Day.key(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if let missed = habits.first(where: { !$0.completedDays.contains(yesterday) && !store.isDoneToday($0) && !$0.completedDays.isEmpty }) {
            out.append("«\(missed.title)» فاتتك أمس، عادي يصير 🤍 " + g("المهم ترجع لها اليوم. لو وقتها ما يناسبك، غيّره من الطاولة.", "المهم ترجعين لها اليوم. لو وقتها ما يناسبك، غيّريه من الطاولة."))
        }

        if let next = store.nextLevel {
            out.append("باقي لك \(Fmt.num(next.minXP - store.xp)) نقطة و" + g("توصل", "توصلين") + " لمستوى «\(next.title)» ⭐")
        } else {
            out.append("وصلت أعلى مستوى: «\(store.level.title)» 👑")
        }
        return out
    }

    static func tip(for store: GameStore) -> String {
        let general = [
            "اربط العادة الجديدة بشي تسويه كل يوم، مثل: بعد ما أشرب قهوتي أقرأ ٥ صفحات ☕️📖",
            "ابدأ صغير لدرجة إنك ما تقدر تقول لا. الاستمرار أهم من الكمية 🌱",
            "لو فاتك يوم، لا يفوتك يومين. ارجع على طول 💪",
            "جهّز بيئتك: خلّ الشي اللي تبيه قدام عينك، والشي اللي تبي تتركه بعيد 👀",
            "كافئ نفسك! النقاط اللي تجمعها تقدر تفتح فيها ملابس من الدولاب 🎁"
        ]
        let quitTips = ["لما تجيك الرغبة، انتظر ١٠ دقائق وسوّ شي ثاني. غالبًا بتروح ⏳"]
        let pool = store.habits.contains { $0.kind == .quit } ? general + quitTips : general
        return Gendered.text(pool.randomElement() ?? general[0])
    }
}
