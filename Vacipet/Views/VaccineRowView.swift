//
//  VaccineRowView.swift
//  Vacipet
//
//  Linha editável de uma vacina no formulário: nome,
//  data de aplicação e local, com botão de remover.
//

import UIKit

// Componente reutilizável: cada "card de vacina" do formulário é um
// VaccineRowView. O pai (PetFormViewController) pede para criar e
// destruir linhas — por isso o callback onRemove devolve a própria linha.
final class VaccineRowView: UIView {

    // MARK: Controles expostos

    // Controles públicos porque quem salva é o formulário —
    // ele lê nome/local/data diretamente destas propriedades.
    let nomeField = UITextField()
    let localField = UITextField()
    let datePicker = UIDatePicker()

    // Callback chamada ao tocar na lixeira; o dono decide o que fazer
    // (neste caso: remover a linha da stack).
    var onRemove: ((VaccineRowView) -> Void)?

    // MARK: Inicialização

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
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AppColors.sand
        layer.cornerRadius = 16

        let icon = UIImageView(image: UIImage(systemName: "syringe.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)))
        icon.tintColor = AppColors.terracotta
        icon.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "VACINA"
        titleLabel.font = AppFont.sectionLabel
        titleLabel.textColor = AppColors.textSecondary

        // UIButton de sistema: um botão já estilizado pelo iOS;
        // addTarget liga o toque ao método @objc removeTapped().
        let removeButton = UIButton(type: .system)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.setImage(UIImage(systemName: "trash.circle.fill"), for: .normal)
        removeButton.tintColor = AppColors.textSecondary
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        removeButton.accessibilityLabel = "Remover vacina" // VoiceOver

        // UIView() vazio como "mola": empilha icon/título à esquerda
        // e o botão lixeira à direita, ocupando o espaço livre.
        let headerStack = UIStackView(arrangedSubviews: [icon, titleLabel, UIView(), removeButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        configureField(nomeField, placeholder: "Nome da vacina")
        configureField(localField, placeholder: "Local (ex.: Clínica Vet Amigo)")

        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)))
        calendarIcon.tintColor = AppColors.textSecondary
        // Hugging priority .required: o ícone não estica, quem cresce é o resto.
        calendarIcon.setContentHuggingPriority(.required, for: .horizontal)

        let dateCaption = UILabel()
        dateCaption.text = "Aplicação"
        dateCaption.font = AppFont.caption
        dateCaption.textColor = AppColors.textSecondary
        dateCaption.setContentHuggingPriority(.required, for: .horizontal)

        // .compact: mostra uma etiqueta com a data; ao tocar, abre o seletor.
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = AppColors.primary

        let dateRow = UIStackView(arrangedSubviews: [calendarIcon, dateCaption, datePicker])
        dateRow.axis = .horizontal
        dateRow.alignment = .center
        dateRow.spacing = 8

        let pinIcon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)))
        pinIcon.tintColor = AppColors.textSecondary
        pinIcon.setContentHuggingPriority(.required, for: .horizontal)

        let localRow = UIStackView(arrangedSubviews: [pinIcon, localField])
        localRow.axis = .horizontal
        localRow.alignment = .center
        localRow.spacing = 8

        let body = UIStackView(arrangedSubviews: [nomeField, dateRow, localRow])
        body.axis = .vertical
        body.spacing = 12
        body.translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerStack)
        addSubview(body)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            body.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            body.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            body.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            body.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])
    }

    // MARK: Helpers

    // Aplica estilo comum aos campos de texto e insere um padding pelo leftView.
    private func configureField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.font = AppFont.bodyMedium
        field.textColor = AppColors.primaryDeep
        field.backgroundColor = AppColors.card
        field.layer.cornerRadius = 10
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        field.leftViewMode = .always
        field.autocorrectionType = .no
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
    }

    // MARK: Ações

    // @objc: método exposto para o runtime do Objective-C,
    // necessário para seletores (#selector) de botões/gestos.
    @objc private func removeTapped() {
        onRemove?(self)
    }

    // MARK: Valores

    var vacinaNome: String { nomeField.text?.trimmingCharacters(in: .whitespaces) ?? "" }
    var vacinaLocal: String { localField.text?.trimmingCharacters(in: .whitespaces) ?? "" }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

// Previews do SwiftUI para iterar no visual sem abrir o app.

#Preview("Linha de vacina") {
    ViewPreview {
        let row = VaccineRowView()
        row.nomeField.text = "V8 Polivalente"
        row.localField.text = "Clínica Vet Amigo"
        row.datePicker.date = .now
        return row
    }
    .frame(width: 350, height: 170)
    .padding(20)
    .background(Color(uiColor: AppColors.background))
}

#Preview("Linha de vacina — vazia") {
    ViewPreview {
        VaccineRowView()
    }
    .frame(width: 350, height: 170)
    .padding(20)
    .background(Color(uiColor: AppColors.background))
}
#endif
