import SwiftUI

#if os(watchOS)
import WatchKit

@main
struct BioSyncApp: App {
    @WKApplicationDelegateAdaptor(ExtensionDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                BioSyncNotificationManager.shared.configure()
            } else if newPhase == .background {
                BackgroundManager.shared.scheduleNextBackgroundRefresh()
            }
        }
    }
}

class ExtensionDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        BioSyncNotificationManager.shared.configure()
        BackgroundManager.shared.scheduleNextBackgroundRefresh()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                Task {
                    await BackgroundManager.shared.handleBackgroundTask(refreshTask)
                }
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
#endif

#if os(iOS)
import UIKit

@main
struct BioSyncPhoneApp: App {
    @UIApplicationDelegateAdaptor(PhoneAppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            PhoneContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                BioSyncNotificationManager.shared.configure()
            }
        }
    }
}

class PhoneAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        BioSyncNotificationManager.shared.configure()
        _ = WatchConnectivityManager.shared
        return true
    }
}
#endif
