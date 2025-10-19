

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';
import '../../theme/financial_gradients.dart';


class ShareBoletosScreen extends StatelessWidget {
  const ShareBoletosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boletos Enviados'),
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
        child: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getSentBoletoRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Ocorreu um erro ao carregar os envios.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(PhosphorIcons.paperPlaneTiltFill,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum boleto enviado ainda',
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final sentRequest = snapshot.data!.docs[index];
              final data = sentRequest.data() as Map<String, dynamic>;
              final boletoData = data['boletoData'] as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final status = data['status'] as String?;
              final isPaid = data['isPaidByRecipient'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: FinancialGradients.cardGradient(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      PhosphorIcons.paperPlaneTiltFill,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    boletoData['description'] ?? 'Boleto sem descrição',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enviado para: ${data['toEmail']}'),
                      if (timestamp != null)
                        Text(
                          'Em: ${DateFormat("dd/MM/yy 'às' HH:mm").format(timestamp.toDate())}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                    ],
                  ),
                    trailing: _buildStatusChip(context, status, isPaid),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String? status, bool isPaid) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'accepted':
        if (isPaid) {
          icon = PhosphorIcons.checkCircleFill;
          color = const Color(0xFF059669);
          label = 'Pago';
        } else {
          icon = PhosphorIcons.infoFill;
          color = theme.colorScheme.primary;
          label = 'Aceito';
        }
        break;
      case 'declined':
        icon = PhosphorIcons.xCircleFill;
        color = theme.colorScheme.error;
        label = 'Recusado';
        break;
      default: 
        icon = PhosphorIcons.clockFill;
        color = const Color(0xFFD97706);
        label = 'Pendente';
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
