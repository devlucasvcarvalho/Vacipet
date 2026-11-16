//
//  EmptyStateView.swift
//  Vacipet
//
//  Tela de "nenhum pet ainda": pata grande sobre círculo areia,
//  título e convite para usar o botão de adicionar.
//

import UIKit

// Views customizadas são subclasses de UIView com as subviews
// e constraints criadas no init — mesmo padrão de um view em SwiftUI,
// só que explícito.
final class EmptyStateView: UIView {

    // MARK: Subviews

    private let circleView = UIView()
    private let pawImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // MARK: Inicialização

    // Sempre os dois inits: o de código (frame) e o de nib.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Layout

    private func setup() {
        // translatesAutoresizingMaskIntoConstraints = false é obrigatório
        // para Auto Layout manual: sem ele o sistema briga com as constraints.
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.backgroundColor = AppColors.sand
        circleView.layer.cornerRadius = 90 // metade da largura = círculo perfeito

        pawImageView.translatesAutoresizingMaskIntoConstraints = false
        pawImageView.image = UIImage(systemName: "pawprint.fill") // SF Symbol
        pawImageView.tintColor = AppColors.terracotta
        pawImageView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Nenhum pet por aqui ainda"
        titleLabel.font = AppFont.screenTitle
        titleLabel.textColor = AppColors.primaryDeep
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0 // 0 = quantas linhas forem necessárias

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Toque na pata abaixo para\nregistrar o seu primeiro pet"
        subtitleLabel.font = AppFont.body
        subtitleLabel.textColor = AppColors.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        addSubview(circleView)
        addSubview(pawImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        // Constraints de Auto Layout: descrevem RELAÇÕES entre as views
        // (a pata fica no centro do círculo...), não coordenadas absolutas.
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.topAnchor.constraint(equalTo: topAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 180),
            circleView.heightAnchor.constraint(equalToConstant: 180),

            pawImageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            pawImageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            pawImageView.widthAnchor.constraint(equalToConstant: 88),
            pawImageView.heightAnchor.constraint(equalToConstant: 88),

            titleLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
        ])
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

// Previews do SwiftUI para iterar no visual sem abrir o app.

#Preview("Estado vazio") {
    ViewPreview {
        let view = EmptyStateView()
        view.backgroundColor = AppColors.background
        return view
    }
    .frame(width: 390, height: 500)
    .ignoresSafeArea()
}

#Preview("Estado vazio — Dark") {
    ViewPreview {
        let view = EmptyStateView()
        view.backgroundColor = AppColors.background
        return view
    }
    .frame(width: 390, height: 500)
    .preferredColorScheme(.dark)
    .ignoresSafeArea()
}
#endif
