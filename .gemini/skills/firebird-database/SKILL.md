---
name: "Firebird Database"
description: "Padrões de desenvolvimento com banco de dados Firebird via FireDAC — conexão, PSQL, generators, transactions, migrations"
---

# Firebird Database — Skill

Use esta skill ao trabalhar com banco de dados Firebird em projetos Delphi via FireDAC.

## Quando Usar

- Ao configurar conexão FireDAC com Firebird
- Ao criar tabelas, generators, stored procedures, triggers, domains e views
- Ao implementar Repositories com FireDAC + Firebird
- Ao trabalhar com transactions, isolation levels e concorrência
- Ao planejar migrações de schema (scripts versionados)
- Ao otimizar queries e índices para Firebird

## Versões do Firebird

| Versão | Novidades Relevantes |
|--------|----------------------|
| **2.5** | Trace API, `LIST()` aggregate, Windows Trusted Auth |
| **3.0** | `BOOLEAN` nativo, `IDENTITY` columns, Packages, UDR (substitui UDF), Window Functions (`OVER`), Encryption |
| **4.0** | `DECFLOAT`, `INT128`, `TIME/TIMESTAMP WITH TIME ZONE`, Replication, Batch API, `LATERAL` join |
| **5.0** | `WHEN NOT MATCHED BY SOURCE`, Parallel Backup, SQL Security hardening, Profiler |

> **Recomendação:** Use Firebird 3.0+ para novos projetos. Evite features depreciadas como UDFs.

## Conexão FireDAC com Firebird

### Configuração Mínima

```pascal
unit MeuApp.Infra.Database.Connection;

interface

uses
  FireDAC.Comp.Client,
  FireDAC.Phys.FB,        // Driver Firebird
  FireDAC.Phys.FBDef,     // Defaults do Firebird
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.DApt;

type
  /// <summary>
  ///   Factory de conexão Firebird via FireDAC.
  /// </summary>
  TFirebirdConnectionFactory = class
  public
    /// <summary>
    ///   Cria e configura uma conexão Firebird.
    /// </summary>
    /// <param name="ADatabasePath">Caminho completo do arquivo .fdb</param>
    /// <param name="AUserName">Usuário (padrão: SYSDBA)</param>
    /// <param name="APassword">Senha do banco</param>
    /// <returns>Conexão FireDAC configurada e aberta</returns>
    class function CreateConnection(
      const ADatabasePath: string;
      const AUserName: string = 'SYSDBA';
      const APassword: string = 'masterkey'
    ): TFDConnection;

    /// <summary>
    ///   Cria uma conexão via Embedded Server (sem fbserver).
    /// </summary>
    class function CreateEmbeddedConnection(
      const ADatabasePath: string
    ): TFDConnection;
  end;

implementation

uses
  System.SysUtils;

class function TFirebirdConnectionFactory.CreateConnection(
  const ADatabasePath: string;
  const AUserName: string;
  const APassword: string): TFDConnection;
begin
  if ADatabasePath.Trim.IsEmpty then
    raise EArgumentException.Create('ADatabasePath não pode ser vazio');

  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'FB';
    Result.Params.Database := ADatabasePath;
    Result.Params.UserName := AUserName;
    Result.Params.Password := APassword;

    { Configurações recomendadas }
    Result.Params.Values['CharacterSet'] := 'UTF8';
    Result.Params.Values['Protocol'] := 'TCPIP';     // Local: 'Local'
    Result.Params.Values['Server'] := 'localhost';
    Result.Params.Values['Port'] := '3050';
    Result.Params.Values['SQLDialect'] := '3';        // SEMPRE Dialect 3
    Result.Params.Values['PageSize'] := '16384';      // 16KB recomendado

    { Opções do driver FireDAC }
    Result.FormatOptions.StrsTrim2Len := True;         // Trim CHAR para VARCHAR
    Result.FetchOptions.Mode := fmAll;                 // Fetch completo
    Result.ResourceOptions.AutoReconnect := True;      // Reconexão automática
    Result.TxOptions.Isolation := xiReadCommitted;     // Isolation padrão

    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

class function TFirebirdConnectionFactory.CreateEmbeddedConnection(
  const ADatabasePath: string): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'FB';
    Result.Params.Database := ADatabasePath;

    { Embedded: sem servidor, sem user/password obrigatórios no FB3+ }
    Result.Params.Values['Protocol'] := 'Local';
    Result.Params.Values['CharacterSet'] := 'UTF8';
    Result.Params.Values['SQLDialect'] := '3';

    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;
```

