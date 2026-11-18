//
//  SceneDelegate.swift
//  Vacipet
//
//  Ponto de entrada da cena: cria a window, o container do SwiftData
//  e define a navegação raiz (UINavigationController com a lista de pets).
//

import UIKit
import SwiftData

// O SceneDelegate é chamado pelo UIKit quando a cena (janela) do app é criada.
// É aqui — e não no storyboard — que montamos a interface programaticamente.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    // MARK: Propriedades
    
    // O ModelContainer precisa ficar VIVO enquanto o app estiver aberto.
    // O ModelContext não é dono do container — se a única referência
    // sair de escopo, a primeira busca no banco trappeia (crash).
    // Por isso ele é guardado aqui, na vida inteira do SceneDelegate.
    private var container: ModelContainer?
    
    // MARK: Ciclo de vida da cena
    
    // Chamado uma única vez, quando a cena está para se conectar ao app.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Garante que a cena é uma UIWindowScene (tela do dispositivo).
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // A window é a raiz da hierarquia de views; sem storyboard, criamos manualmente.
        let window = UIWindow(windowScene: windowScene)
        // tintColor global: qualquer UIButton/controle sem tint próprio usa AppColors.primary.
        window.tintColor = AppColors.primary
        
        do {
            // Cria o ModelContainer do SwiftData: ele define o schema (Pet e Vacina)
            // e aponta para o arquivo SQLite em disco (padrão do framework).
            // Falhar aqui significa que o schema mudou de forma incompatível
            // ou o disco está com problema — por isso há um fallback abaixo.
            let container = try ModelContainer(for: Pet.self, Vacina.self)
            self.container = container // mantém o container vivo (veja acima)
            
            // A raiz da navegação é a lista de pets. O ModelContext
            // (a "sessão" de leitura/escrita do SwiftData) é injetado
            // manualmente — é assim que fazemos dependency injection em UIKit.
            let listVC = PetListViewController(modelContext: container.mainContext)
            let navigation = UINavigationController(rootViewController: listVC)
            // >>> A DECISÃO <<<
            // UserDefaults funciona como um dicionário persistente por usuário/app.
            let jaViuOnboarding = UserDefaults.standard.bool(forKey: "onboardingConcluido")
            
            if jaViuOnboarding {
                // Já viu: segue o jogo, igual a antes.
                window.rootViewController = navigation
            } else {
                // Primeira vez: onboarding como root; ao terminar, trocamos o root.
                let onboarding = OnboardingViewController()
                onboarding.onFinish = {
                    // O onboarding já marcou o flag; aqui só trocamos a cena.
                    window.rootViewController = navigation
                    // Opcional — troca com dissolução suave:
                    // UIView.transition(with: window, duration: 0.35,
                    //                   options: .transitionCrossDissolve,
                    //                   animations: nil)
                }
                window.rootViewController = onboarding
            }
        } catch {
            // Se o banco falhar, mostramos um aviso em vez de crashar.
            let fallback = UIViewController()
            fallback.view.backgroundColor = AppColors.background
            
            let label = UILabel()
            label.text = "Não foi possível abrir o banco de dados:\n\(error.localizedDescription)"
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = AppFont.body
            label.textColor = AppColors.destructive
            // translatesAutoresizingMaskIntoConstraints = false:
            // obrigatório quando usamos constraints manuais de Auto Layout.
            label.translatesAutoresizingMaskIntoConstraints = false
            fallback.view.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: fallback.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: fallback.view.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: fallback.view.leadingAnchor, constant: 32),
                label.trailingAnchor.constraint(equalTo: fallback.view.trailingAnchor, constant: -32),
            ])
            window.rootViewController = fallback
        }
        
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
