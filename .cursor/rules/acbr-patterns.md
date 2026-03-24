---
description: "Projeto ACBr - Boas práticas, prefixos, injeção de dependências e isolamento de componentes fiscais"
globs: ["**/*.pas", "**/*.dfm"]
alwaysApply: false
---

# Projeto ACBr — Cursor Rules

Use estas regras ao trabalhar com componentes da suíte **Projeto ACBr** (Automação Comercial Brasil) em aplicações Delphi.

## Isolamento e Padrões (SOLID)

- ❌ **Não instancie ou acople os componentes ACBr diretamente nos formulários de UI** (ex: colocar um `TACBrNFe` dentro do `TfrmEmissao`).
- ✅ **Crie abstrações ou classes de Serviço** (ex: `TNFeService`) em Módulos de Domínio/Infra que encapsulem o `TACBrNFe`.
- O formulário só deve disparar uma interface, por exemplo: `INFeService.Emitir(Nota)`.

## Gerenciamento de Memória

- Componentes ACBr criados dinamicamente em Services **sempre** devem ser liberados apropriadamente (Try/Finally ou criados como Child de DataModules mantidos por injeção).
  
```pascal
// Exemplo de criação dinâmica encapsulada
var
  LAcbrNFe: TACBrNFe;
begin
  LAcbrNFe := TACBrNFe.Create(nil);
  try
    // Configurações e uso
    LAcbrNFe.Configuracoes.Certificados.NumeroSerie := 'XYZ';
  finally
    LAcbrNFe.Free;
  end;
end;
```

## Configurações Dinâmicas

- Evite ler de arquivos `.ini` via UI. Carregue as configurações via uma camada de configuração do sistema (`IConfiguration`) e injete-a no serviço que encapsula a ACBr.

## Tratamento de Erros e Retornos

- Capture exceções específicas do ACBr quando possível.
- Converta retornos longos do componente (ex: status, motivos de rejeição) em Object Results/Records da aplicação em vez de prender a aplicação à string formatação natural do componente.

## Convenções de Prefixos (UI/Design Time)

Se precisar dropar o componente ou instanciá-lo em tempo de execução, siga estas convenções de nomes:
- **TACBrNFe:** `acbrNFe`
- **TACBrCTe:** `acbrCTe`
- **TACBrBoleto:** `acbrBoleto`
- **TACBrTEFD:** `acbrTef`
- **TACBrPosPrinter:** `acbrPosPrinter`
- **TACBrECF:** `acbrEcf`
- **TACBrCEP:** `acbrCep`