### FDPhysFBDriverLink — Configurar Client Library

```pascal
uses
  FireDAC.Phys.FBWrapper,
  FireDAC.Phys.FB;

var
  LDriverLink: TFDPhysFBDriverLink;
begin
  LDriverLink := TFDPhysFBDriverLink.Create(nil);
  try
    { Apontar fbclient.dll customizado (32/64-bit) }
    LDriverLink.VendorLib := 'C:\Firebird\fbclient.dll';

    { Embedded: usar fbclient.dll local ao .exe }
    // LDriverLink.VendorLib := ExtractFilePath(ParamStr(0)) + 'fbclient.dll';
  finally
    { DriverLink geralmente vive por toda a aplicação — criar no DataModule }
  end;
end;
```

### Connection Pooling

```pascal
{ No FDManager ou no Connection Definition }
FDManager.ConnectionDefs.AddConnectionDef;
with FDManager.ConnectionDefs.ConnectionDefByName('FB_POOL') do
begin
  DriverID := 'FB';
  Database := 'C:\Data\MeuBanco.fdb';
  UserName := 'SYSDBA';
  Password := 'masterkey';
  Params.Values['CharacterSet'] := 'UTF8';
  Params.Values['Pooled'] := 'True';
  Params.Values['POOL_MaximumItems'] := '50';
  Params.Values['POOL_CleanupTimeout'] := '30000';
  Params.Values['POOL_ExpireTimeout'] := '90000';
end;
```

## Dialects — SEMPRE Dialect 3

| Feature | Dialect 1 | Dialect 3 |
|---------|-----------|-----------|
| `DATE` | Inclui hora | Apenas data (use `TIMESTAMP` para data+hora) |
| `"Identificadores"` | Erro de sintaxe | Permite nomes case-sensitive com aspas duplas |
| Precisão numérica | `DOUBLE PRECISION` | `NUMERIC(18, x)` até 18 dígitos |
| Recomendação | ❌ Legado | ✅ **Obrigatório para novos projetos** |

> ⚠️ **Regra:** Sempre `SQLDialect := 3`. Dialect 1 é legado do InterBase e causa ambiguidades com `DATE`.

## Tipos de Dados — Mapeamento Firebird ↔ Delphi

| Firebird | Delphi (FireDAC) | Observação |
|----------|------------------|------------|
| `INTEGER` | `ftInteger` / `AsInteger` | 32-bit |
| `BIGINT` | `ftLargeint` / `AsLargeInt` | 64-bit |
| `SMALLINT` | `ftSmallint` / `AsSmallInt` | 16-bit |
| `VARCHAR(N)` | `ftString` / `AsString` | Usar com `CHARACTER SET UTF8` |
| `CHAR(N)` | `ftFixedChar` | Preenche com espaços — preferir `VARCHAR` |
| `NUMERIC(P,S)` | `ftBCD` / `AsCurrency` | Valores monetários |
| `DOUBLE PRECISION`| `ftFloat` / `AsFloat` | Ponto flutuante |
| `DATE` | `ftDate` / `AsDateTime` | Apenas data (Dialect 3) |
| `TIME` | `ftTime` / `AsDateTime` | Apenas hora |
| `TIMESTAMP` | `ftDateTime` / `AsDateTime` | Data + Hora |
| `BOOLEAN` (FB3+) | `ftBoolean` / `AsBoolean` | `TRUE`/`FALSE` nativo |
| `BLOB SUB_TYPE TEXT` | `ftMemo` / `AsString` | Texto grande (CLOB) |
| `BLOB SUB_TYPE 0` | `ftBlob` / `AsBytes` | Dados binários |

## Generators (Sequences)

### Criar Generator

```sql
/* Generator clássico (todas as versões) */
CREATE GENERATOR GEN_CUSTOMER_ID;

/* Sequence (Firebird 3+, mais moderno) */
CREATE SEQUENCE SEQ_CUSTOMER_ID;
```

### Obter Próximo Valor no Delphi

