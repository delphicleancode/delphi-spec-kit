unit Test.I18nApp.Core.LanguageManager;

interface

uses
  DUnitX.TestFramework, I18nApp.Core.LanguageManager, System.SysUtils;

type
  // Fake Object conforming to TDD conventions for testing observer
  TFakeLanguageObserver = class(TInterfacedObject, TLanguageObserver)
  private
    FNotifiedLanguage: string;
    FCallCount: Integer;
  public
    procedure LanguageChanged(const ALang: string);
    property NotifiedLanguage: string read FNotifiedLanguage;
    property CallCount: Integer read FCallCount;
  end;

  [TestFixture]
  TTestLanguageManager = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure GetInstance_Always_ReturnsSameSingleton;

    [Test]
    procedure SetLanguage_DifferentLanguage_NotifiesObservers;

    [Test]
    procedure SetLanguage_SameLanguage_DoesNotNotifyObservers;

    [Test]
    procedure IsRTL_ArabicLanguage_ReturnsTrue;

    [Test]
    procedure IsRTL_PortugueseLanguage_ReturnsFalse;
  end;

implementation

{ TFakeLanguageObserver }

procedure TFakeLanguageObserver.LanguageChanged(const ALang: string);
begin
  FNotifiedLanguage := ALang;
  Inc(FCallCount);
end;

{ TTestLanguageManager }

procedure TTestLanguageManager.Setup;
begin
  // Normally Singleton is tough to test sequentially if state persists.
  // We explicitly destroy it to start fresh for every test.
  TLanguageManager.DestroyLanguageManager;
end;

procedure TTestLanguageManager.TearDown;
begin
  TLanguageManager.DestroyLanguageManager;
end;

procedure TTestLanguageManager.GetInstance_Always_ReturnsSameSingleton;
var
  LInstance1, LInstance2: TLanguageManager;
begin
  //Action
  LInstance1 := TLanguageManager.GetInstance;
  LInstance2 := TLanguageManager.GetInstance;

  //Assert
  Assert.AreSame(LInstance1, LInstance2);
end;

procedure TTestLanguageManager.SetLanguage_DifferentLanguage_NotifiesObservers;
var
  LManager: TLanguageManager;
  LFakeObserver: TFakeLanguageObserver;
begin
  // Arrange
  LManager := TLanguageManager.GetInstance;
  LFakeObserver := TFakeLanguageObserver.Create;
  LManager.RegisterObserver(LFakeObserver);
  
  // Action - Initial is usually pt-BR. Changing to en-US.
  LManager.SetLanguage('en-US');

  //Assert
  Assert.AreEqual(1, LFakeObserver.CallCount);
  Assert.AreEqual('en-US', LFakeObserver.NotifiedLanguage);
  
  // Cleanup
  LManager.UnregisterObserver(LFakeObserver);
end;

procedure TTestLanguageManager.SetLanguage_SameLanguage_DoesNotNotifyObservers;
var
  LManager: TLanguageManager;
  LFakeObserver: TFakeLanguageObserver;
  LInitialLang: string;
begin
  // Arrange
  LManager := TLanguageManager.GetInstance;
  LInitialLang := LManager.CurrentLang;
  LFakeObserver := TFakeLanguageObserver.Create;
  LManager.RegisterObserver(LFakeObserver);
  
  // Action - Changing to SAME language
  LManager.SetLanguage(LInitialLang);

  //Assert
  Assert.AreEqual(0, LFakeObserver.CallCount, 'Observer should not be notified if language state hasn''''t changed.');
  
  // Cleanup
  LManager.UnregisterObserver(LFakeObserver);
end;

procedure TTestLanguageManager.IsRTL_ArabicLanguage_ReturnsTrue;
var
  LManager: TLanguageManager;
begin
  // Arrange
  LManager := TLanguageManager.GetInstance;
  LManager.SetLanguage('ar-SA');
  
  //Action
  var LRTL := LManager.IsRTL;

  //Assert
  Assert.IsTrue(LRTL, 'Arabic language (ar-SA) should be parsed as RTL');
end;

procedure TTestLanguageManager.IsRTL_PortugueseLanguage_ReturnsFalse;
var
  LManager: TLanguageManager;
begin
  // Arrange
  LManager := TLanguageManager.GetInstance;
  LManager.SetLanguage('pt-BR');
  
  //Action
  var LRTL := LManager.IsRTL;

  //Assert
  Assert.IsFalse(LRTL, 'Portuguese (pt-BR) is not RTL');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestLanguageManager);

end.

