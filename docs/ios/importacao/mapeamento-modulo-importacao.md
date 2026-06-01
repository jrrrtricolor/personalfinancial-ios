# Mapeamento Do Módulo De Importação

Este documento mapeia as classes e funções do módulo de importação de arquivos
do repositório de referência `jrrrtricolor/PersonalFinancialSystem`.

O objetivo é deixar claro o que existe antes de implementar a versão
Apple-native.

## Fluxo Geral

1. A tela lista arquivos disponíveis no diretório de entrada.
2. O usuário escolhe um arquivo.
3. A origem é normalizada pela extensão do arquivo.
4. O parser correto extrai registros brutos.
5. O importador STG persiste a importação e os registros brutos.
6. O promotor Business interpreta os registros da importação.
7. O arquivo importado com sucesso é movido para o diretório de importados.
8. A tela exibe totais de STG e Business.

## Arquivos De Referência

| Arquivo | Papel |
| --- | --- |
| `financeiro/models.py` | Modelo de banco STG e Business |
| `financeiro/views/importacoes.py` | Fluxo web da importação |
| `financeiro/importacao/stg.py` | Persistência de arquivos na camada STG |
| `financeiro/parsers/base.py` | Contrato comum dos parsers |
| `financeiro/parsers/tipos.py` | Tipos compartilhados entre parser e STG |
| `financeiro/parsers/aib_csv.py` | Parser de CSV do AIB |
| `financeiro/parsers/revolut_pdf.py` | Parser de PDF do Revolut |
| `financeiro/parsers/factory.py` | Seleção do parser por origem |
| `financeiro/parsers/normalizador.py` | Normalização de dados brutos |
| `financeiro/parsers/validadores.py` | Validação de transações extraídas |
| `financeiro/parsers/pdf.py` | Utilitário de linhas PDF |
| `financeiro/parsers/__init__.py` | Exportação pública dos parsers |

## Modelos De Banco

### `OrigemImportacao`

Fonte externa de dados financeiros.

Funções:

- `__str__`: retorna o nome da origem.

### `ImportacaoArquivo`

Arquivo recebido para importação.

Classes internas:

- `Status`: enum textual com `pendente`, `processando`, `concluida`, `falhou` e
  `removida`;
- `TipoArquivo`: enum textual com `csv` e `pdf`.

Funções:

- `__str__`: retorna origem e nome do arquivo.

### `RegistroImportado`

Registro bruto extraído de arquivo importado.

Funções:

- `__str__`: retorna identificação do registro e da importação.

### `Categoria`

Categoria financeira de negócio.

Funções:

- `__str__`: retorna o nome da categoria.

### `TipoMovimento`

Tipo semântico de movimentação financeira.

Funções:

- `__str__`: retorna o nome do tipo.

### `RegraCategoriaManual`

Regra manual para categorizar descrições recorrentes.

Funções:

- `__str__`: retorna descrição e categoria vinculada.

### `Transacao`

Transação normalizada e interpretada para relatórios.

Funções:

- `__str__`: retorna data, descrição normalizada, valor e moeda.

## Tela E Orquestração Web

Arquivo: `financeiro/views/importacoes.py`.

### `ArquivoEntrada`

Representa um arquivo disponível para importação.

Campos:

- `nome`;
- `tamanho_kb`;
- `origem_sugerida`.

### `listar_importacoes`

Renderiza a tela principal de importação de arquivos.

### `atualizar_painel_importacoes`

Atualiza o painel de importações via HTMX ou renderiza a tela completa.

### `importar_arquivo`

Orquestra a importação selecionada pelo usuário.

Responsabilidades:

- resolver o arquivo dentro do diretório permitido;
- normalizar a origem pela extensão;
- importar o arquivo para STG;
- promover dados para Business;
- contar registros e transações do arquivo;
- mover arquivo importado com sucesso;
- montar mensagem de retorno.

### `_normalizar_origem_por_arquivo`

Garante que CSV seja tratado como `aib_csv` e PDF como `revolut_pdf`.

### `_montar_contexto`