```pascal
/// <summary>
///   Obtém o próximo valor de um generator Firebird.
/// </summary>
function GetNextGeneratorValue(
  AConnection: TFDConnection;
  const AGeneratorName: string): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := AConnection;
    LQuery.SQL.Text := 'SELECT GEN_ID(' + AGeneratorName + ', 1) FROM RDB$DATABASE';
    LQuery.Open;
    Result := LQuery.Fields[0].AsLargeInt;
  finally
    LQuery.Free;
  end;
end;

/// <summary>
///   Alternativa moderna com NEXT VALUE FOR (Firebird 3+).
/// </summary>
function GetNextSequenceValue(
  AConnection: TFDConnection;
  const ASequenceName: string): Int64;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := AConnection;
    LQuery.SQL.Text := 'SELECT NEXT VALUE FOR ' + ASequenceName + ' FROM RDB$DATABASE';
    LQuery.Open;
    Result := LQuery.Fields[0].AsLargeInt;
  finally
    LQuery.Free;
  end;
end;
```

### IDENTITY Columns (Firebird 3+)

```sql
/* Auto-increment nativo — dispensa generator manual */
CREATE TABLE customers (
  id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

/* Para pegar o ID gerado após INSERT: */
INSERT INTO customers (name) VALUES ('João') RETURNING id;
```

### RETURNING no Delphi (pegar ID após Insert)

```pascal
procedure TFirebirdCustomerRepository.Insert(ACustomer: TCustomer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'INSERT INTO customers (name, cpf, email) ' +
      'VALUES (:name, :cpf, :email) RETURNING id';
    LQuery.ParamByName('name').AsString := ACustomer.Name;
    LQuery.ParamByName('cpf').AsString := ACustomer.Cpf;
    LQuery.ParamByName('email').AsString := ACustomer.Email;
    LQuery.Open; { Open, não ExecSQL — pois RETURNING retorna dados }
    ACustomer.Id := LQuery.Fields[0].AsInteger;
  finally
    LQuery.Free;
  end;
end;
```

## Stored Procedures em Firebird

### Selectable (retorna resultset — usa SUSPEND)

```sql
CREATE OR ALTER PROCEDURE SP_CUSTOMERS_BY_STATUS (
  P_STATUS SMALLINT
)
RETURNS (
  O_ID       INTEGER,
  O_NAME     VARCHAR(100),
  O_CPF      VARCHAR(14),
  O_STATUS   SMALLINT
)
AS
BEGIN
  FOR SELECT id, name, cpf, status
      FROM customers
      WHERE status = :P_STATUS
      INTO :O_ID, :O_NAME, :O_CPF, :O_STATUS
  DO
    SUSPEND;  /* Retorna cada linha (como um cursor) */
END
```

**Chamar no Delphi (tratada como SELECT):**

```pascal
LQuery.SQL.Text := 'SELECT * FROM SP_CUSTOMERS_BY_STATUS(:P_STATUS)';
LQuery.ParamByName('P_STATUS').AsSmallInt := Ord(csActive);
LQuery.Open;
```

### Executable (executa ação — não usa SUSPEND)

```sql
CREATE OR ALTER PROCEDURE SP_DEACTIVATE_CUSTOMER (
  P_CUSTOMER_ID INTEGER
)
AS
BEGIN
  UPDATE customers SET status = 1 WHERE id = :P_CUSTOMER_ID;
END
```

**Chamar no Delphi:**

```pascal
LQuery.SQL.Text := 'EXECUTE PROCEDURE SP_DEACTIVATE_CUSTOMER(:P_CUSTOMER_ID)';
LQuery.ParamByName('P_CUSTOMER_ID').AsInteger := ACustomerId;
LQuery.ExecSQL;
```

## Execute Block (SQL anônimo com PSQL)

```sql
/* Útil para lotes e scripts sem criar procedure permanente */
EXECUTE BLOCK (P_LIMIT INTEGER = :P_LIMIT)
RETURNS (O_NAME VARCHAR(100), O_TOTAL INTEGER)
AS
BEGIN
  FOR SELECT name, COUNT(*) FROM orders
      GROUP BY name
      HAVING COUNT(*) > :P_LIMIT
      INTO :O_NAME, :O_TOTAL
  DO
    SUSPEND;
END
```

## Domains (Tipos Reutilizáveis)

