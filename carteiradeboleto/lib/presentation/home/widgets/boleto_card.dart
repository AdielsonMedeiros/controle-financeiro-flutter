import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../data/models/boleto_model.dart';

class BoletoCard extends StatefulWidget {
  final Boleto boleto;
  final bool isOverdue;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  const BoletoCard({
    super.key,
    required this.boleto,
    required this.isOverdue,
    required this.onMarkAsPaid,
    required this.onDelete,
    required this.onSend,
  });

  @override
  State<BoletoCard> createState() => _BoletoCardState();
}

class _BoletoCardState extends State<BoletoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final statusColor =
        widget.isOverdue ? Colors.red.shade400 : Colors.orange.shade400;
    final statusText = widget.isOverdue ? 'ATRASADO' : 'PENDENTE';
    final statusIcon =
        widget.isOverdue ? PhosphorIcons.warningCircle : PhosphorIcons.clock;

    // Calcula dias restantes
    final daysUntilDue = widget.boleto.dueDate
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;
    final String daysText = widget.isOverdue
        ? '${daysUntilDue.abs()} ${daysUntilDue.abs() == 1 ? 'dia' : 'dias'} atrasado'
        : daysUntilDue == 0
            ? 'Vence hoje!'
            : 'Faltam $daysUntilDue ${daysUntilDue == 1 ? 'dia' : 'dias'}';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: widget.isOverdue
                ? LinearGradient(
                    colors: isDarkMode
                        ? [
                            Colors.red.shade900.withOpacity(0.3),
                            Colors.red.shade800.withOpacity(0.2)
                          ]
                        : [
                            Colors.red.shade50,
                            Colors.red.shade100.withOpacity(0.5)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isOverdue ? null : theme.cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: widget.isOverdue
                    ? Colors.red.withOpacity(0.15)
                    : Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: widget.isOverdue
                  ? Colors.red.withOpacity(0.4)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com título e valor
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ícone do boleto
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            PhosphorIcons.receipt,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Descrição e tag
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.boleto.description,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PhosphorIcons.tag,
                                      size: 14,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.boleto.tag,
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Status e valor
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 18, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Valor
                        Text(
                          currencyFormat.format(widget.boleto.value),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Data de vencimento
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.calendar,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(widget.boleto.dueDate),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                daysText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: widget.isOverdue
                                      ? Colors.red.shade600
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Detalhes expandidos
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          const SizedBox(height: 16),
                          if (widget.boleto.barcode?.isNotEmpty ?? false)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? theme.colorScheme.surfaceContainerHighest
                                    : theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.barcode,
                                    size: 20,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.boleto.barcode ?? '',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                        ],
                      ),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 12),
                    // Botões de ação
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(PhosphorIcons.trash,
                                  color: Colors.red.shade400, size: 22),
                              tooltip: 'Deletar',
                              onPressed: widget.onDelete,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.red.shade50.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(PhosphorIcons.paperPlaneTilt,
                                  color: theme.colorScheme.primary, size: 22),
                              tooltip: 'Enviar para amigo',
                              onPressed: widget.onSend,
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.primaryContainer
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(PhosphorIcons.checkCircle, size: 20),
                          label: const Text('Marcar como Pago'),
                          onPressed: widget.onMarkAsPaid,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