Monta o contexto compartilhado da tela de importações.

### `_listar_importacoes`

Lista importações com totais de registros STG e transações Business.

### `_listar_arquivos_entrada`

Lista arquivos `.csv` e `.pdf` disponíveis no diretório de entrada.

### `_resolver_arquivo_entrada`

Resolve e valida um arquivo dentro do diretório permitido de entrada.

Proteções:

- rejeita nome vazio;
- rejeita path traversal;
- rejeita arquivo inexistente.

### `_mover_arquivo_para_importados`

Move arquivo importado com sucesso para o diretório de importados.

### `_criar_destino_importado`

Cria um caminho de destino sem sobrescrever arquivo existente.

### `_sugerir_origem`

Sugere `revolut_pdf` para PDFs ou arquivos com `revolut` no nome. Caso
contrário, sugere `aib_csv`.

## Camada STG

Arquivo: `financeiro/importacao/stg.py`.

### `ResultadoImportacaoStg`

Resultado da persistência de um arquivo na camada STG.

Campos:

- `importacao`;
- `registros_criados`;
- `registros_existentes`.

### `ImportadorStg`

Importa registros brutos para a camada STG.

### `ImportadorStg.importar`

Persiste um arquivo financeiro na camada STG.

Fluxo:

- valida existência do arquivo;
- cria parser pela origem;
- extrai registros brutos;
- rejeita arquivo sem registros;
- calcula hash do arquivo;
- obtém ou cria origem;
- extrai período das transações;
- cria ou reutiliza importação;
- persiste registros brutos;
- marca importação como concluída.

### `ImportadorStg._obter_origem`

Obtém ou cria a origem de importação.

### `ImportadorStg._persistir_registros`

Persiste registros brutos extraídos pelo parser.

### `ImportadorStg._calcular_hash_arquivo`

Calcula SHA-256 do conteúdo do arquivo.

### `ImportadorStg._calcular_hash_registro`

Calcula SHA-256 determinístico de um registro bruto.

### `ImportadorStg._calcular_hash_json`

Calcula SHA-256 a partir de conteúdo serializado em JSON ordenado.

### `ImportadorStg._identificar_tipo_arquivo`

Identifica `csv` ou `pdf` pelo sufixo do arquivo.

### `ImportadorStg._extrair_periodo`

Extrai data inicial e final a partir das transações extraídas.

## Tipos Compartilhados

Arquivo: `financeiro/parsers/tipos.py`.

### `RegistroBruto`

Contrato entre parser e camada STG.

Campos:

- `numero_linha`;
- `numero_pagina`;
- `secao`;
- `dados`.

Funções:

- `__post_init__`: valida números não negativos e protege `dados` contra
  mutação acidental.

### `DadosTransacaoExtraida`

Representa uma transação lida da fonte, ainda antes da camada Business.

Campos:

- `numero_linha`;
- `conta`;
- `data_transacao`;
- `descricao_original`;
- `valor`;
- `moeda`;
- `saldo`;
- `tipo_transacao`;
- `valor_local`;
- `moeda_local`;
- `origem`;
- `dados_brutos`.

Funções:

- `__post_init__`: protege `dados_brutos` contra mutação acidental.

## Contrato Base Dos Parsers

Arquivo: `financeiro/parsers/base.py`.

### `ParserArquivoFinanceiro`

Interface comum para parsers financeiros.

### `ParserArquivoFinanceiro.__init__`

Inicializa caminho do arquivo, normalizador e validador.

### `ParserArquivoFinanceiro.extrair`

Extrai registros brutos do arquivo financeiro.

### `ParserArquivoFinanceiro.extrair_transacoes`

Extrai transações estruturadas do arquivo financeiro.

### `ParserArquivoFinanceiro._iterar_linhas`

Itera dados da fonte mantendo referência da linha de origem.

### `ParserArquivoFinanceiro._mapear_transacao`

Mapeia dados brutos da fonte para `DadosTransacaoExtraida`.

### `ParserArquivoFinanceiro._validar_tipo_transacao`

Valida o tipo de transação informado ou inferido pela fonte.

