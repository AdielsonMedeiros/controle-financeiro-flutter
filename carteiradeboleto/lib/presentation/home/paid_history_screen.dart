

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/models/boleto_model.dart';
import '../../data/services/firestore_service.dart';

class PaidHistoryScreen extends StatefulWidget {
  const PaidHistoryScreen({super.key});

  @override
  State<PaidHistoryScreen> createState() => _PaidHistoryScreenState();
}

class _PaidHistoryScreenState extends State<PaidHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecorationTheme = InputDecoration(
      filled: true,
      
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24.0),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2.0,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pagamentos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: inputDecorationTheme.copyWith(
                labelText: 'Buscar por descrição ou tag...',
                prefixIcon: const Icon(PhosphorIcons.magnifyingGlass),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(PhosphorIcons.xCircle),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getPaidBoletosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Ocorreu um erro ao carregar o histórico.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.receipt,
                            size: 80,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum boleto pago ainda',
                          style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final boleto = Boleto.fromFirestore(doc);
                  final description = boleto.description.toLowerCase();
                  final tag = boleto.tag.toLowerCase();

                  return _searchQuery.isEmpty ||
                      description.contains(_searchQuery) ||
                      tag.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(
                    child: Text('Nenhum boleto encontrado para a sua busca.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final boleto = Boleto.fromFirestore(doc);
                    return PaidBoletoCard(boleto: boleto);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PaidBoletoCard extends StatelessWidget {
  final Boleto boleto;
  const PaidBoletoCard({super.key, required this.boleto});

  @override
  Widget build(BuildContext context) {
    String paidAtDate = 'Data de pagamento indisponível';
    if (boleto.paidAt != null) {
      paidAtDate =
          'Pago em: ${DateFormat('dd/MM/yyyy').format(boleto.paidAt!.toDate())}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(PhosphorIcons.checkCircleFill, color: Colors.green.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boleto.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paidAtDate,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(boleto.value),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
