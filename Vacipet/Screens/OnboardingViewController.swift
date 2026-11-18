//
//  OnboardingViewController.swift.swift
//  Vacipet
//
//  Created by Lucas Vieira de Carvalho on 18/11/26.
//
//
//  Container do onboarding: páginas deslizáveis + indicadores + Pular/Continuar.
//

import UIKit
//import Foundation

final class OnboardingViewController: UIViewController {

    // MARK: Dados

    // Todas as páginas do conteúdo, em ordem.
    private let pages = OnboardingContent.pages
    // Índice da página visível — atualizado quando a animação termina.
    private var currentIndex = 0

    // Chamado quando o usuário toca em "Pular" ou "Começar".
    // Quem recebe (o SceneDelegate) decide o que fazer depois —
    // mesmo padrão do onSave do formulário.
    var onFinish: (() -> Void)?

    // MARK: Subviews

    private lazy var pageViewController: UIPageViewController = {
        // .scroll = páginas deslizam como em um ScrollView;
        // há também .pageCurl (efeito livro), mas não queremos isso aqui.
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pvc.dataSource = self // recebe as perguntas "antes/depois"
        pvc.delegate = self   // recebe "terminou a animação de troca"
        return pvc
    }()

    private let pageControl = UIPageControl()
    private let skipButton = UIButton(type: .system)
    private let continueButton = UIButton(type: .system)

    // MARK: Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        // 1) Embute o UIPageViewController na nossa view (child VC)
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)

        // 2) Mostra a primeira página
        pageViewController.setViewControllers(
            [makePage(at: 0)],
            direction: .forward,
            animated: false
        )

        // 3) Pular (canto superior direito)
        skipButton.setTitle("Pular", for: .normal)
        skipButton.setTitleColor(AppColors.textSecondary, for: .normal)
        skipButton.titleLabel?.font = AppFont.captionMedium
        skipButton.addTarget(self, action: #selector(finish), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.accessibilityLabel = "Pular introdução"
        view.addSubview(skipButton)

        // 4) Continuar / Começar (centralizado embaixo)
        continueButton.setTitle("Continuar", for: .normal)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = AppColors.primary
        config.baseForegroundColor = .white
        config.background.cornerRadius = 14
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 34, bottom: 14, trailing: 34)
        continueButton.configuration = config
        continueButton.titleLabel?.font = AppFont.bodyMedium
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)

        // 5) Pontinhos
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = AppColors.sand
        pageControl.currentPageIndicatorTintColor = AppColors.primary
        pageControl.isUserInteractionEnabled = false // só decoração; a navegação é pelos botões/arraste
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)

        // 6) Constraints
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -16),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -28),

            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    // MARK: Páginas

    private func makePage(at index: Int) -> OnboardingPageViewController {
        OnboardingPageViewController(page: pages[index], index: index)
    }

    // MARK: Ações

    @objc private func continueTapped() {
        if currentIndex == pages.count - 1 {
            finish() // última página → Começar
        } else {
            let nextIndex = currentIndex + 1
            currentIndex = nextIndex
            pageViewController.setViewControllers(
                [makePage(at: nextIndex)],
                direction: .forward,
                animated: true
            )
            updatePageChrome()
        }
    }

    @objc private func finish() {
        // Quem apresentou decide o que fazer (o SceneDelegate troca o root).
        // Quem "lembra" que o usuário já viu o onboarding é o mesmo lugar.
        UserDefaults.standard.set(true, forKey: "onboardingConcluido")
        onFinish?()
    }

    // MARK: Pontinhos e botão

    private func updatePageChrome() {
        pageControl.currentPage = currentIndex
        continueButton.setTitle(currentIndex == pages.count - 1 ? "Começar" : "Continuar", for: .normal)
    }
}

// MARK: - UIPageViewControllerDataSource

extension OnboardingViewController: UIPageViewControllerDataSource {
    // Pergunta: "quem vem ANTES desta página?"
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? OnboardingPageViewController, page.index > 0 else { return nil }
        return makePage(at: page.index - 1)
    }

    // Pergunta: "quem vem DEPOIS desta página?"
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? OnboardingPageViewController,
              page.index < pages.count - 1 else { return nil }
        return makePage(at: page.index + 1)
    }
}

// MARK: - UIPageViewControllerDelegate

extension OnboardingViewController: UIPageViewControllerDelegate {
    // Chamado ao FIM da animação: correto mesmo se o usuário só "arrastou e voltou".
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let page = pageViewController.viewControllers?.first as? OnboardingPageViewController
        else{ return }
              currentIndex = page.index
        updatePageChrome()
    }
}