### `ParserArquivoFinanceiro._criar_registro_bruto`

Cria `RegistroBruto` com seção do parser.

### `ParserArquivoFinanceiro._criar_transacao`

Cria `DadosTransacaoExtraida` e executa validação comum.

## Parser AIB CSV

Arquivo: `financeiro/parsers/aib_csv.py`.

### `AibCsvParser`

Extrai registros brutos e transações estruturadas de CSV exportado pelo AIB.

Constantes:

- `SECAO = "aib_csv"`;
- `COLUNAS_OBRIGATORIAS`;
- `TIPOS_TRANSACAO_SUPORTADOS`.

Tipos suportados:

- `ATM`;
- `Credit`;
- `Debit`;
- `Direct Debit`.

### `AibCsvParser.__init__`

Inicializa parser com caminho, encoding e normalizador.

### `AibCsvParser.extrair`

Lê o CSV e retorna `RegistroBruto` para cada linha.

### `AibCsvParser.extrair_transacoes`

Lê o CSV e retorna `DadosTransacaoExtraida` para cada linha.

### `AibCsvParser._ler_dataframe`

Lê CSV com pandas, preservando valores como texto.

### `AibCsvParser._validar_colunas`

Garante presença das colunas obrigatórias do AIB.

### `AibCsvParser._iterar_linhas`

Converte linhas do DataFrame em pares de número de linha e dicionário.

### `AibCsvParser._mapear_transacao`

Mapeia uma linha AIB para uma transação extraída.

Regras:

- data usa formato `dd/mm/aaaa`;
- débito vira valor negativo;
- crédito vira valor positivo;
- descrição vem de `Description1`, `Description2` e `Description3`.

### `AibCsvParser._validar_tipo_transacao`

Rejeita tipos de transação AIB não mapeados.

### `AibCsvParser._validar_dataframe`

Garante que a estrutura recebida é um DataFrame.

## Parser Revolut PDF

Arquivo: `financeiro/parsers/revolut_pdf.py`.

### `RevolutPdfParser`

Extrai registros brutos e transações estruturadas de extratos PDF do Revolut.

Constantes:

- `SECAO = "revolut_pdf"`;
- `CONTA_CORRENTE = "Account"`;
- `POCKETS = "Personal and Group Pockets"`;
- `TIPOS_TRANSACAO_SUPORTADOS`;
- `MESES`.

Tipos suportados:

- `money_out`;
- `money_in`.

### `RevolutPdfParser.__init__`

Inicializa parser com caminho, normalizador e extrator de linhas PDF.

### `RevolutPdfParser.extrair`

Retorna registros brutos extraídos do PDF.

### `RevolutPdfParser.extrair_transacoes`

Retorna transações estruturadas extraídas do PDF.

### `RevolutPdfParser._ler_linhas_pdf`

Abre o PDF, percorre páginas e extrai linhas transacionais.

### `RevolutPdfParser._iterar_linhas`

Percorre linhas do PDF, identifica seção atual e monta transações.

### `RevolutPdfParser._extrair_dados_transacao`

Extrai data, descrição, dinheiro de saída, dinheiro de entrada, saldo, seção e
detalhes.

### `RevolutPdfParser._mapear_transacao`

Mapeia linha Revolut para `DadosTransacaoExtraida`.

Regras:

- `money_out` vira valor negativo;
- `money_in` vira valor positivo;
- moeda atual é `EUR`;
- conta recebe a seção do extrato;
- detalhes complementares entram na descrição original.

### `RevolutPdfParser._validar_tipo_transacao`

Rejeita tipo Revolut não mapeado.

### `RevolutPdfParser._validar_dados_pdf`

Garante que a estrutura intermediária do PDF é um dicionário.

### `RevolutPdfParser._parse_data_revolut`

Converte datas textuais do Revolut para data normalizada.

Formatos aceitos:

- `24 Apr 2026`;
- `Apr 24, 2026`.

### `RevolutPdfParser._montar_data_textual`

Monta a data a partir das três primeiras palavras da linha.

