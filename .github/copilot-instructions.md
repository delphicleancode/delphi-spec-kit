# GitHub Copilot — Instructions for Delphi Projects

## Contexto

This is a **Delphi (Object Pascal)** project that follows SOLID principles, clean code and the Object Pascal Style Guide. See `AGENTS.md` in the project root for the complete convention reference.

## General Guidelines

1. **Always generate code in Object Pascal** (Delphi) unless explicitly requested in another language.
2. **Use PascalCase** for all identifiers. Lowercase reserved words.
3. **Respect the prefixes** of the Pascal convention: `T` (classes), `I` (interfaces), `E` (exceptions), `F` (private fields), `A` (parameters), `L` (local variables).
4. **Prefer interfaces** over concrete classes for dependencies.
5. **Use constructor injection** for dependency injection.
6. **Never put business logic in form event handlers** (`OnClick`, `OnChange`, etc.). Delegate to services.

## Code Style

### Indentation and Formatting
- Indentation: **2 spaces** (no tabs)
- `begin` on the **same line** of `if`, `for`, `while`, `with` when in a single block
- `begin` on **new line** for method implementations
- Limit of **120 characters** per line

### Unit Sections
Order unit sections according to:
```
unit Nome;

interface

uses
  { RTL units },
  { Units do projeto };

type
  { Enums e Records }
  { Interfaces }
  { Classes }

implementation

uses
  { Units adicionais só necessárias na implementação };

{ Implementações }

end.
```

### Variable Declaration
```pascal
// Preferir inline var quando disponível (Delphi 10.3+)
var LCustomer := TCustomer.Create('João');

// Ou declaraction explícita com prefixo L
var
  LCustomer: TCustomer;
  LCount: Integer;
```

## Error Handling

- Use **specific exceptions** (create exception classes per domain):
  ```pascal
  EBusinessRuleException = class(Exception);
  EEntityNotFoundException = class(Exception);
  EValidationException = class(Exception);
  ```
- **Guard clauses** at the beginning of the method instead of deep nesting
- **Try/finally** for memory management
- **Try/except** only for actual error handling, never for control flow

## Documentation

- Generate **XMLDoc** for public methods and properties
- Comments in **Portuguese** for Brazilian projects
- Do not comment self-explanatory code

## Design Patterns

When creating new features, follow the layered architecture:
- **Domain:** Entities, Value Objects, Interfaces
- **Application:** Services, Use Cases, DTOs
- **Infrastructure:** Repositories (FireDAC), external APIs
- **Presentation:** Forms VCL/FMX

## What NOT to generate

- ❌ Do not use `with` statement
- ❌ Do not create global variables
- ❌ Do not use `AnsiString` when `string` (UnicodeString) is appropriate
- ❌ Don't use magic numbers — declare constants
- ❌ Don't do generic catch (`except on E: Exception do ShowMessage`)
- ❌ Don't mix UI logic with business logic
- ❌ Do not create methods with more than 20 lines
- ❌ Don't ignore `Free` of temporary objects (use try/finally)

## REST Frameworks

### Horse
- Controller: class with `class procedure RegisterRoutes`
- Handler: `class procedure Nome(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc)`
- Middleware: `THorse.Use(Jhonson)`, `THorse.Use(CORS)`, `THorse.Use(HandleException)`
- Routes: kebab-case, plural — `/api/customers`, `/api/order-items`
- Always delegate to Services — never access data in the controller

### DelphiMVCFramework
- Controller: inherits `TMVCController` with `[MVCPath('/api/resource')]`
- Routes: attributes `[MVCPath]`, `[MVCHTTPMethod([httpGET])]`
- Active Record: inherits `TMVCActiveRecord` with `[MVCTable]`, `[MVCTableField]`
- Serialization via `Render()` — do not use `Response.Content` directly
- JWT: `TMVCJWTAuthenticationMiddleware`