```sql
/* Domínios centralizam validações e tipos no schema */
CREATE DOMAIN DM_ID        AS INTEGER NOT NULL;
CREATE DOMAIN DM_NAME      AS VARCHAR(100) NOT NULL;
CREATE DOMAIN DM_CPF       AS VARCHAR(14);
CREATE DOMAIN DM_EMAIL     AS VARCHAR(150);
CREATE DOMAIN DM_MONEY     AS NUMERIC(15, 2) DEFAULT 0;
CREATE DOMAIN DM_STATUS    AS SMALLINT DEFAULT 0 CHECK (VALUE IN (0, 1, 2));
CREATE DOMAIN DM_BOOLEAN   AS SMALLINT DEFAULT 0 CHECK (VALUE IN (0, 1)); /* Firebird 2.5 */
/* Firebird 3+: usar BOOLEAN nativo em vez de DM_BOOLEAN */

CREATE TABLE customers (
  id     DM_ID,
  name   DM_NAME,
  cpf    DM_CPF,
  email  DM_EMAIL,
  status DM_STATUS,
  PRIMARY KEY (id)
);
```

## Triggers

```sql
/* Trigger para auto-increment com Generator */
CREATE OR ALTER TRIGGER TRG_CUSTOMER_BI FOR customers
  ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL OR NEW.id = 0) THEN
    NEW.id = GEN_ID(GEN_CUSTOMER_ID, 1);
END

/* Trigger de auditoria */
CREATE OR ALTER TRIGGER TRG_CUSTOMER_AU FOR customers
  ACTIVE AFTER UPDATE POSITION 0
AS
BEGIN
  INSERT INTO audit_log (table_name, record_id, action, changed_at)
    VALUES ('customers', NEW.id, 'UPDATE', CURRENT_TIMESTAMP);
END
```

## Transactions e Isolation Levels

### Níveis de Isolamento no Firebird

| Nível | FireDAC | Uso |
|-------|---------|-----|
| **Read Committed** | `xiReadCommitted` | ✅ Padrão — lê dados commitados, sem dirty reads |
| **Snapshot** (Concurrency) | `xiSnapshot` | Relatórios — visão consistente do momento do START |
| **Snapshot Table Stability** | `xiSerializable` | Raro — lock exclusivo na tabela |

### Controle Manual de Transação

```pascal
/// <summary>
///   Executa operação dentro de transação explícita.
/// </summary>
procedure ExecuteInTransaction(AConnection: TFDConnection; AProc: TProc);
begin
  AConnection.StartTransaction;
  try
    AProc;
    AConnection.Commit;
  except
    AConnection.Rollback;
    raise;
  end;
end;

{ Uso }
ExecuteInTransaction(FConnection,
  procedure
  begin
    FCustomerRepo.Insert(LCustomer);
    FOrderRepo.Insert(LOrder);
    FStockRepo.DecreaseStock(LOrder.Items);
  end
);
```

### Transação com Isolation Level Específico

```pascal
var
  LTransaction: TFDTransaction;
begin
  LTransaction := TFDTransaction.Create(nil);
  try
    LTransaction.Connection := FConnection;
    LTransaction.Options.Isolation := xiSnapshot; { Leitura consistente }
    LTransaction.Options.ReadOnly := True;
    LTransaction.StartTransaction;
    try
      { Queries de relatório aqui — snapshot imutável }
      LTransaction.Commit;
    except
      LTransaction.Rollback;
      raise;
    end;
  finally
    LTransaction.Free;
  end;
end;
```

## Event Alerter (Eventos do Banco)

```sql
/* No Firebird: */
CREATE OR ALTER TRIGGER TRG_ORDER_NOTIFY FOR orders
  ACTIVE AFTER INSERT POSITION 0
AS
BEGIN
  POST_EVENT 'NEW_ORDER';
END
```

```pascal
{ No Delphi: escutar eventos do banco }
uses
  FireDAC.Phys.FB; // TFDPhysFBEventAlerter

var
  LAlerter: TFDEventAlerter;
begin
  LAlerter := TFDEventAlerter.Create(nil);
  try
    LAlerter.Connection := FConnection;
    LAlerter.Names.Text := 'NEW_ORDER';
    LAlerter.Options.Timeout := 0;  { Sem timeout — espera indefinidamente }
    LAlerter.OnAlert := HandleNewOrderEvent;
    LAlerter.Active := True;
  finally
    { Manter vivo enquanto a aplicação rodar — liberação no Destroy }
  end;
end;

procedure TMyService.HandleNewOrderEvent(ASender: TFDCustomEventAlerter;
  const AEventName: string; const AArgument: Variant);
begin
  if AEventName = 'NEW_ORDER' then
    RefreshOrderList;
end;
```

