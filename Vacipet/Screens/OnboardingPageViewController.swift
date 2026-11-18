//
//  OnboardingPageViewController.swift
//  Vacipet
//
//  Created by Lucas Vieira de Carvalho on 18/11/26.
//
//  Uma página do onboarding: símbolo grande, título e mensagem centralizados.
//

import UIKit

final class OnboardingPageViewController: UIViewController {

    // MARK: Dependência

    // Recebe o conteúdo pronto — ela não decide o que exibir, só exibe.
    let page: OnboardingPage
    
    let index: Int

    // MARK: Inicialização

    init(page: OnboardingPage, index: Int) {
        self.page = page
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não suportado")
    }

    // MARK: Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        let symbolView = UIImageView(image: UIImage(systemName: page.symbol))
        symbolView.tintColor = AppColors.primary
        symbolView.contentMode = .scaleAspectFit
        symbolView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = page.title
        titleLabel.font = AppFont.screenTitle
        titleLabel.textColor = AppColors.primaryDeep
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let messageLabel = UILabel()
        messageLabel.text = page.message
        messageLabel.font = AppFont.body
        messageLabel.textColor = AppColors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [symbolView, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        stack.isLayoutMarginsRelativeArrangement = true
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            symbolView.widthAnchor.constraint(equalToConstant: 120),
            symbolView.heightAnchor.constraint(equalToConstant: 120),

            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
