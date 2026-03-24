/// <summary>
///   Exemplo completo de Threading & Multi-Threading em Delphi.
///   Demonstra: TThread, TTask, Synchronize/Queue, TCriticalSection,
///   TInterlocked, TParallel.For, BackgroundWorker genérico, Producer-Consumer.
/// </summary>
unit Example.Threading.Patterns;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  System.SyncObjs;

type
  // =========================================================================
  // Exceções de Domínio
  // =========================================================================

  EOperationCancelledException = class(Exception);

  // =========================================================================
  // 1. Token de Cancelamento (thread-safe via TInterlocked)
  // =========================================================================

  ICancellationToken = interface
    ['{THRD0001-0001-0001-0001-000000000001}']
    function IsCancelled: Boolean;
    procedure Cancel;
    procedure ThrowIfCancelled;
  end;

  TCancellationToken = class(TInterfacedObject, ICancellationToken)
  private
    FCancelled: Integer;
  public
    function IsCancelled: Boolean;
    procedure Cancel;
    procedure ThrowIfCancelled;
  end;

  // =========================================================================
  // 2. Background Worker Genérico (TTask + Queue)
  // =========================================================================

  /// <summary>
  ///   Executa trabalho pesado em background e retorna o resultado na main thread.
  ///   Usa TTask.Run internamente — gerenciado pelo ThreadPool do sistema.
  /// </summary>
  TBackgroundWorker<T> = class
  public
    class procedure Execute(
      AWorkFunc: TFunc<T>;
      AOnSuccess: TProc<T>;
      AOnError: TProc<string>);
  end;

  // =========================================================================
  // 3. Thread-Safe Counter (TCriticalSection)
  // =========================================================================

  TThreadSafeCounter = class
  private
    FCount: Integer;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Increment;
    procedure Decrement;
    function Value: Integer;
  end;

  // =========================================================================
  // 4. Thread-Safe Cache (MREWS — Multi-Read, Exclusive-Write)
  // =========================================================================

  TThreadSafeCache<TKey, TValue> = class
  private
    FData: TDictionary<TKey, TValue>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create;
    destructor Destroy; override;
    function TryGet(const AKey: TKey; out AValue: TValue): Boolean;
    procedure Put(const AKey: TKey; const AValue: TValue);
    procedure Remove(const AKey: TKey);
    function Count: Integer;
  end;

  // =========================================================================
  // 5. Worker Thread com Fila (Producer-Consumer)
  // =========================================================================

  TWorkItem = record
    Id: Integer;
    Data: string;
  end;

  TWorkerThread = class(TThread)
  private
    FQueue: TThreadedQueue<TWorkItem>;
    FProcessedCount: Integer;
    FOnItemProcessed: TProc<TWorkItem>;
  protected
    procedure Execute; override;
  public
    constructor Create(AQueue: TThreadedQueue<TWorkItem>);
    property ProcessedCount: Integer read FProcessedCount;
    property OnItemProcessed: TProc<TWorkItem> write FOnItemProcessed;
  end;

  // =========================================================================
  // 6. Demonstração de Padrões de Threading
  // =========================================================================

  TThreadingDemo = class
  public
    { 1. Anonymous Thread simples }
    class procedure DemoAnonymousThread;

    { 2. TTask.Run (PPL) }
    class procedure DemoTaskRun;

    { 3. TParallel.For }
    class procedure DemoParallelFor;

    { 4. TFuture<T> }
    class procedure DemoFuture;

    { 5. BackgroundWorker genérico }
    class procedure DemoBackgroundWorker;

    { 6. Producer-Consumer }
    class procedure DemoProducerConsumer;

    { 7. Múltiplas tasks com WaitForAll }
    class procedure DemoWaitForAll;
  end;

implementation

{ TCancellationToken }

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
    raise EOperationCancelledException.Create('Operação cancelada pelo usuário');
end;

{ TBackgroundWorker<T> }

class procedure TBackgroundWorker<T>.Execute(
  AWorkFunc: TFunc<T>;
  AOnSuccess: TProc<T>;
  AOnError: TProc<string>);
begin
  TTask.Run(
    procedure
    var
      LResult: T;
    begin
      try
        { Executar trabalho pesado em thread do pool }
        LResult := AWorkFunc();

        { Retornar resultado na main thread }
        TThread.Queue(nil,
          procedure
          begin
            AOnSuccess(LResult);
          end);
      except
        on E: Exception do
        begin
          var LMsg := E.Message;
          TThread.Queue(nil,
            procedure
            begin
              AOnError(LMsg);
            end);
        end;
      end;
    end);
end;

{ TThreadSafeCounter }

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
    FLock.Leave;
  end;
end;

procedure TThreadSafeCounter.Decrement;
begin
  FLock.Enter;
  try
    Dec(FCount);
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeCounter.Value: Integer;
begin
  FLock.Enter;
  try
    Result := FCount;
  finally
    FLock.Leave;
  end;
end;

{ TThreadSafeCache<TKey, TValue> }

constructor TThreadSafeCache<TKey, TValue>.Create;
begin
  inherited Create;
  FData := TDictionary<TKey, TValue>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TThreadSafeCache<TKey, TValue>.Destroy;
begin
  FLock.Free;
  FData.Free;
  inherited;
end;

function TThreadSafeCache<TKey, TValue>.TryGet(
  const AKey: TKey; out AValue: TValue): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FData.TryGetValue(AKey, AValue);
  finally
    FLock.EndRead;
  end;
end;

procedure TThreadSafeCache<TKey, TValue>.Put(
  const AKey: TKey; const AValue: TValue);