## Criação de Schema — Script de Migração

```sql
/* migration_001_initial_schema.sql */

/* ===== Domains ===== */
CREATE DOMAIN DM_ID       AS INTEGER NOT NULL;
CREATE DOMAIN DM_NAME     AS VARCHAR(100) NOT NULL;
CREATE DOMAIN DM_CPF      AS VARCHAR(14);
CREATE DOMAIN DM_EMAIL    AS VARCHAR(150);
CREATE DOMAIN DM_MONEY    AS NUMERIC(15,2) DEFAULT 0 NOT NULL;
CREATE DOMAIN DM_STATUS   AS SMALLINT DEFAULT 0 CHECK (VALUE BETWEEN 0 AND 2);
CREATE DOMAIN DM_MEMO     AS BLOB SUB_TYPE TEXT SEGMENT SIZE 4096;

/* ===== Generators ===== */
CREATE GENERATOR GEN_CUSTOMER_ID;
CREATE GENERATOR GEN_PRODUCT_ID;
CREATE GENERATOR GEN_ORDER_ID;
CREATE GENERATOR GEN_ORDER_ITEM_ID;

/* ===== Tables ===== */
CREATE TABLE customers (
  id       DM_ID,
  name     DM_NAME,
  cpf      DM_CPF,
  email    DM_EMAIL,
  status   DM_STATUS,
  notes    DM_MEMO,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT PK_CUSTOMER PRIMARY KEY (id),
  CONSTRAINT UQ_CUSTOMER_CPF UNIQUE (cpf)
);

CREATE TABLE products (
  id         DM_ID,
  name       DM_NAME,
  price      DM_MONEY,
  stock_qty  INTEGER DEFAULT 0 NOT NULL,
  status     DM_STATUS,
  CONSTRAINT PK_PRODUCT PRIMARY KEY (id)
);

CREATE TABLE orders (
  id            DM_ID,
  customer_id   INTEGER NOT NULL,
  order_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  total_amount  DM_MONEY,
  status        DM_STATUS,
  CONSTRAINT PK_ORDER PRIMARY KEY (id),
  CONSTRAINT FK_ORDER_CUSTOMER FOREIGN KEY (customer_id)
    REFERENCES customers (id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE order_items (
  id          DM_ID,
  order_id    INTEGER NOT NULL,
  product_id  INTEGER NOT NULL,
  quantity    INTEGER NOT NULL CHECK (quantity > 0),
  unit_price  DM_MONEY,
  total_price DM_MONEY,
  CONSTRAINT PK_ORDER_ITEM PRIMARY KEY (id),
  CONSTRAINT FK_ITEM_ORDER FOREIGN KEY (order_id)
    REFERENCES orders (id) ON DELETE CASCADE,
  CONSTRAINT FK_ITEM_PRODUCT FOREIGN KEY (product_id)
    REFERENCES products (id) ON DELETE RESTRICT
);

/* ===== Indices ===== */
CREATE INDEX IDX_CUSTOMER_NAME    ON customers (name);
CREATE INDEX IDX_ORDER_DATE       ON orders (order_date);
CREATE INDEX IDX_ORDER_CUSTOMER   ON orders (customer_id);
CREATE INDEX IDX_ITEM_ORDER       ON order_items (order_id);

/* ===== Triggers (Auto-Increment) ===== */
SET TERM ^;

CREATE TRIGGER TRG_CUSTOMER_BI FOR customers
  ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL OR NEW.id = 0) THEN
    NEW.id = GEN_ID(GEN_CUSTOMER_ID, 1);
END^

CREATE TRIGGER TRG_PRODUCT_BI FOR products
  ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL OR NEW.id = 0) THEN
    NEW.id = GEN_ID(GEN_PRODUCT_ID, 1);
END^

CREATE TRIGGER TRG_ORDER_BI FOR orders
  ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL OR NEW.id = 0) THEN
    NEW.id = GEN_ID(GEN_ORDER_ID, 1);
END^

CREATE TRIGGER TRG_ORDER_ITEM_BI FOR order_items
  ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW.id IS NULL OR NEW.id = 0) THEN
    NEW.id = GEN_ID(GEN_ORDER_ITEM_ID, 1);
END^

SET TERM ;^
```

## Migração de Schema no Delphi

