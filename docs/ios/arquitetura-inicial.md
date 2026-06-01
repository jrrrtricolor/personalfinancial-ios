# Arquitetura Inicial

## Objetivo

Criar um sistema Apple-native para clareza financeira pessoal, com suporte a
macOS, iPhone e Apple Watch.

O projeto deve preservar o princípio central do sistema de referência:

> Movimentação de dinheiro não significa necessariamente despesa.

O app não deve ser tratado como um aplicativo tradicional de orçamento. Ele deve
ser um mecanismo de observabilidade financeira pessoal, capaz de importar,
normalizar, interpretar e consultar transações financeiras de forma auditável.

## Plataformas

- macOS: importação de arquivos, auditoria, manutenção e análise completa.
- iPhone: consulta diária, categorização manual e acompanhamento de período.
- Apple Watch: indicadores rápidos e resumos financeiros essenciais.

## Tecnologias Iniciais

- Swift.
- SwiftUI.
- SwiftData.
- Swift Package Manager.
- Swift Testing para testes unitários.
- XCTest para testes de interface quando necessário.
- WatchConnectivity para integração com Apple Watch.

## Estrutura Sugerida

```text
personalfinancial-ios
├── PersonalFinancial.xcodeproj
├── Apps
│   ├── PersonalFinancialApp
│   └── PersonalFinancialWatchApp
├── Packages
│   ├── FinancialDomain
│   ├── FinancialImporting
│   ├── FinancialPersistence
│   ├── FinancialReports
│   ├── FinancialDesign
│   └── FinancialTesting
├── docs
│   ├── arquitetura
│   ├── decisoes
│   └── qualidade
└── scripts
```

## Camadas

### FinancialDomain

Camada central do sistema. Deve conter as regras financeiras puras.

Responsabilidades:

- representar entidades financeiras;
- representar categorias;
- representar tipos de movimento;
- normalizar descrições;
- classificar movimentos de forma determinística;
- calcular gasto real;
- validar transações;
- gerar hashes canônicos;
- proteger regras de negócio contra detalhes de UI e persistência.

Esta camada não pode depender de SwiftUI, SwiftData, CloudKit,
WatchConnectivity ou APIs de interface.

### FinancialImporting

Camada responsável por transformar arquivos externos em registros canônicos.

Responsabilidades:

- importar AIB CSV;
- preparar suporte futuro para Revolut PDF;
- validar formato de arquivo;
- preservar dados brutos;
- calcular hash de arquivo;
- calcular hash de registro;
- reportar erros de importação de forma rastreável.

Importadores não devem salvar dados diretamente na persistência.

### FinancialPersistence

Camada responsável pelo armazenamento local.

Responsabilidades:

- persistir importações;
- persistir registros brutos;
- persistir transações interpretadas;
- persistir categorias;
- persistir regras manuais;
- isolar SwiftData do domínio financeiro.

SwiftData deve permanecer nesta camada para evitar acoplamento entre domínio e
infraestrutura.

### FinancialReports

Camada responsável por montar dados prontos para consumo pelas telas.

Responsabilidades:

- montar indicadores financeiros;
- agrupar gastos por categoria;
- montar visão de reservas;
- calcular valor não explicado;
- detectar padrões financeiros;
- aplicar filtros de período.

### FinancialDesign

Camada responsável pelo design system compartilhado.

Responsabilidades:

- definir cores;
- definir tipografia;
- criar componentes SwiftUI reutilizáveis;
- criar cards de indicadores;
- criar gráficos;
- criar estados vazios;
- criar componentes compactos para Apple Watch.

### Apps

Camada de composição das aplicações.

Responsabilidades:

- configurar cenas SwiftUI;
- configurar navegação;
- configurar injeção de dependências;
- configurar permissões;
- integrar recursos específicos de plataforma.

## Regra Arquitetural Principal

A lógica financeira não pertence à interface.

Telas devem consumir dados preparados por casos de uso, consultores ou
montadores de relatório. Elas não devem interpretar movimentações financeiras.
