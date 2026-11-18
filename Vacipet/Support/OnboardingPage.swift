//
//  OnboardingPage.swift
//  Vacipet
//
//  Created by Lucas Vieira de Carvalho on 18/11/26.
//

import Foundation

struct OnboardingPage {
    let symbol: String   // nome do SF Symbol, ex.: "pawprint.circle.fill"
    let title: String
    let message: String
}

enum OnboardingContent {
    // Se um dia quiser mudar o texto, muda só aqui.
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "pawprint.circle.fill",
            title: "Cuide da saúde do seu pet",
            message: "Chega de carteirinha de papel perdida.\nTudo sobre seus pets em um só lugar."
        ),
        OnboardingPage(
            symbol: "camera.badge.ellipsis",
            title: "Cadastre seu pet",
            message: "Toque na pata azul.\nAdicione foto, nome, nascimento e observações."
        ),
        OnboardingPage(
            symbol: "syringe.fill",
            title: "Vacinas em dia",
            message: "Em cada pet, toque em Adicionar em Vacinas:\nnome, data e local. Depois toque no card\npara ver tudo, editar ou excluir."
        ),
    ]
}
