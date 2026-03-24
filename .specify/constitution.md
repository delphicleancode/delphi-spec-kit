# Constituição — Delphi Spec-Kit

> Princípios fundamentais que governam todo o desenvolvimento neste projeto.

## Linguagem e Plataforma

Este projeto utiliza **Delphi (Object Pascal)** com frameworks **VCL** e/ou **FMX** e acesso a dados via **FireDAC**. Todo código gerado DEVE seguir as convenções do **Object Pascal Style Guide**.

## Princípios Inegociáveis

### 1. SOLID Always

- **SRP:** Uma classe, uma responsabilidade. Separar validação, persistência e apresentação.
- **OCP:** Extensão via interfaces e herança, não modificação de classes existentes.
- **LSP:** Subtipos substituíveis sem quebrar comportamento.
- **ISP:** Interfaces pequenas e focadas.
- **DIP:** Depender de abstrações (interfaces), usar constructor injection.

### 2. Clean Code Always

- Métodos ≤ 20 linhas
- Nomes auto-descritivos em PascalCase
- Guard clauses em vez de nesting
- Constantes nomeadas (sem números mágicos)
- XMLDoc para APIs públicas

### 3. Arquitetura em Camadas

```
Presentation → Application → Domain ← Infrastructure
```

O **Domain nunca depende** de outras camadas. Infrastructure implementa as interfaces definidas em Domain.

### 4. Convenções do Pascal Guide

- Prefixos obrigatórios: `T`, `I`, `E`, `F`, `A`, `L`
- Units nomeadas como: `Projeto.Camada.Dominio.Funcionalidade.pas`
- Componentes com prefixo de 3 letras: `btn`, `edt`, `lbl`, `cmb`, `qry`, `ds`

### 5. Proibições Absolutas

- ❌ `with` statement
- ❌ Variáveis globais
- ❌ Lógica de negócio em event handlers de forms
- ❌ Catch genérico de exceptions
- ❌ God classes ou God units
- ❌ Ignorar gerenciamento de memória

## Processo de Desenvolvimento

1. **Especificar** — Definir requisitos e critérios de aceitação
2. **Planejar** — Projetar interfaces e classes antes de implementar
3. **Implementar** — Código limpo seguindo SOLID e convenções
4. **Testar** — DUnitX para testes unitários
5. **Revisar** — Verificar aderência às regras desta constituição
