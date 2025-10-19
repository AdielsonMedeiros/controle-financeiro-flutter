# 🎨 Guia de Widgets Modernos

## Componentes Criados

### 1. **GlassCard** - Efeito Glassmorphism
```dart
GlassCard(
  padding: EdgeInsets.all(20),
  blur: 10,
  child: Text('Conteúdo'),
)
```

### 2. **AnimatedCounter** - Contador Animado
```dart
AnimatedCounter(
  value: 1234.56,
  prefix: 'R\$ ',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
)
```

### 3. **AnimatedCard** - Card com Animações
```dart
AnimatedCard(
  padding: EdgeInsets.all(20),
  onTap: () => print('Clicado'),
  gradient: [Colors.blue, Colors.purple],
  child: Text('Conteúdo'),
)
```

### 4. **StatsCard** - Card de Estatísticas
```dart
StatsCard(
  title: 'Receitas',
  value: 5000.00,
  icon: Icons.arrow_upward_rounded,
  color: Colors.green,
  percentage: 12.5, // Opcional
  subtitle: 'Este mês', // Opcional
)
```

### 5. **TransactionItem** - Item de Transação
```dart
TransactionItem(
  transaction: transaction,
  onEdit: () => editTransaction(),
  onDelete: () => deleteTransaction(),
)
```

### 6. **AnimatedFAB** - FAB Animado
```dart
AnimatedFAB(
  onPressed: () => addTransaction(),
  icon: Icons.add_rounded,
  label: 'Nova',
)
```

### 7. **ShimmerLoading** - Loading Moderno
```dart
ShimmerLoading(
  width: 200,
  height: 50,
  borderRadius: BorderRadius.circular(12),
)
```

## 🎨 Paleta de Cores (AppColors)

### Light Theme
- Primary: `#6366F1` (Indigo)
- Secondary: `#10B981` (Verde Esmeralda)
- Accent: `#F59E0B` (Âmbar)
- Background: `#F8FAFC`

### Dark Theme
- Primary: `#818CF8` (Indigo Claro)
- Secondary: `#34D399` (Verde Neon)
- Accent: `#FBBF24` (Âmbar Claro)
- Background: `#0F172A`

## ⚡ Performance

Todos os componentes são otimizados com:
- `const` constructors quando possível
- `RepaintBoundary` para widgets complexos
- Animações com `vsync` para sincronização
- Curves suaves (easeOut, elasticOut)

## 🚀 Como Usar

1. Importe o widget necessário
2. Use com as propriedades desejadas
3. Personalize cores e animações conforme necessário

## 💡 Dicas

- Use `AnimatedCard` para cards interativos
- Use `GlassCard` para efeitos modernos
- Use `StatsCard` para métricas importantes
- Use `ShimmerLoading` durante carregamentos
