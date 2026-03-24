---
description: Boas práticas de gerenciamento de memória, prevenção de memory leaks e tratamento de exceções em Delphi
---

# 🧠 Gerenciamento de Memória e Exceções em Delphi

## Contexto

Delphi possui um **gerenciamento de memória manual** para instâncias de classes (não derivadas de interfaces) e usa **ARC (Automatic Reference Counting)** apenas para interfaces (`IInterface`), Strings, Arrays Dinâmicos e tipos anônimos. Tratamento pobre de exceções e esquecimento da liberação da memória resultam em **Memory Leaks** crônicos, falhas catastróficas em produção e instabilidade sistêmica.

Como a IA, você deve proativamente garantir que todo objeto criado seja liberado independentemente de fluxos de erro.

## Objetivos desta Skill

- Ensinar como gerar blocos seguros de `try..finally`.
- Prevenir Memory Leaks orientando sobre `Free` e `FreeAndNil`.
- Promover o uso de Interfaces para automação de memória.
- Instituir o tratamento defensivo e tipado de Exceções (`try..except`).
- Introduzir Exceções de Domínio customizadas.

---

## 🛑 Gerenciamento de Memória: Regras Críticas

### 1. O Padrão Ouro: `try..finally`
Sempre que uma instância de objeto for criada e não tiver um Owner que a gerencie, instancie em um bloco `try..finally`.
O `try` deve ocorrer **IMEDIATAMENTE** na linha subsequente à criação.

```pascal
var
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LList.Add('Item 1');
    // ...
  finally
    LList.Free;
  end;
end;
```

**Anti-Pattern (NÃO USE):**
Código entre o `Create` e o `try` pode gerar uma exceção, vazando o objeto recém-criado.
```pascal
  // ERRADO - vazamento em potencial!
  LList := TStringList.Create;
  LList.Add('Item 1');
  try
    // ...
```

### 2. Múltiplos Objetos no Mesmo Bloco
Ao alocar múltiplos recursos temporários em um mesmo método, não aninhe dezenas de `try..finally` caso não seja estritamente necessário. Mas cuide para inicializar todos com `nil` antes se houver chance de vazamento, ou aninhe com prudência. O padrão ideal é liberação sequencial garantida, mas o aninhamento estrito é o mais seguro para alocações encadeadas:

```pascal
var
  LStream: TMemoryStream;
  LReader: TStreamReader;
begin
  LStream := TMemoryStream.Create;
  try
    LReader := TStreamReader.Create(LStream);
    try
      // lógicas com ambos
    finally
      LReader.Free;
    end;
  finally
    LStream.Free;
  end;
end;
```

### 3. Evite Criar Objetos para Passagem Simples
Se uma API recebe um parâmetro de classe, declare uma interface ou instancie antes do método com `try..finally`. Nunca passe um `.Create` inline para um parâmetro num método se não tiver garantia absoluta de que a função consumidora irá liberar a memória.

### 4. Garbage Collection via Intefaces
Para Injeção de Dependências, Patterns de Repositório/Serviço ou Classes Funcionais Temporárias, use herança de `TInterfacedObject` vinculada a uma `Interface`.
O Delphi eliminará a instância quando o contador de referências chegar a zero.
```pascal
var
  LService: ICustomerService;
begin
  // Sem try..finally e sem chamadas de .Free.
  // Memória é varrida ao sair do escopo desta procedure.
  LService := TCustomerService.Create; 
  LService.ProcessDailyBatch;
end;
```

---

## 🚨 Tratamento de Exceções: O Padrão Transparente

### 1. Capturas Específicas, Não Genéricas
Use `try..except` primariamente para interceptar erros recuperáveis, logar falhas sem interromper loops, ou transformar exceções de infraestrutura em exceções de domínio mais semânticas.
Nunca "Cale" (Swallow) uma exceção sem justificativa lógica.

```pascal
try
  PerformDatabaseCommit;
except
  // Captura ESPECÍFICA de banco de dados
  on E: EFDDBEngineException do
  begin
    Logger.Error('Falha no banco de dados [Cód: %d]: %s', [E.ErrorCode, E.Message]);
    raise EDatabaseConnectionException.Create('Serviço temporariamente indisponível.');
  end;
  // Captura ESPECÍFICA de validação
  on E: EValidationException do
  begin
    ShowWarning(E.Message);
  end;
end;
```

**Anti-Pattern (NÃO USE):**
Isto cega o rastreio da aplicação (esconde `AccessViolations` e `Out of Memory`).
```pascal
try
  ProcessData;
except
  // Errado! Esconde qualquer erro do desenvolvedor durante debug!
end;
```

### 2. Criação de Exceções Baseadas na Lógica de Negócios (DDD)
Não use `raise Exception.Create(str)`. Declare exceções coesas para permitir interceptação elegante pelas camadas superiores (Controllers REST, Interface UI).

```pascal
type
  // Domínio / Essência das Regras
  EBusinessRuleException = class(Exception);
  ECustomerLimitReachedException = class(EBusinessRuleException);
  
  // Infraestrutura
  EInfrastructureException = class(Exception);
  EDatabaseConnectionException = class(EInfrastructureException);
```

### 3. Encapsulando Erros e `Raise` sem Modificar Contexto
Se precisar apenas realizar um log pontual mas quiser que a exceção flua naturalmente para a UI global, utilize apenas `raise;` puro.

```pascal
try
  SomeDangerousCall;
except
  on E: Exception do
  begin
    Logger.LogError('Critical failure', E);
    raise; // REPROJETA a exceção original com a mesma stack-trace
  end;
end;
```

---

## 💡 Fluxo de Ação da IA

Quando solicitado a escrever/refatorar código:
1. Revise se cada `TObject.Create` resultará numa desalocação (`.Free` ou Ownership de terceiros).
2. Injete `try..finally` se notar código legado sem ele.
3. Se gerar Serviços, recomende Injeção de Dependências por Interfaces (`IService`) para simplificar varredura de lixo (GC).
4. Em lógicas que possam falhar, crie Exceções Tipológicas para validar fluxo e prevenir condicionais espaguete de código de erro (`if return = -1 then`).
