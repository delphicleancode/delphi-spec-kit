# Tasks: [Feature Name]

## Legenda

- `[ ]` — Pendente
- `[/]` — In progress
- `[x]` — Completed

## 1. Domain Layer

- [ ] Create entity `T[Nome]` in `*.Domain.[X].Entity.pas`
  - [ ] Set domain properties and validations
  - [ ] Create enum `T[Nome]Status` if necessary
  - [ ] Add XMLDoc

- [ ] Create interface `I[Nome]Repository` in `*.Domain.[X].Repository.Intf.pas`
  - [ ] Define CRUD methods (FindById, FindAll, Insert, Update, Delete)
  - [ ] Define specific search methods

## 2. Application Layer

- [ ] Create interface `I[Nome]Service` in `*.Application.[X].Service.Intf.pas`
  - [ ] Define business methods

- [ ] Create service `T[Nome]Service` in `*.Application.[X].Service.pas`
  - [ ] Constructor injection with `I[Nome]Repository`
  - [ ] Implement business validations
  - [ ] Guard clauses in all methods
  - [ ] Methods ≤ 20 lines

## 3. Infrastructure Layer

- [ ] Create `T[Nome]Repository` repository in `*.Infra.[X].Repository.pas`
  - [ ] Implement `I[Nome]Repository` with FireDAC
  - [ ] Try/finally for TFDQuery temporary
  - [ ] Parameterize all queries (without SQL injection)

- [ ] Update factory in `*.Infra.Factory.pas`
  - [ ] Add `Create[Nome]Repository`
  - [ ] Add `Create[Nome]Service`

- [ ] Create SQL migration
  - [ ] Table creation script
  - [ ] Test execution on the bank

## 4. Presentation Layer

- [ ] Create listing form `Tfrm[Nome]List` in `*.Presentation.[X].List.pas`
  - [ ] PageControl with tabSearch
  - [ ] DBGrid for display
  - [ ] Search filters
  - [ ] Buttons: New, Edit, Delete

- [ ] Create `Tfrm[Nome]Edit` editing form in `*.Presentation.[X].Edit.pas`
  - [ ] Fields linked to the entity
  - [ ] Visual validation of mandatory fields
  - [ ] Buttons: Save, Cancel

## 5. Tests

- [ ] Create Service unit tests
  - [ ] Creation test with valid data
  - [ ] Validation test with invalid data
  - [ ] Duplicity test

- [ ] Create Repository tests (with bank in memory)

## 6. Integration and Review

- [ ] Register form in main menu
- [ ] Test full flow (CRUD)
- [ ] Code review: check SOLID and clean code
- [ ] Check XMLDoc in public APIs