begin
  FLock.BeginWrite;
  try
    FData.AddOrSetValue(AKey, AValue);
  finally
    FLock.EndWrite;
  end;
end;

procedure TThreadSafeCache<TKey, TValue>.Remove(const AKey: TKey);
begin
  FLock.BeginWrite;
  try
    FData.Remove(AKey);
  finally
    FLock.EndWrite;
  end;
end;

function TThreadSafeCache<TKey, TValue>.Count: Integer;
begin
  FLock.BeginRead;
  try
    Result := FData.Count;
  finally
    FLock.EndRead;
  end;
end;

{ TWorkerThread }

constructor TWorkerThread.Create(AQueue: TThreadedQueue<TWorkItem>);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FQueue := AQueue;
  FProcessedCount := 0;
end;

procedure TWorkerThread.Execute;
var
  LItem: TWorkItem;
  LResult: TWaitResult;
begin
  TThread.NameThreadForDebugging('WorkerThread');

  while not Terminated do
  begin
    LResult := FQueue.PopItem(LItem);
    if LResult = wrSignaled then
    begin
      { Processar item }
      TInterlocked.Increment(FProcessedCount);

      { Notificar via Queue (não-bloqueante) }
      if Assigned(FOnItemProcessed) then
        TThread.Queue(nil,
          procedure
          begin
            FOnItemProcessed(LItem);
          end);
    end;
  end;
end;

{ TThreadingDemo }

class procedure TThreadingDemo.DemoAnonymousThread;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      TThread.NameThreadForDebugging('AnonymousDemo');
      try
        { Trabalho pesado em background }
        Sleep(2000);

        { ✅ Atualizar UI via Queue }
        TThread.Queue(nil,
          procedure
          begin
            // lblStatus.Caption := 'Concluído!';
          end);
      except
        on E: Exception do
          TThread.Queue(nil,
            procedure
            begin
              // ShowMessage('Erro: ' + E.Message);
            end);
      end;
    end).Start;
end;

class procedure TThreadingDemo.DemoTaskRun;
begin
  TTask.Run(
    procedure
    begin
      TThread.NameThreadForDebugging('TaskRunDemo');
      { Executado no ThreadPool gerenciado }
      Sleep(1000);

      TThread.Queue(nil,
        procedure
        begin
          // lblStatus.Caption := 'Task concluída';
        end);
    end);
end;

class procedure TThreadingDemo.DemoParallelFor;
var
  LTotal: Integer;
begin
  LTotal := 0;

  TParallel.For(1, 100,
    procedure(AIndex: Integer)
    begin
      { Cada iteração pode rodar em thread diferente }
      { Proteger acesso a variáveis compartilhadas! }
      TInterlocked.Increment(LTotal);
    end);

  { Aqui LTotal = 100 (TParallel.For é síncrono - bloqueia até acabar) }
end;

class procedure TThreadingDemo.DemoFuture;
var
  LFuture: IFuture<Integer>;
begin
  LFuture := TFuture<Integer>.Create(
    function: Integer
    begin
      TThread.NameThreadForDebugging('FutureDemo');
      Sleep(2000);
      Result := 42;
    end);

  LFuture.Start;

  { Fazer outros trabalhos enquanto o future roda... }

  { .Value bloqueia até o resultado estar disponível }
  // ShowMessage('Resultado: ' + LFuture.Value.ToString);
end;

class procedure TThreadingDemo.DemoBackgroundWorker;
begin
  TBackgroundWorker<Integer>.Execute(
    function: Integer
    begin
      { Trabalho pesado em background }
      Sleep(3000);
      Result := 42;
    end,
    procedure(AResult: Integer)
    begin
      { Sucesso - executado na main thread }
      // ShowMessage('Resultado: ' + AResult.ToString);
    end,
    procedure(AErrorMsg: string)
    begin
      { Erro - executado na main thread }
      // ShowMessage('Erro: ' + AErrorMsg);
    end);
end;

class procedure TThreadingDemo.DemoProducerConsumer;
var
  LQueue: TThreadedQueue<TWorkItem>;
  LWorker: TWorkerThread;
  LItem: TWorkItem;
  I: Integer;
begin
  LQueue := TThreadedQueue<TWorkItem>.Create(100, 1000, 1000);
  try
    LWorker := TWorkerThread.Create(LQueue);
    try
      LWorker.Start;

      { Produzir 10 itens }
      for I := 1 to 10 do
      begin
        LItem.Id := I;
        LItem.Data := Format('Item_%d', [I]);
        LQueue.PushItem(LItem);
      end;

      { Aguardar processamento }
      Sleep(2000);

      { Parar worker }
      LWorker.Terminate;
      LWorker.WaitFor;
    finally
      LWorker.Free;
    end;
  finally
    LQueue.Free;
  end;
end;

class procedure TThreadingDemo.DemoWaitForAll;
var
  LTask1, LTask2, LTask3: ITask;
begin
  LTask1 := TTask.Create(
    procedure
    begin
      TThread.NameThreadForDebugging('Task1');
      Sleep(1000);
    end);

  LTask2 := TTask.Create(
    procedure
    begin
      TThread.NameThreadForDebugging('Task2');
      Sleep(2000);
    end);

  LTask3 := TTask.Create(
    procedure
    begin
      TThread.NameThreadForDebugging('Task3');
      Sleep(1500);
    end);

  LTask1.Start;
  LTask2.Start;
  LTask3.Start;

  { Aguardar todas (timeout 10s) }
  TTask.WaitForAll([LTask1, LTask2, LTask3], 10000);
end;

end.
