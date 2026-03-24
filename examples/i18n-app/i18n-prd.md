Crie um exemplo completo e funcional de aplicação Delphi VCL utilizando o padrão i18n (internationalization) com Observer Pattern.

## REQUISITOS FUNCIONAIS

A aplicação deve conter:

- Form principal com MenuBar (Arquivo, Cadastros, Vendas, Configurações, Ajuda)
- 3 forms de cadastro: Clientes, Produtos, Vendas  
- Banco SQLite com FireDAC (script DDL incluído)
- Menu Configurações > Idioma com seleção PT-BR/EN-US

## ESTRUTURA TÉCNICA OBRIGATÓRIA

### 1. **Padrão Observer para i18n**

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

### 2. **Arquivos de Recursos JSON**

```
resources/
├── pt-BR.json → {"app.title": "Sistema de Vendas", "client.cadastro": "Cadastro de Clientes"}
└── en-US.json → {"app.title": "Sales System", "client.cadastro": "Customer Registration"}
```

### 3. **Componentes Visual**

```
- TMenuItem para cada ação traduzida
- TLabels, TButtons, TGroupBox com Caption dinâmicos  
- TStatusBar com mensagens traduzidas
- Formatação de moeda/data por cultura (PT-BR: R$ 1.234,56 | EN: $1,234.56)
```

## IMPLEMENTAÇÃO POR FORM

### FormPrincipal (implementa TLanguageObserver)

```
protected
  procedure LanguageChanged(ALang: string); override;
private
  procedure UpdateCaptions;
public
  constructor Create(AOwner: TComponent); override;
```

### FormCliente, FormProduto, FormVenda

```
- Todos implementam TLanguageObserver
- UpdateCaptions() recarrega TODOS captions/labels
- Campos obrigatórios com asterisco (*) traduzido
```

## BANCO DE DADOS

```
CREATE TABLE clientes (
  id INTEGER PRIMARY KEY,
  nome VARCHAR(100),
  email VARCHAR(100),
  criado_em DATETIME
);
-- + tabelas produtos, vendas
```

## FLUXO DE MUDANÇA DE IDIOMA

```
1. Menu Config > Idioma > [PT-BR|EN-US]
2. LanguageManager.SetLanguage('pt-BR')
3. NotifyObservers() → todos forms atualizam INSTANTANEAMENTE  
4. StatusBar mostra "Idioma alterado para Português"
```

## DELIVERABLES ESPERADOS NO CÓDIGO

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

## BOAS PRÁTICAS OBRIGATÓRIAS

```
- NENHUM hard-coded string no código
- Chaves de recurso com padrão: "form.campo.nome"
- Fallback para PT-BR se idioma não existir  
- Cache de recursos carregados
- Suporte RTL (Right-to-Left) preparado
```

Crie o código **completo e compilável** seguindo exatamente esta especificação, incluindo todas as units, forms e recursos.
