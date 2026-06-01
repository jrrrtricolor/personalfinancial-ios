// swift-tools-version: 6.3
// Esta linha declara a versão mínima do Swift exigida para compilar o app.

import PackageDescription

let package = Package(
    name: "PersonalFinancial",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "PersonalFinancial",
            targets: ["PersonalFinancial"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "PersonalFinancial",
            path: "PersonalFinancial",
            exclude: [
                "README.md",
            ],
            resources: [
                .process("Persistencia/BancoDados.sql"),
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3"),
            ]
        ),
    ]
)
