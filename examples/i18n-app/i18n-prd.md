Create a complete and functional example of a Delphi VCL application using the i18n (internationalization) pattern with Observer Pattern.

## FUNCTIONAL REQUIREMENTS

The application must contain:

- Main form with MenuBar (File, Registrations, Sales, Settings, Help)
- 3 registration forms: Customers, Products, Sales
- SQLite database with FireDAC (DDL script included)
- Settings menu > Language with PT-BR/EN-US selection

## MANDATORY TECHNICAL STRUCTURE

### 1. **Observer Pattern for i18n**

```
TLanguageObserver = interface
  procedure LanguageChanged(ALang: string);
end;

TLanguageManager = class
private
  FObservers: TList<TLanguageObserver>;
  FCurrentLang: string;
  procedure NotifyObservers;
public
  procedure RegisterObserver(AObserver: TLanguageObserver);
  procedure UnregisterObserver(AObserver: TLanguageObserver);  
  procedure SetLanguage(ALang: string);
  function GetString(const AKey: string): string;
end;
```

### 2. **JSON Resource Files**

```
resources/
├── pt-BR.json → {"app.title": "Sistema de Vendas", "client.cadastro": "Cadastro de Clientes"}
└── en-US.json → {"app.title": "Sales System", "client.cadastro": "Customer Registration"}
```

### 3. **Visual Components**

```
- TMenuItem para cada ação traduzida
- TLabels, TButtons, TGroupBox com Caption dinâmicos  
- TStatusBar com mensagens traduzidas
- Formatação de moeda/data por cultura (PT-BR: R$ 1.234,56 | EN: $1,234.56)
```

## IMPLEMENTATION BY FORM

### FormPrincipal (implements TLanguageObserver)

```
protected
  procedure LanguageChanged(ALang: string); override;
private
  procedure UpdateCaptions;
public
  constructor Create(AOwner: TComponent); override;
```

### CustomerForm, ProductForm, VendaForm

```
- Todos implementam TLanguageObserver
- UpdateCaptions() recarrega TODOS captions/labels
- Campos obrigatórios com asterisco (*) traduzido
```

## DATABASE

```
CREATE TABLE clientes (
  id INTEGER PRIMARY KEY,
  nome VARCHAR(100),
  email VARCHAR(100),
  criado_em DATETIME
);
-- + tabelas produtos, vendas
```

## LANGUAGE CHANGE FLOW

```
1. Menu Config > Idioma > [PT-BR|EN-US]
2. LanguageManager.SetLanguage('pt-BR')
3. NotifyObservers() → todos forms atualizam INSTANTANEAMENTE  
4. StatusBar mostra "Idioma alterado para Português"
```

## DELIVERABLES EXPECTED IN THE CODE

```
[ ] Unit LanguageManager.pas (Singleton Observer)
[ ] Unit Resources.pas (JSON loader)
[ ] 4 Forms completos (.pas + .dfm)
[ ] Script SQLite (.sql)
[ ] 2 arquivos JSON de recursos
[ ] Formatação regional (GetLocaleFormatSettings)
[ ] Tratamento de erro (try/except)
[ ] Hotkeys traduzidos (Ctrl+N = Novo)
```

## MANDATORY GOOD PRACTICES

```
- NENHUM hard-coded string no código
- Chaves de recurso com padrão: "form.campo.nome"
- Fallback para PT-BR se idioma não existir  
- Cache de recursos carregados
- Suporte RTL (Right-to-Left) preparado
```

Create **complete and compilable** code following this specification exactly, including all units, forms and resources.
