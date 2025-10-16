import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADICIONE ESTA LINHA
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _firestoreService = FirestoreService();

  Widget _buildTabWithBadge(String title, int count) {
    final theme = Theme.of(context);

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getFriendRequests(),
      builder: (context, friendSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getBoletoRequests(),
          builder: (context, boletoSnapshot) {
            final friendRequestCount =
                friendSnapshot.hasData ? friendSnapshot.data!.docs.length : 0;
            final boletoRequestCount =
                boletoSnapshot.hasData ? boletoSnapshot.data!.docs.length : 0;

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Solicitações'),
                  bottom: TabBar(
                    tabs: [
                      _buildTabWithBadge('Amizade', friendRequestCount),
                      _buildTabWithBadge('Boletos', boletoRequestCount),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    _buildFriendRequestsList(),
                    _buildBoletoRequestsList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard({
    required Widget title,
    Widget? subtitle,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(PhosphorIcons.userPlus)),
              title: title,
              subtitle: subtitle,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(PhosphorIcons.xCircle),
                  label: const Text('Recusar'),
                  onPressed: onDecline,
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(PhosphorIcons.checkCircle),
                  label: const Text('Aceitar'),
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getFriendRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum pedido de amizade.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final request = snapshot.data!.docs[index];
            return _buildRequestCard(
              title: Text('${request['fromEmail']} quer ser seu amigo.'),
              onAccept: () {
                // ALTERAÇÃO AQUI
                final currentUserEmail =
                    FirebaseAuth.instance.currentUser?.email ?? '';
                _firestoreService.acceptFriendRequest(
                  request.id,
                  request['fromId'],
                  request['fromEmail'],
                  request['toId'],
                  currentUserEmail,
                );
              },
              onDecline: () =>
                  _firestoreService.declineFriendRequest(request.id),
            );
          },
        );
      },
    );
  }

  Widget _buildBoletoRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getBoletoRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhuma solicitação de boleto.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final request = snapshot.data!.docs[index];
            final requestData = request.data() as Map<String, dynamic>;
            final boletoData =
                requestData['boletoData'] as Map<String, dynamic>;

            return _buildRequestCard(
              title: Text('${requestData['fromEmail']} te enviou um boleto.'),
              subtitle: Text(boletoData['description']),
              onAccept: () => _firestoreService.acceptBoletoRequest(
                  request.id, requestData),
              onDecline: () =>
                  _firestoreService.declineBoletoRequest(request.id),
            );
          },
        );
      },
    );
  }
}