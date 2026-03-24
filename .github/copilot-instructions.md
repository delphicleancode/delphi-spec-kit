# GitHub Copilot — Instruções para Projetos Delphi

## Contexto

Este é um projeto **Delphi (Object Pascal)** que segue princípios SOLID, clean code e o Object Pascal Style Guide. Consulte `AGENTS.md` na raiz do projeto para a referência completa de convenções.

## Diretrizes Gerais

1. **Sempre gere código em Object Pascal** (Delphi) salvo quando explicitamente solicitado em outra linguagem.
2. **Use PascalCase** para todos os identificadores. Palavras reservadas em minúsculas.
3. **Respeite os prefixos** da convenção Pascal: `T` (classes), `I` (interfaces), `E` (exceptions), `F` (campos privados), `A` (parâmetros), `L` (variáveis locais).
4. **Prefira interfaces** a classes concretas para dependências.
5. **Use constructor injection** para injeção de dependência.
6. **Nunca coloque lógica de negócio em event handlers** de forms (`OnClick`, `OnChange`, etc.). Delegue para services.

## Estilo de Código

### Indentação e Formatação
- Indentação: **2 espaços** (sem tabs)
- `begin` na **mesma linha** de `if`, `for`, `while`, `with` quando em bloco único
- `begin` em **nova linha** para implementações de métodos
- Limite de **120 caracteres** por linha

### Seções de Unit
Ordenar seções da unit conforme:
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

### Declaração de Variáveis
```pascal
// Preferir inline var quando disponível (Delphi 10.3+)
var LCustomer := TCustomer.Create('João');

// Ou declaração explícita com prefixo L
var
  LCustomer: TCustomer;
  LCount: Integer;
```

## Error Handling

- Use **exceptions específicas** (criar classes de exception por domínio):
  ```pascal
  EBusinessRuleException = class(Exception);
  EEntityNotFoundException = class(Exception);
  EValidationException = class(Exception);
  ```
- **Guard clauses** no início do método em vez de nesting profundo
- **Try/finally** para gerenciamento de memória
- **Try/except** apenas para tratamento real de erros, nunca para fluxo de controle

## Documentação

- Gerar **XMLDoc** para métodos e propriedades públicas
- Comentários em **português** para projetos brasileiros
- Não comentar código auto-explicativo

## Padrões de Projeto

Ao criar novas funcionalidades, seguir a arquitetura em camadas:
- **Domain:** Entidades, Value Objects, Interfaces
- **Application:** Services, Use Cases, DTOs
- **Infrastructure:** Repositories (FireDAC), APIs externas
- **Presentation:** Forms VCL/FMX

## O que NÃO gerar

- ❌ Não use `with` statement
- ❌ Não crie variáveis globais
- ❌ Não use `AnsiString` quando `string` (UnicodeString) for apropriado
- ❌ Não use números mágicos — declare constantes
- ❌ Não faça catch genérico (`except on E: Exception do ShowMessage`)
- ❌ Não misture lógica de UI com lógica de negócio
- ❌ Não crie métodos com mais de 20 linhas
- ❌ Não ignore o `Free` de objetos temporários (use try/finally)

## Frameworks REST

### Horse
- Controller: classe com `class procedure RegisterRoutes`
- Handler: `class procedure Nome(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc)`
- Middleware: `THorse.Use(Jhonson)`, `THorse.Use(CORS)`, `THorse.Use(HandleException)`
- Rotas: kebab-case, plural — `/api/customers`, `/api/order-items`
- Sempre delegar para Services — nunca acessar dados no controller

### DelphiMVCFramework
- Controller: herda `TMVCController` com `[MVCPath('/api/resource')]`
- Rotas: attributes `[MVCPath]`, `[MVCHTTPMethod([httpGET])]`
- Active Record: herda `TMVCActiveRecord` com `[MVCTable]`, `[MVCTableField]`
- Serialização via `Render()` — não usar `Response.Content` direto
- JWT: `TMVCJWTAuthenticationMiddleware`

### Dext Framework
- Minimal API: `App.Builder.MapGet`, `MapPost` usando funcoes anônimas (handlers)
- Roteamento nativo com Auto Model Binding populando DTOs
- Dependency Injection: `App.Services.AddSingleton`, `AddScoped`
- Entity ORM: `DbContext.Where(U.Age > 18)` (expressões Smart Properties em vez de strings SQL)
- Async: use `TAsyncTask` para assincronismo e promessas

