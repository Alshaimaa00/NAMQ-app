//
//  AppDelegate.swift
//  NAMQ
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // التطبيق عربي: كل الواجهة من اليمين لليسار
        UIView.appearance().semanticContentAttribute = .forceRightToLeft
        UNUserNotificationCenter.current().delegate = self

        // السبلاش أول شي، وبعده: تسجيل الدخول ← إنشاء الشخصية ← الغرفة
        // (لو المستخدم سجّل وأنشأ شخصيته قبل، يروح للغرفة مباشرة بعد السبلاش)
        let nav = UINavigationController(rootViewController: SplashViewController())
        nav.setNavigationBarHidden(true, animated: false)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        return true
    }

    // الغرفة مصممة بالطول
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }

    // يظهر التذكير حتى لو التطبيق مفتوح (مفيد أثناء العرض)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