### `RevolutPdfParser._montar_texto_intervalo`

Monta texto com palavras posicionadas dentro de uma faixa horizontal.

### `RevolutPdfParser._linha_inicia_transacao`

Identifica se a linha começa com data e inicia uma transação.

### `RevolutPdfParser._linha_complementar`

Identifica linhas complementares de transação.

Prefixos aceitos:

- `From:`;
- `Reference:`;
- `To:`.

### `RevolutPdfParser._deve_ignorar_linha`

Ignora cabeçalhos, rodapés e textos institucionais do extrato.

## Normalizador

Arquivo: `financeiro/parsers/normalizador.py`.

### `NormalizadorRegistroBruto`

Normaliza estruturas brutas antes da persistência STG, sem interpretar
significado financeiro.

### `NormalizadorRegistroBruto.normalizar_dados`

Remove espaços das chaves do dicionário.

### `NormalizadorRegistroBruto.parse_data`

Converte data textual para data normalizada.

### `NormalizadorRegistroBruto.parse_decimal`

Remove símbolo de euro e separadores, depois converte texto para `Decimal`.

### `NormalizadorRegistroBruto.calcular_valor_debito_credito`

Calcula valor assinado a partir de débito ou crédito.

Regras:

- débito e crédito não podem estar ambos vazios;
- débito e crédito não podem estar ambos preenchidos;
- débito vira valor negativo;
- crédito vira valor positivo.

### `NormalizadorRegistroBruto.montar_descricao_original`

Monta descrição preservada com partes textuais não vazias.

### `NormalizadorRegistroBruto.normalizar_descricao`

Normaliza descrição para comparação determinística.

## Validador

Arquivo: `financeiro/parsers/validadores.py`.

### `ValidadorTransacaoExtraida`

Valida o contrato comum de transações extraídas.

### `ValidadorTransacaoExtraida.validar`

Valida todos os campos obrigatórios de `DadosTransacaoExtraida`.

### `ValidadorTransacaoExtraida._validar_numero_linha`

Garante que o número da linha é inteiro e não negativo.

### `ValidadorTransacaoExtraida._validar_texto`

Garante que campos textuais obrigatórios são strings preenchidas.

### `ValidadorTransacaoExtraida._validar_moeda`

Garante moeda ISO de três letras.

### `ValidadorTransacaoExtraida._validar_tipo`

Garante que um campo possui o tipo esperado.

## Factory

Arquivo: `financeiro/parsers/factory.py`.

### `ParserArquivoFactory`

Cria parsers financeiros a partir da origem informada.

### `ParserArquivoFactory.criar`

Retorna o parser correto para a origem.

Mapeamento atual:

- `aib_csv` -> `AibCsvParser`;
- `revolut_pdf` -> `RevolutPdfParser`.

## PDF

Arquivo: `financeiro/parsers/pdf.py`.

### `PdfPlumberLineExtractor`

Agrupa palavras extraídas por `pdfplumber` em linhas textuais.

### `PdfPlumberLineExtractor.agrupar_palavras_por_linha`

Agrupa palavras por coordenada vertical e ordena por posição horizontal.

## Exportação Pública

Arquivo: `financeiro/parsers/__init__.py`.

Símbolos exportados:

- `AibCsvParser`;
- `DadosTransacaoExtraida`;
- `NormalizadorRegistroBruto`;
- `ParserArquivoFactory`;
- `ParserArquivoFinanceiro`;
- `RegistroBruto`;
- `ValidadorTransacaoExtraida`.

## Pontos Que Devem Ser Preservados No iOS

- A importação deve preservar dados brutos.
- Parser não deve salvar diretamente no banco.
- Parser não deve aplicar interpretação financeira final.
- STG não deve responder relatórios.
- Business deve manter vínculo com importação e registro bruto.
- Hash de arquivo evita importação duplicada.
- Hash de registro evita duplicidade dentro da importação.
- Valor monetário deve usar `Decimal`.
- CSV deve ser tratado como AIB.
- PDF deve ser tratado como Revolut.
- Pockets do Revolut devem continuar separados da conta corrente.
