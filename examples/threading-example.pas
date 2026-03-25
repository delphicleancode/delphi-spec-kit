/// <summary>
/// Complete example of Threading & Multi-Threading in Delphi.
/// Demonstrates: TThread, TTask, Synchronize/Queue, TCriticalSection,
/// TInterlocked, TParallel.For, Generic BackgroundWorker, Producer-Consumer.
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
  // Domain Exceptions
  // =========================================================================

  EOperationCancelledException = class(Exception);

  // =========================================================================
  // 1. Cancellation Token (thread-safe via TInterlocked)
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
  // 2. Generic Background Worker (TTask + Queue)
  // =========================================================================

  /// <summary>
  /// Performs heavy work in the background and returns the result on the main thread.
  /// Uses TTask.Run internally — managed by the system ThreadPool.
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
  // 5. Worker Thread with Queue (Producer-Consumer)
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
  // 6. Threading Patterns Demonstration
  // =========================================================================

  TThreadingDemo = class
  public
    { 1. Simple Anonymous Thread }
    class procedure DemoAnonymousThread;

    { 2. TTask.Run (PPL) }
    class procedure DemoTaskRun;

    { 3. TParallel.For }
    class procedure DemoParallelFor;

    { 4. TFuture<T> }
    class procedure DemoFuture;

    { 5. Generic BackgroundWorker }
    class procedure DemoBackgroundWorker;

    { 6. Producer-Consumer }
    class procedure DemoProducerConsumer;

    { 7. Multiple tasks with WaitForAll }
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
    raise EOperationCancelledException.Create('Operation canceled by user');
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
        { Execute heavy work in the thread pool }
        LResult := AWorkFunc();

        { Return result on the main thread }
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

      { Notify via Queue (non-blocking) }
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
        { Heavy work in background }
        Sleep(2000);

        { ✅ Update UI via Queue }
        TThread.Queue(nil,
          procedure
          begin
            // lblStatus.Caption := 'Done!';
          end);
      except
        on E: Exception do
          TThread.Queue(nil,
            procedure
            begin
              // ShowMessage('Error: ' + E.Message);
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
      { Executed on the managed ThreadPool }
      Sleep(1000);

      TThread.Queue(nil,
        procedure
        begin
          // lblStatus.Caption := 'Task completed';
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
      { Each iteration can run on a different thread }
      { Protect access to shared variables! }
      TInterlocked.Increment(LTotal);
    end);

  { Here LTotal = 100 (TParallel.For is synchronous — blocks until done) }
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

  { Do other work while the future runs... }

  { .Value blocks until the result is available }
  // ShowMessage('Result:' + LFuture.Value.ToString);
end;

class procedure TThreadingDemo.DemoBackgroundWorker;
begin
  TBackgroundWorker<Integer>.Execute(
    function: Integer
    begin
      { Heavy work in background }
      Sleep(3000);
      Result := 42;
    end,
    procedure(AResult: Integer)
    begin
      { Success — executed on the main thread }
      // ShowMessage('Result:' + AResult.ToString);
    end,
    procedure(AErrorMsg: string)
    begin
      { Error — executed on the main thread }
      // ShowMessage('Error: ' + AErrorMsg);
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

      { Produce 10 items }
      for I := 1 to 10 do
      begin
        LItem.Id := I;
        LItem.Data := Format('Item_%d', [I]);
        LQueue.PushItem(LItem);
      end;

      { Wait for processing }
      Sleep(2000);

      { Stop worker }
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

  { Wait for all (10s timeout) }
  TTask.WaitForAll([LTask1, LTask2, LTask3], 10000);
end;

end.