### DevExpress Components 
- Prefixos de componentes DevExpress: `grd` (TcxGrid), `tvw` (TcxGridDBTableView), `lyt` (TdxLayoutControl), `skn` (TdxSkinController)
- Preferir `TdxLayoutControl` a posicionamento manual
- Configurar grid via código quando colunas são dinâmicas
- Exportação: usar `cxGridExportLink` para Excel/PDF

### Projeto ACBr (Automação Comercial)
- **Regra de Ouro:** Não acoplar componentes (`TACBrNFe`, `TACBrCTe`, etc.) diretamente nos forms de UI. 
- Isolar a lógica fiscal em classes Service (ex: `TNFeService`) ou Repositories.
- Configurar certificados e bibliotecas criptográficas (WinCrypt/OpenSSL) via código, com dados obtidos dinamicamente de classes de abstração.
- Sempre garanta liberação de memória caso construa os componentes ACBr dinamicamente num Service (`try...finally Free;`).
- Prefixos comuns na UI ou DataModules base: `acbrNFe`, `acbrECF`, `acbrTef`, `acbrBoleto`.

### Banco de Dados Firebird
- **Regra de Ouro:** Dialect 3 SEMPRE (`SQLDialect := '3'`), CharacterSet UTF8, PageSize 16384.
- **RETURNING:** `INSERT INTO ... RETURNING id` exige `LQuery.Open`, NUNCA `ExecSQL` (que descarta o resultado).
- **Generators:** Usar `GEN_ID(generator, 1)` em triggers `BEFORE INSERT` ou `IDENTITY` (Firebird 3+).
- **Stored Procedures:** Selectable (com `SUSPEND`) → `SELECT * FROM SP_NOME(...)`. Executable → `EXECUTE PROCEDURE SP_NOME(...)`.
- **Transactions:** Usar explicitamente `StartTransaction/Commit/Rollback` para operações compostas. Isolation padrão: `xiReadCommitted`.
- **Error Handling:** Tratar `EFDDBEngineException.Kind` → `ekRecordLocked` (deadlock), `ekUKViolated` (duplicado), `ekFKViolated` (FK).
- **Domains:** Usar Domains (`DM_ID`, `DM_NAME`, `DM_MONEY`) para centralizar tipos e validações no schema.
- **Anti-patterns:** ❌ Concatenar SQL, ❌ `ExecSQL` com `RETURNING`, ❌ Ignorar `CharacterSet`, ❌ `CREATE TABLE IF NOT EXISTS` (usar `RDB$RELATIONS`).

### Banco de Dados PostgreSQL
- **Driver:** `DriverName := 'PG'`, `CharacterSet := 'UTF8'`, porta padrão 5432.
- **IDENTITY:** Usar `GENERATED ALWAYS AS IDENTITY` em vez de `SERIAL` para novos projetos (PG 10+).
- **RETURNING:** Mesma regra do Firebird — `INSERT ... RETURNING id` exige `LQuery.Open`, não `ExecSQL`.
- **UPSERT:** `INSERT ... ON CONFLICT (col) DO UPDATE SET ...` — nativo no PostgreSQL.
- **JSONB:** Usar para dados semi-estruturados. Cast no SQL com `::jsonb`. Indexável com GIN.
- **ENUM Types:** `CREATE TYPE status AS ENUM (...)` mapeado para enum Pascal via constantes de string.
- **Functions:** Retornam valor ou tabela — `SELECT * FROM fn_nome(...)`. Procedures (PG 11+): `CALL sp_nome(...)`.
- **Metadata:** Usar `information_schema.tables` / `information_schema.columns` (não `RDB$`).
- **Anti-patterns:** ❌ `SERIAL` (usar `IDENTITY`), ❌ `SELECT *` em tabelas grandes, ❌ N+1 queries, ❌ JSON como TEXT (usar `JSONB`).

