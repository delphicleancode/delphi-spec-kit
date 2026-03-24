---
description: "Padrões MySQL/MariaDB Database — conexão FireDAC, AUTO_INCREMENT, LAST_INSERT_ID(), UPSERT, JSON, stored procedures, transactions"
globs: ["**/*.pas", "**/*.sql"]
alwaysApply: false
---

# MySQL / MariaDB Database — Cursor Rules

Use estas regras ao desenvolver com banco de dados MySQL ou MariaDB via FireDAC.

## Conexão Obrigatória

```pascal
{ Configuração base }
FConnection.DriverName := 'MySQL';
FConnection.Params.Values['Server'] := 'localhost';
FConnection.Params.Values['Port'] := '3306';
FConnection.Params.Database := 'meubanco';
FConnection.Params.UserName := 'root';
FConnection.Params.Password := 'senha';
FConnection.Params.Values['CharacterSet'] := 'utf8mb4';  // NUNCA 'utf8' (só 3 bytes!)
```

## AUTO_INCREMENT e LAST_INSERT_ID()

```pascal
// ⚠️ MySQL NÃO suporta RETURNING!
// Usar LAST_INSERT_ID() após INSERT

LQuery.SQL.Text := 'INSERT INTO customers (name) VALUES (:name)';
LQuery.ParamByName('name').AsString := ACustomer.Name;
LQuery.ExecSQL;

// Obter ID gerado
LQuery.SQL.Text := 'SELECT LAST_INSERT_ID() AS new_id';
LQuery.Open;
ACustomer.Id := LQuery.FieldByName('new_id').AsInteger;

// Alternativa FireDAC:
// ACustomer.Id := FConnection.GetLastAutoGenValue('');
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

## JSON Nativo (MySQL 5.7+)

```pascal
{ Gravar JSON }
LQuery.ParamByName('settings').AsString := '{"theme":"dark"}';

{ Ler campo JSON — operador ->> }
LQuery.SQL.Text := 'SELECT settings->>''$.theme'' FROM ... WHERE id = :id';
```

## Stored Procedures e Functions

| Tipo | Chamada Delphi |
|------|----------------|
| **Procedure** | `CALL sp_nome(:param)` + `ExecSQL` |
| **Function escalar** | `SELECT fn_nome(:param)` + `Open` |
| **Procedure com result set** | `CALL sp_nome(:param)` + `Open` |

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

| Isolation | FireDAC | Uso |
|-----------|---------|-----|
| Read Uncommitted | `xiDirtyRead` | ⚠️ Quase nunca |
| Read Committed | `xiReadCommitted` | ✅ Recomendado |
| Repeatable Read | `xiRepeatableRead` | Padrão InnoDB |
| Serializable | `xiSerializable` | Máxima consistência |

> **Nota:** O default do InnoDB é `REPEATABLE READ`, diferente de Firebird/PG (`READ COMMITTED`).

## Tratamento de Erros MySQL

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

## Cuidados Importantes

| Tópico | Regra |
|--------|-------|
| **Charset** | `utf8mb4` SEMPRE (nunca `utf8` — só 3 bytes no MySQL!) |
| **Engine** | `InnoDB` SEMPRE (nunca MyISAM em novos projetos) |
| **RETURNING** | ❌ NÃO existe no MySQL — usar `LAST_INSERT_ID()` |
| **COLLATE** | `utf8mb4_unicode_ci` para comparação case-insensitive correta |
| **Boolean** | `TINYINT(1)` — convenção MySQL, mapear como `AsBoolean` |
| **Timestamps** | `ON UPDATE CURRENT_TIMESTAMP` para auto-update |

## Metadata — Verificar Existência

```sql
-- Tabela existe?
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'customers';

-- Coluna existe?
SELECT COUNT(*) FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'customers' AND column_name = 'email';
```

## Proibições em MySQL

- ❌ Concatenar SQL — usar parâmetros parametrizados
- ❌ `utf8` como charset — usar `utf8mb4`
- ❌ `RETURNING` (não existe) — usar `LAST_INSERT_ID()`
- ❌ `MyISAM` para novas tabelas — usar `InnoDB`
- ❌ `SELECT *` sem `LIMIT` — paginar com `LIMIT/OFFSET`
- ❌ N+1 queries — usar JOIN/subquery
- ❌ Ignorar índices em colunas de WHERE/JOIN
- ❌ `RDB$` para metadata — usar `information_schema`
