import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/models/boleto_model.dart';
import '../../../data/services/firestore_service.dart';

class ShareBoletoDialog extends StatefulWidget {
  final Boleto boleto;

  const ShareBoletoDialog({super.key, required this.boleto});

  @override
  State<ShareBoletoDialog> createState() => _ShareBoletoDialogState();
}

class _ShareBoletoDialogState extends State<ShareBoletoDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Compartilhar Boleto'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Amigos'),
                Tab(text: 'Grupos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsList(firestoreService),
                  _buildGroupsList(firestoreService),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildFriendsList(FirestoreService firestoreService) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
              child: Text('Ocorreu um erro ao carregar os amigos.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Você não tem amigos para compartilhar boletos.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final friends = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friendDoc = friends[index];
            final friendData = friendDoc.data() as Map<String, dynamic>;
            final friendEmail = friendData['email'] ?? 'E-mail indisponível';
            final friendId = friendDoc.id;

            // ALTERAÇÃO AQUI: Garante que o nome seja exibido corretamente
            // Se 'displayName' for nulo ou vazio, usa o e-mail como fallback.
            final displayName =
                (friendData['displayName'] != null && friendData['displayName'].isNotEmpty)
                    ? friendData['displayName']
                    : friendEmail;

            return ListTile(
              title: Text(displayName), // Usa a variável corrigida
              onTap: () async {
                Navigator.of(context).pop();
                final result = await firestoreService.sendBoletoRequest(
                  widget.boleto,
                  friendId,
                  friendEmail,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result)),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList(FirestoreService firestoreService) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getGroupsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
              child: Text('Ocorreu um erro ao carregar os grupos.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Você não participa de nenhum grupo.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final groups = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final groupDoc = groups[index];
            final groupData = groupDoc.data() as Map<String, dynamic>;
            final groupId = groupDoc.id;

            return ListTile(
              title: Text(groupData['groupName']),
              onTap: () async {
                Navigator.of(context).pop();
                await firestoreService.shareBoletoWithGroup(
                    groupId, widget.boleto);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Boleto compartilhado com "${groupData['groupName']}"!')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
