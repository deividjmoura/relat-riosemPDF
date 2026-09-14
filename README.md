# Relatórios em PDF - Lear (RDP + Scrap)

Aplicativo **offline-first** para Android (iOS depois) que digitaliza os formulários de produção da Lear:

1. **RDP – Relatório de Produção do Corte** (F QUA-E 054 Rev.04)
2. **Registro de Scrap – Área Corte** (F QUA-E 102 Rev.04)

## Funcionalidades principais

### RDP (Relatório de Produção)
- Botão **Adicionar Setup** com todos os campos da linha inicial (PN da peça, taxa planejada, taxa real, quantidade, etc.)
- Campos de cabeçalho: MAQ, Operador, REG, Turno, Horímetro Inicial/Final, Observações
- **Cronômetros simultâneos** (vários ao mesmo tempo)
  - Ao parar um cronômetro pergunta: **“Essa pausa foi de que?”**
  - Os minutos são automaticamente lançados na coluna correta (TM / TP / PP)
- Finalizar turno → gera **PDF no layout do formulário oficial** (A4 landscape)

### Scrap
- Formulário completo (Terminal, Selo, Cabo)
- Leitura de **código de barras / QR** com a câmera
- Edição de item: quantidade, total e motivo (dropdown com códigos oficiais)
- PDF no layout do **F QUA-E 102** (duas colunas, seções TERMINAL / SELO / CABO + lista de motivos)

## Tecnologias
- Flutter 3.24+
- SQLite (sqflite) – dados offline
- pdf + printing – geração e compartilhamento de PDF
- mobile_scanner – leitura de códigos de barras
- provider – estado

## Como rodar

```bash
git clone https://github.com/deividjmoura/relat-riosemPDF.git
cd relat-riosemPDF
flutter create . --platforms=android   # só na 1ª vez
flutter pub get
flutter run   # celular USB ou emulador
```

## Roadmap

- [x] Estrutura inicial
- [x] Tela de Setup + formulário RDP
- [x] Multi-cronômetros com seleção de motivo
- [x] PDF do RDP (layout F QUA-E 054)
- [x] Tela de Scrap + scanner
- [x] Edição de item de scrap (qtd + motivo)
- [x] PDF do Scrap (layout F QUA-E 102)
- [ ] Histórico de relatórios salvos
- [ ] Exportação em lote
- [ ] Versão iOS

## Licença
Uso interno – Lear Corporation / privado.
