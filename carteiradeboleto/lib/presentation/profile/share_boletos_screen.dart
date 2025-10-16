

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';


class ShareBoletosScreen extends StatelessWidget {
  const ShareBoletosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boletos Enviados'),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                  Icon(PhosphorIcons.paperPlaneTilt,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                child: ListTile(
                  leading: const Icon(PhosphorIcons.paperPlaneTilt),
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
              );
            },
          );
        },
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
          color = Colors.green.shade700;
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
        color = Colors.orange.shade800;
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
