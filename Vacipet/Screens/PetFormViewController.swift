//
//  PetFormViewController.swift
//  Vacipet
//
//  Formulário (sheet) de adicionar/editar pet: foto, dados do animal
//  e lista dinâmica de vacinas — o mesmo formulário serve para os dois modos.
//

import UIKit
import SwiftData
import PhotosUI // PHPickerViewController (galeria)

// Um único formulário para adicionar e editar, decidido pelo init:
// pet == nil → adicionar; pet != nil → editar (pré-preenchido).
final class PetFormViewController: UIViewController {

    // MARK: Modo e callbacks

    // enum interno "associado": add ou edit(um Pet específico).
    private enum Mode {
        case add
        case edit(Pet)
    }

    // Apresentador (lista ou detalhe) escuta este callback para recarregar
    // depois de salvar — sheets não disparam viewWillAppear ao fechar.
    var onSave: (() -> Void)?

    // MARK: Dependências e estado

    private let modelContext: ModelContext
    private let mode: Mode

    // Foto
    private let photoContainer = UIView()
    private let photoImageView = UIImageView()
    private let placeholderPaw = UIImageView()
    private let cameraBadge = UIView()
    private let photoHintLabel = UILabel()
    // Bytes da foto selecionada; nil quando não há foto.
    private var selectedPhotoData: Data?

    // Campos
    private let nameField = UITextField()
    private let birthDatePicker = UIDatePicker()
    private let notesTextView = UITextView()
    private let notesPlaceholder = UILabel() // placeholder manual para UITextView

    // Vacinas
    private let vaccinesStack = UIStackView()
    private let addVaccineButton = UIButton(type: .system)
    private var vaccineRows: [VaccineRowView] = []

    // Área rolável — formulários maiores que a tela rolam em vez de cortar.
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // UIBarButtonItem pode ser habilitado/desabilitado conforme a validação.
    private var saveBarButton: UIBarButtonItem!

    // MARK: Inicialização

    // pet == nil → modo adicionar; pet != nil → modo editar.
    init(modelContext: ModelContext, pet: Pet?) {
        self.modelContext = modelContext
        self.mode = pet.map { .edit($0) } ?? .add
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não suportado")
    }

    private var isEditingPet: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        // NavigationItem: botões à esquerda e à direita da barra.
        title = isEditingPet ? "Editar Pet" : "Novo Pet"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancelar", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.leftBarButtonItem?.setTitleTextAttributes([.font: AppFont.bodyMedium, .foregroundColor: AppColors.textSecondary], for: .normal)

        saveBarButton = UIBarButtonItem(title: "Salvar", style: .done, target: self, action: #selector(saveTapped))
        saveBarButton.setTitleTextAttributes([.font: AppFont.bodyMedium, .foregroundColor: AppColors.primary], for: .normal)
        saveBarButton.setTitleTextAttributes([.font: AppFont.bodyMedium, .foregroundColor: AppColors.textSecondary], for: .disabled)
        navigationItem.rightBarButtonItem = saveBarButton

        setupScrollContent()
        setupPhotoSection()
        setupInfoSection()
        setupVaccinesSection()

        // Pré-preencher só faz sentido no modo edição.
        if case .edit(let pet) = mode {
            prefill(with: pet)
        }
        updateSaveState()

        // Notificações globais de teclado: ajustamos o inset do scroll
        // para o campo focado não ficar escondido atrás do teclado.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Layout — ScrollView e pilha de conteúdo

    private func setupScrollContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive // arrastar para baixo fecha o teclado
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Duas cadeias de constraints:
        // 1) scrollView ocupa a tela (safeArea em cima, bottom na view).
        // 2) contentStack é a "folha" dentro do scrollView: suas bordas definem
        //    a área rolável (contentLayoutGuide) e sua largura é fixada à
        //    largura da tela (frameLayoutGuide).
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
    }

    // MARK: Layout — Seção da foto

