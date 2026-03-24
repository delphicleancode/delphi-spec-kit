---
name: "Delphi Code Review"
description: "Checklist de revisão de código Delphi — qualidade, segurança, performance, SOLID, memória"
---

# Delphi Code Review — Skill

## Checklist Rápido

### Corretude
- [ ] Código faz o que deveria fazer
- [ ] Edge cases tratados (nil, lista vazia, valor zero)
- [ ] Error handling implementado com exceptions específicas
- [ ] Sem bugs óbvios

### Segurança
- [ ] Queries SQL parametrizadas (sem concatenação de strings)
- [ ] Input validado e sanitizado
- [ ] Sem credenciais ou senhas hardcoded
- [ ] Sem SQL injection via `Format` ou concatenação em queries

### Performance
- [ ] Sem queries N+1 (evitar loop com query dentro)
- [ ] Sem loops desnecessários
- [ ] Objetos grandes liberados o mais cedo possível
- [ ] `TObjectList` com `OwnsObjects` configurado corretamente

### Qualidade de Código
- [ ] Nomes auto-descritivos seguindo Pascal Guide
- [ ] DRY — sem código duplicado
- [ ] SOLID — princípios respeitados
- [ ] Métodos ≤ 20 linhas
- [ ] Guard clauses em vez de nesting profundo

### Gerenciamento de Memória
- [ ] `try/finally` com `Free` para objetos temporários
- [ ] Interfaces para reference counting automático
- [ ] `Assigned()` antes de acessar referências que podem ser nil
- [ ] Destructor `Destroy` com `override` liberando campos owned
- [ ] Sem memory leaks em caminhos de exception

### Nomenclatura Pascal
- [ ] PascalCase para todos os identificadores
- [ ] Prefixo `T` em classes, `I` em interfaces, `E` em exceptions
- [ ] Prefixo `F` em campos privados, `A` em parâmetros, `L` em variáveis locais
- [ ] Units: `Projeto.Camada.Dominio.Funcionalidade.pas`
- [ ] Componentes: prefixo de 3 letras (`btn`, `edt`, `lbl`, etc.)

### Testes
- [ ] Testes unitários para código novo
- [ ] Edge cases testados
- [ ] Testes legíveis e manuteníveis

### Documentação
- [ ] XMLDoc para métodos e propriedades públicas
- [ ] Comentários em português quando necessário
- [ ] Não comentar código auto-explicativo

## Anti-Patterns a Sinalizar

```pascal
// ❌ Números mágicos
if ACustomer.Age > 18 then

// ✅ Constantes nomeadas
const MINIMUM_AGE = 18;
if ACustomer.Age > MINIMUM_AGE then

// ❌ with statement
with AQuery do begin
  SQL.Text := '...';
  Open;
end;

// ✅ Referência explícita
AQuery.SQL.Text := '...';
AQuery.Open;

// ❌ Catch genérico
except
  on E: Exception do ShowMessage(E.Message);

// ✅ Exceptions específicas
except
  on E: EFDDBEngineException do
    raise EDatabaseException.Create('Falha: ' + E.Message);

// ❌ Lógica em OnClick
procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  // 50 linhas de lógica de negócio aqui
end;

// ✅ Delegar para Service
procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  FService.SaveCustomer(GetFormData);
end;

// ❌ Memory leak
function GetItems: TStringList;
begin
  Result := TStringList.Create;
  LoadItems(Result); // se LoadItems lançar exception, leak!
end;

// ✅ Seguro
function GetItems: TStringList;
begin
  Result := TStringList.Create;
  try
    LoadItems(Result);
  except
    Result.Free;
    raise;
  end;
end;
```

## Guia de Comentários de Review

```
🔴 BLOQUEANTE: Memory leak — objeto não liberado em caso de exception
🔴 BLOQUEANTE: SQL injection — query usando concatenação de string

🟡 SUGESTÃO: Extrair método — este bloco tem 35 linhas
🟡 SUGESTÃO: Usar interface em vez de classe concreta (DIP)

🟢 NIT: Renomear variável 'S' para nome descritivo
🟢 NIT: Preferir guard clause a nesting

❓ PERGUNTA: O que acontece se ACustomer for nil aqui?
❓ PERGUNTA: Este objeto é liberado por quem?
```

## Checklist SOLID Específico

| Princípio | Verificar |
|-----------|-----------|
| **SRP** | Classe tem UMA responsabilidade? Service não faz acesso a dados? |
| **OCP** | Novas funcionalidades adicionam classes, não modificam existentes? |
| **LSP** | Qualquer implementação da interface funciona no lugar da outra? |
| **ISP** | Interface não tem métodos que implementadores não usam? |
| **DIP** | Constructor recebe interfaces, não classes concretas? |
