# 💰 Controle Financeiro

Um aplicativo Flutter completo para gerenciamento de finanças pessoais, disponível na Google Play Store.

## 📱 Funcionalidades

- ✅ **Gestão de Transações**: Registre receitas e despesas com categorias personalizáveis
- 📊 **Relatórios Visuais**: Gráficos interativos de evolução mensal e análise por categoria
- 🎯 **Orçamentos**: Defina e monitore orçamentos por categoria
- 📈 **Insights Automáticos**: Análises comparativas e sugestões inteligentes
- 🔔 **Notificações**: Alertas de orçamento e resumos periódicos
- 📤 **Exportação**: Exporte seus dados em CSV ou PDF
- 🌓 **Tema Claro/Escuro**: Interface adaptável
- 🔐 **Autenticação Segura**: Login com email, Google ou GitHub
- ☁️ **Sincronização na Nuvem**: Dados salvos no Firebase

## 🚀 Tecnologias

- **Flutter** 3.0+
- **Firebase** (Auth, Firestore, Crashlytics, Cloud Messaging)
- **Provider** (Gerenciamento de estado)
- **FL Chart** (Gráficos)
- **Local Notifications** (Notificações)

## 📦 Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/controlefinanceiro.git
cd controlefinanceiro
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure o Firebase:
   - Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
   - Adicione os arquivos de configuração:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. Execute o app:
```bash
flutter run
```

## 🔧 Build para Produção

### Android
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

## 📝 Versão Atual

**v0.0.2+4** - Disponível na Play Store

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.

## 📄 Licença

Este projeto está sob a licença MIT.

## 👨‍💻 Desenvolvedor

Desenvolvido por Adielson Tech

---

⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!