    private func setupPhotoSection() {
        let photoSection = UIStackView()
        photoSection.axis = .vertical
        photoSection.alignment = .center // centraliza horizontalmente
        photoSection.spacing = 10

        // Container circular clicável: mostra a foto (ou a pata) e o selo de câmera.
        photoContainer.translatesAutoresizingMaskIntoConstraints = false
        photoContainer.backgroundColor = AppColors.sand
        photoContainer.layer.cornerRadius = 66
        photoContainer.layer.borderWidth = 2
        photoContainer.layer.borderColor = AppColors.terracotta.withAlphaComponent(0.45).cgColor
        photoContainer.isUserInteractionEnabled = true
        // UITapGestureRecognizer: qualquer toque no círculo vira um "photoTapped".
        photoContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(photoTapped)))

        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = 64

        placeholderPaw.translatesAutoresizingMaskIntoConstraints = false
        placeholderPaw.image = UIImage(systemName: "pawprint.fill")
        placeholderPaw.tintColor = AppColors.terracotta.withAlphaComponent(0.75)
        placeholderPaw.contentMode = .scaleAspectFit

        photoContainer.addSubview(photoImageView)
        photoContainer.addSubview(placeholderPaw)

        // Selo de câmera (bolha azul) no canto inferior direito do círculo.
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)))
        cameraIcon.tintColor = .white
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false

        cameraBadge.translatesAutoresizingMaskIntoConstraints = false
        cameraBadge.backgroundColor = AppColors.primary
        cameraBadge.layer.cornerRadius = 16
        cameraBadge.layer.borderWidth = 3
        cameraBadge.layer.borderColor = AppColors.background.cgColor
        cameraBadge.addSubview(cameraIcon)

        photoContainer.addSubview(cameraBadge)

        photoHintLabel.translatesAutoresizingMaskIntoConstraints = false
        photoHintLabel.text = "Toque para adicionar uma foto"
        photoHintLabel.font = AppFont.captionMedium
        photoHintLabel.textColor = AppColors.textSecondary

        photoSection.addArrangedSubview(photoContainer)
        photoSection.addArrangedSubview(photoHintLabel)
        contentStack.addArrangedSubview(photoSection)

        NSLayoutConstraint.activate([
            photoContainer.widthAnchor.constraint(equalToConstant: 132),
            photoContainer.heightAnchor.constraint(equalToConstant: 132),

            photoImageView.topAnchor.constraint(equalTo: photoContainer.topAnchor, constant: 2),
            photoImageView.leadingAnchor.constraint(equalTo: photoContainer.leadingAnchor, constant: 2),
            photoImageView.trailingAnchor.constraint(equalTo: photoContainer.trailingAnchor, constant: -2),
            photoImageView.bottomAnchor.constraint(equalTo: photoContainer.bottomAnchor, constant: -2),

            placeholderPaw.centerXAnchor.constraint(equalTo: photoContainer.centerXAnchor),
            placeholderPaw.centerYAnchor.constraint(equalTo: photoContainer.centerYAnchor),
            placeholderPaw.widthAnchor.constraint(equalToConstant: 48),
            placeholderPaw.heightAnchor.constraint(equalToConstant: 48),

            cameraBadge.widthAnchor.constraint(equalToConstant: 34),
            cameraBadge.heightAnchor.constraint(equalToConstant: 34),
            cameraBadge.trailingAnchor.constraint(equalTo: photoContainer.trailingAnchor, constant: 2),
            cameraBadge.bottomAnchor.constraint(equalTo: photoContainer.bottomAnchor, constant: 2),

            cameraIcon.centerXAnchor.constraint(equalTo: cameraBadge.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: cameraBadge.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 15),
            cameraIcon.heightAnchor.constraint(equalToConstant: 15),
        ])
    }

    // MARK: Layout — Seção "Sobre o pet"

    private func setupInfoSection() {
        let sectionHeader = sectionLabel("SOBRE O PET")

        // Campo nome: contentor com ícone + UITextField.
        let nameContainer = fieldContainer()
        let pawIcon = iconView("pawprint")
        nameField.placeholder = "Nome do animal"
        nameField.font = AppFont.bodyMedium
        nameField.textColor = AppColors.primaryDeep
        nameField.autocorrectionType = .no
        // .editingChanged dispara a cada tecla — usado para validar o botão Salvar.
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        nameContainer.addArrangedSubview(pawIcon)
        nameContainer.addArrangedSubview(nameField)

        // Nascimento: date picker compact (toque abre o calendário).
        let dateContainer = fieldContainer()
        let calendarIcon = iconView("calendar")
        let dateLabel = UILabel()
        dateLabel.text = "Nascimento"
        dateLabel.font = AppFont.body
        dateLabel.textColor = AppColors.textSecondary
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        birthDatePicker.datePickerMode = .date
        birthDatePicker.preferredDatePickerStyle = .compact
        birthDatePicker.tintColor = AppColors.primary
        birthDatePicker.maximumDate = .now // sem pet do futuro :)
        birthDatePicker.date = Calendar.current.date(byAdding: .year, value: -2, to: .now) ?? .now
        dateContainer.addArrangedSubview(calendarIcon)
        dateContainer.addArrangedSubview(dateLabel)
        dateContainer.addArrangedSubview(birthDatePicker)

        // Observações: UITextView não tem placeholder nativo,
        // então sobrepomos um UILabel e escondemos quando há texto.
        let notesContainer = fieldContainer(alignment: .top)
        let noteIcon = iconView("note.text")
        noteIcon.setContentHuggingPriority(.required, for: .vertical)
        notesTextView.font = AppFont.body
        notesTextView.textColor = AppColors.primaryDeep
        notesTextView.backgroundColor = .clear
        notesTextView.textContainerInset = .zero
        notesTextView.delegate = self
        notesTextView.isScrollEnabled = false // cresce com o conteúdo
        notesTextView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        notesContainer.addArrangedSubview(noteIcon)

        let notesWrap = UIView()
        notesWrap.addSubview(notesTextView)
        notesWrap.addSubview(notesPlaceholder)
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        notesPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        notesPlaceholder.text = "Observações (alergias, comportamento, ração...)"
        notesPlaceholder.font = AppFont.body
        notesPlaceholder.textColor = AppColors.textSecondary.withAlphaComponent(0.7)
        notesPlaceholder.numberOfLines = 0
        NSLayoutConstraint.activate([
            notesTextView.topAnchor.constraint(equalTo: notesWrap.topAnchor),
            notesTextView.leadingAnchor.constraint(equalTo: notesWrap.leadingAnchor),
            notesTextView.trailingAnchor.constraint(equalTo: notesWrap.trailingAnchor),
            notesTextView.bottomAnchor.constraint(equalTo: notesWrap.bottomAnchor),

            notesPlaceholder.topAnchor.constraint(equalTo: notesWrap.topAnchor),
            notesPlaceholder.leadingAnchor.constraint(equalTo: notesWrap.leadingAnchor, constant: 5),
            notesPlaceholder.trailingAnchor.constraint(equalTo: notesWrap.trailingAnchor),
        ])
        notesContainer.addArrangedSubview(notesWrap)

        let stack = UIStackView(arrangedSubviews: [sectionHeader, nameContainer, dateContainer, notesContainer])
        stack.axis = .vertical
        stack.spacing = 12
        contentStack.addArrangedSubview(stack)
    }

    // MARK: Layout — Seção "Vacinas"

    private func setupVaccinesSection() {
        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        let label = sectionLabel("VACINAS")

        addVaccineButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addVaccineButton.setTitle(" Adicionar", for: .normal)
        addVaccineButton.setTitleColor(AppColors.terracotta, for: .normal)
        addVaccineButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold), forImageIn: .normal)
        addVaccineButton.titleLabel?.font = AppFont.captionMedium
        addVaccineButton.addTarget(self, action: #selector(addVaccineTapped), for: .touchUpInside)

        // UIView() vazio vira "mola" empilhada: rótulo à esquerda, botão à direita.
        headerRow.addArrangedSubview(label)
        headerRow.addArrangedSubview(UIView())
        headerRow.addArrangedSubview(addVaccineButton)

        vaccinesStack.axis = .vertical
        vaccinesStack.spacing = 10

        let stack = UIStackView(arrangedSubviews: [headerRow, vaccinesStack])
        stack.axis = .vertical
        stack.spacing = 12
        contentStack.addArrangedSubview(stack)
    }

    // MARK: Helpers de UI

    private func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = AppFont.sectionLabel
        label.textColor = AppColors.textSecondary
        return label
    }

    private func iconView(_ systemName: String) -> UIImageView {
        let view = UIImageView(image: UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)))
        view.tintColor = AppColors.terracotta
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 22).isActive = true
        view.contentMode = .scaleAspectFit
        return view
    }

    // Container "card" horizontal com margens internas (layoutMargins).
    private func fieldContainer(alignment: UIStackView.Alignment = .center) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = alignment
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        stack.backgroundColor = AppColors.card
        stack.layer.cornerRadius = 14
        return stack
    }

    // Adiciona uma linha de vacina (nova ou vinda do banco) à lista.
    private func addVaccineRow(vacina: Vacina? = nil) {
        let row = VaccineRowView()
        // Callback da lixeira: remove a linha do array e da tela.
        row.onRemove = { [weak self] removed in
            self?.vaccineRows.removeAll { $0 === removed }
            removed.removeFromSuperview()
            UISelectionFeedbackGenerator().selectionChanged()
        }
        if let vacina {
            row.nomeField.text = vacina.nome
            row.localField.text = vacina.local
            row.datePicker.date = vacina.dataAplicacao
        }
        vaccineRows.append(row)
        vaccinesStack.addArrangedSubview(row) // a stack reposiciona as linhas sozinha
    }

    // MARK: Dados

    // Pré-preenche os campos a partir de um Pet existente (modo editar).
    private func prefill(with pet: Pet) {
        nameField.text = pet.nome
        birthDatePicker.date = pet.dataNascimento
        notesTextView.text = pet.observacoes
        notesPlaceholder.isHidden = !pet.observacoes.isEmpty

        if let data = pet.foto {
            selectedPhotoData = data
            photoImageView.image = UIImage(data: data)
            placeholderPaw.isHidden = true
        }

        let ordenadas = pet.vacinas.sorted { $0.dataAplicacao < $1.dataAplicacao }
        for vacina in ordenadas {
            addVaccineRow(vacina: vacina)
        }
    }

    // Habilita/desabilita o botão Salvar: só com nome não vazio.
    private func updateSaveState() {
        let valid = !(nameField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        saveBarButton.isEnabled = valid
    }

    @objc private func nameChanged() {
        updateSaveState()
    }

    // Reduz a imagem para no máximo 1024 px e comprime em JPEG.
    // Evita estourar o store do SwiftData com fotos de 12 MP.
    private func downsampledJPEG(from image: UIImage, maxDimension: CGFloat = 1024, compression: CGFloat = 0.72) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1 // 1 px = 1 ponto: tamanho exato, independente da tela
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let rendered = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return rendered.jpegData(compressionQuality: compression)
    }

    private func applyPhoto(_ image: UIImage) {
        selectedPhotoData = downsampledJPEG(from: image)
        photoImageView.image = image
        placeholderPaw.isHidden = true
    }

    // MARK: Ações

    @objc private func cancelTapped() {
        dismiss(animated: true) // dispensa a sheet sem salvar
    }

    @objc private func addVaccineTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        addVaccineRow()
    }

    // ActionSheet: tirar foto / escolher da galeria / remover (remover só com foto).
    @objc private func photoTapped() {
        let alert = UIAlertController(title: "Foto do pet", message: nil, preferredStyle: .actionSheet)

        // No simulador não há câmera — por isso testamos antes de mostrar a opção.
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Tirar foto", style: .default) { [weak self] _ in
                self?.presentCamera()
            })
        }
        alert.addAction(UIAlertAction(title: "Escolher da galeria", style: .default) { [weak self] _ in
            self?.presentGallery()
        })
        if selectedPhotoData != nil {
            alert.addAction(UIAlertAction(title: "Remover foto", style: .destructive) { [weak self] _ in
                self?.selectedPhotoData = nil
                self?.photoImageView.image = nil
                self?.placeholderPaw.isHidden = false
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // Em iPad o action sheet precisa de uma âncora de popover.
        if let popover = alert.popoverPresentationController {
            popover.sourceView = photoContainer
            popover.sourceRect = photoContainer.bounds
        }
        present(alert, animated: true)
    }

    private func presentCamera() {
        // UIImagePickerController: o seletor "antigo" do UIKit —
        // obrigatório para a câmera (o PHPicker não acessa a câmera).
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentGallery() {
        // PHPickerViewController: a galeria moderna, fora de processo —
        // NÃO exige permissão de fotos do usuário.
        var config = PHPickerConfiguration()
        config.selectionLimit = 1 // só uma foto
        config.filter = .images    // só imagens, sem vídeos
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: Salvar

    @objc private func saveTapped() {
        let nome = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !nome.isEmpty else { return }

        let observacoes = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let nascimento = birthDatePicker.date

        // Modo adicionar → cria o Pet; modo editar → atualiza o existente.
        let pet: Pet
        switch mode {
        case .add:
            pet = Pet(nome: nome, dataNascimento: nascimento, observacoes: observacoes, foto: selectedPhotoData)
            modelContext.insert(pet) // agenda a criação no contexto
        case .edit(let existing):
            pet = existing
            pet.nome = nome
            pet.dataNascimento = nascimento
            pet.observacoes = observacoes
            pet.foto = selectedPhotoData
            // Estratégia simples e segura: apaga as vacinas do banco
            // e recria a partir das linhas — evita bugs de "linha ↔ registro".
            for vacina in pet.vacinas {
                modelContext.delete(vacina)
            }
        }

        // Linhas sem nome são ignoradas — não poluem o banco.
        for row in vaccineRows {
            let rowNome = row.vacinaNome
            guard !rowNome.isEmpty else { continue }
            let vacina = Vacina(nome: rowNome, dataAplicacao: row.datePicker.date, local: row.vacinaLocal, pet: pet)
            modelContext.insert(vacina)
        }

        // Até aqui tudo é "pendente"; save() é que grava de fato no disco.
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSave?() // avisa quem apresentou (lista/detalhe) para recarregar
            dismiss(animated: true)
        } catch {
            let alert = UIAlertController(title: "Erro ao salvar", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    // MARK: Teclado

    // keyboardWillShow: o iOS informa o quadro final do teclado;
    // aumentamos o contentInset inferior do scroll pela altura dele.
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let keyboardInView = view.convert(frame, from: nil) // do sistema de coordenadas da tela → da view
        let overlap = keyboardInView.maxY - view.bounds.height + view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = max(0, overlap) + 16
        scrollView.verticalScrollIndicatorInsets.bottom = scrollView.contentInset.bottom
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

// MARK: - UITextViewDelegate

extension PetFormViewController: UITextViewDelegate {
    // Mostra/esconde o placeholder manual conforme a digitação.
    func textViewDidChange(_ textView: UITextView) {
        notesPlaceholder.isHidden = !textView.text.isEmpty
    }
}

// MARK: - UIImagePickerControllerDelegate / UINavigationControllerDelegate

// O seletor da câmera devolve a foto via delegate — por isso os dois protocolos.
extension PetFormViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            applyPhoto(image)
        }
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

// O PHPicker entrega a foto via itemProvider — assíncrono, então voltamos
// para a main thread antes de atualizar a UI (regra de ouro no UIKit).
extension PetFormViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.applyPhoto(image)
            }
        }
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

// Previews do SwiftUI: o formulário isolado no canvas (novo, editar, Dark).

#Preview("Novo pet") {
    ControllerPreview {
        UINavigationController(rootViewController: PetFormViewController(modelContext: PreviewStore.seeded, pet: nil))
    }
    .ignoresSafeArea()
}

#Preview("Editar pet") {
    ControllerPreview {
        UINavigationController(rootViewController: PetFormViewController(modelContext: PreviewStore.seeded, pet: PreviewStore.thor))
    }
    .ignoresSafeArea()
}

#Preview("Editar pet — Dark") {
    ControllerPreview {
        UINavigationController(rootViewController: PetFormViewController(modelContext: PreviewStore.seeded, pet: PreviewStore.thor))
    }
    .preferredColorScheme(.dark)
    .ignoresSafeArea()
}
#endif
