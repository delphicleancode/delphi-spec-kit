---
name: Delphi Test-Driven Development (TDD) e DUnitX
description: Diretrizes de como a IA deve agir e codificar quando o usuário pedir TDD, testes unitários, DUnitX ou fakes/mocks usando Interfaces em Delphi.
---

# Test-Driven Development (TDD) em Delphi com DUnitX

Esta skill orienta as expectativas comportamentais para desenvolvimento guiado por testes (TDD) usando o ecossistema moderno Delphi.

Quando operando sob o escopo de TDD, a IA DEVE SEMPRE priorizar o ciclo **Red-Green-Refactor**. Se o usuário solicitar TDD, NÃO escreva a implementação do negócio antes de escrever o teste que irá falhar.

## O Ciclo Red-Green-Refactor (Regras de Interação)

1. **Red (Teste Falho):** Comece declarando o esqueleto da classe/interface alvo na `interface` section apenas para compilar. Então, escreva imediatamente um Test Case DUnitX completo chamando o comportamento inexistente ou asserindo um resultado esperado. O teste falhará logicamente.
2. **Green (Código Mínimo):** Escreva a implementação real mínima e bruta, suficiente para fazer o `Assert` do teste passar.
3. **Refactor (Limpeza):** Aprimore o código (Clean Code, remoção de duplicação, otimizações) garantindo que o teste não quebre.

## DUnitX Best Practices

### Estrutura do Teste
- **Classe de Teste:** O test case deve ser anotado com `[TestFixture]`.
- **Setup e TearDown:** Use `[Setup]` para instanciar as Classes e Fakes. Use `[TearDown]` para limpar instâncias que não usem ARC (Interfaces).
- **Sem Memory Leaks nos Testes:** O `[TearDown]` e a injeção via Interface (ARC) são mandatórios para manter a suite estanque.

### Nomenclatura dos Métodos de Teste
Abrace convenções de contexto como **Action_Condition_ExpectedResult**:
```pascal
[Test]
procedure ComputeDiscount_LoyalCustomer_ReturnsTenPercent;
```

### Asserções Modernas
Substitua validações manuais booleanas (`Assert.IsTrue(A = B)`) por `Assert` fluentes e específicos:
- `Assert.AreEqual(100.0, FInvoice.Total)`
- `Assert.IsNotNull(FCustomer)`
- `Assert.WillRaise(procedure begin FSut.DoInvalid; end, EBusinessRuleException)`
- `Assert.Contains('Error', LMessage)`

### Injeção de Dependências e Mocks (Test Doubles)
Para isolar a classe sob teste (SUT - System Under Test) da infraestrutura (Banco de Dados, APIs, View), aplique **Strict Dependency Inversion (DIP)** injetando `Interfaces` no SUT via construtor.

Como o Delphi não tem built-in Mocking Framework no RTL, escreva Classes "Fake/Mock" locais implementando a Interface para simular a dependência dentro da sessão de `implementation` do teste.

```pascal
// Cria-se o Fake apenas no arquivo de teste
TFakeEmailService = class(TInterfacedObject, IEmailService)
public
  SentCount: Integer;
  procedure Send(const AMsg: string);
end;
```

## AntiPatterns que a IA deve Evitar

1. ❌ Acoplamento direto ao banco de dados (`TFDQuery`) na classe testada. Sempre abstrair o acesso a banco num `IRepository` e criar um `TFakeRepository` para o DUnitX.
2. ❌ Testar UI. Restrinja o escopo do DUnitX à Camada de Domínio e Application Services.
3. ❌ Escrever a classe inteira junto com os testes. O usuário deve ser acompanhado passo-a-passo no TDD. Caso a IA seja obrigada a fornecer tudo, envie os Testes primeiro no output.
4. ❌ Engolir Exceções (`try..except on E: Exception do`) em métodos sendo testados, isso quebra o `Assert.WillRaise()`.
