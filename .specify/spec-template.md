# Specification: [Feature Name]

## Contexto

<!-- Describe the problem or need that this feature solves -->

## Functional Requirements

### User Stories

1. **How** [user type], **want** [action], **for** [benefit].
2. **How** [user type], **want** [action], **for** [benefit].

### Acceptance Criteria (EARS)

<!-- Use EARS notation: WHEN [condition] THE SYSTEM SHALL [behavior] -->

1. **WHEN** [event/condition] **THE SYSTEM SHALL** [expected behavior].
2. **WHEN** [event/condition] **THE SYSTEM SHALL** [expected behavior].
3. **WHEN** [event/condition] **THE SYSTEM SHALL** [expected behavior].

## Non-Functional Requirements

- **Performance:** [ex: response in < 500ms]
- **Compatibility:** [ex: Delphi 11+, Windows 10+]
- **Database:** [ex: SQLite via FireDAC]

## Business Rules

1. [Rule 1]
2. [Rule 2]

## Data Model

### Entities

```pascal
type
  T[NomeDaEntidade] = class
  private
    FId: Integer;
    // ... campos
  public
    property Id: Integer read FId write FId;
    // ... properties
  end;
```

### Tables

```sql
CREATE TABLE [nome_tabela] (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- campos
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## Wireframe/Layout

<!-- Describe or reference the screen layout if applicable -->

- Main form: `Tfrm[Nome]`
- Components: `pgcMain`, `tabSearch`, `tabEdit`

## Out of Scope

- [What will NOT be done in this spec]
