---
name: "DevExpress/DEXT Components"
description: "Padrões para uso de componentes DevExpress (DEXT) em aplicações Delphi VCL"
---

# DevExpress (DEXT) Components — Skill

Use esta skill ao desenvolver interfaces ricas com componentes **DevExpress** (DEXT) para Delphi VCL.

## Quando Usar

- Ao criar grids avançados com `TcxGrid`
- Ao usar `TcxDBTreeList` para estruturas hierárquicas
- Ao implementar layout managers (`TdxLayoutControl`)
- Ao customizar skins e themes

## Componentes Principais

| Componente | Uso | Prefixo |
|-----------|-----|---------|
| `TcxGrid` | Grid avançado com agrupamento, filtros, sumários | `grd` |
| `TcxGridDBTableView` | View tabular data-aware | `tvw` |
| `TcxGridDBBandedTableView` | View com bandas/colunas agrupadas | `btvw` |
| `TcxGridDBCardView` | View de cards | `cvw` |
| `TcxDBTreeList` | TreeList data-aware | `trl` |
| `TdxLayoutControl` | Layout manager responsivo | `lyt` |
| `TdxLayoutGroup` | Grupo dentro de layout | `lgrp` |
| `TdxLayoutItem` | Item dentro de layout | `litm` |
| `TcxDBTextEdit` | Edit text data-aware | `edt` |
| `TcxDBComboBox` | ComboBox data-aware | `cmb` |
| `TcxDBDateEdit` | Date picker data-aware | `dte` |
| `TcxDBCurrencyEdit` | Editor monetário data-aware | `cur` |
| `TcxDBCheckBox` | Checkbox data-aware | `chk` |
| `TcxDBLookupComboBox` | Lookup combo data-aware | `lcb` |
| `TcxDBMemo` | Memo data-aware | `mmo` |
| `TdxBarManager` | Barra de ferramentas/ribbon | `bar` |
| `TdxRibbon` | Ribbon UI | `rbn` |
| `TdxNavBar` | Barra de navegação | `nav` |
| `TdxSkinController` | Controller de skins | `skn` |
| `TcxPageControl` | PageControl avançado | `pgc` |
| `TcxGroupBox` | GroupBox estilizado | `grp` |

## Configuração de TcxGrid

```pascal
// Criação programática de colunas
procedure TfrmCustomerList.ConfigureGrid;
var
  LView: TcxGridDBTableView;
begin
  LView := grdCustomers.Views[0] as TcxGridDBTableView;
  LView.DataController.DataSource := dsCustomers;

  // Configurar comportamento
  LView.OptionsData.Editing := False;        // Somente leitura
  LView.OptionsData.Deleting := False;
  LView.OptionsData.Inserting := False;
  LView.OptionsView.GroupByBox := True;       // Agrupamento visual
  LView.OptionsView.Footer := True;          // Rodapé com sumários
  LView.OptionsView.Indicator := True;       // Indicador de linha
  LView.OptionsCustomize.ColumnFiltering := True;
  LView.OptionsCustomize.ColumnSorting := True;
  LView.OptionsSelection.MultiSelect := True;

  // Configurar colunas individualmente
  ConfigureColumn(LView.GetColumnByFieldName('name'), 'Nome', 200);
  ConfigureColumn(LView.GetColumnByFieldName('cpf'), 'CPF', 120);
  ConfigureColumn(LView.GetColumnByFieldName('email'), 'E-mail', 250);
end;

procedure TfrmCustomerList.ConfigureColumn(
  AColumn: TcxGridDBColumn; const ACaption: string; AWidth: Integer);
begin
  if not Assigned(AColumn) then Exit;
  AColumn.Caption := ACaption;
  AColumn.Width := AWidth;
  AColumn.HeaderAlignmentHorz := taCenter;
end;
```

## Sumários no Grid

```pascal
// Sumário no Footer
procedure ConfigureFooterSummary(AView: TcxGridDBTableView);
var
  LSummary: TcxGridDBTableSummaryItem;
begin
  AView.DataController.Summary.FooterSummaryItems.Clear;

  LSummary := AView.DataController.Summary.FooterSummaryItems.Add
    as TcxGridDBTableSummaryItem;
  LSummary.FieldName := 'value';
  LSummary.Kind := skSum;
  LSummary.Format := 'Total: R$ #,##0.00';
  LSummary.Column := AView.GetColumnByFieldName('value');

  LSummary := AView.DataController.Summary.FooterSummaryItems.Add
    as TcxGridDBTableSummaryItem;
  LSummary.FieldName := 'id';
  LSummary.Kind := skCount;
  LSummary.Format := 'Registros: %d';
  LSummary.Column := AView.GetColumnByFieldName('name');
end;
```

