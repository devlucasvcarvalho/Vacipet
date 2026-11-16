//
//  PreviewStore.swift
//  Vacipet
//
//  Dados de exemplo (in-memory) e wrappers que permitem mostrar
//  as views UIKit nos previews do SwiftUI. Só existe em DEBUG.
//

#if DEBUG
import UIKit
import SwiftUI
import SwiftData

// MARK: - Dados de exemplo

// Os previews precisam de um banco pronto para exibir.
// Usamos ModelConfiguration(isStoredInMemoryOnly: true): o banco vive
// só na memória e some quando o processo fecha — perfeito para preview.
// Os containers são static let: ficam vivos para sempre (lembre que
// ModelContext não é dono do ModelContainer, senão dá crash no primeiro fetch).
enum PreviewStore {

    // MARK: Containers

    static let emptyContainer: ModelContainer = makeContainer(seed: false)
    static let seededContainer: ModelContainer = makeContainer(seed: true)

    static var empty: ModelContext { emptyContainer.mainContext }
    static var seeded: ModelContext { seededContainer.mainContext }

    // MARK: Pets de exemplo

    // Thor com 3 vacinas (aparece em cards, detalhe e edição).
    static var thor: Pet {
        let pets = (try? seededContainer.mainContext.fetch(FetchDescriptor<Pet>())) ?? []
        return pets.first(where: { $0.nome == "Thor" }) ?? pets[0]
    }

    // MARK: Construção do banco em memória

    private static func makeContainer(seed: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Pet.self, Vacina.self, configurations: configuration)
        let context = container.mainContext

        if seed {
            let calendar = Calendar.current

            let thorNascimento = calendar.date(byAdding: .month, value: -34, to: .now)!
            let thor = Pet(
                nome: "Thor",
                dataNascimento: thorNascimento,
                observacoes: "Alergia a ração com frango. Muito brincalhão e sociável.",
                foto: makeDogImage()
            )
            context.insert(thor)
            context.insert(Vacina(nome: "V8 Polivalente", dataAplicacao: calendar.date(byAdding: .month, value: -8, to: .now)!, local: "Clínica Vet Amigo", pet: thor))
            context.insert(Vacina(nome: "Antirrábica", dataAplicacao: calendar.date(byAdding: .month, value: -3, to: .now)!, local: "Pet Center", pet: thor))
            context.insert(Vacina(nome: "Vermífugo", dataAplicacao: calendar.date(byAdding: .day, value: -20, to: .now)!, local: "Casa", pet: thor))

            let luna = Pet(
                nome: "Luna",
                dataNascimento: calendar.date(byAdding: .year, value: -1, to: .now)!,
                observacoes: ""
            )
            context.insert(luna)

            try? context.save()
        }

        return container
    }

    // MARK: Foto de exemplo

    // Ilustração plana de um cachorro (desenhada com Core Graphics),
    // usada como "foto" do Thor nos previews e na lista.
    static func makeDogImage() -> Data? {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let cream = UIColor(red: 0.97, green: 0.94, blue: 0.89, alpha: 1)
            let brown = UIColor(red: 0.72, green: 0.48, blue: 0.34, alpha: 1)
            let darkBrown = UIColor(red: 0.56, green: 0.36, blue: 0.24, alpha: 1)
            let ink = UIColor(red: 0.23, green: 0.17, blue: 0.13, alpha: 1)

            cream.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            darkBrown.setFill()
            UIBezierPath(ovalIn: CGRect(x: 52, y: 140, width: 96, height: 190)).fill()
            UIBezierPath(ovalIn: CGRect(x: 364, y: 140, width: 96, height: 190)).fill()

            brown.setFill()
            UIBezierPath(ovalIn: CGRect(x: 96, y: 90, width: 320, height: 330)).fill()

            cream.setFill()
            UIBezierPath(ovalIn: CGRect(x: 168, y: 250, width: 176, height: 140)).fill()

            ink.setFill()
            UIBezierPath(ovalIn: CGRect(x: 226, y: 268, width: 60, height: 42)).fill()
            UIBezierPath(ovalIn: CGRect(x: 158, y: 185, width: 44, height: 44)).fill()
            UIBezierPath(ovalIn: CGRect(x: 310, y: 185, width: 44, height: 44)).fill()

            cream.setFill()
            UIBezierPath(ovalIn: CGRect(x: 172, y: 196, width: 13, height: 13)).fill()
            UIBezierPath(ovalIn: CGRect(x: 324, y: 196, width: 13, height: 13)).fill()
        }
        return image.jpegData(compressionQuality: 0.85)
    }
}

// MARK: - Wrappers UIKit → SwiftUI

// #Preview só entende views SwiftUI; um UIViewController precisa ser
// "embrulhado" em um UIViewControllerRepresentable para aparecer no canvas.
// Cada wrapper recebe uma factory closure — quem chama decide o que mostrar.

struct ControllerPreview: UIViewControllerRepresentable {
    let factory: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        factory()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// Mesma ideia para UIViews (EmptyStateView, VaccineRowView, células).
struct ViewPreview: UIViewRepresentable {
    let factory: () -> UIView

    func makeUIView(context: Context) -> UIView {
        let view = factory()
        // flexibleWidth/Height: a view acompanha o frame que o SwiftUI propõe.
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif
