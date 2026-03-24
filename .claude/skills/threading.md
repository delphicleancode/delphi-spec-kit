---
name: "Threading & Multi-Threading"
description: "Padrões de threading em Delphi — TThread, TTask, TParallel, Synchronize, Queue, thread-safety, Producer-Consumer, pools, cancelamento e debugging"
---

# Threading & Multi-Threading — Skill

Use esta skill ao trabalhar com threads, tarefas assíncronas e paralelismo em projetos Delphi.

## Quando Usar

- Ao executar operações demoradas sem bloquear a UI (VCL/FMX)
- Ao implementar processamento paralelo de dados
- Ao criar servidores/workers que processam requisições concorrentes
- Ao sincronizar acesso a recursos compartilhados
- Ao gerenciar pools de threads e filas de trabalho
- Ao implementar cancelamento gracioso de threads

## Regra de Ouro do Threading em Delphi

> **NUNCA acesse componentes visuais (VCL/FMX) diretamente de uma thread secundária.**
> Use `TThread.Synchronize` ou `TThread.Queue` para atualizar a UI.

## Abordagens Disponíveis

| Abordagem | Quando Usar | Complexidade |
|-----------|-------------|-------------|
| `TThread` | Controle total, threads de longa duração | Média |
| `TThread.CreateAnonymousThread` | Tarefas simples, one-shot | Baixa |
| `TTask` (PPL) | Paralelismo moderno, tasks leves | Baixa |
| `TParallel.For` (PPL) | Loops paralelos em coleções | Baixa |
| `TFuture<T>` (PPL) | Resultado assíncrono com valor de retorno | Baixa |
| `TThreadPool` | Pool de threads reutilizáveis | Média |
| Thread dedicada (herança) | Workers permanentes, servidores, filas | Alta |

## TThread — Abordagem Clássica

### Thread com Herança (Recomendado para Workers)

```pascal
type
  /// <summary>
  ///   Worker thread para processamento em background.
  ///   Demonstra herança de TThread com cancelamento via Terminated.
  /// </summary>
  TDataProcessorThread = class(TThread)
  private
    FItems: TThreadList<string>;
    FOnProgress: TProc<Integer, Integer>;
    FOnComplete: TProc<Boolean>;
  protected
    procedure Execute; override;
  public
    constructor Create(AItems: TThreadList<string>);
    property OnProgress: TProc<Integer, Integer> write FOnProgress;
    property OnComplete: TProc<Boolean> write FOnComplete;
  end;

constructor TDataProcessorThread.Create(AItems: TThreadList<string>);
begin
  inherited Create(True);   // Criar suspensa
  FreeOnTerminate := True;  // Auto-libera ao terminar
  FItems := AItems;
end;

procedure TDataProcessorThread.Execute;
var
  LList: TList<string>;
  LTotal, I: Integer;
begin
  try
    LList := FItems.LockList;
    try
      LTotal := LList.Count;
    finally
      FItems.UnlockList;
    end;

    for I := 0 to LTotal - 1 do
    begin
      { Verificar cancelamento em cada iteração }
      if Terminated then
        Exit;

      { Processar item }
      ProcessItem(I);

      { Atualizar UI via Queue (não-bloqueante) }
      if Assigned(FOnProgress) then
        TThread.Queue(nil,
          procedure
          begin
            FOnProgress(I + 1, LTotal);
          end);
    end;

    { Notificar conclusão na main thread }
    if Assigned(FOnComplete) then
      TThread.Queue(nil,
        procedure
        begin
          FOnComplete(not Terminated);
        end);
  except
    on E: Exception do
    begin
      TThread.Queue(nil,
        procedure
        begin
          raise EThreadException.Create('Erro no processamento: ' + E.Message);
        end);
    end;
  end;
end;
```

### Uso da Thread Dedicada

```pascal
procedure TfrmMain.btnProcessClick(Sender: TObject);
var
  LThread: TDataProcessorThread;
begin
  LThread := TDataProcessorThread.Create(FSharedItems);
  LThread.OnProgress :=
    procedure(ACurrent, ATotal: Integer)
    begin
      pbrProgress.Max := ATotal;
      pbrProgress.Position := ACurrent;
      lblStatus.Caption := Format('Processando %d de %d...', [ACurrent, ATotal]);
    end;
  LThread.OnComplete :=
    procedure(ASuccess: Boolean)
    begin
      if ASuccess then
        ShowMessage('Concluído com sucesso!')
      else
        ShowMessage('Processamento cancelado.');
    end;
  LThread.Start;  // Iniciar a thread
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  { Solicitar cancelamento gracioso }
  if Assigned(FCurrentThread) then
    FCurrentThread.Terminate;
end;
```

### CreateAnonymousThread (Tarefas Simples)

```pascal
/// <summary>
///   Forma mais simples de executar código em background.
///   Ideal para one-shot tasks sem necessidade de controle avançado.
/// </summary>
procedure TfrmMain.LoadDataAsync;
begin
  btnLoad.Enabled := False;

  TThread.CreateAnonymousThread(
    procedure
    var
      LData: TStringList;
    begin
      LData := TStringList.Create;
      try
        { Trabalho pesado (thread secundária — OK!) }
        LData.LoadFromFile('C:\dados\arquivo_grande.csv');
        Sleep(2000); // Simular processamento

        { Atualizar UI (DEVE usar Synchronize ou Queue) }
        TThread.Synchronize(nil,
          procedure
          begin
            mmoOutput.Lines.Assign(LData);
            btnLoad.Enabled := True;
            lblStatus.Caption := Format('Carregados %d registros', [LData.Count]);
          end);
      finally
        LData.Free;
      end;
    end
  ).Start;
end;
```

## Synchronize vs Queue

| Método | Comportamento | Quando Usar |
|--------|--------------|-------------|
| `TThread.Synchronize` | **Bloqueante** — espera a main thread processar | Quando precisa do resultado da UI |
| `TThread.Queue` | **Não-bloqueante** — enfileira e continua | Progresso, logs, atualizações visuais |

```pascal
{ Synchronize: BLOQUEIA a thread até a main thread processar }
TThread.Synchronize(nil,
  procedure
  begin
    lblStatus.Caption := 'Processando...';
  end);
// A thread só continua AQUI depois que a main thread executou o código acima

{ Queue: NÃO BLOQUEIA — enfileira e continua imediatamente }
TThread.Queue(nil,
  procedure
  begin
    lblStatus.Caption := 'Processando...';
  end);
// A thread continua IMEDIATAMENTE, sem esperar a main thread
```

> **Recomendação:** Prefira `Queue` sempre que possível. Use `Synchronize` apenas quando precisar de um resultado da UI de volta na thread.

## PPL — Parallel Programming Library (System.Threading)

### TTask — Tarefas Leves

```pascal
uses
  System.Threading;

/// <summary>
///   TTask é a forma moderna de executar tarefas em background.
///   Gerenciado automaticamente pelo pool de threads do sistema.
/// </summary>
procedure TfrmMain.ExecuteMultipleTasks;
var
  LTask1, LTask2, LTask3: ITask;
begin
  LTask1 := TTask.Create(
    procedure
    begin
      { Tarefa 1: Carregar dados do banco }
      LoadCustomers;
    end);

  LTask2 := TTask.Create(
    procedure
    begin
      { Tarefa 2: Processar relatório }
      GenerateReport;
    end);

  LTask3 := TTask.Create(
    procedure
    begin
      { Tarefa 3: Enviar emails }
      SendPendingEmails;
    end);

  { Iniciar todas as tarefas em paralelo }
  LTask1.Start;
  LTask2.Start;
  LTask3.Start;

  { Aguardar todas completarem (com timeout) }
  TTask.WaitForAll([LTask1, LTask2, LTask3], 30000); // 30s timeout

  TThread.Queue(nil,
    procedure
    begin
      ShowMessage('Todas as tarefas concluídas!');
    end);
end;
```

### TTask.Run — Atalho Direto

```pascal
{ Forma mais simples de executar em background via PPL }
TTask.Run(
  procedure
  begin
    { Código executado no ThreadPool }
    PerformHeavyCalculation;

    TThread.Queue(nil,
      procedure
      begin
        lblResult.Caption := 'Cálculo concluído';
      end);
  end);
```

### TParallel.For — Loops Paralelos

```pascal
uses
  System.Threading,
  System.SyncObjs;

/// <summary>
///   TParallel.For distribui iterações do loop entre múltiplas threads.
///   Ideal para processamento de coleções independentes.
/// </summary>
procedure TfrmMain.ProcessImagesParallel;
var
  LFiles: TArray<string>;
  LProcessed: Integer;
  LLock: TCriticalSection;
begin
  LFiles := TDirectory.GetFiles('C:\Images', '*.jpg');
  LProcessed := 0;
  LLock := TCriticalSection.Create;
  try
    TParallel.For(0, High(LFiles),
      procedure(AIndex: Integer)
      begin
        { Cada imagem processada em thread separada }
        ResizeImage(LFiles[AIndex]);

        { Atualizar contador de forma thread-safe }
        LLock.Enter;
        try
          Inc(LProcessed);
        finally
          LLock.Leave;
        end;
      end);

    ShowMessage(Format('%d imagens processadas', [LProcessed]));
  finally
    LLock.Free;
  end;
end;
```

> **⚠️ CUIDADO:** Cada iteração de `TParallel.For` pode rodar em threads diferentes. Variáveis compartilhadas **DEVEM** ser protegidas com `TCriticalSection`, `TMonitor` ou `TInterlocked`.

### TFuture<T> — Resultado Assíncrono

```pascal
uses
  System.Threading;

/// <summary>
///   TFuture executa uma tarefa e retorna um valor quando pronto.
///   A leitura de .Value bloqueia até o resultado estar disponível.
/// </summary>
procedure TfrmMain.CalculateAsync;
var
  LFuture: IFuture<Double>;
begin
  LFuture := TFuture<Double>.Create(
    function: Double
    begin
      { Cálculo pesado em background }
      Sleep(3000);
      Result := CalculateComplexFormula(FInputData);
    end);

  LFuture.Start;

  { Fazer outras coisas enquanto o cálculo roda... }
  PrepareReport;

  { Pegar o resultado (bloqueia SE ainda não terminou) }
  ShowMessage(Format('Resultado: %.2f', [LFuture.Value]));
end;
```

## Thread-Safety — Proteção de Recursos

### TCriticalSection

```pascal
type
  TThreadSafeCounter = class
  private
    FCount: Integer;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Increment;
    procedure Decrement;
    function GetValue: Integer;
  end;

constructor TThreadSafeCounter.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FCount := 0;
end;

destructor TThreadSafeCounter.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TThreadSafeCounter.Increment;
begin
  FLock.Enter;
  try
    Inc(FCount);
  finally
    FLock.Leave;  // SEMPRE no finally!
  end;
end;

function TThreadSafeCounter.GetValue: Integer;
begin
  FLock.Enter;
  try
    Result := FCount;
  finally
    FLock.Leave;
  end;
end;
```

### TMonitor (Lock Nativo de Objeto)

```pascal
{ TMonitor usa o próprio objeto como lock — sem criar TCriticalSection }
procedure TThreadSafeList.AddItem(const AItem: string);
begin
  TMonitor.Enter(FList);
  try
    FList.Add(AItem);
  finally
    TMonitor.Exit(FList);
  end;
end;
```

### TInterlocked (Operações Atômicas)

```pascal
{ Para operações simples em Integer/Int64 — sem lock explícito }
TInterlocked.Increment(FProcessedCount);
TInterlocked.Decrement(FPendingCount);
TInterlocked.Add(FTotalBytes, LBytesRead);
TInterlocked.Exchange(FOldValue, LNewValue);
TInterlocked.CompareExchange(FTarget, LNewVal, LExpectedVal);
```

### TThreadList<T> (Lista Thread-Safe)

```pascal
var
  FSharedList: TThreadList<string>;

{ Thread A: adicionar }
LList := FSharedList.LockList;
try
  LList.Add('item');
finally
  FSharedList.UnlockList;
end;

{ Thread B: ler }
LList := FSharedList.LockList;
try
  for LItem in LList do
    ProcessItem(LItem);
finally
  FSharedList.UnlockList;
end;
```

### TMultiReadExclusiveWriteSynchronizer (MREWS)

