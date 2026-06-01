import Foundation
import SQLite3

/// Erros possíveis ao abrir ou preparar o banco financeiro local.
enum ErroBancoDados: Error, Equatable {
    case aberturaFalhou(String)
    case schemaNaoEncontrado(URL)
    case execucaoFalhou(String)
}

/// Gerencia a conexão SQLite usada pelo app.
final class BancoDados {
    private let urlBanco: URL
    private let urlSchema: URL
    private var conexao: OpaquePointer?

    init(urlBanco: URL, urlSchema: URL) {
        self.urlBanco = urlBanco
        self.urlSchema = urlSchema
    }

    deinit {
        fechar()
    }

    /// Abrir a conexão e ativar chaves estrangeiras.
    func abrir() throws {
        guard conexao == nil else {
            return
        }

        if sqlite3_open(urlBanco.path, &conexao) != SQLITE_OK {
            let mensagem = mensagemErro()
            sqlite3_close(conexao)
            conexao = nil
            throw ErroBancoDados.aberturaFalhou(mensagem)
        }

        try executar("PRAGMA foreign_keys = ON;")
    }

    /// Criar a estrutura do banco quando ela ainda não existir.
    func criarEstruturaSeNecessario() throws {
        try abrir()

        guard FileManager.default.fileExists(atPath: urlSchema.path) else {
            throw ErroBancoDados.schemaNaoEncontrado(urlSchema)
        }

        let schema = try String(contentsOf: urlSchema, encoding: .utf8)
        try executar(schema)
    }

    /// Fechar a conexão aberta com SQLite.
    func fechar() {
        guard let conexaoAberta = conexao else {
            return
        }

        sqlite3_close(conexaoAberta)
        conexao = nil
    }

    /// Executar comandos SQL em lote.
    private func executar(_ sql: String) throws {
        var erro: UnsafeMutablePointer<CChar>?

        if sqlite3_exec(conexao, sql, nil, nil, &erro) != SQLITE_OK {
            let mensagem = erro.map { String(cString: $0) } ?? mensagemErro()
            sqlite3_free(erro)
            throw ErroBancoDados.execucaoFalhou(mensagem)
        }
    }

    /// Obter a última mensagem de erro da conexão.
    private func mensagemErro() -> String {
        guard let conexao else {
            return "Conexão SQLite indisponível."
        }

        return String(cString: sqlite3_errmsg(conexao))
    }
}