### Dext Framework
- Minimal API: `App.Builder.MapGet`, `MapPost` using anonymous functions (handlers)
- Native routing with Auto Model Binding populating DTOs
- Dependency Injection: `App.Services.AddSingleton`, `AddScoped`
- Entity ORM: `DbContext.Where(U.Age > 18)` (Smart Properties expressions instead of SQL strings)
- Async: use `TAsyncTask` for asynchronism and promises

### DevExpress Components
- DevExpress component prefixes: `grd` (TcxGrid), `tvw` (TcxGridDBTableView), `lyt` (TdxLayoutControl), `skn` (TdxSkinController)
- Prefer `TdxLayoutControl` to manual positioning
- Configure grid via code when columns are dynamic
- Export: use `cxGridExportLink` for Excel/PDF

### ACBr Project (Commercial Automation)
- **Golden Rule:** Do not attach components (`TACBrNFe`, `TACBrCTe`, etc.) directly to UI forms.
- Isolate tax logic in Service classes (e.g. `TNFeService`) or Repositories.
- Configure certificates and cryptographic libraries (WinCrypt/OpenSSL) via code, with data dynamically obtained from abstraction classes.
- Always guarantee memory freeing if you build ACBr components dynamically in a Service (`try...finally Free;`).
- Common prefixes in the base UI or DataModules: `acbrNFe`, `acbrECF`, `acbrTef`, `acbrBoleto`.

### Firebird Database
- **Rule of Thumb:** Dialect 3 ALWAYS (`SQLDialect := '3'`), CharacterSet UTF8, PageSize 16384.
- **RETURNING:** `INSERT INTO ... RETURNING id` requires `LQuery.Open`, NEVER `ExecSQL` (which discards the result).
- **Generators:** Use `GEN_ID(generator, 1)` in `BEFORE INSERT` or `IDENTITY` triggers (Firebird 3+).
- **Stored Procedures:** Selectable (with `SUSPEND`) → `SELECT * FROM SP_NOME(...)`. Executable → `EXECUTE PROCEDURE SP_NOME(...)`.
- **Transactions:** Explicitly use `StartTransaction/Commit/Rollback` for compound operations. Isolation pattern: `xiReadCommitted`.
- **Error Handling:** Treat `EFDDBEngineException.Kind` → `ekRecordLocked` (deadlock), `ekUKViolated` (duplicate), `ekFKViolated` (FK).
- **Domains:** Use Domains (`DM_ID`, `DM_NAME`, `DM_MONEY`) to centralize types and validations in the schema.
- **Anti-patterns:** ❌ Concatenate SQL, ❌ `ExecSQL` with `RETURNING`, ❌ Ignore `CharacterSet`, ❌ `CREATE TABLE IF NOT EXISTS` (use `RDB$RELATIONS`).

### PostgreSQL Database
- **Driver:** `DriverName := 'PG'`, `CharacterSet := 'UTF8'`, default port 5432.
- **IDENTITY:** Use `GENERATED ALWAYS AS IDENTITY` instead of `SERIAL` for new projects (PG 10+).
- **RETURNING:** Same rule as Firebird — `INSERT ... RETURNING id` requires `LQuery.Open`, not `ExecSQL`.
- **UPSERT:** `INSERT ... ON CONFLICT (col) DO UPDATE SET ...` — native to PostgreSQL.
- **JSONB:** Use for semi-structured data. Cast in SQL with `::jsonb`. Indexable with GIN.
- **ENUM Types:** `CREATE TYPE status AS ENUM (...)` mapped to Pascal enum via string constants.
- **Functions:** Return value or table — `SELECT * FROM fn_nome(...)`. Procedures (PG 11+): `CALL sp_nome(...)`.
- **Metadata:** Use `information_schema.tables` / `information_schema.columns` (not `RDB$`).
- **Anti-patterns:** ❌ `SERIAL` (use `IDENTITY`), ❌ `SELECT *` in large tables, ❌ N+1 queries, ❌ JSON as TEXT (use `JSONB`).

