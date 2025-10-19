

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';
import '../../theme/financial_gradients.dart';

enum FilterType { month, year, custom }

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = true;
  Map<String, double> _metricsData = {};
  double _totalValue = 0;
  FilterType _activeFilter = FilterType.month;

  @override
  void initState() {
    super.initState();
    _handleFilterChange(FilterType.month);
  }

  void _handleFilterChange(FilterType filter) {
    final now = DateTime.now();
    setState(() {
      _activeFilter = filter;
      switch (filter) {
        case FilterType.month:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case FilterType.year:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case FilterType.custom:
          break;
      }
    });
    _fetchMetricsData();
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final safeEndDate = _endDate.isAfter(now) ? now : _endDate;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _startDate, end: safeEndDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
            picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _activeFilter = FilterType.custom;
      });
      _fetchMetricsData();
    }
  }

  Future<void> _fetchMetricsData() async {
    setState(() {
      _isLoading = true;
      _metricsData = {};
      _totalValue = 0;
    });

    final boletos =
        await _firestoreService.getPaidBoletosByDateRange(_startDate, _endDate);
    final Map<String, double> dataMap = {};
    double total = 0;

    for (var boleto in boletos) {
      dataMap.update(boleto.tag, (value) => value + boleto.value,
          ifAbsent: () => boleto.value);
      total += boleto.value;
    }

    if (mounted) {
      setState(() {
        _metricsData = dataMap;
        _totalValue = total;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas de Gastos'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF059669).withOpacity(0.1),
                const Color(0xFFD97706).withOpacity(0.05),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinancialGradients.backgroundSubtle(context),
        ),
        child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFilterChips(),
          const SizedBox(height: 24),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isLoading ? 0.5 : 1.0,
            child: Column(
              children: [
                Text(
                  'Exibindo de ${DateFormat('dd/MM/yy').format(_startDate)} a ${DateFormat('dd/MM/yy').format(_endDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                          .format(_totalValue),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildChart(),
          const SizedBox(height: 32),
          if (!_isLoading && _metricsData.isNotEmpty) ...[
            Text('Resumo por Tag',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            ..._generateLegend(_metricsData),
          ]
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        FilterChip(
          avatar: const Icon(PhosphorIcons.calendarFill),
          label: const Text('Este Mês'),
          selected: _activeFilter == FilterType.month,
          onSelected: (selected) {
            if (selected) _handleFilterChange(FilterType.month);
          },
        ),
        FilterChip(
          avatar: const Icon(PhosphorIcons.calendarBlankFill),
          label: const Text('Este Ano'),
          selected: _activeFilter == FilterType.year,
          onSelected: (selected) {
            if (selected) _handleFilterChange(FilterType.year);
          },
        ),
        FilterChip(
          avatar: const Icon(PhosphorIcons.calendarPlusFill),
          label: const Text('Período'),
          selected: _activeFilter == FilterType.custom,
          onSelected: (_) => _selectCustomDateRange(context),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_metricsData.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(PhosphorIcons.chartPieSliceFill,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text('Nenhum boleto pago encontrado para o período.',
                  textAlign: TextAlign.center,
                  
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: _generateChartSections(_metricsData),
          centerSpaceRadius: 60,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateChartSections(Map<String, double> data) {
    final List<Color> colors = [
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF0891B2),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF34D399),
      const Color(0xFF0EA5E9),
      const Color(0xFFFBBF24),
      const Color(0xFF38BDF8),
      const Color(0xFF22D3EE)
    ];
    int colorIndex = 0;

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final percentage =
          (_totalValue > 0) ? (entry.value / _totalValue) * 100 : 0.0;
      return PieChartSectionData(
        color: colors[colorIndex++ % colors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors
              .white, 
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();
  }

  List<Widget> _generateLegend(Map<String, double> data) {
    final List<Color> colors = [
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF0891B2),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF34D399),
      const Color(0xFF0EA5E9),
      const Color(0xFFFBBF24),
      const Color(0xFF38BDF8),
      const Color(0xFF22D3EE)
    ];
    int colorIndex = 0;

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final item = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[colorIndex++ % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(entry.key, style: const TextStyle(fontSize: 16))),
            Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                    .format(entry.value),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
      return item;
    }).toList();
  }
}
