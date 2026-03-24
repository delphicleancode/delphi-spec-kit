---
name: "Delphi Clean Code"
description: "Padrões pragmáticos de código limpo para Delphi — conciso, direto, sem over-engineering"
---

# Delphi Clean Code — Skill

> **CRITICAL SKILL** — Seja **conciso, direto e focado na solução**.

## Princípios Fundamentais

| Princípio | Regra |
|-----------|-------|
| **SRP** | Uma função/classe faz UMA coisa |
| **DRY** | Não repita código — extraia e reutilize |
| **KISS** | Solução mais simples que funciona |
| **YAGNI** | Não construa o que não foi pedido |
| **Boy Scout** | Deixe o código melhor do que encontrou |

## Regras de Nomenclatura (Pascal Guide)

| Elemento | Convenção |
|----------|-----------|
| **Variáveis** | Revelar intenção: `LCustomerCount` não `N` |
| **Métodos** | Verbo + substantivo: `GetCustomerById` não `Customer` |
| **Booleanos** | Forma de pergunta: `IsActive`, `HasPermission`, `CanEdit` |
| **Constantes** | SCREAMING_SNAKE: `MAX_RETRY_COUNT` |
| **Campos** | Prefixo `F`: `FCustomerName` |
| **Parâmetros** | Prefixo `A`: `ACustomerName` |
| **Var. locais** | Prefixo `L`: `LCustomer` |

> **Regra:** Se precisar de comentário para explicar um nome, renomeie.

## Regras de Métodos

| Regra | Descrição |
|-------|-----------|
| **Curto** | Máximo 20 linhas, ideal 5-10 |
| **Uma Coisa** | Faz uma coisa e faz bem |
| **Um Nível** | Um nível de abstração por método |
| **Poucos Args** | Máximo 3 argumentos, preferir 0-2 |
| **Sem Efeitos Colaterais** | Não mute inputs inesperadamente |

## Estrutura de Código

| Padrão | Aplicação |
|--------|-----------|
| **Guard Clauses** | Early returns para edge cases |
| **Flat > Nested** | Evitar nesting profundo (máx 2 níveis) |
| **Composição** | Métodos pequenos compostos |
| **Colocation** | Código relacionado junto |

### Guard Clauses em Delphi

```pascal
// ❌ RUIM — nesting excessivo
procedure ProcessOrder(AOrder: TOrder);
begin
  if Assigned(AOrder) then
  begin
    if AOrder.Items.Count > 0 then
    begin
      if AOrder.IsValid then
      begin
        // lógica real aqui
      end;
    end;
  end;
end;

// ✅ BOM — guard clauses
procedure ProcessOrder(AOrder: TOrder);
begin
  if not Assigned(AOrder) then
    raise EArgumentNilException.Create('AOrder cannot be nil');
  if AOrder.Items.Count = 0 then
    raise EBusinessRuleException.Create('Order must have items');
  if not AOrder.IsValid then
    raise EValidationException.Create('Order validation failed');

  // lógica real aqui — sem nesting
end;
```

## Anti-Patterns (NÃO FAÇA)

| ❌ Padrão | ✅ Correção |
|-----------|------------|
| Comentar cada linha | Deletar comentários óbvios |
| Método > 20 linhas | Dividir por responsabilidade |
| Números mágicos | Constantes nomeadas |
| `with` statement | Variáveis locais explícitas |
| Variáveis globais | Constructor injection |
| Catch genérico | Exceptions específicas |
| Lógica em `OnClick` | Delegar para Service |
| God class / God unit | Uma classe = uma responsabilidade |
| Ignorar `Free` | `try/finally` sempre |

## Gerenciamento de Memória

```pascal
// ✅ Objetos temporários — sempre try/finally
LList := TStringList.Create;
try
  LList.Add('item');
  // usar LList
finally
  LList.Free;
end;

// ✅ Interfaces — reference counting automático
var LService: IMyService;
LService := TMyService.Create; // liberado automaticamente

// ✅ Owner pattern para componentes visuais
LButton := TButton.Create(Self); // Self libera automaticamente
```

## Estilo de Código AI

| Situação | Ação |
|----------|------|
| Usuário pede feature | Escreva diretamente |
| Usuário reporta bug | Corrija, não explique |
| Requisito não claro | Pergunte, não assuma |

## 🔴 Antes de Editar (PENSE PRIMEIRO!)

| Pergunta | Por quê |
|----------|---------|
| **Quais units usam esta?** | Podem quebrar |
| **O que esta unit importa?** | Interfaces podem mudar |
| **Que testes cobrem isto?** | Testes podem falhar |
| **É componente compartilhado?** | Múltiplos pontos afetados |

> 🔴 **Regra:** Edite o arquivo + todos os dependentes na MESMA tarefa.

## 🔴 Self-Check (OBRIGATÓRIO)

| Check | Pergunta |
|-------|----------|
| ✅ **Objetivo atingido?** | Fiz exatamente o que foi pedido? |
| ✅ **Arquivos editados?** | Modifiquei todos os necessários? |
| ✅ **Código funciona?** | Testei/verifiquei? |
| ✅ **Sem erros?** | Compila sem warnings? |
| ✅ **Nada esquecido?** | Edge cases tratados? |
| ✅ **Memory safe?** | Objetos liberados corretamente? |

> 🔴 **Regra:** Se QUALQUER check falhar, corrija antes de finalizar.
