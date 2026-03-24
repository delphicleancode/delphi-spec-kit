# Delphi AI Spec-Kit — AGENTS.md

> Este arquivo é reconhecido automaticamente por **Antigravity**, **GitHub Copilot**, **Cursor** e **Kiro**.
> Ele define as regras universais para desenvolvimento Delphi com IA.

## Linguagem e Stack

- **Linguagem:** Object Pascal (Delphi)
- **IDE Nativa:** RAD Studio / Delphi
- **Frameworks:** VCL, FMX, FireDAC
- **Banco de dados:** FireDAC (SQLite, PostgreSQL, Firebird, SQL Server)
- **Testes:** DUnitX
- **Build:** MSBuild / Delphi Compiler (dcc32/dcc64)
- **Extensões de arquivo:** `.pas` (units), `.dfm`/`.fmx` (forms), `.dpr` (project), `.dpk` (package), `.dproj` (project config)

## Convenções de Nomenclatura — Pascal Guide

### Regra Geral

Usar **PascalCase** (InfixCaps) para todos os identificadores. Palavras reservadas sempre em **minúsculas** (`begin`, `end`, `if`, `then`, `else`, `nil`, `string`).

### Prefixos Obrigatórios

| Tipo | Prefixo | Exemplo |
|------|---------|---------|
| Classe | `T` | `TCustomerRepository` |
| Interface | `I` | `ICustomerRepository` |
| Exception | `E` | `ECustomerNotFound` |
| Campo privado | `F` | `FCustomerName` |
| Parâmetro | `A` | `ACustomerName` |
| Tipo enumerado | `T` | `TOrderStatus` |
| Itens de enum | prefixo curto | `osNew`, `osPending`, `osClosed` |

### Nomenclatura de Units

```
NomeProjeto.Camada.Dominio.Funcionalidade.pas
```

Exemplos:

- `MeuApp.Domain.Customer.Entity.pas`
- `MeuApp.Infra.Customer.Repository.pas`
- `MeuApp.Application.Customer.Service.pas`
- `MeuApp.Presentation.Customer.View.pas`

### Nomenclatura de Métodos

- Métodos de ação: usar verbos — `Execute`, `CreateOrder`, `ValidateCustomer`
- Getters: prefixo `Get` — `GetCustomerName`
- Setters: prefixo `Set` — `SetCustomerName`
- Funções booleanas: prefixo `Is`, `Has`, `Can` — `IsValid`, `HasPermission`, `CanDelete`

### Nomenclatura de Testes de Unidade (TDD)

- Seguir o padrão genérico comportamental em testes DUnitX: `Action_Condition_ExpectedResult`
- Exemplo: `ProcessOrder_WithoutStock_RaisesException`, `CalculateTotal_WithDiscount_ReturnsLowerValue`
- Crie fakes na unit de teste com prefixo `TFake` (ex: `TFakeInventoryRepository`)

### Nomenclatura de Forms e DataModules

- Tipo: `TfrmCustomerEdit`, `TdmDatabase`
- Variável: `frmCustomerEdit`, `dmDatabase`
- Unit: `MeuApp.Presentation.Customer.Edit.pas`

### Componentes em Forms

Usar prefixo de 3 letras indicando o tipo:

| Componente | Prefixo | Exemplo |
|-----------|---------|---------|
| TButton | `btn` | `btnSave` |
| TEdit | `edt` | `edtName` |
| TLabel | `lbl` | `lblName` |
| TComboBox | `cmb` | `cmbStatus` |
| TDBGrid | `dbg` | `dbgCustomers` |
| TPanel | `pnl` | `pnlTop` |
| TPageControl | `pgc` | `pgcMain` |
| TTabSheet | `tab` | `tabSearch` |
| TDataSource | `ds` | `dsCustomers` |
| TFDQuery | `qry` | `qryCustomers` |
| TFDConnection | `con` | `conMain` |
| TMemo | `mmo` | `mmoObservation` |
| TCheckBox | `chk` | `chkActive` |
| TDateTimePicker | `dtp` | `dtpBirthDate` |
| TImage | `img` | `imgPhoto` |
| TListView | `lvw` | `lvwItems` |
| TTreeView | `tvw` | `tvwCategories` |
| TToolBar | `tlb` | `tlbMain` |
| TActionList | `act` | `actMain` |
| TPopupMenu | `pmn` | `pmnGrid` |
| TTimer | `tmr` | `tmrRefresh` |
| TStatusBar | `stb` | `stbMain` |