```pascal
type
  TThreadSafeCache = class
  private
    FData: TDictionary<string, string>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create;
    destructor Destroy; override;
    function TryGet(const AKey: string; out AValue: string): Boolean;
    procedure Put(const AKey, AValue: string);
  end;

function TThreadSafeCache.TryGet(const AKey: string; out AValue: string): Boolean;
begin
  FLock.BeginRead;  // Múltiplas threads podem ler simultaneamente
  try
    Result := FData.TryGetValue(AKey, AValue);
  finally
    FLock.EndRead;
  end;
end;

procedure TThreadSafeCache.Put(const AKey, AValue: string);
begin
  FLock.BeginWrite;  // Apenas uma thread pode escrever por vez
  try
    FData.AddOrSetValue(AKey, AValue);
  finally
    FLock.EndWrite;
  end;
end;
```

## Padrão Producer-Consumer

```pascal
type
  /// <summary>
  ///   Producer-Consumer com TThreadedQueue (fila thread-safe).
  /// </summary>
  TProducerConsumerDemo = class
  private
    FQueue: TThreadedQueue<string>;
    FProducerThread: TThread;
    FConsumerThread: TThread;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
  end;

constructor TProducerConsumerDemo.Create;
begin
  inherited;
  { QueueDepth=100, PushTimeout=1000ms, PopTimeout=1000ms }
  FQueue := TThreadedQueue<string>.Create(100, 1000, 1000);
end;

procedure TProducerConsumerDemo.Start;
begin
  { Producer: gera itens continuamente }
  FProducerThread := TThread.CreateAnonymousThread(
    procedure
    var
      I: Integer;
    begin
      I := 0;
      while not TThread.Current.CheckTerminated do
      begin
        Inc(I);
        FQueue.PushItem(Format('Item_%d', [I]));
        Sleep(100);
      end;
    end);
  FProducerThread.FreeOnTerminate := False;

  { Consumer: processa itens da fila }
  FConsumerThread := TThread.CreateAnonymousThread(
    procedure
    var
      LItem: string;
      LResult: TWaitResult;
    begin
      while not TThread.Current.CheckTerminated do
      begin
        LResult := FQueue.PopItem(LItem);
        if LResult = wrSignaled then
          ProcessItem(LItem);
      end;
    end);
  FConsumerThread.FreeOnTerminate := False;

  FProducerThread.Start;
  FConsumerThread.Start;
end;

procedure TProducerConsumerDemo.Stop;
begin
  FProducerThread.Terminate;
  FConsumerThread.Terminate;
  FProducerThread.WaitFor;
  FConsumerThread.WaitFor;
  FProducerThread.Free;
  FConsumerThread.Free;
end;
```

## Eventos e Sinalização

### TEvent

```pascal
uses
  System.SyncObjs;

var
  FStopEvent: TEvent;

{ Criar }
FStopEvent := TEvent.Create(nil, True, False, ''); // Manual reset, initially unsignaled

{ Thread: esperar sinal }
procedure TWorkerThread.Execute;
begin
  while not Terminated do
  begin
    { Esperar até 500ms por sinal de parada }
    if FStopEvent.WaitFor(500) = wrSignaled then
      Break;

    { Fazer trabalho }
    DoWork;
  end;
end;

{ Main thread: sinalizar parada }
FStopEvent.SetEvent;
```

### TSemaphore (Limite de Concorrência)

```pascal
uses
  System.SyncObjs;

var
  FSemaphore: TSemaphore;

{ Limitar a 5 threads simultâneas }
FSemaphore := TSemaphore.Create(nil, 5, 5, '');

{ Em cada thread: }
FSemaphore.Acquire;
try
  { Apenas 5 threads podem estar aqui simultaneamente }
  PerformLimitedWork;
finally
  FSemaphore.Release;
end;
```

## Thread Pool Customizado

```pascal
type
  TCustomThreadPool = class
  private
    FThreads: TObjectList<TThread>;
    FQueue: TThreadedQueue<TProc>;
    FMaxThreads: Integer;
  public
    constructor Create(AMaxThreads: Integer = 4);
    destructor Destroy; override;
    procedure QueueWork(AProc: TProc);
  end;

constructor TCustomThreadPool.Create(AMaxThreads: Integer);
var
  I: Integer;
begin
  inherited Create;
  FMaxThreads := AMaxThreads;
  FQueue := TThreadedQueue<TProc>.Create(1000, INFINITE, 500);
  FThreads := TObjectList<TThread>.Create(True);

  for I := 0 to FMaxThreads - 1 do
  begin
    var LThread := TThread.CreateAnonymousThread(
      procedure
      var
        LProc: TProc;
        LResult: TWaitResult;
      begin
        while not TThread.Current.CheckTerminated do
        begin
          LResult := FQueue.PopItem(LProc);
          if (LResult = wrSignaled) and Assigned(LProc) then
          try
            LProc();
          except
            on E: Exception do
              { Log error, don't crash the pool thread }
              TThread.Queue(nil,
                procedure
                begin
                  // Logger.LogError(E);
                end);
          end;
        end;
      end);
    LThread.FreeOnTerminate := False;
    LThread.Start;
    FThreads.Add(LThread);
  end;
end;

procedure TCustomThreadPool.QueueWork(AProc: TProc);
begin
  FQueue.PushItem(AProc);
end;
```

## Cancelamento com Token

```pascal
type
  ICancellationToken = interface
    ['{CANCEL01-0001-0001-0001-000000000001}']
    function IsCancelled: Boolean;
    procedure Cancel;
    procedure ThrowIfCancelled;
  end;

  TCancellationToken = class(TInterfacedObject, ICancellationToken)
  private
    FCancelled: Integer;  // 0=false, 1=true (atômico)
  public
    function IsCancelled: Boolean;
    procedure Cancel;
    procedure ThrowIfCancelled;
  end;

function TCancellationToken.IsCancelled: Boolean;
begin
  Result := TInterlocked.Read(FCancelled) = 1;
end;

procedure TCancellationToken.Cancel;
begin
  TInterlocked.Exchange(FCancelled, 1);
end;

procedure TCancellationToken.ThrowIfCancelled;
begin
  if IsCancelled then
    raise EOperationCancelled.Create('Operação cancelada pelo usuário');
end;

{ Uso: }
procedure ProcessWithCancellation(AToken: ICancellationToken);
begin
  for var I := 0 to 999 do
  begin
    AToken.ThrowIfCancelled;
    ProcessItem(I);
  end;
end;
```

## Padrões Importantes

### Padrão: Background Worker com Resultado

```pascal
type
  /// <summary>
  ///   Generic background worker que executa uma função e retorna
  ///   o resultado na main thread.
  /// </summary>
  TBackgroundWorker<T> = class
  public
    class procedure Execute(
      AWorkFunc: TFunc<T>;
      AOnSuccess: TProc<T>;
      AOnError: TProc<Exception>);
  end;

class procedure TBackgroundWorker<T>.Execute(
  AWorkFunc: TFunc<T>;
  AOnSuccess: TProc<T>;
  AOnError: TProc<Exception>);
begin
  TTask.Run(
    procedure
    var
      LResult: T;
    begin
      try
        LResult := AWorkFunc();
        TThread.Queue(nil,
          procedure
          begin
            AOnSuccess(LResult);
          end);
      except
        on E: Exception do
          TThread.Queue(nil,
            procedure
            begin
              AOnError(E);
            end);
      end;
    end);
end;

{ Uso elegante: }
TBackgroundWorker<TObjectList<TCustomer>>.Execute(
  function: TObjectList<TCustomer>
  begin
    Result := FCustomerRepo.FindAll;
  end,
  procedure(ACustomers: TObjectList<TCustomer>)
  begin
    FillGrid(ACustomers);
    lblStatus.Caption := Format('%d clientes carregados', [ACustomers.Count]);
  end,
  procedure(AError: Exception)
  begin
    ShowMessage('Erro: ' + AError.Message);
  end);
```

### Padrão: Timer Thread (Execução Periódica)

```pascal
type
  TTimerThread = class(TThread)
  private
    FInterval: Cardinal;
    FOnTimer: TProc;
  protected
    procedure Execute; override;
  public
    constructor Create(AIntervalMs: Cardinal; AOnTimer: TProc);
  end;

constructor TTimerThread.Create(AIntervalMs: Cardinal; AOnTimer: TProc);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FInterval := AIntervalMs;
  FOnTimer := AOnTimer;
end;

procedure TTimerThread.Execute;
begin
  while not Terminated do
  begin
    Sleep(FInterval);
    if not Terminated and Assigned(FOnTimer) then
      FOnTimer();
  end;
end;
```

