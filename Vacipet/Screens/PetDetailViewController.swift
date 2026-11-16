//
//  PetDetailViewController.swift
//  Vacipet
//
//  Detalhe do pet: foto grande, idade, observações e lista de vacinas,
//  com ações de editar (sheet) e excluir (confirmação destrutiva).
//

import UIKit
import SwiftData

// Esta tela é empilhada pela lista (push). Ela não "busca" o pet —
// recebe o objeto já pronto, padrão de navegação no UIKit.
final class PetDetailViewController: UIViewController {

    // MARK: Dependências e estado

    private let modelContext: ModelContext
    private let pet: Pet

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // MARK: Inicialização

    init(modelContext: ModelContext, pet: Pet) {
        self.modelContext = modelContext
        self.pet = pet
        super.init(nibName: nil, bundle: nil)
        // Esconde a barra inferior do UITabBar/toolbar ao empilhar (padrão moderno).
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não suportado")
    }

    // MARK: Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

      
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Editar",
            style: .plain,
            target: self,
            action: #selector(editTapped)
        )
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([.font: AppFont.bodyMedium, .foregroundColor: AppColors.primary], for: .normal)

        // Mesma estrutura de scroll + stack vertical do formulário.
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])

        rebuildContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reconstrói ao aparecer (ex.: voltou de outro fluxo).
        // Um pop para esta tela dispara viewWillAppear normalmente.
        rebuildContent()
    }

    // MARK: Conteúdo

    // Estratégia "rebuild total": remove tudo e reconstrói as seções.
    // Simples e sempre correto — o custo é irrelevante para ~10 views.
    private func rebuildContent() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        title = pet.nome

        contentStack.addArrangedSubview(makePhotoSection())
        contentStack.addArrangedSubview(makeNotesCard())
        contentStack.addArrangedSubview(makeVaccinesSection())
        contentStack.addArrangedSubview(makeDeleteButton())
    }

    // Seção do topo: foto grande (ou pata placeholder), nome, pill de idade e nascimento.
    private func makePhotoSection() -> UIView {
        let container = UIView()

        let photoView = UIImageView()
        photoView.translatesAutoresizingMaskIntoConstraints = false
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.layer.cornerRadius = 24
        photoView.backgroundColor = AppColors.sand

        if let data = pet.foto, let image = UIImage(data: data) {
            photoView.image = image
        } else {
            // Sem foto: pata grande centralizada como placeholder.
            let paw = UIImageView(image: UIImage(systemName: "pawprint.fill"))
            paw.tintColor = AppColors.terracotta
            paw.contentMode = .scaleAspectFit
            paw.translatesAutoresizingMaskIntoConstraints = false
            photoView.addSubview(paw)
            NSLayoutConstraint.activate([
                paw.centerXAnchor.constraint(equalTo: photoView.centerXAnchor),
                paw.centerYAnchor.constraint(equalTo: photoView.centerYAnchor),
                paw.widthAnchor.constraint(equalToConstant: 84),
                paw.heightAnchor.constraint(equalToConstant: 84),
            ])
        }

        let nameLabel = UILabel()
        nameLabel.text = pet.nome
        nameLabel.font = AppFont.detailTitle
        nameLabel.textColor = AppColors.primaryDeep
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // "Pill": UILabel com fundo colorido e cantos arredondados — "badge" de idade.
        let agePill = UILabel()
        agePill.text = "  " + pet.idadeTexto + "  "
        agePill.font = AppFont.captionMedium
        agePill.textColor = AppColors.terracotta
        agePill.backgroundColor = AppColors.terracottaSoft
        agePill.textAlignment = .center
        agePill.layer.cornerRadius = 13
        agePill.clipsToBounds = true
        agePill.translatesAutoresizingMaskIntoConstraints = false
        let pillWidth = agePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 90)
        pillWidth.isActive = true

        let birthLabel = UILabel()
        birthLabel.text = "Nascimento: " + Formatters.longDateString(from: pet.dataNascimento)
        birthLabel.font = AppFont.caption
        birthLabel.textColor = AppColors.textSecondary
        birthLabel.textAlignment = .center
        birthLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(photoView)
        container.addSubview(nameLabel)
        container.addSubview(agePill)
        container.addSubview(birthLabel)

        NSLayoutConstraint.activate([
            photoView.topAnchor.constraint(equalTo: container.topAnchor),
            photoView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            photoView.heightAnchor.constraint(equalToConstant: 230),

            nameLabel.topAnchor.constraint(equalTo: photoView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            agePill.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            agePill.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            agePill.heightAnchor.constraint(equalToConstant: 26),

            birthLabel.topAnchor.constraint(equalTo: agePill.bottomAnchor, constant: 8),
            birthLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            birthLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            birthLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    // Card "Observações" — mostra o texto ou um aviso discreto quando vazio.
    private func makeNotesCard() -> UIView {
        let card = UIView()
        card.backgroundColor = AppColors.card
        card.layer.cornerRadius = 16

        let icon = UIImageView(image: UIImage(systemName: "note.text", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)))
        icon.tintColor = AppColors.terracotta
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "OBSERVAÇÕES"
        title.font = AppFont.sectionLabel
        title.textColor = AppColors.textSecondary
        title.translatesAutoresizingMaskIntoConstraints = false

        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.numberOfLines = 0
        text.font = AppFont.body
        if pet.observacoes.isEmpty {
            text.text = "Sem observações registradas."
            text.textColor = AppColors.textSecondary
        } else {
            text.text = pet.observacoes
            text.textColor = AppColors.primaryDeep
        }

        card.addSubview(icon)
        card.addSubview(title)
        card.addSubview(text)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.widthAnchor.constraint(equalToConstant: 20),

            title.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),

            text.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 10),
            text.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            text.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            text.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])

        return card
    }

    // Seção "Vacinas": cabeçalho com contagem em badge + linhas de cada vacina.
    private func makeVaccinesSection() -> UIView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 12

        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        let label = UILabel()
        label.text = "VACINAS"
        label.font = AppFont.sectionLabel
        label.textColor = AppColors.textSecondary

        // Badge azul com o número de vacinas.
        let countBadge = UILabel()
        countBadge.text = " \(pet.vacinas.count) "
        countBadge.font = AppFont.captionMedium
        countBadge.textColor = .white
        countBadge.backgroundColor = AppColors.primary
        countBadge.layer.cornerRadius = 10
        countBadge.clipsToBounds = true
        countBadge.textAlignment = .center
        countBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 26).isActive = true
        countBadge.heightAnchor.constraint(equalToConstant: 20).isActive = true

        headerRow.addArrangedSubview(label)
        headerRow.addArrangedSubview(countBadge)
        headerRow.addArrangedSubview(UIView()) // mola: empurra rótulo/badge à esquerda

        section.addArrangedSubview(headerRow)

        // Ordena por data de aplicação (mais antigas primeiro).
        let ordenadas = pet.vacinas.sorted { $0.dataAplicacao < $1.dataAplicacao }
        if ordenadas.isEmpty {
            let empty = UILabel()
            empty.text = "Nenhuma vacina registrada ainda."
            empty.font = AppFont.body
            empty.textColor = AppColors.textSecondary
            empty.textAlignment = .center
            section.addArrangedSubview(empty)
        } else {
            for vacina in ordenadas {
                section.addArrangedSubview(makeVaccineRow(vacina))
            }
        }

        return section
    }

    // Linha de uma vacina: círculo com seringa + nome + "data · local".
    private func makeVaccineRow(_ vacina: Vacina) -> UIView {
        let card = UIView()
        card.backgroundColor = AppColors.card
        card.layer.cornerRadius = 16

        let iconCircle = UIView()
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.backgroundColor = AppColors.sand
        iconCircle.layer.cornerRadius = 20

        let icon = UIImageView(image: UIImage(systemName: "syringe.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)))
        icon.tintColor = AppColors.terracotta
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(icon)

        let nameLabel = UILabel()
        nameLabel.text = vacina.nome
        nameLabel.font = AppFont.headline
        nameLabel.textColor = AppColors.primaryDeep
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Junta data e local em uma linha: "11 de março de 2026 · Clínica X".
        let detailLabel = UILabel()
        var detail = Formatters.longDateString(from: vacina.dataAplicacao)
        if !vacina.local.isEmpty {
            detail += "  ·  " + vacina.local
        }
        detailLabel.text = detail
        detailLabel.font = AppFont.caption
        detailLabel.textColor = AppColors.textSecondary
        detailLabel.numberOfLines = 2
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconCircle)
        card.addSubview(nameLabel)
        card.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            iconCircle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconCircle.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconCircle.widthAnchor.constraint(equalToConstant: 40),
            iconCircle.heightAnchor.constraint(equalToConstant: 40),

            icon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 19),
            icon.heightAnchor.constraint(equalToConstant: 19),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: iconCircle.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            detailLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])

        return card
    }

    // Botão destrutivo no fim da tela.
    private func makeDeleteButton() -> UIButton {
        let button = UIButton(type: .system)
        // UIButton.Configuration: API moderna de configuração de botões no UIKit.
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        configuration.imagePadding = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        button.configuration = configuration
        button.setTitle("Excluir pet", for: .normal)
        button.setTitleColor(AppColors.destructive, for: .normal)
        button.titleLabel?.font = AppFont.bodyMedium
        button.backgroundColor = AppColors.destructive.withAlphaComponent(0.12)
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        return button
    }

    // MARK: Ações

    @objc private func editTapped() {
        let form = PetFormViewController(modelContext: modelContext, pet: pet)
        // A sheet não dispara viewWillAppear ao fechar — por isso
        // o form avisa via callback para reconstruir o conteúdo do detalhe.
        form.onSave = { [weak self] in self?.rebuildContent() }

        let nav = UINavigationController(rootViewController: form)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()] // dois detents, como definido no plano
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        present(nav, animated: true)
    }

    @objc private func deleteTapped() {
        // Confirmação destrutiva: ação irreversível pede confirmação explícita.
        let alert = UIAlertController(
            title: "Excluir \(pet.nome)?",
            message: "O pet e todas as suas vacinas serão apagados. Esta ação não pode ser desfeita.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Excluir", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.modelContext.delete(self.pet) // cascade apaga as vacinas junto
            do {
                try self.modelContext.save()
            } catch {
                assertionFailure("Erro ao excluir pet: \(error)")
            }
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            // Volta para a lista; viewWillAppear dela recarrega os dados.
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

// Previews do SwiftUI: o detalhe isolado no canvas (normal e Dark).

#Preview("Detalhe do pet") {
    ControllerPreview {
        UINavigationController(rootViewController: PetDetailViewController(modelContext: PreviewStore.seeded, pet: PreviewStore.thor))
    }
    .ignoresSafeArea()
}

#Preview("Detalhe do pet — Dark") {
    ControllerPreview {
        UINavigationController(rootViewController: PetDetailViewController(modelContext: PreviewStore.seeded, pet: PreviewStore.thor))
    }
    .preferredColorScheme(.dark)
    .ignoresSafeArea()
}
#endif
