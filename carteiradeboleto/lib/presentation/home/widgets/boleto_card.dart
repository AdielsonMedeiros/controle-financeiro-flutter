import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../data/models/boleto_model.dart';

class BoletoCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final statusColor =
        isOverdue ? Colors.red.shade400 : Colors.orange.shade400;
    final statusText = isOverdue ? 'ATRASADO' : 'PENDENTE';
    final statusIcon =
        isOverdue ? PhosphorIcons.warningCircle : PhosphorIcons.clock;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boleto.description,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        avatar: Icon(statusIcon, size: 16, color: statusColor),
                        label: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: statusColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  currencyFormat.format(boleto.value),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Vence em: ${DateFormat('dd/MM/yyyy').format(boleto.dueDate)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const Divider(height: 24, thickness: 0.8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.trash, color: Colors.red.shade400),
                  tooltip: 'Deletar',
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.paperPlaneTilt,
                      color: theme.colorScheme.primary.withOpacity(0.8)),
                  tooltip: 'Enviar para amigo',
                  onPressed: onSend,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(PhosphorIcons.checkCircle, size: 18),
                  label: const Text('Pagar'),
                  onPressed: onMarkAsPaid,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
