# Tarefas: [Nome da Feature]

## Legenda

- `[ ]` — Pendente
- `[/]` — Em progresso
- `[x]` — Concluída

## 1. Domain Layer

- [ ] Criar entidade `T[Nome]` em `*.Domain.[X].Entity.pas`
  - [ ] Definir propriedades e validações de domínio
  - [ ] Criar enum `T[Nome]Status` se necessário
  - [ ] Adicionar XMLDoc

- [ ] Criar interface `I[Nome]Repository` em `*.Domain.[X].Repository.Intf.pas`
  - [ ] Definir métodos CRUD (FindById, FindAll, Insert, Update, Delete)
  - [ ] Definir métodos de busca específicos

## 2. Application Layer

- [ ] Criar interface `I[Nome]Service` em `*.Application.[X].Service.Intf.pas`
  - [ ] Definir métodos de negócio

- [ ] Criar service `T[Nome]Service` em `*.Application.[X].Service.pas`
  - [ ] Constructor injection com `I[Nome]Repository`
  - [ ] Implementar validações de negócio
  - [ ] Guard clauses em todos os métodos
  - [ ] Métodos ≤ 20 linhas

## 3. Infrastructure Layer

- [ ] Criar repository `T[Nome]Repository` em `*.Infra.[X].Repository.pas`
  - [ ] Implementar `I[Nome]Repository` com FireDAC
  - [ ] Try/finally para TFDQuery temporários
  - [ ] Parametrizar todas as queries (sem SQL injection)

- [ ] Atualizar factory em `*.Infra.Factory.pas`
  - [ ] Adicionar `Create[Nome]Repository`
  - [ ] Adicionar `Create[Nome]Service`

- [ ] Criar migration SQL
  - [ ] Script de criação da tabela
  - [ ] Testar execução no banco

## 4. Presentation Layer

- [ ] Criar form de listagem `Tfrm[Nome]List` em `*.Presentation.[X].List.pas`
  - [ ] PageControl com tabSearch
  - [ ] DBGrid para exibição
  - [ ] Filtros de pesquisa
  - [ ] Botões: Novo, Editar, Excluir

- [ ] Criar form de edição `Tfrm[Nome]Edit` em `*.Presentation.[X].Edit.pas`
  - [ ] Campos vinculados à entidade
  - [ ] Validação visual de campos obrigatórios
  - [ ] Botões: Salvar, Cancelar

## 5. Testes

- [ ] Criar testes unitários do Service
  - [ ] Teste de criação com dados válidos
  - [ ] Teste de validação com dados inválidos
  - [ ] Teste de duplicidade

- [ ] Criar testes do Repository (com banco em memória)

## 6. Integração e Revisão

- [ ] Registrar form no menu principal
- [ ] Testar fluxo completo (CRUD)
- [ ] Code review: verificar SOLID e clean code
- [ ] Verificar XMLDoc em APIs públicas