### Componentes DevExpress (DEXT) em Forms

| Componente | Prefixo | Exemplo |
|-----------|---------|---------|
| TcxGrid | `grd` | `grdCustomers` |
| TcxGridDBTableView | `tvw` | `tvwCustomers` |
| TcxDBTreeList | `trl` | `trlCategories` |
| TdxLayoutControl | `lyt` | `lytMain` |
| TdxLayoutGroup | `lgrp` | `lgrpPersonal` |
| TdxLayoutItem | `litm` | `litmName` |
| TcxDBTextEdit | `edt` | `edtName` |
| TcxDBComboBox | `cmb` | `cmbStatus` |
| TcxDBDateEdit | `dte` | `dtpBirthDate` |
| TcxDBCurrencyEdit | `cur` | `curPrice` |
| TcxDBLookupComboBox | `lcb` | `lcbCity` |
| TdxBarManager | `bar` | `barMain` |
| TdxRibbon | `rbn` | `rbnMain` |
| TdxSkinController | `skn` | `sknController` |

### Projeto ACBr (Automação Comercial)

| Componente | Prefixo | Exemplo |
|-----------|---------|---------|
| TACBrNFe | `acbrNFe` | `acbrNFe1` ou `acbrNfeEmissor` |
| TACBrCTe | `acbrCte` | `acbrCteMain` |
| TACBrBoleto | `acbrBoleto` | `acbrBoletoCob` |
| TACBrTEFD | `acbrTef` | `acbrTefVisa` |
| TACBrPosPrinter | `acbrPosPrinter`| `acbrPosPrinterCaixa` |
| TACBrSAT | `acbrSat` | `acbrSatFiscal` |
| TACBrCEP | `acbrCep` | `acbrCepBusca` |

**Nota ACBr:** Evite prender a UI diretamente em eventos interativos do componente. Isole a lógica fiscal.

### Componentes Intraweb (Web)

| Componente | Prefixo | Exemplo |
|-----------|---------|---------|
| TIWAppForm | `iwForm`| `iwFormLogin` |
| TIWButton | `iwBtn` | `iwBtnSave` |
| TIWEdit | `iwEdt` | `iwEdtName` |
| TIWLabel | `iwLbl` | `iwLblTitle` |
| TIWComboBox | `iwCmb` | `iwCmbStatus` |
| TIWGrid | `iwGrd` | `iwGrdItems` |
| TIWRegion | `iwReg` | `iwRegContainer` |

**Nota Intraweb:** Evite variáveis globais de unit para controle de estado do usuário. Guarde dados transientes sempre no `UserSession` para evitar vazamentos entre sessões.

## Frameworks REST (Horse, DMVC, Dext)

### Dext Framework

