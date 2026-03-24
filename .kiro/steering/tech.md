# Stack Técnica — Delphi

## Linguagem e Compilador

- **Linguagem:** Object Pascal (Delphi 10.x / 11.x / 12.x)
- **Compilador:** dcc32 (32-bit) / dcc64 (64-bit)
- **Build System:** MSBuild (via `.dproj`)
- **IDE Nativa:** RAD Studio / Delphi

## Frameworks Principais

| Framework | Uso |
|-----------|-----|
| **VCL** | Interfaces desktop Windows |
| **FMX** | Interfaces cross-platform (Windows, macOS, Android, iOS) |
| **FireDAC** | Acesso a banco de dados universal |
| **DUnitX** | Framework de testes unitários |
| **REST Client** | Consumo de APIs REST |

## Bancos de Dados Suportados

- **SQLite** — apps locais e mobile
- **Firebird** — apps corporativas (banco principal do ecossistema Delphi)
- **PostgreSQL** — projetos modernos
- **MySQL / MariaDB** — web hosting, LAMP/LEMP stack, alta popularidade
- **SQL Server** — ambientes Microsoft

### Firebird — Regras Críticas

- **Driver FireDAC:** `DriverName := 'FB'`
- **Dialect 3 SEMPRE:** `SQLDialect := '3'` (Dialect 1 é legado InterBase)
- **CharacterSet UTF8:** Obrigatório para suporte a acentos
- **PageSize:** 16384 (16KB recomendado para produção)
- **RETURNING com Open:** `INSERT ... RETURNING id` exige `LQuery.Open`, não `ExecSQL`
- **Generators:** Auto-increment via `GEN_ID()` em triggers `BEFORE INSERT`
- **Stored Procedures:** Selectable (com `SUSPEND`) × Executable
- **Skills:** `.gemini/skills/firebird-database/SKILL.md`
- **Rules:** `.cursor/rules/firebird-patterns.md`

### PostgreSQL — Regras Críticas

- **Driver FireDAC:** `DriverName := 'PG'`
- **IDENTITY sobre SERIAL:** Usar `GENERATED ALWAYS AS IDENTITY` para novos projetos (PG 10+)
- **CharacterSet UTF8:** Sempre definir na conexão
- **RETURNING com Open:** `INSERT ... RETURNING id` exige `LQuery.Open`, não `ExecSQL`
- **UPSERT nativo:** `INSERT ... ON CONFLICT (col) DO UPDATE SET ...`
- **JSONB:** Dados semi-estruturados com índice GIN (não guardar como TEXT)
- **PL/pgSQL:** Functions (`SELECT * FROM fn()`) / Procedures (`CALL sp()`, PG 11+)
- **Metadata:** Usar `information_schema` (não `RDB$` — isso é Firebird)
- **Skills:** `.gemini/skills/postgresql-database/SKILL.md`
- **Rules:** `.cursor/rules/postgresql-patterns.md`

### MySQL / MariaDB — Regras Críticas

- **Driver FireDAC:** `DriverName := 'MySQL'`
- **`utf8mb4` SEMPRE:** Nunca `utf8` (só 3 bytes no MySQL, não suporta emoji)
- **InnoDB SEMPRE:** Nunca MyISAM em novos projetos (FK + transactions)
- **Sem `RETURNING`:** MySQL NÃO suporta `RETURNING` — usar `LAST_INSERT_ID()`
- **UPSERT:** `INSERT ... ON DUPLICATE KEY UPDATE`
- **JSON nativo:** Tipo `JSON` com `->>`/`JSON_EXTRACT` (MySQL 5.7+)
- **Procedures:** `CALL sp_nome(...)`, Functions: `SELECT fn_nome(...)`
- **Metadata:** Usar `information_schema` + `DATABASE()` para schema atual
- **Skills:** `.gemini/skills/mysql-database/SKILL.md`
- **Rules:** `.cursor/rules/mysql-patterns.md`

### Threading & Multi-Threading — Regras Críticas

- **Regra de Ouro:** NUNCA acessar VCL/FMX de thread secundária
- **Synchronize:** Bloqueante — espera a main thread processar
- **Queue:** Não-bloqueante — enfileira e continua (PREFERIR)
- **TTask.Run:** Forma moderna de executar em background (PPL, pool gerenciado)
- **TParallel.For:** Loops paralelos — proteger variáveis com `TInterlocked`/`TCriticalSection`
- **TCriticalSection:** `Enter`/`Leave` SEMPRE no `finally` — nunca fora
- **Anti-patterns:** `Sleep()` na main thread, `FreeOnTerminate + WaitFor`, variáveis sem lock
- **Skills:** `.gemini/skills/threading/SKILL.md`
- **Rules:** `.cursor/rules/threading-patterns.md`

## Dependências Externas

- Preferir **zero dependências de terceiros** quando possível
- Componentes VCL/FMX nativos para UI
- FireDAC nativo para acesso a dados
- Quando necessário, usar ACBr para funcionalidades fiscais brasileiras

## Padrões de Código

### Tipos de Arquivo

| Extensão | Descrição |
|----------|-----------|
| `.pas` | Unit (código-fonte) |
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
// Usar generics para coleções tipadas
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

## Testagem e Qualidade (TDD)

- **Test-Driven Development (TDD):** Adoção de desenvolvimento guiado a testes sempre que possível na camada de regras de negócio (Domain/App Services) via **Red-Green-Refactor**.
- **Framework Ouro:** `DUnitX`
- **Isolamento de Infraestrutura:** Testes de banco ou dependências externas devem ser "mockados" através da criação de Fakes locais implementando as Interfaces. NUNCA execute testes de unidade no banco de dados real.
- **Prevenção de Leaks em Testes:** Toda suite deve gerenciar memória adequadamente nos métodos `[TearDown]` e/ou utilizando contagem de referência em mock interfaces.