```pascal
/// <summary>
///   Controle de versão de schema via tabela de migrações.
/// </summary>
procedure EnsureMigrationTable(AConnection: TFDConnection);
begin
  AConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS (SELECT 1 FROM RDB$RELATIONS ' +
    'WHERE RDB$RELATION_NAME = ''SCHEMA_MIGRATIONS'') ' +
    '/* Alternativa segura: */'
  );
  { No Firebird, CREATE TABLE IF NOT EXISTS não existe nativamente.
    Verificar via metadata: }
  if not TableExists(AConnection, 'SCHEMA_MIGRATIONS') then
    AConnection.ExecSQL(
      'CREATE TABLE SCHEMA_MIGRATIONS (' +
      '  version INTEGER NOT NULL PRIMARY KEY,' +
      '  description VARCHAR(200),' +
      '  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP' +
      ')'
    );
end;

function TableExists(AConnection: TFDConnection; const ATableName: string): Boolean;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := AConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) FROM RDB$RELATIONS ' +
      'WHERE RDB$RELATION_NAME = :name AND RDB$SYSTEM_FLAG = 0';
    LQuery.ParamByName('name').AsString := ATableName.ToUpper;
    LQuery.Open;
    Result := LQuery.Fields[0].AsInteger > 0;
  finally
    LQuery.Free;
  end;
end;
```

## Backup e Restore via GBak (Command Line)

```bash
# Backup
gbak -b -v -user SYSDBA -password masterkey localhost:C:\Data\MeuBanco.fdb C:\Backup\MeuBanco.fbk

# Restore
gbak -c -v -page_size 16384 -user SYSDBA -password masterkey C:\Backup\MeuBanco.fbk localhost:C:\Data\MeuBanco_Restored.fdb

# Backup via Services API (sem caminho local)
gbak -b -se localhost:service_mgr C:\Data\MeuBanco.fdb C:\Backup\MeuBanco.fbk -user SYSDBA -password masterkey
```

## Anti-Patterns Firebird a Evitar

```pascal
// ❌ Dialect 1 — ambiguidade com DATE
Result.Params.Values['SQLDialect'] := '1';

// ✅ Dialect 3 — SEMPRE
Result.Params.Values['SQLDialect'] := '3';

// ❌ Concatenar SQL — SQL Injection
LQuery.SQL.Text := 'SELECT * FROM customers WHERE name = ''' + AName + '''';

// ✅ Parâmetros parametrizados
LQuery.SQL.Text := 'SELECT * FROM customers WHERE name = :name';
LQuery.ParamByName('name').AsString := AName;

// ❌ Ignorar CharacterSet — problemas com acentos
Result.DriverName := 'FB';
Result.Params.Database := APath;
Result.Connected := True;  // Sem CharacterSet!

// ✅ Sempre definir CharacterSet
Result.Params.Values['CharacterSet'] := 'UTF8';

// ❌ ExecSQL com RETURNING — não retorna nada!
LQuery.SQL.Text := 'INSERT INTO ... RETURNING id';
LQuery.ExecSQL;  // id PERDIDO!

// ✅ Open com RETURNING — retorna o resultset
LQuery.SQL.Text := 'INSERT INTO ... RETURNING id';
LQuery.Open;  // id disponível em Fields[0]
ACustomer.Id := LQuery.Fields[0].AsInteger;

// ❌ Criar banco sem Page Size adequado
CREATE DATABASE '...' PAGE_SIZE 4096;  // Muito pequeno para tabelas grandes

// ✅ Page Size otimizado
CREATE DATABASE '...' PAGE_SIZE 16384 DEFAULT CHARACTER SET UTF8;

// ❌ Não tratar deadlocks
LQuery.ExecSQL;  // pode dar deadlock em concorrência

// ✅ Tratar deadlocks com retry
try
  LQuery.ExecSQL;
except
  on E: EFDDBEngineException do
  begin
    if E.Kind = ekRecordLocked then
      raise EConflictException.Create('Registro bloqueado por outra transação')
    else
      raise;
  end;
end;
```

## Packages (Firebird 3+)

