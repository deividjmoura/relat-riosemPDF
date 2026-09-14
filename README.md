# Relatórios em PDF - Lear (RDP + Scrap)

Aplicativo **offline-first** para Android (iOS depois) que digitaliza os formulários de produção da Lear:

1. **RDP – Relatório de Produção do Corte** (F QUA-E 054 Rev.04)
2. **Registro de Scrap – Área Corte** (F QUA-E 102 Rev.04)

## Funcionalidades principais

### RDP (Relatório de Produção)
- Botão **Adicionar Setup** com todos os campos da linha inicial (PN da peça, taxa planejada, taxa real, quantidade, etc.)
- Campos de cabeçalho: MAQ, Operador, REG, Turno, Horímetro Inicial/Final, Observações
- **Cronômetros simultâneos** (vários ao mesmo tempo)
  - Exemplo: Manutenção + Logística ao mesmo tempo
  - Ao parar um cronômetro pergunta: **“Essa pausa foi de que?”**
  - Os minutos são automaticamente lançados na coluna correta (TM / TP / PP)
- Finalizar turno → gera **PDF no layout do formulário oficial** (A4 landscape)
- Compartilhar ou salvar no celular

### Scrap
- Formulário completo (Terminal, Selo, Cabo)
- Leitura de **código de barras / QR** com a câmera do celular (preenche automaticamente Terminal/Item)
- Motivos de scrap (códigos 1410, 1411… 1509) já cadastrados
- Geração de PDF no formato oficial (em evolução)

## Tecnologias
- Flutter 3.24+
- SQLite (sqflite) – dados offline
- pdf + printing – geração e compartilhamento de PDF
- mobile_scanner – leitura de códigos de barras
- provider – estado

## Como clonar e subir o projeto

### 1. Clone o repositório
```bash
git clone https://github.com/deividjmoura/relat-riosemPDF.git
cd relat-riosemPDF
```

### 2. Instale as dependências
```bash
flutter pub get
```

### 3. Rode no Android
```bash
flutter run
```

### 4. Para gerar o APK de release
```bash
flutter build apk --release
```
O arquivo fica em: `build/app/outputs/flutter-apk/app-release.apk`

## Estrutura de pastas

```
lib/
├── main.dart
├── app.dart
├── models/               # Modelos de dados (RDP, Scrap, Timer)
├── services/             # Banco, PDF, Barcode
├── screens/
│   ├── home_screen.dart
│   ├── rdp/              # Telas do Relatório de Produção
│   └── scrap/            # Telas do Registro de Scrap
├── widgets/              # Cronômetros, dialogs
└── utils/                # Categorias oficiais TM/TP/PP
```

## Próximos passos (roadmap)

- [x] Estrutura inicial
- [x] Tela de Setup + formulário RDP
- [x] Multi-cronômetros com seleção de motivo
- [x] Geração de PDF do RDP (layout alinhado ao F QUA-E 054)
- [x] Tela de Scrap + scanner de código de barras
- [ ] Geração de PDF do Scrap **idêntico** ao F QUA-E 102
- [ ] Edição completa de item de scrap (qtd + motivo)
- [ ] Histórico de relatórios salvos
- [ ] Exportação em lote
- [ ] Versão iOS

## Licença
Uso interno – Lear Corporation / privado.
