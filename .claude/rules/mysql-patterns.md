---
description: "MySQL/MariaDB Database defaults — FireDAC connection, AUTO_INCREMENT, LAST_INSERT_ID(), UPSERT, JSON, stored procedures, transactions"
globs: ["**/*.pas", "**/*.sql"]
alwaysApply: false
---

# MySQL / MariaDB Database — Claude Rules

Use these rules when developing with MySQL or MariaDB databases via FireDAC.

## Connection Required

```pascal
{ Configuração base }
FConnection.DriverName := 'MySQL';
FConnection.Params.Values['Server'] := 'localhost';
FConnection.Params.Values['Port'] := '3306';
FConnection.Params.Database := 'meubanco';
FConnection.Params.UserName := 'root';
FConnection.Params.Password := 'senha';
FConnection.Params.Values['CharacterSet'] := 'utf8mb4';  //NEVER 'utf8' (only 3 bytes!)
```

## AUTO_INCREMENT and LAST_INSERT_ID()

```pascal
//⚠️ MySQL DOES NOT support RETURNING!
//Use LAST_INSERT_ID() after INSERT

LQuery.SQL.Text := 'INSERT INTO customers (name) VALUES (:name)';
LQuery.ParamByName('name').AsString := ACustomer.Name;
LQuery.ExecSQL;

//Get generated ID
LQuery.SQL.Text := 'SELECT LAST_INSERT_ID() AS new_id';
LQuery.Open;
ACustomer.Id := LQuery.FieldByName('new_id').AsInteger;

//Alternativa FireDAC:
//ACustomer.Id := FConnection.GetLastAutoGenValue('');
```

## UPSERT — INSERT ... ON DUPLICATE KEY UPDATE

```pascal
LQuery.SQL.Text :=
  'INSERT INTO customers (cpf, name, email) ' +
  'VALUES (:cpf, :name, :email) ' +
  'ON DUPLICATE KEY UPDATE ' +
  '  name = VALUES(name), email = VALUES(email)';
LQuery.ExecSQL;
```

## Native JSON (MySQL 5.7+)

```pascal
{ Gravar JSON }
LQuery.ParamByName('settings').AsString := '{"theme":"dark"}';

{ Ler campo JSON — operador ->> }
LQuery.SQL.Text := 'SELECT settings->>''$.theme'' FROM ... WHERE id = :id';
```

## Stored Procedures and Functions

| Type | Delphi Call |
|------|----------------|
| **Procedure** | `CALL sp_nome(:param)` + `ExecSQL` |
| **Scalar function** | `SELECT fn_nome(:param)` + `Open` |
| **Procedure with result set** | `CALL sp_nome(:param)` + `Open` |

## Transactions

```pascal
FConnection.StartTransaction;
try
  FRepoA.Insert(LObjA);
  FRepoB.Insert(LObjB);
  FConnection.Commit;
except
  FConnection.Rollback;
  raise;
end;
```

| Isolation | FireDAC | Usage |
|-----------|---------|-----|
| Read Uncommitted | `xiDirtyRead` | ⚠️ Almost never |
| Read Committed | `xiReadCommitted` | ✅ Recommended |
| Repeatable Read | `xiRepeatableRead` | InnoDB Standard |
| Serializable | `xiSerializable` | Maximum consistency |

> **Note:** InnoDB's default is `REPEATABLE READ`, different from Firebird/PG (`READ COMMITTED`).

## MySQL Error Handling

```pascal
except
  on E: EFDDBEngineException do
  begin
    case E.Kind of
      ekUKViolated:
        raise EDuplicateException.Create('Registro duplicado');
      ekFKViolated:
        raise EDependencyException.Create('Violação de FK');
      ekRecordLocked:
        raise EConflictException.Create('Deadlock detectado');
      ekServerGone:
        raise EConnectionLostException.Create('Conexão perdida');
    else
      raise;
    end;
  end;
end;
```

## Important Care

| Topic | Rule |
|--------|-------|
| **Charset** | `utf8mb4` ALWAYS (never `utf8` — only 3 bytes in MySQL!) |
| **Engine** | `InnoDB` ALWAYS (never MyISAM in new projects) |
| **RETURNING** | ❌ Does NOT exist in MySQL — use `LAST_INSERT_ID()` |
| **COLLATE** | `utf8mb4_unicode_ci` for correct case-insensitive comparison |
| **Boolean** | `TINYINT(1)` — MySQL convention, map as `AsBoolean` |
| **Timestamps** | `ON UPDATE CURRENT_TIMESTAMP` for auto-update |

## Metadata — Check Existence

```sql
-- Tabela existe?
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'customers';

-- Coluna existe?
SELECT COUNT(*) FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'customers' AND column_name = 'email';
```

## Prohibitions in MySQL

- ❌ Concatenate SQL — use parameterized parameters
- ❌ `utf8` as charset — use `utf8mb4`
- ❌ `RETURNING` (does not exist) — use `LAST_INSERT_ID()`
- ❌ `MyISAM` for new tables — use `InnoDB`
- ❌ `SELECT *` without `LIMIT` — page with `LIMIT/OFFSET`
- ❌ N+1 queries — use JOIN/subquery
- ❌ Ignore indexes on WHERE/JOIN columns
- ❌ `RDB$` for metadata — use `information_schema`
