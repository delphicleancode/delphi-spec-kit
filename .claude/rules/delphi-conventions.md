---
description: "Convenções Delphi Object Pascal — nomenclatura, estilo, formatação"
globs: ["**/*.pas", "**/*.dpr", "**/*.dpk"]
alwaysApply: true
---

# Convenções Delphi — Claude Rules

## Nomenclatura

- **PascalCase** para todos os identificadores
- Palavras reservadas em **minúsculas** (`begin`, `end`, `if`, `nil`, `string`)
- Prefixos: `T` (classes), `I` (interfaces), `E` (exceptions), `F` (campos privados), `A` (parâmetros), `L` (variáveis locais)
- Units: `Projeto.Camada.Dominio.Funcionalidade.pas`
- Componentes: prefixo de 3 letras (`btn`, `edt`, `lbl`, `cmb`, `pnl`, `qry`, `ds`)

## Formatação

- Indentação: 2 espaços
- Limite: 120 caracteres por linha
- `begin` na mesma linha para blocos `if`/`for`/`while`
- `begin` em nova linha para corpo de métodos

## Seções Obrigatórias da Unit

```pascal
unit Nome;
interface
uses { ... };
type { Enums → Interfaces → Classes }
implementation
uses { imports extras };
{ Implementação agrupada por classe }
end.
```

## Documentação

- XMLDoc para métodos e propriedades públicas
- Comentários em português para projetos brasileiros
- Não comentar código auto-explicativo

## Gerenciamento de Memória

- `try/finally` com `Free` para objetos temporários
- Interfaces para reference counting automático
- Variáveis locais com prefixo `L`
- Owner pattern para componentes visuais

## Proibições

- ❌ `with` statement
- ❌ Variáveis globais
- ❌ Catch genérico (`except on E: Exception`)
- ❌ Números mágicos — use constantes
- ❌ Strings hardcoded — use `resourcestring` ou constantes
- ❌ Métodos > 20 linhas
