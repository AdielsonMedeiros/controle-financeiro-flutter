# 🧪 Guia de Testes - Controle Financeiro

## 📋 Estrutura de Testes

```
test/
├── models/                    # Testes de modelos de dados
│   ├── financial_transaction_test.dart
│   └── budget_test.dart
├── services/                  # Testes de serviços
│   └── export_service_test.dart
├── widgets/                   # Testes de widgets
│   └── animated_counter_test.dart
├── integration/               # Testes de integração
│   └── app_flow_test.dart
└── validation/                # Testes de validação
    └── data_validation_test.dart
```

## 🚀 Como Executar os Testes

### Executar todos os testes
```bash
flutter test
```

### Executar testes específicos
```bash
# Testar apenas modelos
flutter test test/models/

# Testar apenas validações
flutter test test/validation/

# Testar arquivo específico
flutter test test/models/financial_transaction_test.dart
```

### Executar com cobertura
```bash
flutter test --coverage
```

### Ver relatório de cobertura (requer lcov)
```bash
# Windows (instalar Perl + lcov)
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

## ✅ Checklist Pré-Publicação

### 1. Testes Unitários
- [x] Modelos de dados (FinancialTransaction, Budget)
- [x] Lógica de cálculos financeiros
- [x] Validações de entrada

### 2. Testes de Widgets
- [x] Renderização de componentes
- [x] Animações básicas
- [x] Estados de loading

### 3. Testes de Integração
- [x] Formatação de moeda
- [x] Cálculos de porcentagem
- [x] Filtros de data
- [x] Ordenação de dados

### 4. Validações
- [x] Valores monetários
- [x] Descrições e categorias
- [x] Datas e períodos
- [x] Tipos de transação
- [x] Formato de email

## 🎯 Cobertura de Testes

### Áreas Testadas
- ✅ Modelos de dados
- ✅ Lógica de negócio
- ✅ Cálculos financeiros
- ✅ Validações de entrada
- ✅ Formatação de dados
- ✅ Filtros e ordenação

### Áreas Não Testadas (Requerem Firebase Mock)
- ⚠️ Autenticação Firebase
- ⚠️ Operações Firestore
- ⚠️ Notificações push
- ⚠️ Upload de arquivos

## 🔍 Testes Manuais Recomendados

Antes de publicar, teste manualmente:

### Funcionalidades Principais
1. **Autenticação**
   - [ ] Login com email/senha
   - [ ] Login com Google
   - [ ] Login com GitHub
   - [ ] Recuperação de senha
   - [ ] Logout

2. **Transações**
   - [ ] Adicionar receita
   - [ ] Adicionar despesa
   - [ ] Editar transação
   - [ ] Excluir transação
   - [ ] Filtrar por período
   - [ ] Buscar transações

3. **Orçamentos**
   - [ ] Criar orçamento
   - [ ] Editar orçamento
   - [ ] Ver progresso
   - [ ] Alertas de limite

4. **Relatórios**
   - [ ] Gráfico mensal
   - [ ] Gráfico por categoria
   - [ ] Exportar PDF
   - [ ] Exportar CSV
   - [ ] Compartilhar relatório

5. **Interface**
   - [ ] Tema claro/escuro
   - [ ] Animações suaves
   - [ ] Scroll fluido
   - [ ] Responsividade

6. **Notificações**
   - [ ] Alerta de orçamento
   - [ ] Resumo semanal
   - [ ] Resumo mensal
   - [ ] Lembretes

### Testes de Dispositivo
- [ ] Android 8.0+ (API 26+)
- [ ] Diferentes tamanhos de tela
- [ ] Modo retrato e paisagem
- [ ] Conexão lenta
- [ ] Modo offline

### Testes de Performance
- [ ] App inicia em < 3 segundos
- [ ] Scroll a 60 FPS
- [ ] Sem travamentos
- [ ] Consumo de memória aceitável
- [ ] Tamanho do APK/AAB razoável

## 🐛 Debugging

### Ver logs durante testes
```bash
flutter test --verbose
```

### Executar em modo debug
```bash
flutter run --debug
flutter run --profile  # Para análise de performance
```

### Analisar performance
```bash
flutter run --profile
# Abrir DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## 📊 Métricas de Qualidade

### Antes de Publicar
- ✅ Todos os testes passando
- ✅ Sem warnings no build
- ✅ Sem erros de lint
- ✅ App funciona offline (básico)
- ✅ Dados sincronizam corretamente
- ✅ Exportação funciona
- ✅ Notificações funcionam

### Comandos Úteis
```bash
# Verificar problemas
flutter analyze

# Formatar código
flutter format .

# Limpar build
flutter clean

# Verificar dependências
flutter pub outdated
```

## 🎉 Pronto para Publicar!

Quando todos os testes passarem e a checklist estiver completa:

```bash
flutter build appbundle --release
```

O arquivo estará em: `build/app/outputs/bundle/release/app-release.aab`

---

**Dica**: Execute `flutter test` antes de cada commit para garantir qualidade contínua!
