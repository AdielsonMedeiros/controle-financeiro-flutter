

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../data/models/boleto_model.dart';

class PaidBoletoCard extends StatelessWidget {
  final Boleto boleto;

  const PaidBoletoCard({super.key, required this.boleto});

  @override
  Widget build(BuildContext context) {
    final paidDate = boleto.paidAt?.toDate();
    final formattedDate = paidDate != null
        ? DateFormat('dd/MM/yyyy').format(paidDate)
        : 'Data indisponível';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            
            
            CircleAvatar(
              backgroundColor: Colors.green.withAlpha(26), 
              child: const Icon(
                PhosphorIcons.checkCircleFill,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boleto.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pago em: $formattedDate',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            Text(
              
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(boleto.value),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}