---
description: Test-Driven Development (TDD) rigoroso com DUnitX, nomenclaturas e injeção de dependências para isolamento com fakes e mocks.
globs: *Test*.pas, *.pas
---

# Delphi TDD e Testes de Unidade (DUnitX)

- **Test-First (Red-Green-Refactor):** Ao implementar novas regras sob ordem de "TDD", você DEVE estruturar primeiro o Test Case e suas asserções (`Assert`) falhas, antes de conceber os algoritmos concretos da lógica de negócio.
- **Nomenclatura Padrão Expressiva:** Prefixos de métodos de teste devem seguir o escopo semântico `Metodo_Cenario_Expectativa`. Exemplo: `[Test] procedure CalculateTax_EmptyOrder_ThrowsException;`.
- **Framework Padrão:** Use `DUnitX`. Sempre decore as classes de teste com `[TestFixture]`, métodos com `[Test]` e setups com `[Setup] / [TearDown]`.
- **Isolamento Total (Fakes/Mocks):** NUNCA escreva um teste de unidade que envolva acoplamento direto com Banco de Dados `TFDConnection`, APIs externas, Rede ou VCL/Forms. Tudo o que é externo à Service ou Entidade testada deve ser simulado no arquivo do teste em uma subclasse isolada FAKE implementando a Interface de dependência (`IMyRepository`).
- **Validação de Exceções:** Para provar Guard Clauses de domínio, instancie obrigatoriamente métodos anônimos usando o `Assert.WillRaise()` injetando o tipo esperado de `Exception`.
