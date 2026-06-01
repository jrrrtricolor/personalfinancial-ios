# Plano De Implementação Do Módulo De Importação

Este plano define uma implementação simples para o `personalfinancial-ios`, sem
criar módulos Swift prematuros.

## Diretriz

Começar com uma estrutura única dentro de `PersonalFinancial/`.

Não criar Swift Packages neste momento.

## Estrutura Inicial

```text
PersonalFinancial
├── App
├── Dominio
├── Importacao
├── Persistencia
└── Relatorios
```

## Ordem Recomendada

### 1. Modelo De Dados

Criar representações equivalentes ao banco de referência:

- `OrigemImportacao`;
- `ImportacaoArquivo`;
- `RegistroImportado`;
- `Categoria`;
- `TipoMovimento`;
- `RegraCategoriaManual`;
- `Transacao`.

Critério de qualidade:

- não usar `Double` ou `Float` para dinheiro;
- preservar campos equivalentes ao banco de referência;
- manter nomes claros em português brasileiro.

### 2. Tipos De Importação

Criar os contratos usados antes da persistência:

- `RegistroBruto`;
- `DadosTransacaoExtraida`;
- `ResultadoImportacaoStg`.

### 3. Normalizador E Validador

Implementar:

- normalização de chaves;
- parsing de data;
- parsing de decimal;
- cálculo de débito e crédito;
- montagem de descrição original;
- normalização de descrição;
- validação de transação extraída.

### 4. Parser AIB CSV

Implementar primeiro o CSV do AIB.

Motivos:

- é mais simples que PDF;
- é determinístico;
- valida o fluxo completo de importação;
- reduz risco inicial.

### 5. Importador STG

Implementar o importador que:

- calcula hash do arquivo;
- obtém ou cria origem;
- cria importação;
- persiste registros brutos;
- calcula período;
- evita duplicidade.

### 6. Tela Simples De Importação

Criar uma tela inicial que permita:

- selecionar arquivo;
- listar importações;
- exibir status;
- exibir quantidade de registros importados.

### 7. Revolut PDF

Implementar depois do fluxo AIB estar funcionando.

Motivos:

- PDF exige leitura por layout;
- regras de seção são mais frágeis;
- pockets exigem cuidado para não confundir provisionamento com despesa.

## Fora Do Escopo Inicial

- sincronização iCloud;
- Apple Watch;
- gráficos;
- relatórios avançados;
- importação Revolut PDF;
- categorização automática avançada;
- edição completa de regras manuais.

## Primeiro Commit De Código Sugerido

```text
Feature:: adiciona modelos base de importação
```

Esse commit deve conter apenas o modelo base necessário para representar o banco
de referência no app.
