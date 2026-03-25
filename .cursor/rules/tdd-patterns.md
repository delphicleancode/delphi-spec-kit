---
description: Rigorous Test-Driven Development (TDD) with DUnitX, naming and dependency injection for isolation with fakes and mocks.
globs: *Test*.pas, *.pas
---

# Delphi TDD and Unit Tests (DUnitX)

- **Test-First (Red-Green-Refactor):** When implementing new rules under "TDD" order, you MUST first structure the Test Case and its failed assertions (`Assert`), before designing the concrete business logic algorithms.
- **Expressive Standard Nomenclature:** Test method prefixes must follow the `Metodo_Cenario_Expectativa` semantic scope. Example: `[Test] procedure CalculateTax_EmptyOrder_ThrowsException;`.
- **Default Framework:** Use `DUnitX`. Always decorate test classes with `[TestFixture]`, methods with `[Test]` and setups with `[Setup] / [TearDown]`.
- **Total Isolation (Fakes/Mocks):** NEVER write a unit test that involves direct coupling with the `TFDConnection` Database, external APIs, Network or VCL/Forms. Everything external to the tested Service or Entity must be simulated in the test file in a FAKE isolated subclass implementing the Dependency Interface (`IMyRepository`).
- **Exception Validation:** To prove domain Guard Clauses, instantiate anonymous methods using `Assert.WillRaise()` by injecting the expected type of `Exception`.