### Banco de Dados MySQL / MariaDB
- **Driver:** `DriverName := 'MySQL'`, porta padrão 3306. Client library: `libmysql.dll` (ou `libmariadb.dll`).
- **Charset:** `utf8mb4` SEMPRE. O `utf8` do MySQL só tem 3 bytes (não suporta emoji). Collation: `utf8mb4_unicode_ci`.
- **AUTO_INCREMENT:** MySQL NÃO suporta `RETURNING`. Obter ID via `LAST_INSERT_ID()` ou `FConnection.GetLastAutoGenValue('')`.
- **UPSERT:** `INSERT ... ON DUPLICATE KEY UPDATE name = VALUES(name)` — nativo no MySQL.
- **JSON:** Tipo `JSON` nativo (MySQL 5.7+). Operadores `->>`/`JSON_EXTRACT`. Índice via Generated Column.
- **Engine:** `InnoDB` SEMPRE (nunca MyISAM). Precisa de FK e transactions.
- **Procedures:** `CALL sp_nome(...)`. Functions: `SELECT fn_nome(...)`. `SIGNAL SQLSTATE` para erros.
- **Anti-patterns:** ❌ `utf8` (usar `utf8mb4`), ❌ `RETURNING` (usar `LAST_INSERT_ID()`), ❌ MyISAM, ❌ N+1 queries.

### Intraweb Framework
- **Stateful Web:** Jamais utilize variáveis globais (variáveis declaradas na interface da unit) para dados interativos (elas vazam cross-session). Guarde estado em `UserSession`.
- Evite código de UI bloqueante da VCL Clássica (`ShowMessage()`, `InputBox()`, chamadas Modais). 
- Dê total preferência a renderizações assíncronas usando interrupções Ajax, codificando os eventos no tipo `OnAsyncClick` em vez dos posts inteiros padrão.
- Prefixos padronizados de componentes: utilize sempre `iw` base (`iwBtnSave`, `iwEdtUser`).

---

## 🧵 Threads e Multi-Threading

- **Regra de Ouro:** NUNCA acessar componentes visuais (VCL/FMX) diretamente de thread secundária. Usar `TThread.Synchronize` (bloqueante) ou `TThread.Queue` (não-bloqueante).
- **Tarefas simples:** `TThread.CreateAnonymousThread` ou `TTask.Run` (PPL — forma moderna, pool gerenciado).
- **Loops paralelos:** `TParallel.For` para processar coleções independentes. Proteger variáveis compartilhadas com `TInterlocked` ou `TCriticalSection`.
- **Resultado assíncrono:** `TFuture<T>` — `.Value` bloqueia até o resultado estar pronto.
- **Thread-Safety:** `TCriticalSection` (Enter/Leave no `finally`), `TMonitor`, `TInterlocked` (operações atômicas), `TThreadList<T>`, `TMultiReadExclusiveWriteSynchronizer` (cache).
- **Producer-Consumer:** `TThreadedQueue<T>` com `PushItem`/`PopItem`.
- **Cancelamento:** Verificar `Terminated` em loops de `TThread`, ou usar token de cancelamento customizado.
- **Debugging:** `TThread.NameThreadForDebugging('NomeDaThread')` para facilitar identificação no IDE.
- **Anti-patterns:** ❌ `Sleep()` na main thread, ❌ `FreeOnTerminate + WaitFor`, ❌ Variáveis compartilhadas sem lock, ❌ Exceções não tratadas em threads (são silenciosas).

---

## 🛑 Gerenciamento de Memória e Controle de Exceções

- **Nunca sugira código propenso a Memory Leaks:** Em Delphi, todo `TObject` criado sem `Owner` ou fora de `Interfaces` (ARC) precisa **obrigatoriamente** estar protegido por `try..finally` e `Free` e a palavra chave `try` deve vir IMEDIATAMENTE APÓS a sua criação. Nenhuma exceção entre o Create e o Try.
- **Não crie instâncias em parâmetros diretamente:** Se as chamadas `Foo(TObjeto.Create)` não pertencerem a uma liberação nativa gerenciada pelo recebedor assinado, você deve instanciar antes, proteger com try e enviar a var.
- **Tratamento de Exceções Baseado em Domínio:** Use e crie Classes de `Exception` personalizadas para suas lógicas.
- **Transparência de Exceções:** Ao usar o bloco `except`, seja estritamente focado em exceptions específicas (`on E: EFDDBEngineException do`). Caso utilize o `Exception` genérico de raiz, NUNCA deixe de usar o `raise;` puro no final do exception block para não ocultar de Stack Traces globais os erros técnicos.

