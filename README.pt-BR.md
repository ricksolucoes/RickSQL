# 🗄️ RickSQL

<p align="center">
  <strong>Camada Delphi para execução de SQL com drivers, conexão, materialização e erros encapsulados.</strong>
</p>

<p align="center">
  <a href="https://docwiki.embarcadero.com/RADStudio/en/Delphi_Language_Guide_Index">
    <img src="https://img.shields.io/badge/Language-Object%20Pascal-5C2D91?style=for-the-badge&logo=delphi&logoColor=white" alt="Object Pascal">
  </a>
  <a href="https://www.embarcadero.com/products/delphi">
    <img src="https://img.shields.io/badge/IDE-Delphi-E62431?style=for-the-badge&logo=delphi&logoColor=white" alt="IDE Delphi">
  </a>
  <a href="https://docwiki.embarcadero.com/RADStudio/en/FireMonkey_Application_Platform">
    <img src="https://img.shields.io/badge/UI-FireMonkey/VCL-2563EB?style=for-the-badge" alt="FireMonkey">
  </a>
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-Revocable%20Software%20License-8250DF?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Owner-RickSolu%C3%A7%C3%B5es-1F6FEB?style=flat-square" alt="RickSoluções">
  <img src="https://img.shields.io/badge/Platform-Multiplataforma-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Multiplataforma">
</p>

<p align="center">
  🇺🇸 <a href="README.md">English</a> | 🇧🇷 Português (Brasil)
</p>

## ✨ Visão geral

O `RickSQL` é um framework Delphi para execução de comandos SQL sobre o FireDAC. A aplicação informa o mecanismo de banco, as opções de conexão e o comando; o framework resolve internamente provider, `DriverID`, driver link, porta padrão, biblioteca cliente, sessão FireDAC, parâmetros, transação, materialização e conversão de falhas para erros estruturados.

O projeto possui duas formas públicas de consumo:

- **`Rick.SQL` / `TRickSQL`** — fachada principal, direta e orientada a records;
- **`Rick.SQL.Interf` / `TRickSQLInterf`** — API fluente complementar baseada em interfaces.

O núcleo não cria formulários nem exibe mensagens visuais. A aplicação consumidora decide como apresentar resultados e erros.

## ⚙️ Instalação

*Opcional*

