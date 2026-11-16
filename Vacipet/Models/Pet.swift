//
//  Pet.swift
//  Vacipet
//
//  Modelo (entidade) do pet no banco SwiftData: nome, nascimento,
//  foto (bytes) e o relacionamento com as vacinas.
//

import Foundation
import SwiftData

// @Model transforma a classe em uma entidade gerenciada pelo SwiftData,
// gerando o schema (colunas da tabela) automaticamente a partir das propriedades.
@Model
final class Pet {

    // MARK: Propriedades persistidas

    // .unique impede dois pets com o mesmo id (constraint no banco).
    @Attribute(.unique) var id: UUID
    var nome: String
    var dataNascimento: Date
    var observacoes: String
    // Como decidido no planejamento, a foto fica como bytes no próprio registro.
    // Imagens grandes podem inchar o store — por isso o form redimensiona
    // antes de salvar (veja PetFormViewController.downsampledJPEG).
    var foto: Data?

    // MARK: Relacionamentos

    // A lista de vacinas pertence ao pet. .cascade = apagar o pet
    // também apaga as vacinas dele (não ficam "órfãs" no banco).
    // inverse liga este lado ao campo pet dentro de Vacina —
    // declarar o inverse em UM dos lados é o suficiente, nunca nos dois.
    @Relationship(deleteRule: .cascade, inverse: \Vacina.pet)
    var vacinas: [Vacina] = []

    // MARK: Inicialização

    init(nome: String, dataNascimento: Date, observacoes: String = "", foto: Data? = nil) {
        self.id = UUID()
        self.nome = nome
        self.dataNascimento = dataNascimento
        self.observacoes = observacoes
        self.foto = foto
    }

    // MARK: Propriedades computadas

    // Propriedades computadas NÃO são persistidas — são calculadas sob demanda.
    var idadeTexto: String {
        Formatters.idade(from: dataNascimento)
    }
}
