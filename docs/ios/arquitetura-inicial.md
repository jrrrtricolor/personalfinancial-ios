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
- XCTest para testes iniciais e automações de interface quando necessário.
- Swift Testing poderá ser adotado quando o toolchain do projeto expuser o módulo de forma estável.
- WatchConnectivity para integração com Apple Watch.

## Estrutura Sugerida

```text
personalfinancial-ios
├── PersonalFinancial
│   ├── App
│   ├── Dominio
│   ├── Importacao
│   ├── Persistencia
│   ├── Relatorios
│   ├── Design
│   └── Watch
├── docs
└── README.md
```

## Organização Interna

O projeto deve começar simples, em um único app SwiftUI.

Não criaremos pacotes Swift separados no início. Módulos só devem ser extraídos
quando houver necessidade real de isolamento, reuso ou redução de complexidade.

### Dominio

Área central do sistema. Deve conter as regras financeiras puras.

Responsabilidades:

- representar entidades financeiras;
- representar categorias;
- representar tipos de movimento;
- normalizar descrições;
- classificar movimentos de forma determinística;
- calcular gasto real;
- validar transações;
- gerar hashes canônicos;
- proteger regras de negócio contra detalhes de interface e persistência.

O domínio não deve depender de telas. Quando possível, deve permanecer livre de
detalhes de SwiftUI, SwiftData e WatchConnectivity.

### Importacao

Área responsável por transformar arquivos externos em registros canônicos.

Responsabilidades:

- importar AIB CSV;
- preparar suporte futuro para Revolut PDF;
- validar formato de arquivo;
- preservar dados brutos;
- calcular hash de arquivo;
- calcular hash de registro;
- reportar erros de importação de forma rastreável.

Importadores não devem salvar dados diretamente na persistência.

### Persistencia

Área responsável pelo armazenamento local.

Responsabilidades:

- persistir importações;
- persistir registros brutos;
- persistir transações interpretadas;
- persistir categorias;
- persistir regras manuais;
- isolar SwiftData do domínio financeiro.

SwiftData deve ficar concentrado nesta área para evitar acoplamento excessivo
entre domínio e infraestrutura.

### Relatorios

Área responsável por montar dados prontos para consumo pelas telas.

Responsabilidades:

- montar indicadores financeiros;
- agrupar gastos por categoria;
- montar visão de reservas;
- calcular valor não explicado;
- detectar padrões financeiros;
- aplicar filtros de período.

### Design

Área responsável pelos componentes visuais compartilhados.

Responsabilidades:

- definir cores;
- definir tipografia;
- criar componentes SwiftUI reutilizáveis;
- criar cards de indicadores;
- criar gráficos;
- criar estados vazios;
- criar componentes compactos para Apple Watch.

### App

Área de composição da aplicação principal.

Responsabilidades:

- configurar cenas SwiftUI;
- configurar navegação;
- configurar injeção de dependências;
- configurar permissões;
- integrar recursos específicos de plataforma.

### Watch

Área destinada às telas e integrações do Apple Watch.

O Apple Watch deve consumir resumos financeiros. Ele não deve executar importação
de arquivos nem manutenção avançada.

## Regra Arquitetural Principal

A lógica financeira não pertence à interface.

Telas devem consumir dados preparados por casos de uso, consultores ou
montadores de relatório. Elas não devem interpretar movimentações financeiras.
