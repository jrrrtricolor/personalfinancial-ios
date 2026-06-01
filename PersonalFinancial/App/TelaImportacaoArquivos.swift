import SwiftUI
import UniformTypeIdentifiers

/// Tela principal de importação de arquivos financeiros.
struct TelaImportacaoArquivos: View {
    @StateObject private var viewModel: ImportacaoArquivosViewModel
    @State private var exibindoSeletorArquivo = false

    @MainActor
    init() {
        _viewModel = StateObject(
            wrappedValue: ImportacaoArquivosViewModel(
                bancoDados: ImportacaoArquivosViewModel.criarBancoPadrao()
            )
        )
    }

    init(viewModel: ImportacaoArquivosViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Selecionar arquivo") {
                        exibindoSeletorArquivo = true
                    }

                    if let mensagem = viewModel.mensagem {
                        Text(mensagem)
                            .foregroundStyle(viewModel.mensagemErro ? .red : .secondary)
                    }
                }

                Section("Importações") {
                    ForEach(viewModel.importacoes) { importacao in
                        linhaImportacao(importacao)
                    }
                }
            }
            .navigationTitle("Importação")
            .task {
                await viewModel.carregarImportacoes()
            }
            .fileImporter(
                isPresented: $exibindoSeletorArquivo,
                allowedContentTypes: [.commaSeparatedText, .pdf],
                allowsMultipleSelection: false,
                onCompletion: importarArquivo
            )
        }
    }

    private func linhaImportacao(_ importacao: ImportacaoArquivoResumo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(importacao.nomeArquivo)
                .font(.headline)

            Text("\(importacao.origemCodigo) · \(importacao.status)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(importacao.totalRegistros) registros STG · \(importacao.totalTransacoes) transações Business")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func importarArquivo(_ resultado: Result<[URL], Error>) {
        Task {
            await viewModel.importar(resultado)
        }
    }
}

/// Estado e ações da tela de importação.
@MainActor
final class ImportacaoArquivosViewModel: ObservableObject {
    @Published private(set) var importacoes: [ImportacaoArquivoResumo] = []
    @Published private(set) var mensagem: String?
    @Published private(set) var mensagemErro = false

    private let bancoDados: BancoDados
    private let repositorio: RepositorioImportacaoSQLite
    private let importador: ImportadorStg

    init(bancoDados: BancoDados) {
        self.bancoDados = bancoDados
        repositorio = RepositorioImportacaoSQLite(bancoDados: bancoDados)
        importador = ImportadorStg(repositorio: repositorio)
    }

    /// Carregar importações já registradas no banco.
    func carregarImportacoes() async {
        do {
            try bancoDados.criarEstruturaSeNecessario()
            importacoes = try repositorio.listarImportacoes()
        } catch {
            definirErro(error)
        }
    }

    /// Importar arquivo selecionado pelo usuário.
    func importar(_ resultado: Result<[URL], Error>) async {
        do {
            let url = try obterArquivoSelecionado(resultado)
            let acesso = url.startAccessingSecurityScopedResource()
            defer {
                if acesso {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let origem = sugerirOrigem(url)
            let resultado = try importador.importar(origem: origem, urlArquivo: url)
            importacoes = try repositorio.listarImportacoes()
            definirSucesso(resultado)
        } catch {
            definirErro(error)
        }
    }

    private func obterArquivoSelecionado(_ resultado: Result<[URL], Error>) throws -> URL {
        let urls = try resultado.get()

        guard let url = urls.first else {
            throw ErroImportacao.csvInvalido("Selecione um arquivo para importação.")
        }

        return url
    }

    private func definirSucesso(_ resultado: ResultadoImportacaoStg) {
        mensagemErro = false
        mensagem = "STG: \(resultado.registrosCriados) novos e \(resultado.registrosExistentes) existentes."
    }

    private func definirErro(_ erro: Error) {
        mensagemErro = true
        mensagem = String(describing: erro)
    }

    private func sugerirOrigem(_ url: URL) -> String {
        let nome = url.lastPathComponent.lowercased()
        return url.pathExtension.lowercased() == "pdf" || nome.contains("revolut")
            ? "revolut_pdf"
            : "aib_csv"
    }

    static func criarBancoPadrao() -> BancoDados {
        BancoDados(
            urlBanco: urlBancoPadrao(),
            urlSchema: urlSchemaPadrao()
        )
    }

    private static func urlBancoPadrao() -> URL {
        let diretorio = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("PersonalFinancial", isDirectory: true)

        try? FileManager.default.createDirectory(at: diretorio, withIntermediateDirectories: true)
        return diretorio.appendingPathComponent("personalfinancial.sqlite3")
    }

    private static func urlSchemaPadrao() -> URL {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "BancoDados", withExtension: "sql") {
            return url
        }
        #endif

        return Bundle.main.url(forResource: "BancoDados", withExtension: "sql")
            ?? URL(fileURLWithPath: "PersonalFinancial/Persistencia/BancoDados.sql")
    }
}
