---
description: "Threading Patterns in Delphi — TThread, TTask, Synchronize/Queue, thread-safety, PPL, cancellation"
globs: ["**/*.pas"]
alwaysApply: false
---

# Threading & Multi-Threading — Claude Rules

Use these rules when working with threads and asynchronous tasks in Delphi.

## Golden Rule

> **NEVER access visual components (VCL/FMX) from a secondary thread.**
> Use `TThread.Synchronize` (blocking) or `TThread.Queue` (non-blocking).

## Approaches

| Approach | When to Use |
|-----------|-------------|
| `TThread.CreateAnonymousThread` | Simple, one-shot tasks |
| `TTask.Run` (PPL) | Modern way, managed pool |
| `TParallel.For` | Parallel loop in collections |
| `TFuture<T>` | Asynchronous result with value |
| `TThread` (inheritance) | Permanent workers, queues, servers |

## Update UI from Thread

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

## TTask.Run — Modern Way

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

| Mechanism | When to Use |
|-----------|-------------|
| `TCriticalSection` | Classic critical section (Enter/Leave) |
| `TMonitor` | Object native lock (Enter/Exit) |
| `TInterlocked` | Atomic operations on Integer/Int64 |
| `TThreadList<T>` | Thread-safe list with LockList/UnlockList |
| `TMultiReadExclusiveWriteSynchronizer` | Cache: many reads, few writes |
| `TThreadedQueue<T>` | Thread-safe queue (Producer-Consumer) |

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

## Threading Prohibitions

- ❌ Access VCL/FMX directly from secondary thread
- ❌ `Sleep()` in the main thread (freezes the UI!)
- ❌ `FreeOnTerminate := True` + `WaitFor` (crash!)
- ❌ Access shared variables without locking
- ❌ Ignore exceptions in threads (they are silent!)
- ❌ Create excess threads (use TTask/Pool)
- ❌ Locks nested in different order (deadlock!)
- ❌ `TCriticalSection.Leave` fora de `finally`

## Debugging

```pascal
{ Nomear threads para o IDE }
TThread.NameThreadForDebugging('DataLoader');
```
