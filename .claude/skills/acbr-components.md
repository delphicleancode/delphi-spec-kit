---
name: Projeto ACBr Patterns
description: Padrões arquiteturais, de injeção de dependência e de UI para o ecossistema Projeto ACBr (Automação Comercial Brasil) em Delphi.
---

# Padrões para Projeto ACBr

O **Projeto ACBr** é vital para emissão de NFe, CTe, NFCe, SAT, TEF e controle de balanças/impressoras fiscais/não fiscais no Brasil. Ele contém componentes fantásticos, porém devido à sua bagagem e histórico de forte acoplamento VCL que acompanha desenvolvedores antigos, as melhores práticas abaixo garantem manutenibilidade nas modernizações.

## 1. Regra de Ouro: Sem Acoplamento Visual Forte

Não instancie componentes `TACBrNFe`, `TACBrCTe`, `TACBrPosPrinter`, etc., diretamente nos Formulários View da interface (`.dfm`/`.fmx`). Isso quebra a arquitetura limpa, o MVC e dificulta imensamente os testes unitários.

### O Que Fazer?

Crie classes "Wrapper" de Serviço ou Infrasctructure Repositories que injetem (via construtor ou Service Locator) as configurações do sistema para a Engine Físcal.

```pascal
type
  INFeEmissor = interface
    ['{GUID}']
    function EmitirNota(ANota: TBaseNFeModel): TEmissionResult;
  end;

  TNFeEmissorACBr = class(TInterfacedObject, INFeEmissor)
  private
    FAcbrNFe: TACBrNFe;
    FConfig: IAppConfig;
    procedure ConfigureComponent;
  public
    constructor Create(AConfig: IAppConfig);
    destructor Destroy; override;
    function EmitirNota(ANota: TBaseNFeModel): TEmissionResult;
  end;
```

## 2. Abstraindo Bibliotecas de Assinatura e Criptografia (OpenSSL vs WinCrypt)

É uma boa prática documentada isolar também as bibliotecas para cada versão de SO caso o projeto seja cross-platform ou suporte VMs (ex Linux Docker vs Windows).
Configure isso *Sempre via código* dinamicamente dentro do wrapper referenciado na Sessão 1, nunca como design-time fixado, usando `LAcbrNFe.Configuracoes.Geral.SSLLib := libWinCrypt;` (ou OpenSSL).

## 3. Lidar com Callbacks e Eventos (ex: TEF)

O ACBrTEFD trabalha fortemente baseado em eventos do VCL (OnExibeMensagem, OnAguardaDigitacao). Implemente-os enviando eventos de barramento nativos ou definindo um "Handler" de UI genérico injetado na classe para que o código do componente permaneça na Camada de Negócios / Gateway, delegando apenas o "Desenhar na Tela" para interfaces específicas que podem ser substituídas em cenários Headless / API REST.

```pascal
  ITefPresentationHandler = interface
    procedure ShowTefMessage(const Msg: string);
    procedure ClearTefMessage;
  end;
```

## 4. Gerenciamento de Memória Dinâmico

Se você instanciar os componentes das sub-funções (ex: ACBrCEP) dinamicamente, evite vazamento de memória.

```pascal
function RetrieveAddress(const AZipCode: string): TAddressResponse;
var
  LCepComponent: TACBrCEP;
begin
  LCepComponent := TACBrCEP.Create(nil);
  try
    LCepComponent.WebService := wsViaCep;
    // Realiza a lógica
    LCepComponent.BuscarPorCEP(AZipCode);
    Result := MapToResponse(LCepComponent.Enderecos[0]);
  finally
    LCepComponent.Free;
  end;
end;
```

## 5. Prefixos dos Componentes

Ao lidar com os componentes design-time em `DataModules` criados para facilitar eventos, utilize estes mapeamentos:

| Componente ACBr | Descrição | Prefixo Típico |
|-----------------|-----------|----------------|
| `TACBrNFe` | Nota Fiscal Eletrônica | `acbrNfe` |
| `TACBrNFCe`| Nota de Consumidor | `acbrNfce` |
| `TACBrCTe` | Conhecimento de Transp. | `acbrCte` |
| `TACBrBoleto`| Boletos | `acbrBoleto` |
| `TACBrTEFD`| TEF | `acbrTef` |
| `TACBrPosPrinter`| Impressoras (EscPOS) | `acbrPosPrinter`|
| `TACBrSAT` | Equipamento SAT CF-e | `acbrSat` |
