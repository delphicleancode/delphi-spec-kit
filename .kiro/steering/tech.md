# Technical Stack — Delphi

## Language and Compiler

- **Language:** Object Pascal (Delphi 10.x / 11.x / 12.x)
- **Compiler:** dcc32 (32-bit) / dcc64 (64-bit)
- **Build System:** MSBuild (via `.dproj`)
- **Native IDE:** RAD Studio / Delphi

## Main Frameworks

| Framework | Usage |
|-----------|-----|
| **VCL** | Windows desktop interfaces |
| **FMX** | Cross-platform interfaces (Windows, macOS, Android, iOS) |
| **FireDAC** | Universal Database Access |
| **DUnitX** | Unit testing framework |
| **REST Client** | Consumption of REST APIs |

## Supported Databases

- **SQLite** — local and mobile apps
- **Firebird** — corporate apps (core database of the Delphi ecosystem)
- **PostgreSQL** — modern projects
- **MySQL / MariaDB** — web hosting, LAMP/LEMP stack, high popularity
- **SQL Server** — Microsoft environments

### Firebird — Critical Rules

- **FireDAC Driver:** `DriverName := 'FB'`
- **Dialect 3 ALWAYS:** `SQLDialect := '3'` (Dialect 1 is InterBase legacy)
- **CharacterSet UTF8:** Required for accent support
- **PageSize:** 16384 (16KB recommended for production)
- **RETURNING with Open:** `INSERT ... RETURNING id` requires `LQuery.Open`, not `ExecSQL`
- **Generators:** Auto-increment via `GEN_ID()` in `BEFORE INSERT` triggers
- **Stored Procedures:** Selectable (with `SUSPEND`) × Executable
- **Skills:** `.gemini/skills/firebird-database/SKILL.md`
- **Rules:** `.cursor/rules/firebird-patterns.md`

### PostgreSQL — Critical Rules

- **FireDAC Driver:** `DriverName := 'PG'`
- **IDENTITY over SERIAL:** Use `GENERATED ALWAYS AS IDENTITY` for new projects (PG 10+)
- **CharacterSet UTF8:** Always set on connection
- **RETURNING with Open:** `INSERT ... RETURNING id` requires `LQuery.Open`, not `ExecSQL`
- **native UPSERT:** `INSERT ... ON CONFLICT (col) DO UPDATE SET ...`
- **JSONB:** Semi-structured data with GIN index (do not save as TEXT)
- **PL/pgSQL:** Functions (`SELECT * FROM fn()`) / Procedures (`CALL sp()`, PG 11+)
- **Metadata:** Use `information_schema` (not `RDB$` — this is Firebird)
- **Skills:** `.gemini/skills/postgresql-database/SKILL.md`
- **Rules:** `.cursor/rules/postgresql-patterns.md`

### MySQL / MariaDB — Critical Rules

- **FireDAC Driver:** `DriverName := 'MySQL'`
- **`utf8mb4` ALWAYS:** Never `utf8` (only 3 bytes in MySQL, does not support emoji)
- **InnoDB ALWAYS:** Never MyISAM in new projects (FK + transactions)
- **No `RETURNING`:** MySQL does NOT support `RETURNING` — use `LAST_INSERT_ID()`
- **UPSERT:** `INSERT ... ON DUPLICATE KEY UPDATE`
- **Native JSON:** Type `JSON` with `->>`/`JSON_EXTRACT` (MySQL 5.7+)
- **Procedures:** `CALL sp_nome(...)`, Functions: `SELECT fn_nome(...)`
- **Metadata:** Use `information_schema` + `DATABASE()` for current schema
- **Skills:** `.gemini/skills/mysql-database/SKILL.md`
- **Rules:** `.cursor/rules/mysql-patterns.md`

### Threading & Multi-Threading — Critical Rules

- **Rule of Thumb:** NEVER access VCL/FMX from secondary thread
- **Synchronize:** Blocking — waits for the main thread to process
- **Queue:** Non-blocking — queue and continue (PREFER)
- **TTask.Run:** Modern way to run in the background (PPL, managed pool)
- **TParallel.For:** Parallel loops — protect variables with `TInterlocked`/`TCriticalSection`
- **TCriticalSection:** `Enter`/`Leave` ALWAYS in `finally` — never out
- **Anti-patterns:** `Sleep()` in the main thread, `FreeOnTerminate + WaitFor`, variables without lock
- **Skills:** `.gemini/skills/threading/SKILL.md`
- **Rules:** `.cursor/rules/threading-patterns.md`

## External Dependencies

- Prefer **zero third-party dependencies** when possible
- Native VCL/FMX components for UI
- Native FireDAC for data access
- When necessary, use ACBr for Brazilian tax features

## Code Standards

### File Types

| Extension | Description |
|----------|-----------|
| `.pas` | Unit (source code) |
| `.dfm` | Form design (VCL) |
| `.fmx` | Form design (FMX) |
| `.dpr` | Project file |
| `.dpk` | Package file |
| `.dproj` | Project config (MSBuild XML) |
| `.res` | Resource file |

### Inline Variables (Delphi 10.3+)
```pascal
// Preferir quando melhora legibilidade
var LCustomer := TCustomer.Create('Nome');
for var I := 0 to List.Count - 1 do
  ProcessItem(List[I]);
```

### Generics
```pascal
// Usar generics para coletions tipadas
var LList: TObjectList<TCustomer>;
LList := TObjectList<TCustomer>.Create(True); // OwnsObjects
```

### Anonymous Methods
```pascal
// Usar para callbacks e expressões funcionais
LList.Sort(
  TComparer<TCustomer>.Construct(
    function(const ALeft, ARight: TCustomer): Integer
    begin
      Result := CompareStr(ALeft.Name, ARight.Name);
    end
  )
);
```

## Testing and Quality (TDD)

- **Test-Driven Development (TDD):** Adoption of test-driven development whenever possible in the business rules layer (Domain/App Services) via **Red-Green-Refactor**.
- **Framework Ouro:** `DUnitX`
- **Infrastructure Isolation:** Bench tests or external dependencies must be "mocked" through the creation of local Fakes implementing the Interfaces. NEVER run unit tests on the real database.
- **Leak Prevention in Tests:** Every suite must manage memory properly in the `[TearDown]` methods and/or using reference counting in mock interfaces.
