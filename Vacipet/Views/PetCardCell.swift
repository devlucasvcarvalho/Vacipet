//
//  PetCardCell.swift
//  Vacipet
//
//  Célula da lista de pets: foto (ou pata placeholder), nome,
//  idade e quantidade de vacinas, com chevron de navegação.
//

import UIKit

// UICollectionViewCell é a "visualização de um item da coleção".
// Ela é criada e reciclada pela collection view — por isso existe
// um prepareForReuse() para limpar estado entre usos.
final class PetCardCell: UICollectionViewCell {

    // MARK: Identificador de reutilização

    // ID usado ao registrar e ao desenfileirar (dequeue) a célula.
    static let reuseID = "PetCardCell"

    // MARK: Subviews

    private let photoImageView = UIImageView()
    private let nameLabel = UILabel()
    private let ageLabel = UILabel()
    private let vaccinesLabel = UILabel()
    private let chevronImageView = UIImageView()

    // MARK: Inicialização

    // Criação via código: precisamos dos dois inits.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    // Criação via nib/storyboard exigiria este init; mantemos mesmo
    // construindo por código, e delegamos para o mesmo setup().
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Ciclo de vida da view

    // O shadowPath limita a sombra ao retângulo arredondado — bem mais
    // barato para a GPU do que a sombra padrão (que segue o alpha).
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
    }

    // Chamado quando a célula sai e vai ser reutilizada: limpa a foto
    // para não vazar uma imagem do pet anterior durante a rolagem.
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }

    // MARK: Layout

    private func setup() {
        // contentView é a "folha" dentro da célula — é onde colocamos
        // as subviews visíveis. Recortes (cornerRadius) vão nela.
        contentView.backgroundColor = AppColors.card
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true

        // A SOMBRA fica na própria célula (não na contentView recortada),
        // senão ela seria cortada pelos cantos arredondados.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 5)

        // scaleAspectFill + clipsToBounds: a foto preenche o quadrado,
        // cortando as sobras em vez de distorcer.
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = 16
        photoImageView.backgroundColor = AppColors.sand

        // Placeholder de pata (SF Symbol) mostrado quando o pet não tem foto.
        let pawPlaceholder = UIImageView(image: UIImage(systemName: "pawprint.fill"))
        pawPlaceholder.tintColor = AppColors.terracotta
        pawPlaceholder.contentMode = .scaleAspectFit
        photoImageView.addSubview(pawPlaceholder)
        pawPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pawPlaceholder.centerXAnchor.constraint(equalTo: photoImageView.centerXAnchor),
            pawPlaceholder.centerYAnchor.constraint(equalTo: photoImageView.centerYAnchor),
            pawPlaceholder.widthAnchor.constraint(equalTo: photoImageView.widthAnchor, multiplier: 0.42),
            pawPlaceholder.heightAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 0.42),
        ])
        pawPlaceholder.tag = 99 // tag para localizarmos o placeholder depois (viewWithTag)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = AppFont.headline
        nameLabel.textColor = AppColors.primaryDeep
        nameLabel.numberOfLines = 1

        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        ageLabel.font = AppFont.captionMedium
        ageLabel.textColor = AppColors.terracotta

        vaccinesLabel.translatesAutoresizingMaskIntoConstraints = false
        vaccinesLabel.font = AppFont.caption
        vaccinesLabel.textColor = AppColors.textSecondary
        vaccinesLabel.numberOfLines = 1

        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
        chevronImageView.tintColor = AppColors.textSecondary
        chevronImageView.contentMode = .scaleAspectFit

        // UIStackView vertical evita calcular posição de cada label na mão.
        let textStack = UIStackView(arrangedSubviews: [nameLabel, ageLabel, vaccinesLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(photoImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            photoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoImageView.widthAnchor.constraint(equalToConstant: 80),
            photoImageView.heightAnchor.constraint(equalToConstant: 80),

            textStack.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -8),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    // MARK: Configuração

    // Padrão "configure(...)": a célula não busca dados sozinha —
    // quem decide o conteúdo é a collection view (cellForItemAt).
    func configure(pet: Pet) {
        nameLabel.text = pet.nome
        ageLabel.text = pet.idadeTexto // calculada a partir da data de nascimento

        let count = pet.vacinas.count
        vaccinesLabel.text = count == 0 ? "Nenhuma vacina" : (count == 1 ? "1 vacina" : "\(count) vacinas")

        // Data presente → mostra a foto; ausente → placeholder de pata.
        if let data = pet.foto, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.viewWithTag(99)?.isHidden = true
        } else {
            photoImageView.image = nil
            photoImageView.viewWithTag(99)?.isHidden = false
        }
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI
import SwiftData

// Previews do SwiftUI: renderizam a view UIKit isolada no canvas do Xcode.

#Preview("Card com foto") {
    ViewPreview {
        let cell = PetCardCell()
        cell.configure(pet: PreviewStore.thor)
        return cell
    }
    .frame(width: 350, height: 108)
    .padding(20)
    .background(Color(uiColor: AppColors.background))
}

#Preview("Card sem foto") {
    ViewPreview {
        let cell = PetCardCell()
        let pets = (try? PreviewStore.seeded.fetch(FetchDescriptor<Pet>())) ?? []
        if let luna = pets.first(where: { $0.nome == "Luna" }) {
            cell.configure(pet: luna)
        }
        return cell
    }
    .frame(width: 350, height: 108)
    .padding(20)
    .background(Color(uiColor: AppColors.background))
}
#endif
