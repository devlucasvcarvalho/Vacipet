//
//  AppColors.swift
//  Vacipet
//
//  Paleta de cores do app (azul saúde + terrosos),
//  com variantes para Dark Mode via UIColor dinâmico.
//

import UIKit

// Centralizamos as cores em um só lugar em vez de espalhar
// "#2E6FDB" pelo código — assim trocar a paleta é uma edição só.
enum AppColors {

    // MARK: Cores

    static let primary = dynamic(light: hex(0x2E6FDB), dark: hex(0x6FA3EF))          // azul saúde (ação principal)
    static let primaryDeep = dynamic(light: hex(0x1F4E9C), dark: hex(0x3D66B0))      // azul profundo (títulos)
    static let terracotta = dynamic(light: hex(0xC0704F), dark: hex(0xD89372))       // terracota (acentos, ícones)
    static let terracottaSoft = dynamic(light: hex(0xF3E2D5), dark: hex(0x3A2B21))   // terracota suave (fundo de pill)

    static let background = dynamic(light: hex(0xFBF9F4), dark: hex(0x1A1714))       // fundo da tela
    static let card = dynamic(light: hex(0xFFFFFF), dark: hex(0x26211D))             // fundo de cards
    static let sand = dynamic(light: hex(0xF4EDE1), dark: hex(0x2E2823))             // bege areia (fundos sutis)
    static let textSecondary = dynamic(light: hex(0x6E665C), dark: hex(0xB8AEA2))    // texto secundário
    static let destructive = dynamic(light: hex(0xC24A3A), dark: hex(0xE08A7A))      // vermelho (excluir)

    // MARK: Helpers

    // UIColor com "provedor dinâmico": a decisão entre claro/escuro
    // é tomada pelo iOS em cada traitCollection (automático no Dark Mode).
    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }

    // Converte 0xRRGGBB em UIColor (vermelho/verde/azul de 0 a 1).
    private static func hex(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