```sql
/* Packages agrupam procedures e functions relacionadas */

/* Header (interface) */
CREATE OR ALTER PACKAGE PKG_CUSTOMER
AS
BEGIN
  PROCEDURE DEACTIVATE(P_ID INTEGER);
  FUNCTION GET_FULL_NAME(P_ID INTEGER) RETURNS VARCHAR(200);
END

/* Body (implementation) */
CREATE OR ALTER PACKAGE BODY PKG_CUSTOMER
AS
BEGIN
  PROCEDURE DEACTIVATE(P_ID INTEGER)
  AS
  BEGIN
    UPDATE customers SET status = 1 WHERE id = :P_ID;
  END

  FUNCTION GET_FULL_NAME(P_ID INTEGER) RETURNS VARCHAR(200)
  AS
    DECLARE VARIABLE V_NAME VARCHAR(200);
  BEGIN
    SELECT name FROM customers WHERE id = :P_ID INTO :V_NAME;
    RETURN V_NAME;
  END
END
```

**Chamar no Delphi:**

```pascal
LQuery.SQL.Text := 'EXECUTE PROCEDURE PKG_CUSTOMER.DEACTIVATE(:ID)';
LQuery.ParamByName('ID').AsInteger := ACustomerId;
LQuery.ExecSQL;

{ Function }
LQuery.SQL.Text := 'SELECT PKG_CUSTOMER.GET_FULL_NAME(:ID) FROM RDB$DATABASE';
LQuery.ParamByName('ID').AsInteger := ACustomerId;
LQuery.Open;
LFullName := LQuery.Fields[0].AsString;
```

## Teste de Integração com Firebird Embedded

```pascal
[TestFixture]
TCustomerRepositoryFirebirdTest = class
private
  FConnection: TFDConnection;
  FDriverLink: TFDPhysFBDriverLink;
  FRepository: ICustomerRepository;
  FTestDbPath: string;
public
  [Setup]
  procedure Setup;

  [TearDown]
  procedure TearDown;

  [Test]
  procedure Insert_ValidCustomer_ShouldReturnGeneratedId;
end;

procedure TCustomerRepositoryFirebirdTest.Setup;
begin
  FTestDbPath := TPath.Combine(TPath.GetTempPath, 'test_' + TGUID.NewGuid.ToString + '.fdb');

  { Configurar driver embedded }
  FDriverLink := TFDPhysFBDriverLink.Create(nil);
  FDriverLink.VendorLib := 'fbclient.dll'; { Embedded no path da aplicação }

  { Criar banco de teste }
  FConnection := TFDConnection.Create(nil);
  FConnection.DriverName := 'FB';
  FConnection.Params.Database := FTestDbPath;
  FConnection.Params.UserName := 'SYSDBA';
  FConnection.Params.Password := 'masterkey';
  FConnection.Params.Values['Protocol'] := 'Local';
  FConnection.Params.Values['CharacterSet'] := 'UTF8';
  FConnection.Params.Values['CreateDatabase'] := 'Yes';  { Cria o .fdb automaticamente }
  FConnection.Connected := True;

  { Criar schema de teste }
  FConnection.ExecSQL('CREATE TABLE customers (id INTEGER PRIMARY KEY, name VARCHAR(100))');
  FConnection.ExecSQL('CREATE GENERATOR GEN_CUSTOMER_ID');

  FRepository := TFirebirdCustomerRepository.Create(FConnection);
end;

procedure TCustomerRepositoryFirebirdTest.TearDown;
begin
  FConnection.Connected := False;
  FConnection.Free;
  FDriverLink.Free;

  { Limpar banco temporário }
  if TFile.Exists(FTestDbPath) then
    TFile.Delete(FTestDbPath);
end;
```

## Checklist Firebird

- [ ] Dialect 3 configurado (`SQLDialect := '3'`)?
- [ ] CharacterSet UTF8 definido?
- [ ] Page Size ≥ 8192 (ideal: 16384)?
- [ ] Queries parametrizadas (sem concatenação de strings)?
- [ ] Generators/Sequences para auto-increment com trigger BI?
- [ ] `RETURNING` com `Open` (não `ExecSQL`)?
- [ ] Transactions explícitas para operações compostas?
- [ ] Deadlocks tratados com `EFDDBEngineException.Kind = ekRecordLocked`?
- [ ] FBClient.dll correto (32/64-bit) configurado no VendorLib?
- [ ] Indices criados para colunas usadas em WHERE e JOIN?
- [ ] Foreign Keys com `ON DELETE`/`ON UPDATE` apropriados?
- [ ] Backup regular via `gbak`?
- [ ] Scripts de migração versionados?