## Anti-Patterns a Evitar

```pascal
// ❌ NUNCA acessar UI diretamente de thread secundária
TThread.CreateAnonymousThread(
  procedure
  begin
    lblStatus.Caption := 'Processando...';  // CRASH ou comportamento imprevisível!
  end).Start;

// ✅ SEMPRE usar Synchronize/Queue para UI
TThread.CreateAnonymousThread(
  procedure
  begin
    TThread.Queue(nil,
      procedure
      begin
        lblStatus.Caption := 'Processando...';  // Seguro!
      end);
  end).Start;

// ❌ NUNCA criar thread com FreeOnTerminate=True e manter referência
FMyThread := TMyThread.Create(True);
FMyThread.FreeOnTerminate := True;
FMyThread.Start;
// ... depois
FMyThread.WaitFor;  // CRASH! O objeto pode já ter sido liberado!

// ✅ Se precisa de WaitFor, NÃO use FreeOnTerminate
FMyThread := TMyThread.Create(True);
FMyThread.FreeOnTerminate := False;
FMyThread.Start;
// ... depois
FMyThread.WaitFor;
FMyThread.Free;

// ❌ NUNCA acessar variáveis compartilhadas sem proteção
Inc(FSharedCounter);  // Race condition!

// ✅ SEMPRE proteger acesso compartilhado
TInterlocked.Increment(FSharedCounter);  // Atômico!
// ou
FLock.Enter;
try
  Inc(FSharedCounter);
finally
  FLock.Leave;
end;

// ❌ NUNCA usar Sleep() na main thread
Sleep(5000);  // Congela a UI por 5 segundos!

// ✅ Mover trabalho pesado para thread
TTask.Run(
  procedure
  begin
    Sleep(5000);  // OK em thread secundária
    TThread.Queue(nil,
      procedure
      begin
        lblStatus.Caption := 'Concluído';
      end);
  end);

// ❌ NUNCA ignorar exceções em threads (elas são silenciosas!)
TThread.CreateAnonymousThread(
  procedure
  begin
    RiskyOperation;  // Se lançar exception, ninguém saberá!
  end).Start;

// ✅ SEMPRE tratar exceções em threads
TThread.CreateAnonymousThread(
  procedure
  begin
    try
      RiskyOperation;
    except
      on E: Exception do
        TThread.Queue(nil,
          procedure
          begin
            HandleError(E.Message);
          end);
    end;
  end).Start;
```

## Debugging de Threads

### Nomear Threads (Facilita Debug)

```pascal
TThread.CreateAnonymousThread(
  procedure
  begin
    TThread.NameThreadForDebugging('DataLoader');
    // ... código
  end).Start;

{ Para TThread herdado: }
procedure TMyThread.Execute;
begin
  TThread.NameThreadForDebugging('MyWorker_' + FId.ToString);
  // ...
end;
```

### Thread Window no IDE

- **View → Debug Windows → Threads:** Lista todas as threads ativas
- Cada thread nomeada aparece com seu nome customizado
- Útil para identificar deadlocks e race conditions

## Checklist de Threading

- [ ] Operações pesadas estão em threads secundárias (não na main thread)?
- [ ] Toda atualização de UI usa `Synchronize` ou `Queue`?
- [ ] Variáveis compartilhadas protegidas com locks (`TCriticalSection`, `TMonitor`, `TInterlocked`)?
- [ ] `FreeOnTerminate` configurado corretamente (True para fire-and-forget, False se precisa WaitFor)?
- [ ] Threads verificam `Terminated` em loops para cancelamento gracioso?
- [ ] Exceções tratadas dentro das threads (não propagam silenciosamente)?
- [ ] Threads nomeadas com `NameThreadForDebugging` para facilitar debug?
- [ ] `TCriticalSection.Leave` sempre no `finally`?
- [ ] Sem `Sleep()` na main thread?
- [ ] Sem deadlocks (locks aninhados na mesma ordem)?
