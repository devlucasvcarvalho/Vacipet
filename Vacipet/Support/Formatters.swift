//
//  Formatters.swift
//  Vacipet
//
//  Funções de formatação de data e de cálculo de idade
//  compartilhadas pelas telas e pelos modelos.
//

import Foundation

// Um enum sem casos funciona como um "namespace" em Swift:
// agrupa funções relacionadas sem permitir instanciar nada.
enum Formatters {

    // MARK: Datas

    // Formata uma data por extenso em pt-BR ("11 de março de 2026").
    // Criamos o DateFormatter na hora porque criar um por chamada
    // é barato aqui e evita estado compartilhado entre threads.
    static func longDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: Idade

    // Calcula a idade a partir da data de nascimento e formata
    // como "X anos e Y meses" (decisão do planejamento do app).
    static func idade(from nascimento: Date, agora: Date = .now) -> String {
        // dateComponents devolve a diferença entre as duas datas
        // em anos e meses, já normalizada pelo calendário.
        let componentes = Calendar.current.dateComponents([.year, .month], from: nascimento, to: agora)
        let anos = componentes.year ?? 0
        let meses = componentes.month ?? 0

        if anos <= 0 && meses <= 0 { return "menos de 1 mês" }
        if anos <= 0 { return "\(meses) \(meses == 1 ? "mês" : "meses")" }
        if meses == 0 { return "\(anos) \(anos == 1 ? "ano" : "anos")" }
        return "\(anos) \(anos == 1 ? "ano" : "anos") e \(meses) \(meses == 1 ? "mês" : "meses")"
    }
}
