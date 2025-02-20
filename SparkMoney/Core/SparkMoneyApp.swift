//
//  FinanceApp.swift
//  Finance
//
//  Created by Oliver Tran on 2/16/25.
//

import SwiftUI
import Firebase

@main
struct SparkMoneyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate : NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        print("Configured Firebase")
        
        return true
    }
}