## TdxLayoutControl (Layout Responsivo)

```pascal
// Organização de formulário com LayoutControl
// Vantagens: responsivo, reposiciona automaticamente, visual consistente

procedure TfrmCustomerEdit.ConfigureLayout;
begin
  lytMain.BeginUpdate;
  try
    // Grupo de dados pessoais
    lgrpPersonal.Caption := 'Dados Pessoais';
    lgrpPersonal.LayoutDirection := ldHorizontal;

    // Grupo de endereço
    lgrpAddress.Caption := 'Endereço';
    lgrpAddress.LayoutDirection := ldHorizontal;

    // Configurar itens
    litmName.Control := edtName;
    litmName.CaptionOptions.Text := 'Nome:';
    litmName.CaptionOptions.Width := 80;
  finally
    lytMain.EndUpdate;
  end;
end;
```

## Skinning / Temas

```pascal
// Aplicar skin globalmente
uses
  dxSkinsCore,
  dxSkinOffice2019Colorful;  // Skin específico

procedure TfrmMain.ApplySkin;
begin
  // Via SkinController (recomendado)
  sknController.NativeStyle := False;
  sknController.SkinName := 'Office2019Colorful';

  // OU programaticamente
  cxLookAndFeelController.NativeStyle := False;
  cxLookAndFeelController.SkinName := 'Office2019Colorful';
end;

// Skins populares: 'Office2019Colorful', 'WXI', 'Metropolis',
// 'MetropolisDark', 'TheBezier', 'Fluent', 'Office2019DarkGray'
```

## Filtros no Grid

```pascal
// Filtro programático
procedure TfrmCustomerList.ApplyFilter(const AField, AValue: string);
var
  LView: TcxGridDBTableView;
begin
  LView := grdCustomers.Views[0] as TcxGridDBTableView;
  LView.DataController.Filter.Root.Clear;
  LView.DataController.Filter.Root.AddItem(
    LView.GetColumnByFieldName(AField),
    foLike,
    '%' + AValue + '%',
    AValue
  );
  LView.DataController.Filter.Active := True;
end;

// Limpar filtro
procedure TfrmCustomerList.ClearFilter;
begin
  (grdCustomers.Views[0] as TcxGridDBTableView)
    .DataController.Filter.Root.Clear;
end;
```

## Exportação de Grid

```pascal
uses
  cxGridExportLink;

// Exportar para Excel
procedure TfrmCustomerList.ExportToExcel;
begin
  cxGridExportLink.ExportGridToXLSX(
    'customers.xlsx',
    grdCustomers,
    False,   // AExpand
    True,    // AUseNativeFormat
    True     // AShowProgress
  );
end;

// Exportar para PDF
procedure TfrmCustomerList.ExportToPDF;
begin
  cxGridExportLink.ExportGridToPDF(
    'customers.pdf',
    grdCustomers
  );
end;
```

## Convenções DEXT

| Aspecto | Convenção |
|---------|-----------|
| **Prefixos** | Seguir tabela acima (`grd`, `tvw`, `lyt`, etc.) |
| **Skins** | Usar `TdxSkinController` no form principal |
| **Layout** | Preferir `TdxLayoutControl` a posicionamento manual |
| **Grid** | Configurar no `FormCreate`, nunca no design-time para colunas dinâmicas |
| **Filtros** | Usar `DataController.Filter` — não filtrar via SQL quando possível |
| **Sumários** | Configurar `FooterSummaryItems` ao invés de calcular manualmente |
| **Exports** | Usar `cxGridExportLink` — não reimplementar exportação |

## Checklist para Projetos DEXT

- [ ] `TdxSkinController` configurado no form principal?
- [ ] Grids configurados com `OptionsData` (read-only quando apropriado)?
- [ ] Sumários de footer configurados com formatos BR (`R$ #,##0.00`)?
- [ ] `TdxLayoutControl` usado para formulários de edição?
- [ ] Colunas do grid com `Caption`, `Width` e `Alignment`?
- [ ] Filtros usando `DataController.Filter` (não SQL)?
- [ ] Exportação via `cxGridExportLink`?
- [ ] Prefixos de componentes seguindo a tabela padrão?
