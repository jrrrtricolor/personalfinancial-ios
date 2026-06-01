# Fluxo Git

## Branches

O desenvolvimento deve acontecer sempre na branch `develop`.

A branch `main` deve representar o estado estável do produto e receber mudanças
somente por Pull Request.

Fluxo oficial:

```text
develop -> Pull Request -> main
```

## Branches De Trabalho

Branches de trabalho devem nascer a partir de `develop`.

Exemplos:

```text
feature/modelo-dominio
feature/importacao-aib-csv
feature/clareza-financeira
feature/watch-resumo
fix/calculo-gasto-real
docs/padroes-projeto
refactor/separar-normalizador
```

## Commits

Commits devem ser pequenos, completos e sucintos.

Formato obrigatório:

```text
Tag:: mensagem curta
```

Tags iniciais:

```text
Docs::
Feature::
Fix::
Refactor::
Test::
Chore::
Build::
Style::
CI::
```

Exemplos:

```text
Docs:: define padrões iniciais do projeto
Feature:: adiciona modelo de transação financeira
Fix:: corrige cálculo de gasto real
Refactor:: separa normalização de descrição
Test:: cobre classificação de transferências
Chore:: configura swift-format
Build:: cria estrutura inicial do app
```

## Mensagens De Commit

A mensagem deve explicar o que foi feito de forma completa, porém sucinta.

Evitar mensagens vagas:

```text
ajustes
wip
fix
coisas
mudanças
update
```

## Separação De Commits

Arquivos devem ser agrupados por contexto.

Exemplo de separação adequada:

```text
Docs:: define arquitetura inicial
Build:: cria estrutura de pacotes Swift
Feature:: adiciona entidades financeiras
Test:: cobre regras de tipo de movimento
```

Evitar misturar no mesmo commit:

- documentação e feature sem relação direta;
- teste e mudança visual independente;
- configuração de build e regra de domínio;
- várias features independentes.

## Pull Requests

Todo Pull Request para `main` deve conter:

- resumo do que foi entregue;
- lista de testes executados;
- riscos conhecidos, quando existirem;
- observações de migração, quando aplicável.
