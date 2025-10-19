import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../data/models/boleto_model.dart';
import '../../../theme/financial_gradients.dart';

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
        widget.isOverdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
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
                            const Color(0xFFEF4444).withOpacity(0.2),
                            const Color(0xFFDC2626).withOpacity(0.1)
                          ]
                        : [
                            const Color(0xFFFEF2F2),
                            const Color(0xFFFEE2E2)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: isDarkMode
                        ? [
                            const Color(0xFFF59E0B).withOpacity(0.15),
                            const Color(0xFFD97706).withOpacity(0.08)
                          ]
                        : [
                            const Color(0xFFFFFBEB),
                            const Color(0xFFFEF3C7)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: widget.isOverdue
                    ? const Color(0xFFEF4444).withOpacity(0.2)
                    : theme.colorScheme.primary.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: widget.isOverdue
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : theme.colorScheme.primary.withOpacity(0.1),
              width: 1,
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
                            gradient: widget.isOverdue
                                ? FinancialGradients.error
                                : LinearGradient(
                                    colors: [
                                      const Color(0xFFD97706).withOpacity(0.2),
                                      const Color(0xFFF59E0B).withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            PhosphorIcons.receiptFill,
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
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF059669).withOpacity(0.15),
                                      const Color(0xFF0891B2).withOpacity(0.1),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PhosphorIcons.tagFill,
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
                            color: widget.isOverdue 
                                ? const Color(0xFFEF4444) // Vermelho para atrasado
                                : const Color(0xFFF59E0B), // Amarelo para pendente
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
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.15),
                                  theme.colorScheme.tertiary.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              PhosphorIcons.calendarCheckFill,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
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
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.secondary.withOpacity(0.15),
                                          theme.colorScheme.tertiary.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      PhosphorIcons.barcodeFill,
                                      size: 18,
                                      color: theme.colorScheme.secondary,
                                    ),
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
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400.withOpacity(0.2),
                                    Colors.red.shade300.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(PhosphorIcons.trashFill,
                                    color: Colors.red.shade400, size: 22),
                                tooltip: 'Deletar',
                                onPressed: widget.onDelete,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.2),
                                    theme.colorScheme.tertiary.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(PhosphorIcons.paperPlaneTiltFill,
                                    color: theme.colorScheme.primary, size: 22),
                                tooltip: 'Enviar para amigo',
                                onPressed: widget.onSend,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: FinancialGradients.success,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(PhosphorIcons.checkCircleFill, size: 20),
                            label: const Text('Marcar como Pago'),
                            onPressed: widget.onMarkAsPaid,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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