Dext (<https://github.com/cesarliws/dext>) é um marco corporativo com inspiração no ecossistema .NET. Convenções:

- **Minimal APIs:** Use `App.Builder.MapGet` com Auto-Binding para DTOs
- **Injeção de Dependência:** Obrigatória. Injete nos endpoints: `function(Dto: MyDto; Rep: ICustomerRepository): IResult`
- **Entity ORM:** Consultas tipo LINQ (`DbContext.Where(U.Age > 18)`). Não use queries em SQL puro encadeado.
- **Async:** Use `TAsyncTask.Run` do `Dext.Core.Tasks`.
- **Resultados:** Retorne frameworks tipados ou Records diretamente, serializados como JSON.

### Horse Framework

Horse é um framework REST minimalista para Delphi (estilo Express). Convenções:

- **Controller:** Classe com `class procedure RegisterRoutes`
- **Handler:** `class procedure Nome(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc)`
- **Middleware:** `procedure Nome(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc)`
- **Rotas:** Kebab-case, plural — `/api/customers`, `/api/order-items`
- **JSON:** Usar middleware `Jhonson` para serialização automática
- **CORS:** Usar middleware `Horse.CORS`
- **Estrutura:** Controllers separados de Services, Services separados de Repositories
- **Pacotes:** `boss install horse horse-jhonson horse-cors horse-jwt`

### DelphiMVCFramework (DMVC)

DMVC é um framework MVC clássico com Active Record, JWT e Swagger:

- **Controller:** Herda de `TMVCController` com `[MVCPath]` attribute
- **Rotas:** Attributes — `[MVCPath]`, `[MVCHTTPMethod]`, `[MVCProduces]`, `[MVCConsumes]`
- **Active Record:** Herda de `TMVCActiveRecord` com `[MVCTable]`, `[MVCTableField]`
- **Serialização:** Automática via `Render()` (JSON por padrão)
- **WebModule:** `TMVCEngine` criado no WebModule com controllers e middleware
- **JWT:** `TMVCJWTAuthenticationMiddleware` built-in
- **RQL:** Resource Query Language para filtros via query string

### DevExpress Components

Componentes visuais avançados para VCL:

- **Grid:** `TcxGrid` com `TcxGridDBTableView` (data-aware)
- **Layout:** `TdxLayoutControl` para formulários responsivos
- **Skins:** `TdxSkinController` para temas globais
- **Exportação:** `cxGridExportLink` para Excel/PDF
- **Filtros:** `DataController.Filter` para filtros programáticos

## Banco de Dados Firebird

Firebird é o banco de dados corporativo mais utilizado com Delphi. Acesso via **FireDAC** (driver `FB`).

### Configuração de Conexão Obrigatória

```pascal
FConnection.DriverName := 'FB';
FConnection.Params.Values['CharacterSet'] := 'UTF8';    // SEMPRE UTF8
FConnection.Params.Values['SQLDialect'] := '3';          // NUNCA Dialect 1
FConnection.Params.Values['Protocol'] := 'TCPIP';        // Ou 'Local' para embedded
FConnection.Params.Values['PageSize'] := '16384';         // 16KB recomendado
FConnection.TxOptions.Isolation := xiReadCommitted;       // Isolation padrão
```

### Regras Essenciais Firebird

- **Dialect 3 SEMPRE** — Dialect 1 é legado InterBase e causa ambiguidade com `DATE`
- **CharacterSet UTF8** — obrigatório para suporte correto a acentos
- **Queries parametrizadas** — nunca concatenar strings em SQL
- **RETURNING com Open** — `INSERT ... RETURNING id` exige `LQuery.Open`, não `ExecSQL`
- **Generators** para auto-increment com triggers `BEFORE INSERT`
- **Domains** para centralizar tipos e validações no schema
- **Stored Procedures:** Selectable (com `SUSPEND`) usa `SELECT FROM SP`; Executable usa `EXECUTE PROCEDURE`
- **Transactions explícitas** para operações compostas (StartTransaction/Commit/Rollback)
- **Tratar deadlocks** via `EFDDBEngineException.Kind = ekRecordLocked`

### Anti-Patterns Firebird

- ❌ `SQLDialect := '1'` — usar SEMPRE `'3'`
- ❌ `ExecSQL` com `RETURNING` — usar `Open`
- ❌ Concatenar SQL — usar parâmetros
- ❌ Ignorar `CharacterSet` — definir `UTF8`
- ❌ `PAGE_SIZE 4096` — usar `16384` para produção
- ❌ Ignorar deadlocks — tratar `ekRecordLocked`
- ❌ `CREATE TABLE IF NOT EXISTS` — não existe no Firebird (verificar via `RDB$RELATIONS`)

> **Skills:** `.gemini/skills/firebird-database/SKILL.md`
> **Rules:** `.cursor/rules/firebird-patterns.md`

## Banco de Dados PostgreSQL

PostgreSQL é o banco de dados open-source mais avançado, ideal para projetos modernos. Acesso via **FireDAC** (driver `PG`).

### Configuração de Conexão

```pascal
FConnection.DriverName := 'PG';
FConnection.Params.Values['Server'] := 'localhost';
FConnection.Params.Values['Port'] := '5432';
FConnection.Params.Database := 'meubanco';
FConnection.Params.UserName := 'postgres';
FConnection.Params.Password := 'senha';
FConnection.Params.Values['CharacterSet'] := 'UTF8';
FConnection.TxOptions.Isolation := xiReadCommitted;
```

### Regras Essenciais PostgreSQL

- **IDENTITY em vez de SERIAL** — usar `GENERATED ALWAYS AS IDENTITY` para novos projetos (PG 10+)
- **RETURNING com Open** — `INSERT ... RETURNING id` exige `LQuery.Open`, não `ExecSQL`
- **UPSERT nativo** — `INSERT ... ON CONFLICT (col) DO UPDATE SET ...`
- **JSONB** — para dados semi-estruturados, indexável com GIN
- **ENUM types** — `CREATE TYPE status AS ENUM ('active', 'inactive')` mapeado para enum Pascal
- **PL/pgSQL** — Functions (`RETURNS TABLE` = Selectable), Procedures (`CALL`, PG 11+)
- **Transactions explícitas** — `StartTransaction/Commit/Rollback`, suporta `SAVEPOINT`
- **Full-Text Search** — `tsvector` + `tsquery` com índice GIN
- **Metadata via `information_schema`** — não usar `RDB$` (isso é Firebird)

### Anti-Patterns PostgreSQL

- ❌ Concatenar SQL — usar parâmetros parametrizados
- ❌ `ExecSQL` com `RETURNING` — usar `Open`
- ❌ `SERIAL` em novos projetos — usar `IDENTITY`
- ❌ `SELECT *` em tabelas grandes — selecionar colunas necessárias
- ❌ N+1 queries — usar JOIN ou subquery
- ❌ Guardar JSON como TEXT — usar `JSONB`
- ❌ Ignorar índices em colunas de WHERE/JOIN

> **Skills:** `.gemini/skills/postgresql-database/SKILL.md`
> **Rules:** `.cursor/rules/postgresql-patterns.md`

## Banco de Dados MySQL / MariaDB

MySQL é o banco de dados open-source mais popular do mundo. MariaDB é um fork compatível. Acesso via **FireDAC** (driver `MySQL`).

### Configuração de Conexão

```pascal
FConnection.DriverName := 'MySQL';
FConnection.Params.Values['Server'] := 'localhost';
FConnection.Params.Values['Port'] := '3306';
FConnection.Params.Database := 'meubanco';
FConnection.Params.UserName := 'root';
FConnection.Params.Password := 'senha';
FConnection.Params.Values['CharacterSet'] := 'utf8mb4';  // NUNCA 'utf8' (só 3 bytes!)
FConnection.TxOptions.Isolation := xiReadCommitted;
```

### Regras Essenciais MySQL

- **`utf8mb4` SEMPRE** — `utf8` no MySQL só tem 3 bytes (não suporta emoji). Usar `utf8mb4`
- **AUTO_INCREMENT + LAST_INSERT_ID()** — MySQL NÃO suporta `RETURNING`. Obter ID via `LAST_INSERT_ID()`
- **UPSERT nativo** — `INSERT ... ON DUPLICATE KEY UPDATE`
- **JSON nativo** — tipo `JSON` com operadores `->>`/`JSON_EXTRACT` (MySQL 5.7+)
- **InnoDB SEMPRE** — nunca MyISAM em novos projetos (precisa de FK e transactions)
- **Stored Procedures** — `CALL sp_nome(...)` para procedures, `SELECT fn_nome(...)` para functions
- **Transactions explícitas** — `StartTransaction/Commit/Rollback`, suporta `SAVEPOINT`
- **COLLATE** — `utf8mb4_unicode_ci` para comparação case-insensitive correta
- **Metadata via `information_schema`** — usar `DATABASE()` para schema atual

### Anti-Patterns MySQL

- ❌ `utf8` como charset — usar `utf8mb4`
- ❌ Tentar `RETURNING` — não existe, usar `LAST_INSERT_ID()`
- ❌ `MyISAM` em novas tabelas — usar `InnoDB`
- ❌ Concatenar SQL — usar parâmetros
- ❌ `SELECT *` sem `LIMIT` — paginar resultados
- ❌ N+1 queries — usar JOIN ou subquery
- ❌ Ignorar índices em colunas de WHERE/JOIN

> **Skills:** `.gemini/skills/mysql-database/SKILL.md`
> **Rules:** `.cursor/rules/mysql-patterns.md`

## Threads e Multi-Threading

Threads são fundamentais para manter a UI responsiva e processar dados em paralelo. Delphi oferece `TThread`, PPL (`TTask`, `TParallel.For`, `TFuture<T>`) e primitivas de sincronização.

### Regra de Ouro

> **NUNCA acesse componentes visuais (VCL/FMX) diretamente de uma thread secundária.**
> Use `TThread.Synchronize` (bloqueante) ou `TThread.Queue` (não-bloqueante) para atualizar a UI.

### Abordagens de Threading

| Abordagem | Quando Usar |
|-----------|-------------|
| `TThread.CreateAnonymousThread` | Tarefas simples, one-shot |
| `TTask.Run` (PPL) | Forma moderna, pool gerenciado |
| `TParallel.For` | Loop paralelo em coleções independentes |
| `TFuture<T>` | Resultado assíncrono com valor de retorno |
| `TThread` (herança) | Workers permanentes, filas, servidores |

### Thread-Safety

- **`TCriticalSection`** — Seção crítica clássica (`Enter`/`Leave` SEMPRE no `finally`)
- **`TMonitor`** — Lock nativo de objeto (`Enter`/`Exit`)
- **`TInterlocked`** — Operações atômicas (`Increment`, `Decrement`, `Exchange`)
- **`TThreadList<T>`** — Lista thread-safe com `LockList`/`UnlockList`
- **`TMultiReadExclusiveWriteSynchronizer`** — Cache: múltiplas leituras, poucas escritas
- **`TThreadedQueue<T>`** — Fila thread-safe para Producer-Consumer

### Anti-Patterns de Threading

- ❌ Acessar VCL/FMX diretamente de thread secundária
- ❌ `Sleep()` na main thread (congela a UI!)
- ❌ `FreeOnTerminate := True` + `WaitFor` (crash!)
- ❌ Acessar variáveis compartilhadas sem lock
- ❌ Ignorar exceções em threads (são silenciosas!)
- ❌ `TCriticalSection.Leave` fora de `finally`

> **Skills:** `.gemini/skills/threading/SKILL.md`
> **Rules:** `.cursor/rules/threading-patterns.md`

## Princípios SOLID em Delphi

### S — Single Responsibility Principle (SRP)

Cada unit e cada classe deve ter **uma única responsabilidade**:

```pascal
// ✅ BOM — responsabilidades separadas
TCustomerValidator = class
  function Validate(ACustomer: TCustomer): TValidationResult;
end;

TCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  function FindById(AId: Integer): TCustomer;
  procedure Save(ACustomer: TCustomer);
end;

// ❌ RUIM — classe fazendo tudo
TCustomer = class
  procedure Validate;     // deveria ser um Validator
  procedure SaveToDb;     // deveria ser um Repository
  procedure SendEmail;    // deveria ser um Service
end;
```

### O — Open/Closed Principle (OCP)

Classes devem ser **abertas para extensão**, fechadas para modificação. Use herança e interfaces:

```pascal
type
  IReportExporter = interface
    procedure Export(AReport: TReport);
  end;

  TPdfExporter = class(TInterfacedObject, IReportExporter)
    procedure Export(AReport: TReport);
  end;

  TExcelExporter = class(TInterfacedObject, IReportExporter)
    procedure Export(AReport: TReport);
  end;
```

### L — Liskov Substitution Principle (LSP)

Subtipos devem ser substituíveis pelo tipo base sem quebrar o comportamento:

```pascal
// ✅ BOM — qualquer ICustomerRepository funciona
procedure TCustomerService.LoadCustomer(ARepo: ICustomerRepository);
begin
  // funciona com TFireDACCustomerRepo, TMemoryCustomerRepo, TMockCustomerRepo
  FCustomer := ARepo.FindById(FCustomerId);
end;
```

### I — Interface Segregation Principle (ISP)

Interfaces pequenas e coesas, não interfaces "gordas":

```pascal
// ✅ BOM — interfaces segregadas
type
  IReadableRepository<T> = interface
    function FindById(AId: Integer): T;
    function FindAll: TObjectList<T>;
  end;

  IWritableRepository<T> = interface
    procedure Save(AEntity: T);
    procedure Delete(AId: Integer);
  end;

  ICustomerRepository = interface(IReadableRepository<TCustomer>)
    ['{GUID}']
    function FindByCpf(const ACpf: string): TCustomer;
  end;
```

### D — Dependency Inversion Principle (DIP)

Dependa de **abstrações** (interfaces), não de implementações concretas. Use **constructor injection**:

```pascal
type
  TOrderService = class
  private
    FOrderRepo: IOrderRepository;
    FNotifier: INotificationService;
  public
    constructor Create(AOrderRepo: IOrderRepository; ANotifier: INotificationService);
    procedure PlaceOrder(AOrder: TOrder);
  end;

constructor TOrderService.Create(AOrderRepo: IOrderRepository; ANotifier: INotificationService);
begin
  inherited Create;
  FOrderRepo := AOrderRepo;
  FNotifier := ANotifier;
end;
```

## Clean Code — Regras Essenciais

### 1. Métodos Curtos

- Máximo **20 linhas** por método (ideal: 5-10)
- Se um método precisa de comentário explicando "o que faz", ele deveria ser extraído em um método com nome descritivo

### 2. Nomes Auto-Descritivos

```pascal
// ❌ RUIM
procedure Proc1(S: string; N: Integer);
function Calc(V: Double): Double;

// ✅ BOM
procedure SendNotificationEmail(const ARecipientEmail: string; ATemplateId: Integer);
function CalculateDiscountedPrice(AOriginalPrice: Double): Double;
```

### 3. Evitar Números Mágicos

```pascal
// ❌ RUIM
if ACustomer.Age > 18 then

// ✅ BOM
const
  MINIMUM_AGE = 18;
// ...
if ACustomer.Age > MINIMUM_AGE then
```

### 4. Guard Clauses

```pascal
// ❌ RUIM — nesting excessivo
procedure ProcessOrder(AOrder: TOrder);
begin
  if Assigned(AOrder) then
  begin
    if AOrder.Items.Count > 0 then
    begin
      if AOrder.IsValid then
      begin
        // lógica real aqui
      end;
    end;
  end;
end;

// ✅ BOM — guard clauses
procedure ProcessOrder(AOrder: TOrder);
begin
  if not Assigned(AOrder) then
    raise EArgumentNilException.Create('AOrder cannot be nil');
  if AOrder.Items.Count = 0 then
    raise EBusinessRuleException.Create('Order must have at least one item');
  if not AOrder.IsValid then
    raise EValidationException.Create('Order validation failed');

  // lógica real aqui — sem nesting
end;
```

### 5. Try/Except Focado e Tipado

```pascal
// ❌ RUIM — catch genérico engolindo erros críticos (Access Violation, OOM)
try
  // grande bloco de código longo
except
  on E: Exception do // Ou pior: sem declarar "on E:"
    ShowMessage(E.Message);
end;

// ✅ BOM — exceptions específicas e recuperação granular
try
  FConnection.Open;
  PerformCriticalAction;
except
  on E: EFDDBEngineException do
    raise EDatabaseConnectionException.Create('Falha local no banco: ' + E.Message);
  on E: EBusinessRuleException do
    raise; // Repassa a exceção para Controller capturar
  on E: Exception do
  begin
    Logger.LogError('Critical unexpected failure', E);
    raise; // NUNCA esconda exceções puras do root Exception sem relançar!
  end;
end;
```

### 6. Organização de Unit

```pascal
unit MeuApp.Domain.Customer.Entity;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  // 1. Types, enums e records primeiro
  TCustomerStatus = (csActive, csInactive, csSuspended);

  // 2. Interfaces
  ICustomer = interface
    ['{GUID}']
    function GetName: string;
    property Name: string read GetName;
  end;

  // 3. Classes
  TCustomer = class(TInterfacedObject, ICustomer)
  private
    FId: Integer;
    FName: string;
    FStatus: TCustomerStatus;
    function GetName: string;
  public
    // Constructor e Destructor primeiro
    constructor Create(const AName: string);
    destructor Destroy; override;

    // Depois métodos públicos
    function IsActive: Boolean;
    procedure Activate;
    procedure Deactivate;

    // Properties por último
    property Id: Integer read FId write FId;
    property Name: string read GetName;
    property Status: TCustomerStatus read FStatus;
  end;

implementation

{ TCustomer }

constructor TCustomer.Create(const AName: string);
begin
  inherited Create;
  if AName.Trim.IsEmpty then
    raise EArgumentException.Create('Customer name cannot be empty');
  FName := AName.Trim;
  FStatus := csActive;
end;

// ... demais implementações
```

## Padrões de Projeto Recomendados

| Padrão | Uso em Delphi |
|--------|---------------|
| **Repository** | Abstrai acesso a dados via interface (FireDAC, REST, etc.) |
| **Service** | Contém lógica de negócio orquestrando repositories e outros services |
| **Factory** | Cria instâncias de objetos complexos ou com dependências |
| **Observer** | Usar `TNotifyEvent` ou interfaces para desacoplar notificações |
| **Strategy** | Interfaces para variar algoritmos (ex: cálculo de impostos) |
| **Unit of Work** | Gerencia transações de banco de dados |

## Anti-Patterns a Evitar

- ❌ **God class / God unit** — units com milhares de linhas fazendo tudo
- ❌ **Acoplamento direto a forms** — lógica de negócio em `OnClick` de botões
- ❌ **Uses circular** — resolvido separando em camadas (Domain, Infra, Application, Presentation)
- ❌ **Variáveis globais** — usar injeção de dependência
- ❌ **Strings hardcoded** — usar `resourcestring` ou constantes
- ❌ **Ignoring memory management** — sempre liberar objetos não gerenciados por referência
- ❌ **`with` statement** — evitar `with` pois reduz legibilidade e dificulta debug
- ❌ **Testes em Banco Real** — acoplar projetos DUnitX diretamente no `TFDConnection` pulando Mocks/Fakes.

## Gerenciamento de Memória (Crítico)

- **Blocos Vigiados:** A regra de ouro no Delphi: Toda vez que existir um código chamando `.Create` para instâncias de Classes TObject, a linha IMEDIATAMENTE subsequente deve ser obrigatoriamente um `try`. NENHUMA linha de código intermediária!

```pascal
// ✅ O Padrão Ouro para Objetos Descartáveis
var LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LList.Add('item');
    // ...
  finally
    LList.Free; // ou FreeAndNil(LList)
  end;
end;

// ✅ Objetos com dono (Owner) - Componentes VCL/FMX
TMyComponent := TMyComponent.Create(Self); // Owner (Self) assume liberação

// ✅ Garbage Collection com Interfaces (ARC)
// O objeto será limpo automaticamente no fim do escopo, dispensando try..free
var LService: IMyService;
begin
  LService := TMyService.Create; 
  LService.DoSomething;
end;

// ✅ Variáveis locais: usar prefixo L
var LCustomer: TCustomer;
```

## Documentação

- Usar **XMLDoc** para métodos públicos e interfaces:

```pascal
/// <summary>
///   Localiza um cliente pelo CPF informado.
/// </summary>
/// <param name="ACpf">CPF do cliente (somente números)</param>
/// <returns>Instância de TCustomer ou nil se não encontrado</returns>
/// <exception cref="EArgumentException">Se ACpf estiver vazio</exception>
function FindByCpf(const ACpf: string): TCustomer;
```

- Comentários em **português** para projetos brasileiros
- Não comentar código óbvio — deixar o nome do método explicar

## Estrutura de Camadas (Arquitetura)

```
src/
├── Domain/           ← Entidades, Value Objects, Interfaces de repositório
├── Application/      ← Services, Use Cases, DTOs
├── Infrastructure/   ← Implementações de repositório (FireDAC), APIs externas
└── Presentation/     ← Forms (VCL/FMX), ViewModels
tests/
└── Unit/             ← Projetos DUnitX e Fakes/Mocks isolados por contexto
```

> **Regra de dependência:** `Presentation → Application → Domain ← Infrastructure`
> O Domain **nunca** depende de outras camadas. Os `tests` dependem de `Application` e `Domain` mas injetam implementações Fakes copiando a `Infrastructure` isoladamente.
