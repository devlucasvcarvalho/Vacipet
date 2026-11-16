//
//  AppDelegate.swift
//  Vacipet
//
//  Configura o ciclo de vida do app (permissões, sessões de cena).
//  A UI em si vive no SceneDelegate.
//

import UIKit

// O AppDelegate cuida do processo do app; a SceneDelegate cuida de cada janela/cena.
// Como o projeto não usa storyboard, toda a construção de UI fica no SceneDelegate.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    // Informa ao sistema qual configuração de cena usar (definida no Info.plist,
    // apontando para SceneDelegate).
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }

}
