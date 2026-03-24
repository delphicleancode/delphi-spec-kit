---
description: "Padrões de Threading em Delphi — TThread, TTask, Synchronize/Queue, thread-safety, PPL, cancelamento"
globs: ["**/*.pas"]
alwaysApply: false
---

# Threading & Multi-Threading — Claude Rules

Use estas regras ao trabalhar com threads e tarefas assíncronas em Delphi.

## Regra de Ouro

> **NUNCA acesse componentes visuais (VCL/FMX) de uma thread secundária.**
> Use `TThread.Synchronize` (bloqueante) ou `TThread.Queue` (não-bloqueante).

## Abordagens

| Abordagem | Quando Usar |
|-----------|-------------|
| `TThread.CreateAnonymousThread` | Tarefas simples, one-shot |
| `TTask.Run` (PPL) | Forma moderna, pool gerenciado |
| `TParallel.For` | Loop paralelo em coleções |
| `TFuture<T>` | Resultado assíncrono com valor |
| `TThread` (herança) | Workers permanentes, filas, servidores |

## Atualizar UI a Partir de Thread

```pascal
{ Queue: não-bloqueante (PREFERIR) }
TThread.Queue(nil,
  procedure
  begin
    lblStatus.Caption := 'Processando...';
  end);

{ Synchronize: bloqueante (quando precisa do resultado) }
TThread.Synchronize(nil,
  procedure
  begin
    lblStatus.Caption := 'Processando...';
  end);
```

## TTask.Run — Forma Moderna

```pascal
uses System.Threading;

TTask.Run(
  procedure
  begin
    { Código pesado em background }
    PerformWork;
    TThread.Queue(nil,
      procedure
      begin
        lblResult.Caption := 'Concluído';
      end);
  end);
```

## Thread-Safety

| Mecanismo | Quando Usar |
|-----------|-------------|
| `TCriticalSection` | Seção crítica clássica (Enter/Leave) |
| `TMonitor` | Lock nativo de objeto (Enter/Exit) |
| `TInterlocked` | Operações atômicas em Integer/Int64 |
| `TThreadList<T>` | Lista thread-safe com LockList/UnlockList |
| `TMultiReadExclusiveWriteSynchronizer` | Cache: muitas leituras, poucas escritas |
| `TThreadedQueue<T>` | Fila thread-safe (Producer-Consumer) |

```pascal
{ TCriticalSection — SEMPRE Leave no finally }
FLock.Enter;
try
  Inc(FSharedCounter);
finally
  FLock.Leave;
end;

{ TInterlocked — Operações atômicas simples }
TInterlocked.Increment(FProcessed);
```

## Cancelamento

```pascal
{ Via Terminated em TThread }
while not Terminated do
begin
  DoWork;
end;

{ Via token customizado em TTask }
if AToken.IsCancelled then
  Exit;
```

## Proibições de Threading

- ❌ Acessar VCL/FMX diretamente de thread secundária
- ❌ `Sleep()` na main thread (congela a UI!)
- ❌ `FreeOnTerminate := True` + `WaitFor` (crash!)
- ❌ Acessar variáveis compartilhadas sem lock
- ❌ Ignorar exceções em threads (são silenciosas!)
- ❌ Criar threads em excesso (usar TTask/Pool)
- ❌ Locks aninhados em ordem diferente (deadlock!)
- ❌ `TCriticalSection.Leave` fora de `finally`

## Debugging

```pascal
{ Nomear threads para o IDE }
TThread.NameThreadForDebugging('DataLoader');
```
