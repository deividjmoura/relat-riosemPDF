# Relatórios em PDF - Lear (RDP + Scrap)

Aplicativo **offline-first** para Android (iOS depois) que digitaliza os formulários de produção da Lear:

1. **RDP – Relatório de Produção do Corte**
2. **Registro de Scrap – Área Corte**

## Funcionalidades principais

### RDP (Relatório de Produção)
- Botão **Adicionar Setup** com todos os campos da linha inicial (PN da peça, taxa planejada, taxa real, quantidade, etc.)
- **Cronômetros simultâneos** (vários ao mesmo tempo)
  - Exemplo: Manutenção + Logística ao mesmo tempo
  - Ao parar um cronômetro pergunta: **“Essa pausa foi de que?”**
  - Os minutos são automaticamente lançados na coluna correta da tabela
- Finalizar turno → gera **PDF idêntico** ao formulário oficial
- Compartilhar ou salvar no celular

### Scrap
- Formulário completo (Terminal, Selo, Cabo)
- Leitura de **código de barras / QR** com a câmera do celular (preenche automaticamente Terminal/Item)
- Motivos de scrap (códigos 1410, 1411… 1509) já cadastrados
- Geração de PDF no formato oficial

## Tecnologias
- Flutter 3.24+
- SQLite (sqflite) – dados offline
- pdf + printing – geração e compartilhamento de PDF
- mobile_scanner – leitura de códigos de barras
- provider / riverpod (estado)

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

### 5. Subir alterações para o GitHub
```bash
git add .
git commit -m "feat: estrutura inicial do app RDP + Scrap"
git push origin main
```

> **Importante**: se o repositório estiver vazio, faça o primeiro push com:
> ```bash
> git branch -M main
> git push -u origin main
> ```

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
└── utils/
```

## Próximos passos (roadmap)

- [x] Estrutura inicial
- [ ] Tela de Setup + formulário RDP
- [ ] Multi-cronômetros com seleção de motivo
- [ ] Geração de PDF do RDP (layout idêntico)
- [ ] Tela de Scrap + scanner de código de barras
- [ ] Geração de PDF do Scrap
- [ ] Histórico de relatórios salvos
- [ ] Exportação em lote
- [ ] Versão iOS

## Licença
Uso interno – Lear Corporation / privado.