### MySQL / MariaDB Database
- **Driver:** `DriverName := 'MySQL'`, default port 3306. Client library: `libmysql.dll` (or `libmariadb.dll`).
- **Charset:** `utf8mb4` ALWAYS. MySQL's `utf8` is only 3 bytes long (does not support emoji). Collation: `utf8mb4_unicode_ci`.
- **AUTO_INCREMENT:** MySQL DOES NOT support `RETURNING`. Get ID via `LAST_INSERT_ID()` or `FConnection.GetLastAutoGenValue('')`.
- **UPSERT:** `INSERT ... ON DUPLICATE KEY UPDATE name = VALUES(name)` — native to MySQL.
- **JSON:** Native `JSON` type (MySQL 5.7+). `->>`/`JSON_EXTRACT` operators. Index via Generated Column.
- **Engine:** `InnoDB` ALWAYS (never MyISAM). Need FK and transactions.
- **Procedures:** `CALL sp_nome(...)`. Functions: `SELECT fn_nome(...)`. `SIGNAL SQLSTATE` for errors.
- **Anti-patterns:** ❌ `utf8` (use `utf8mb4`), ❌ `RETURNING` (use `LAST_INSERT_ID()`), ❌ MyISAM, ❌ N+1 queries.

### Intraweb Framework
- **Stateful Web:** Never use global variables (variables declared in the unit interface) for interactive data (they leak cross-session). Save status to `UserSession`.
- Avoid blocking UI code from Classic VCL (`ShowMessage()`, `InputBox()`, Modal calls).
- Give full preference to asynchronous rendering using Ajax interrupts, encoding events in type `OnAsyncClick` instead of standard entire posts.
- Standard component prefixes: always use `iw` base (`iwBtnSave`, `iwEdtUser`).

---

## 🧵 Threads and Multi-Threading

- **Golden Rule:** NEVER access visual components (VCL/FMX) directly from secondary thread. Use `TThread.Synchronize` (blocking) or `TThread.Queue` (non-blocking).
- **Simple tasks:** `TThread.CreateAnonymousThread` or `TTask.Run` (PPL — modern form, managed pool).
- **Parallel loops:** `TParallel.For` to process independent collections. Protect shared variables with `TInterlocked` or `TCriticalSection`.
- **Asynchronous result:** `TFuture<T>` — `.Value` blocks until the result is ready.
- **Thread-Safety:** `TCriticalSection` (Enter/Leave in `finally`), `TMonitor`, `TInterlocked` (atomic operations), `TThreadList<T>`, `TMultiReadExclusiveWriteSynchronizer` (cache).
- **Producer-Consumer:** `TThreadedQueue<T>` with `PushItem`/`PopItem`.
- **Cancellation:** Check `Terminated` in `TThread` loops, or use custom cancellation token.
- **Debugging:** `TThread.NameThreadForDebugging('NomeDaThread')` to facilitate identification in the IDE.
- **Anti-patterns:** ❌ `Sleep()` in the main thread, ❌ `FreeOnTerminate + WaitFor`, ❌ Shared variables without lock, ❌ Unhandled exceptions in threads (they are silent).

---

## 🛑 Memory Management and Exception Control

- **Never suggest code prone to Memory Leaks:** In Delphi, every `TObject` created without `Owner` or outside `Interfaces` (ARC) must **obligatorily** be protected by `try..finally` and `Free` and the keyword `try` must come IMMEDIATELY AFTER its creation. No exception between Create and Try.
- **Do not create instances in parameters directly:** If the `Foo(TObjeto.Create)` calls do not belong to a native release managed by the signed receiver, you must instantiate first, protect with try and send the var.
- **Domain-Based Exception Handling:** Use and create `Exception` Classes customized for your logics.
- **Exception Transparency:** When using the `except` block, be strictly focused on specific exceptions (`on E: EFDDBEngineException do`). If you use the generic `Exception` from scratch, NEVER stop using the pure `raise;` at the end of the exception block so as not to hide technical errors from global Stack Traces.


