//
//  AppFonts.swift
//  Vacipet
//
//  Fontes "redondas" do app (SF Rounded do sistema),
//  definidas uma vez e reutilizadas em todas as telas.
//

import UIKit

// O briefing pedia fontes redondas; em vez de embutir arquivos de fonte
// (Nunito, Quicksand...), usamos o desenho "rounded" da SF do sistema —
// zero arquivos extras no bundle e acessibilidade preservada.
enum AppFont {

    // MARK: Constantes

    static let screenTitle = rounded(ofSize: 28, weight: .heavy)   // título grande ("Meus Pets")
    static let roundedTitle = rounded(ofSize: 34, weight: .heavy)  // large title da nav bar
    static let detailTitle = rounded(ofSize: 26, weight: .heavy)   // nome na tela de detalhe
    static let headline = rounded(ofSize: 17, weight: .bold)       // nomes em cards e vacinas
    static let body = rounded(ofSize: 16, weight: .regular)        // texto corrido
    static let bodyMedium = rounded(ofSize: 16, weight: .semibold) // botões e campos
    static let caption = rounded(ofSize: 13, weight: .regular)     // legendas
    static let captionMedium = rounded(ofSize: 13, weight: .semibold) // legendas com destaque
    static let sectionLabel = rounded(ofSize: 13, weight: .bold)   // rótulos de seção ("VACINAS")

    // MARK: Helpers

    // withDesign(.rounded) troca a SF padrão pelo desenho arredondado
    // no MESMO tamanho/peso — o sistema escolhe a variação certa.
    private static func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        // Fallback de segurança: se o desenho rounded não existir, usa a fonte base.
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
