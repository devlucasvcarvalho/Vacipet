//
//  Vacina.swift
//  Vacipet
//
//  Modelo (entidade) de uma vacina aplicada em um pet:
//  nome, data da aplicação, local e o vínculo com o pet dono.
//

import Foundation
import SwiftData

// @Model: esta classe vira uma tabela no banco do SwiftData.
@Model
final class Vacina {

    // MARK: Propriedades persistidas

    var id: UUID
    var nome: String
    var dataAplicacao: Date
    // "Local" é texto livre (ex.: "Clínica Vet Amigo"), como combinado no plano.
    var local: String

    // MARK: Relacionamentos

    // Lado "filho" do relacionamento. O inverse está declarado no campo
    // vacinas do Pet, então aqui fica sem anotação extra.
    // É opcional porque o SwiftData preenche após um save/fetch.
    var pet: Pet?

    // MARK: Inicialização

    init(nome: String = "", dataAplicacao: Date = .now, local: String = "", pet: Pet? = nil) {
        self.id = UUID()
        self.nome = nome
        self.dataAplicacao = dataAplicacao
        self.local = local
        self.pet = pet
    }
}
