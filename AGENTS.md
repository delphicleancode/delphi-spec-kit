# Delphi AI Spec-Kit — AGENTS.md

> This file is automatically recognized by **Antigravity**, **GitHub Copilot**, **Cursor** and **Kiro**.
> It defines the universal rules for Delphi development with AI.

## Language and Stack

- **Language:** Object Pascal (Delphi)
- **Native IDE:** RAD Studio / Delphi
- **Frameworks:** VCL, FMX, FireDAC
- **Database:** FireDAC (SQLite, PostgreSQL, Firebird, SQL Server)
- **Tests:** DUnitX
- **Build:** MSBuild / Delphi Compiler (dcc32/dcc64)
- **File extensions:** `.pas` (units), `.dfm`/`.fmx` (forms), `.dpr` (project), `.dpk` (package), `.dproj` (project config)

## Naming Conventions — Pascal Guide

### General Rule

Use **PascalCase** (InfixCaps) for all identifiers. Reserved words are always in **TOK_6__, `end`, `if`, `then`, `else`, `nil`, `string`).

### Mandatory Prefixes

| Type | Prefix | Example |
|------|---------|---------|
| Class | `T` | `TCustomerRepository` |
| Interface | `I` | `ICustomerRepository` |
| Exception | `E` | `ECustomerNotFound` |
| Private field | `F` | `FCustomerName` |
| Parameter | `A` | `ACustomerName` |
| Enumerated type | `T` | `TOrderStatus` |
| Enum Items | short prefix | `osNew`, `osPending`, `osClosed` |

### Unit Naming

```
NomeProjeto.Camada.Dominio.Funcionalidade.pas
```

Examples:

- `MyApp.Domain.Customer.Entity.pas`
- `MyApp.Infra.Customer.Repository.pas`
- `MyApp.Application.Customer.Service.pas`
- `MyApp.Presentation.Customer.View.pas`

### Method Naming

- Action methods: use verbs — `Execute`, `CreateOrder`, `ValidateCustomer`
- Getters: prefix `Get` — `GetCustomerName`
- Setters: prefix `Set` — `SetCustomerName`
- Boolean functions: prefix `Is`, `Has`, `Can` — `IsValid`, `HasPermission`, `CanDelete`

### Unit Test Naming (TDD)

- Follow the generic behavioral pattern in DUnitX tests: `Action_Condition_ExpectedResult`
- Example: `ProcessOrder_WithoutStock_RaisesException`, `CalculateTotal_WithDiscount_ReturnsLowerValue`
- Create fakes in the test unit with prefix `TFake` (ex: `TFakeInventoryRepository`)

### Naming of Forms and DataModules

- Type: `TfrmCustomerEdit`, `TdmDatabase`
- Variable: `frmCustomerEdit`, `dmDatabase`
- Unit: `MyApp.Presentation.Customer.Edit.pas`

### Components in Forms

Use a 3-letter prefix indicating the type:

| Component | Prefix | Example |
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
| T Hours | `tmr` | `tmrRefresh` |
| TStatusBar | `stb` | `stbMain` |

### DevExpress (DEXT) components in Forms

| Component | Prefix | Example |
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

### ACBr Project (Commercial Automation)

| Component | Prefix | Example |
|-----------|---------|---------|
| TACBrNFe | `acbrNFe` | `acbrNFe1` ou `acbrNfeEmissor` |
| TACBrCTe | `acbrCte` | `acbrCteMain` |
| TACBrBoleto | `acbrBoleto` | `acbrBoletoCob` |
| TACBrTEFD | `acbrTef` | `acbrTefVisa` |
| TACBrPosPrinter | `acbrPosPrinter`| `acbrPosPrinterCaixa` |
| TACBrSAT | `acbrSat` | `acbrSatFiscal` |
| TACBrCEP | `acbrCep` | `acbrCepBusca` |

**ACBr Note:** Avoid trapping the UI directly in component interactive events. Isolate tax logic.

### Intraweb Components (Web)