> Para facilitar, recomendo utilizar o [**Boss**](https://github.com/HashLoad/boss) (Gerenciador de Dependências para Delphi) para a instalação, bastando executar o comando abaixo em um terminal (como o Windows PowerShell, por exemplo):

```sh
boss install github.com/ricksolucoes/RickSQL
```

## 🎫 Instalação manual para Delphi

Caso opte pela instalação manual, basta adicionar as seguintes pastas ao seu projeto, em **Project > Options > Building > Delphi Compiler > Search path**:

```text
RickSQL\src
RickSQL\src\model
RickSQL\src\error
RickSQL\src\core
RickSQL\src\services
RickSQL\src\services\drivers
```

Exemplo mínimo com SQLite:

```pascal
uses
  System.SysUtils,
  Data.DB,
  Rick.SQL;

var
  LConnection: TRickSQLConnectionOptions;
  LCommand: TRickSQLCommand;
  LError: TRickSQLError;
  LDataSet: TRickSQLDataSet;
begin
  LConnection := TRickSQL.ConnectionOptions(TRickSQLDatabaseEngine.SQLite);
  LConnection.Database := 'C:\Dados\teste.db';

  LCommand := TRickSQL.Command(LConnection, 'select * from clientes');
  LDataSet := TRickSQL.Open(LCommand, LError);
  try
    if not Assigned(LDataSet) then
      Writeln(LError.Message)
    else
      Writeln('Registros: ', LDataSet.RecordCount);
  finally
    LDataSet.Free;
  end;
end.
```

`TRickSQLDataSet` é um alias público de `Data.DB.TDataSet`. O dataset retornado por `TRickSQL.Open` é materializado em memória e pertence ao chamador.

## 🗄️ Bancos suportados

O enum `TRickSQLDatabaseEngine` possui providers para treze mecanismos:

| Disponibilidade | Mecanismos |
|---|---|
| Padrão | SQLite, Firebird, InterBase, PostgreSQL, MySQL, Advantage, Access |
| Requer `FULL_EDITION` | SQL Server, Oracle, DB2, SQL Anywhere, Informix, ODBC |

A presença do provider na factory não elimina dependências externas: alguns bancos exigem biblioteca cliente nativa, servidor ou configuração específica do ambiente.

Consulte [Bancos suportados](docs/bancos/BANCOS_SUPORTADOS.pt-BR.md) e [Bibliotecas clientes](docs/bancos/BIBLIOTECAS_CLIENTE.pt-BR.md) para portas, `DriverID`, campos obrigatórios e bibliotecas esperadas.

## 🔌 Formas de consumo

### `TRickSQL`

A fachada `Rick.SQL` expõe quatro operações principais:

```pascal
TRickSQL.ConnectionOptions(...);
TRickSQL.Command(...);
TRickSQL.Open(...);
TRickSQL.Execute(...);
```

`Open` retorna um `TDataSet` desconectado ou `nil` com `TRickSQLError` preenchido. `Execute` retorna `TRickSQLExecutionResult` com `Success`, `RowsAffected` e `Error`.

### `TRickSQLInterf`

A unit `Rick.SQL.Interf` oferece uma API fluente complementar:

```pascal
LRick := TRickSQLInterf.New
  .ConnectionOptions
    .Engine(TRickSQLDatabaseEngine.SQLite)
    .Database('C:\Dados\teste.db')
  .Back
  .Command
    .SQL('select * from clientes')
  .Back
  .Cursor
    .Open
  .Back;
```

A referência completa das duas superfícies públicas, incluindo `IRickSQL*`, ownership, parâmetros e reaproveitamento de instância, está em [API pública](docs/api/API_PUBLICA.pt-BR.md).

## ⚙️ Diretivas de compilação

### Provider de espera do FireDAC

`Rick.SQL.Core.ClientLibrary.Resolver` seleciona em tempo de compilação a implementação de `IFDGUIxWaitCursor` exigida pelo FireDAC:

| Host | Condição | Provider |
| --- | --- | --- |
| Console | `CONSOLE` | `FireDAC.ConsoleUI.Wait` |
| VCL | `RICK_VCL_CONNECTION` | `FireDAC.VCLUI.Wait` |
| FMX | `RICK_FMX_CONNECTION` | `FireDAC.FMXUI.Wait` |

Aplicações console não precisam de define específico do RickSQL. Aplicações VCL devem definir `RICK_VCL_CONNECTION` e aplicações FMX devem definir `RICK_FMX_CONNECTION` nas opções do compilador (**Project > Options > Delphi Compiler > Conditional defines**) ou por `-D`.

`RICK_VCL_CONNECTION` e `RICK_FMX_CONNECTION` são mutuamente exclusivos. Em aplicações não-console, a ausência de ambos interrompe a compilação em vez de selecionar um provider arbitrário. A seleção existe somente para registrar o mecanismo de espera do FireDAC e não altera a API pública do RickSQL.

### `FULL_EDITION`

Habilita as implementações funcionais dos providers de SQL Server, Oracle, DB2, SQL Anywhere, Informix e ODBC. Sem o símbolo, esses providers continuam registrados na factory, mas rejeitam configuração/validação informando a exigência de `FULL_EDITION`.

Veja o [Guia de integração](docs/integracao/GUIA_DE_INTEGRACAO.pt-BR.md) para configuração completa.

## 📦 Estrutura do projeto

```text
RickSQL/
├── README.md
├── README.pt-BR.md
├── LICENSE
├── LICENSE-pt-BR
├── src/       # implementação e contratos Delphi
├── NewTests/  # suíte oficial de novas refatorações: DUnit + GUI Test Runner
├── tests/     # suíte legada de compilação, unitários, integração, memória e concorrência
├── samples/   # exemplos executáveis
└── docs/      # documentação técnica centralizada
```

A documentação detalhada não fica distribuída entre `tests` e `samples`; o índice canônico em português está em [`docs/README.pt-BR.md`](docs/README.pt-BR.md).

## 📚 Documentação

| Área | Documento |
|---|---|
| Começar | [Guia de integração](docs/integracao/GUIA_DE_INTEGRACAO.pt-BR.md) |
| Exemplos | [Exemplos de uso](docs/integracao/EXEMPLOS_DE_USO.pt-BR.md) |
| API | [API pública](docs/api/API_PUBLICA.pt-BR.md) |
| Conexão | [Opções de conexão](docs/api/OPCOES_DE_CONEXAO.pt-BR.md) |
| Comandos | [Comandos e parâmetros](docs/api/COMANDOS_E_PARAMETROS.pt-BR.md) |
| Lifetime | [Propriedade e ciclo de vida](docs/api/PROPRIEDADE_E_CICLO_DE_VIDA.pt-BR.md) |
| Erros | [Tratamento de erros](docs/api/TRATAMENTO_DE_ERROS.pt-BR.md) |
| Bancos | [Bancos suportados](docs/bancos/BANCOS_SUPORTADOS.pt-BR.md) |
| Bibliotecas | [Bibliotecas clientes](docs/bancos/BIBLIOTECAS_CLIENTE.pt-BR.md) |
| Testes | [Testes e homologação](docs/testes/TESTES_E_HOMOLOGACAO.pt-BR.md) |
| Engenharia | [Controle de toxicidade](docs/engenharia/CONTROLE_DE_TOXICIDADE.pt-BR.md) |

## 🧪 Testes

A suíte oficial para novas refatorações e correções comportamentais fica em `NewTests/` e usa DUnit com GUI Test Runner. As units de normalização de exceptions estão em `NewTests/src/Error/`, a validação/identificação de parâmetros SQL em `NewTests/src/Validation/`, a cobertura transacional em `NewTests/src/Transaction/`, a verificação do provider FireDAC em `NewTests/src/Infrastructure/` e a cobertura da aplicação canônica de `VendorLib` em `NewTests/src/ClientLibrary/`. A árvore `tests/` permanece como suíte legada e material auxiliar; não é dependência estrutural de `NewTests/`.

Em **19/09/2026**, a suíte oficial executou **124/124 testes**, com **0 falhas**, **0 erros** e **Score 100%** no DUnit GUI Test Runner. No mesmo ciclo de validação, `RickConnection.dproj` registrou build **Debug/Win32: Success** no Delphi 12 Community Edition, e `RickSQL.NewTests.dproj` teve Method Toxicity Metrics executado em Windows 32-bit, com maior `Toxicity` visível de **0,350**. Os detalhes e os limites dessas evidências estão em [`docs/testes`](docs/testes/README.pt-BR.md) e em [Controle de toxicidade](docs/engenharia/CONTROLE_DE_TOXICIDADE.pt-BR.md).

## 📜 Licença

Este projeto é distribuído sob uma licença revogável (**Revocable Software License**).

Antes de utilizar o software, consulte o arquivo [`LICENSE-pt-BR`](LICENSE-pt-BR) para conhecer todos os termos, restrições de uso e permissões.

<div align="center">

## 🗄️ RickSQL

**Camada Delphi para execução de SQL com drivers, conexão, materialização e erros encapsulados.**

Desenvolvido pela **RickSoluções**

<br>

[🇺🇸 Read the Official English Version](./README.md)

</div>
