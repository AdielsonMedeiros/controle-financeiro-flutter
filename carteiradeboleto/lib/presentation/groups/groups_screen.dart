

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';
import '../../theme/financial_gradients.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Grupos'),
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
        stream: _firestoreService.getGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Ocorreu um erro ao carregar os grupos.'));
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
                          theme.colorScheme.primary.withOpacity(0.15),
                          theme.colorScheme.tertiary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(PhosphorIcons.usersThreeFill,
                        size: 60, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum grupo encontrado',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie um grupo para começar a compartilhar boletos!',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final groupDoc = groups[index];
              final groupData = groupDoc.data() as Map<String, dynamic>;
              final groupName = groupData['groupName'] as String;
              final membersCount = (groupData['memberIds'] as List).length;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: FinancialGradients.cardGradient(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF059669).withOpacity(0.2),
                            const Color(0xFF0891B2).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        PhosphorIcons.usersThreeFill,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(groupName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$membersCount membro(s)'),
                    trailing: Icon(PhosphorIcons.caretRightBold, color: theme.colorScheme.primary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailsScreen(
                            groupId: groupDoc.id,
                            groupName: groupName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: FinancialGradients.success,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
            );
          },
          tooltip: 'Criar Grupo',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(PhosphorIcons.plus),
        ),
      ),
    );
  }
}