| Component | Prefix | Example |
|-----------|---------|---------|
| TIWAppForm | `iwForm`| `iwFormLogin` |
| TIWButton | `iwBtn` | `iwBtnSave` |
| TIWEdit | `iwEdt` | `iwEdtName` |
| TIWLabel | `iwLbl` | `iwLblTitle` |
| TIWComboBox | `iwCmb` | `iwCmbStatus` |
| TIWGrid | `iwGrd` | `iwGrdItems` |
| TIWRegion | `iwReg` | `iwRegContainer` |

**Intraweb Note:** Avoid global unit variables to control user state. Always store transient data in `UserSession` to avoid leaks between sessions.

## REST Frameworks (Horse, DMVC, Dext)

### Dext Framework

Dext (<https://github.com/cesarliws/dext>) is an enterprise landmark inspired by the .NET ecosystem. Conventions:

- **Minimal APIs:** Use `App.Builder.MapGet` with Auto-Binding for DTOs
- **Dependency Injection:** Mandatory. Inject into endpoints: `function(Dto: MyDto; Rep: ICustomerRepository): IResult`
- **Entity ORM:** LINQ type queries (`DbContext.Where(U.Age > 18)`). Do not use queries in pure SQL chained.
- **Async:** Use `TAsyncTask.Run` from `Dext.Core.Tasks`.
- **Results:** Return typed frameworks or Records directly, serialized as JSON.

### Horse Framework

Horse is a minimalist REST framework for Delphi (Express style). Conventions:

- **Controller:** Class with `class procedure RegisterRoutes`
- **Handler:** `class procedure Nome(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc)`
- **Middleware:** `procedure Nome(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc)`
- **Routes:** Kebab-case, plural — `/api/customers`, `/api/order-items`
- **JSON:** Use `Jhonson` middleware for automatic serialization
- **CORS:** Use `Horse.CORS` middleware
- **Structure:** Controllers separated from Services, Services separated from Repositories
- **Packages:** `boss install horse horse-jhonson horse-cors horse-jwt`

### DelphiMVCFramework (DMVC)

DMVC is a classic MVC framework with Active Record, JWT and Swagger:

- **Controller:** Inherits from `TMVCController` with `[MVCPath]` attribute
- **Routes:** Attributes — `[MVCPath]`, `[MVCHTTPMethod]`, `[MVCProduces]`, `[MVCConsumes]`
- **Active Record:** Inherits from `TMVCActiveRecord` with `[MVCTable]`, `[MVCTableField]`
- **Serialization:** Automatic via `Render()` (JSON by default)
- **WebModule:** `TMVCEngine` created in WebModule with controllers and middleware
- **JWT:** `TMVCJWTAuthenticationMiddleware` built-in
- **RQL:** Resource Query Language for filters via query string

### DevExpress Components

Advanced visual components for VCL:

- **Grid:** `TcxGrid` with `TcxGridDBTableView` (data-aware)
- **Layout:** `TdxLayoutControl` for responsive forms
- **Skins:** `TdxSkinController` for global themes
- **Export:** `cxGridExportLink` to Excel/PDF
- **Filters:** `DataController.Filter` for programmatic filters

## Firebird Database

Firebird is the most used corporate database with Delphi. Access via **FireDAC** (driver `FB`).

### Mandatory Connection Configuration

```pascal
FConnection.DriverName := 'FB';
FConnection.Params.Values['CharacterSet'] := 'UTF8';    //ALWAYS UTF8
FConnection.Params.Values['SQLDialect'] := '3';          //NEVER Dialect 1
FConnection.Params.Values['Protocol'] := 'TCPIP';        //Or 'Local' for embedded
FConnection.Params.Values['PageSize'] := '16384';         // 16KB recomendado
FConnection.TxOptions.Isolation := xiReadCommitted;       //Standard isolation
```

### Essential Rules Firebird

- **Dialect 3 ALWAYS** — Dialect 1 is InterBase legacy and causes ambiguity with `DATE`
- **CharacterSet UTF8** — required for correct accent support
- **Parameterized queries** — never concatenate strings in SQL
- **RETURNING with Open** — `INSERT ... RETURNING id` requires `LQuery.Open`, not `ExecSQL`
- **Generators** for auto-increment with `BEFORE INSERT` triggers
- **Domains** to centralize types and validations in the schema
- **Stored Procedures:** Selectable (with `SUSPEND`) uses `SELECT FROM SP`; Executable uses `EXECUTE PROCEDURE`
- **Explicit transactions** for compound operations (StartTransaction/Commit/Rollback)
- **Treat deadlocks** via `EFDDBEngineException.Kind = ekRecordLocked`

### Firebird Anti-Patterns

- ❌ `SQLDialect := '1'` — ALWAYS use `'3'`
- ❌ `ExecSQL` with `RETURNING` — use `Open`
- ❌ Concatenate SQL — use parameters
- ❌ Ignore `CharacterSet` — set `UTF8`
- ❌ `PAGE_SIZE 4096` — use `16384` for production
- ❌ Bypass deadlocks — handle `ekRecordLocked`
- ❌ `CREATE TABLE IF NOT EXISTS` — does not exist in Firebird (check via `RDB$RELATIONS`)

> **Skills:** `.gemini/skills/firebird-database/SKILL.md`
> **Rules:** `.cursor/rules/firebird-patterns.md`

## PostgreSQL Database

PostgreSQL is the most advanced open-source database, ideal for modern projects. Access via **FireDAC** (driver `PG`).

### Connection Configuration

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

### Essential Rules PostgreSQL

- **IDENTITY instead of SERIAL** — use `GENERATED ALWAYS AS IDENTITY` for new projects (PG 10+)
- **RETURNING with Open** — `INSERT ... RETURNING id` requires `LQuery.Open`, not `ExecSQL`
- **native UPSERT** — `INSERT ... ON CONFLICT (col) DO UPDATE SET ...`
- **JSONB** — for semi-structured data, indexable with GIN
- **ENUM types** — `CREATE TYPE status AS ENUM ('active', 'inactive')` mapped to Pascal enum
- **PL/pgSQL** — Functions (`RETURNS TABLE` = Selectable), Procedures (`CALL`, PG 11+)
- **Explicit transactions** — `StartTransaction/Commit/Rollback`, supports `SAVEPOINT`
- **Full-Text Search** — `tsvector` + `tsquery` with GIN index
- **Metadata via `information_schema`** — do not use `RDB$` (this is Firebird)

### PostgreSQL Anti-Patterns

- ❌ Concatenate SQL — use parameterized parameters
- ❌ `ExecSQL` with `RETURNING` — use `Open`
- ❌ `SERIAL` in new projects — use `IDENTITY`
- ❌ `SELECT *` in large tables — select required columns
- ❌ N+1 queries — use JOIN or subquery
- ❌ Save JSON as TEXT — use `JSONB`
- ❌ Ignore indexes on WHERE/JOIN columns

> **Skills:** `.gemini/skills/postgresql-database/SKILL.md`
> **Rules:** `.cursor/rules/postgresql-patterns.md`

## MySQL / MariaDB Database

MySQL is the most popular open-source database in the world. MariaDB is a compatible fork. Access via **FireDAC** (driver `MySQL`).

### Connection Configuration

```pascal
FConnection.DriverName := 'MySQL';
FConnection.Params.Values['Server'] := 'localhost';
FConnection.Params.Values['Port'] := '3306';
FConnection.Params.Database := 'meubanco';
FConnection.Params.UserName := 'root';
FConnection.Params.Password := 'senha';
FConnection.Params.Values['CharacterSet'] := 'utf8mb4';  //NEVER 'utf8' (only 3 bytes!)
FConnection.TxOptions.Isolation := xiReadCommitted;
```

### Essential Rules MySQL

- **`utf8mb4` ALWAYS** — `utf8` in MySQL only has 3 bytes (does not support emoji). Use `utf8mb4`
- **AUTO_INCREMENT + LAST_INSERT_ID()** — MySQL does NOT support `RETURNING`. Get ID via `LAST_INSERT_ID()`
- **native UPSERT** — `INSERT ... ON DUPLICATE KEY UPDATE`
- **Native JSON** — `JSON` type with `->>`/`JSON_EXTRACT` operators (MySQL 5.7+)
- **InnoDB ALWAYS** — never MyISAM in new projects (needs FK and transactions)
- **Stored Procedures** — `CALL sp_nome(...)` for procedures, `SELECT fn_nome(...)` for functions
- **Explicit transactions** — `StartTransaction/Commit/Rollback`, supports `SAVEPOINT`
- **COLLATE** — `utf8mb4_unicode_ci` for correct case-insensitive comparison
- **Metadata via `information_schema`** — use `DATABASE()` for current schema

### MySQL Anti-Patterns

- ❌ `utf8` as charset — use `utf8mb4`
- ❌ Try `RETURNING` — does not exist, use `LAST_INSERT_ID()`
- ❌ `MyISAM` in new tables — use `InnoDB`
- ❌ Concatenate SQL — use parameters
- ❌ `SELECT *` without `LIMIT` — page results
- ❌ N+1 queries — use JOIN or subquery
- ❌ Ignore indexes on WHERE/JOIN columns

> **Skills:** `.gemini/skills/mysql-database/SKILL.md`
> **Rules:** `.cursor/rules/mysql-patterns.md`

## Threads and Multi-Threading

Threads are essential for keeping the UI responsive and processing data in parallel. Delphi offers `TThread`, PPL (`TTask`, `TParallel.For`, `TFuture<T>`) and synchronization primitives.

### Golden Rule

> **NEVER access visual components (VCL/FMX) directly from a secondary thread.**
> Use `TThread.Synchronize` (blocking) or `TThread.Queue` (non-blocking) to update the UI.

### Threading Approaches

| Approach | When to Use |
|-----------|-------------|
| `TThread.CreateAnonymousThread` | Simple, one-shot tasks |
| `TTask.Run` (PPL) | Modern way, managed pool |
| `TParallel.For` | Parallel loop in independent collections |
| `TFuture<T>` | Asynchronous result with return value |
| `TThread` (inheritance) | Permanent workers, queues, servers |

### Thread-Safety

- **`TCriticalSection`** — Classic critical section (`Enter`/`Leave` ALWAYS in `finally`)
- **`TMonitor`** — Native object lock (`Enter`/`Exit`)
- **`TInterlocked`** — Atomic operations (`Increment`, `Decrement`, `Exchange`)
- **`TThreadList<T>`** — Thread-safe list with `LockList`/`UnlockList`
- **`TMultiReadExclusiveWriteSynchronizer`** — Cache: multiple reads, few writes
- **`TThreadedQueue<T>`** — Thread-safe queue for Producer-Consumer

### Threading Anti-Patterns

- ❌ Access VCL/FMX directly from secondary thread
- ❌ `Sleep()` in the main thread (freezes the UI!)
- ❌ `FreeOnTerminate := True` + `WaitFor` (crash!)
- ❌ Access shared variables without locking
- ❌ Ignore exceptions in threads (they are silent!)
- ❌ `TCriticalSection.Leave` fora de `finally`

> **Skills:** `.gemini/skills/threading/SKILL.md`
> **Rules:** `.cursor/rules/threading-patterns.md`

## SOLID principles in Delphi

### S — Single Responsibility Principle (SRP)

Each unit and each class must have **a single responsibility**:

```pascal
//✅ GOOD — separate responsibilities
TCustomerValidator = class
  function Validate(ACustomer: TCustomer): TValidationResult;
end;

TCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  function FindById(AId: Integer): TCustomer;
  procedure Save(ACustomer: TCustomer);
end;

//❌ BAD — class doing it all
TCustomer = class
  procedure Validate;     //should be a Validator
  procedure SaveToDb;     //should be a Repository
  procedure SendEmail;    //should be a Service
end;
```

### O — Open/Closed Principle (OCP)

Classes should be **open for extension**, closed for modification. Use inheritance and interfaces:

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

Subtypes must be replaceable with the base type without breaking behavior:

```pascal
//✅ GOOD — any ICustomerRepository works
procedure TCustomerService.LoadCustomer(ARepo: ICustomerRepository);
begin
  //works with TFireDACCustomerRepo, TMemoryCustomerRepo, TMockCustomerRepo
  FCustomer := ARepo.FindById(FCustomerId);
end;
```

### I — Interface Segregation Principle (ISP)

Small, cohesive interfaces, not "fat" interfaces:

```pascal
//✅ GOOD — segregated interfaces
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

Depend on **abstractions** (interfaces), not concrete implementations. Use **constructor injection**:

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

## Clean Code — Essential Rules

### 1. Short Methods

- Maximum **20 lines** per method (ideal: 5-10)
- If a method needs a comment explaining "what it does", it should be extracted into a method with a descriptive name

### 2. Self-Descriptive Names

```pascal
//❌ SPACIOUS
procedure Proc1(S: string; N: Integer);
function Calc(V: Double): Double;

// ✅ BOM
procedure SendNotificationEmail(const ARecipientEmail: string; ATemplateId: Integer);
function CalculateDiscountedPrice(AOriginalPrice: Double): Double;
```

### 3. Avoid Magic Numbers

```pascal
//❌ SPACIOUS
if ACustomer.Age > 18 then

// ✅ BOM
const
  MINIMUM_AGE = 18;
// ...
if ACustomer.Age > MINIMUM_AGE then
```

### 4. Guard Clauses

```pascal
//❌ BAD — excessive nesting
procedure ProcessOrder(AOrder: TOrder);
begin
  if Assigned(AOrder) then
  begin
    if AOrder.Items.Count > 0 then
    begin
      if AOrder.IsValid then
      begin
        //real logic here
      end;
    end;
  end;
end;

//✅ BOM — guard clauses
procedure ProcessOrder(AOrder: TOrder);
begin
  if not Assigned(AOrder) then
    raise EArgumentNilException.Create('AOrder cannot be nil');
  if AOrder.Items.Count = 0 then
    raise EBusinessRuleException.Create('Order must have at least one item');
  if not AOrder.IsValid then
    raise EValidationException.Create('Order validation failed');

  //real logic here — no nesting
end;
```

### 5. Focused and Typed Try/Except

```pascal
//❌ BAD — generic catch swallowing critical errors (Access Violation, OOM)
try
  //large block of long code
except
  on E: Exception do //Or worse: without declaring "on E:"
    ShowMessage(E.Message);
end;

//✅ GOOD — specific exceptions and granular recovery
try
  FConnection.Open;
  PerformCriticalAction;
except
  on E: EFDDBEngineException do
    raise EDatabaseConnectionException.Create('Falha local no banco: ' + E.Message);
  on E: EBusinessRuleException do
    raise; //Pass the exception to the Controller to catch
  on E: Exception do
  begin
    Logger.LogError('Critical unexpected failure', E);
    raise; //NEVER hide pure root Exception exceptions without rethrowing!
  end;
end;
```

### 6. Unit Organization

```pascal
unit MyApp.Domain.Customer.Entity;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  //1. Types, enums and records first
  TCustomerStatus = (csActive, csInactive, csSuspended);

  //2. Interfaces
  ICustomer = interface
    ['{GUID}']
    function GetName: string;
    property Name: string read GetName;
  end;

  //3. Classes
  TCustomer = class(TInterfacedObject, ICustomer)
  private
    FId: Integer;
    FName: string;
    FStatus: TCustomerStatus;
    function GetName: string;
  public
    //Constructor and Destructor first
    constructor Create(const AName: string);
    destructor Destroy; override;

    //After public methods
    function IsActive: Boolean;
    procedure Activate;
    procedure Deactivate;

    //Properties last
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

//... other implementations
```

## Recommended Design Patterns

| Standard | Use in Delphi |
|--------|---------------|
| **Repository** | Abstracts data access via interface (FireDAC, REST, etc.) |
| **Service** | Contains business logic orchestrating repositories and other services |
| **Factory** | Creates instances of complex objects or with dependencies |
| **Observer** | Use `TNotifyEvent` or interfaces to decouple notifications |
| **Strategy** | Interfaces to vary algorithms (e.g. tax calculation) |
| **Unit of Work** | Manages database transactions |

## Anti-Patterns to Avoid

- ❌ **God class / God unit** — units with thousands of lines doing everything
- ❌ **Direct coupling to forms** — business logic in `OnClick` of buttons
- ❌ **Uses circular** — resolved by separating into layers (Domain, Infra, Application, Presentation)
- ❌ **Global variables** — use dependency injection
- ❌ **Hardcoded Strings** — use `resourcestring` or constants
- ❌ **Ignoring memory management** — always free unmanaged objects by reference
- ❌ **`with` statement** — avoid `with` as it reduces readability and makes debugging difficult
- ❌ **Testing in Banco Real** — attach DUnitX projects directly to `TFDConnection`, skipping Mocks/Fakes.

## Memory Management (Critical)

- **Watched Blocks:** The golden rule in Delphi: Whenever there is code calling `.Create` for instances of TObject Classes, the IMMEDIATELY subsequent line must be a `try`. NO intermediate lines of code!

```pascal
//✅ The Gold Standard for Disposable Objects
var LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LList.Add('item');
    // ...
  finally
    LList.Free; //i FreeAndNil(LList)
  end;
end;

//✅ Objects with owner - VCL/FMX components
TMyComponent := TMyComponent.Create(Self); //Owner (Self) assumes release

//✅ Garbage Collection com Interfaces (ARC)
//The object will be automatically cleaned up at the end of the scope, eliminating the need for try..free
var LService: IMyService;
begin
  LService := TMyService.Create; 
  LService.DoSomething;
end;

//✅ Local variables: use L prefix
var LCustomer: TCustomer;
```

## Documentation

- Use **XMLDoc** for public methods and interfaces:

```pascal
///<summary>
///Locates a customer by the CPF entered.
///</summary>
///<param name="ACpf">Customer CPF (numbers only)</param>
///<returns>TCustomer instance or nil if not found</returns>
///<exception cref="EArgumentException">If ACpf is empty</exception>
function FindByCpf(const ACpf: string): TCustomer;
```

- Comments in **Portuguese** for Brazilian projects
- Don't comment obvious code — let the method name explain

## Layer Structure (Architecture)

```
src/
├── Domain/           ← Entidades, Value Objects, Interfaces de repositório
├── Application/      ← Services, Use Cases, DTOs
├── Infrastructure/   ← Implementações de repositório (FireDAC), APIs externas
└── Presentation/     ← Forms (VCL/FMX), ViewModels
tests/
└── Unit/             ← Projetos DUnitX e Fakes/Mocks isolados por contexto
```

> **Dependency rule:** `Presentation → Application → Domain ← Infrastructure`
> The Domain **never** depends on other layers. `tests` depend on `Application` and `Domain` but inject Fake implementations by copying `Infrastructure` alone.

---

## 🚫 AI Context Policy — What to Include and Exclude

> Full strategy documented in `docs/ai-ignore-strategy.md`.

### Files AI Must Always Use as Context

- `AGENTS.md` — universal rules
- `README.md` — project overview
- `.github/copilot-instructions.md` — Copilot pre-prompt
- `.claude/CLAUDE.md` — Claude master prompt
- `.claude/rules/**/*.md` — context-specific rules
- `.claude/skills/**/SKILL.md` — on-demand skills
- `.cursor/rules/**/*.md` — Cursor rules
- `.gemini/skills/**/SKILL.md` — Gemini skills
- `.kiro/steering/**/*.md` — Kiro steering docs
- `examples/**/*.pas` — good practice examples
- `docs/**/*.md` — documentation

### Files AI Must Never Use as Context

- Build artifacts: `*.dcu`, `*.exe`, `*.dll`, `*.bpl`, `*.dcp`, `*.map`, `*.res`
- IDE temporaries: `*.local`, `*.identcache`, `*.stat`, `__history/`, `__recovery/`
- Output directories: `Win32/`, `Win64/`, `Debug/`, `Release/`, `build/`, `dist/`
- Secrets: `*.key`, `*.pfx`, `*.p12`, `.env`, `.env.*`
- Noise: `*.log`, `*.dmp`, `*.bak`, `*.tmp`

See `.cursorignore`, `.gitignore` and `.vscode/settings.json` for the enforced patterns.

