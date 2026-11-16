//
//  PetListViewController.swift
//  Vacipet
//
//  Tela inicial: lista de pets em cards (foto, nome, idade,
//  vacinas) com estado vazio e botão flutuante de pata para adicionar.
//

import UIKit
import SwiftData

// UIViewController é a unidade de tela no UIKit.
// Os três: viewDidLoad (uma vez, ao carregar a view),
// viewWillAppear (toda vez que a tela aparece) e ações de botão.
final class PetListViewController: UIViewController {

    // MARK: Dependências e estado

    // Injetado pelo SceneDelegate — o VC nunca cria o contexto sozinho.
    private let modelContext: ModelContext
    private var pets: [Pet] = [] // cache de dados para a UI (UIKit não tem @Query)

    // MARK: Subviews

    // lazy só cria o objeto no primeiro acesso (quando adicionamos na view).
    private lazy var collectionView: UICollectionView = {
        // Compositional Layout: item → grupo → seção.
        // Item: largura total da tela, altura fixa de 108 pt.
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(108))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // Grupo vertical empilha os itens (cada um vira uma "linha").
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(108))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        // Seção: espaçamento entre cards e margens, inclusive embaixo
        // (120 pt para o conteúdo não ficar escondido atrás do botão).
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 14
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 120, trailing: 20)

        let layout = UICollectionViewCompositionalLayout(section: section)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self // quem fornece as células (extension lá embaixo)
        collectionView.delegate = self    // quem responde a toques/seleção
        // Registrar a classe ensina a collection a reutilizar células (pattern reuse).
        collectionView.register(PetCardCell.self, forCellWithReuseIdentifier: PetCardCell.reuseID)
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

    private let emptyStateView = EmptyStateView()
    private let addButton = UIButton(type: .system)

    // MARK: Inicialização

    // Injeção de dependência via init: o VC recebe o ModelContext pronto.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init(nibName: nil, bundle: nil) // sem nib: tudo construído por código
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não suportado")
    }

    // MARK: Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Meus Pets" // large title por conta do UINavigationController
        view.backgroundColor = AppColors.background

        // Estilo da barra de navegação: large title arredondado na cor primária profunda.
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = AppColors.background
        appearance.largeTitleTextAttributes = [
            .font: AppFont.roundedTitle,
            .foregroundColor: AppColors.primaryDeep,
        ]
        appearance.titleTextAttributes = [
            .font: AppFont.headline,
            .foregroundColor: AppColors.primaryDeep,
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        // Instala a collectionView ocupando a tela inteira.
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        // Botão flutuante de "adicionar": círculo de pata na cor primária.
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setImage(UIImage(systemName: "pawprint.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = AppColors.primary
        addButton.layer.cornerRadius = 36 // metade do diâmetro = círculo
        addButton.layer.shadowColor = AppColors.primary.cgColor
        addButton.layer.shadowOpacity = 0.45
        addButton.layer.shadowRadius = 14
        addButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        addButton.addTarget(self, action: #selector(addPetTapped), for: .touchUpInside)
        addButton.accessibilityLabel = "Adicionar pet"
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // safeAreaLayoutGuide respeita a área do notch/home indicator do aparelho.
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            addButton.widthAnchor.constraint(equalToConstant: 72),
            addButton.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Recarrega os dados sempre que a tela aparece.
        // (pop de uma tela anterior dispara viewWillAppear aqui.)
        reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Pulinho no botão quando a lista está vazia, para chamar atenção.
        guard pets.isEmpty else { return }
        UIView.animate(withDuration: 0.35, delay: 0.25, usingSpringWithDamping: 0.55, initialSpringVelocity: 0.6, options: [], animations: {
            self.addButton.transform = CGAffineTransform(scaleX: 1.14, y: 1.14)
        }, completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.addButton.transform = .identity
            }
        })
    }

    // MARK: Dados

    private func reload() {
        // Busca todos os pets no SwiftData. try? devolve nil em erro;
        // como lista vazia já é um estado válido da UI, engolimos o erro.
        let descriptor = FetchDescriptor<Pet>()
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        // Ordena em memória (localizedCaseInsensitiveCompare respeita acentos pt-BR).
        pets = fetched.sorted { $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending }

        let isEmpty = pets.isEmpty
        emptyStateView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        collectionView.reloadData()
    }

    // MARK: Ações

    @objc private func addPetTapped() {
        UISelectionFeedbackGenerator().selectionChanged() // haptic de seleção

        let form = PetFormViewController(modelContext: modelContext, pet: nil) // nil = modo "adicionar"
        // A sheet não dispara viewWillAppear ao ser dispensada — por isso
        // o form avisa via callback para recarregar a lista.
        form.onSave = { [weak self] in self?.reload() }

        // UINavigationController dentro da sheet: dá a barra superior
        // com "Cancelar" / "Salvar" (navigationItem).
        let nav = UINavigationController(rootViewController: form)
        nav.modalPresentationStyle = .pageSheet

        // Configura a sheet: dois detents (meia tela e tela cheia),
        // "puxador" visível no topo e cantos arredondados.
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        present(nav, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension PetListViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    // DataSource = QUANTAS e QUAIS células existem.

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // dequeueReusableCell recicla uma célula fora da tela;
        // o force cast é seguro porque registramos este tipo acima.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PetCardCell.reuseID, for: indexPath) as! PetCardCell
        cell.configure(pet: pets[indexPath.item])
        return cell
    }

    // Delegate = o que acontece quando o usuário interage (no caso, seleciona).
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true) // remove o destaque azul
        let detail = PetDetailViewController(modelContext: modelContext, pet: pets[indexPath.item])
        navigationController?.pushViewController(detail, animated: true) // push na pilha de navegação
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

// Previews do SwiftUI: a lista isolada no canvas (vazia, com pets, Dark).

#Preview("Lista vazia") {
    ControllerPreview {
        UINavigationController(rootViewController: PetListViewController(modelContext: PreviewStore.empty))
    }
    .ignoresSafeArea()
}

#Preview("Lista com pets") {
    ControllerPreview {
        UINavigationController(rootViewController: PetListViewController(modelContext: PreviewStore.seeded))
    }
    .ignoresSafeArea()
}

#Preview("Lista com pets — Dark") {
    ControllerPreview {
        UINavigationController(rootViewController: PetListViewController(modelContext: PreviewStore.seeded))
    }
    .preferredColorScheme(.dark)
    .ignoresSafeArea()
}
#endif
