

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';

class AddMembersScreen extends StatefulWidget {
  final String groupId;
  final List<String> currentMemberIds;

  const AddMembersScreen({
    super.key,
    required this.groupId,
    required this.currentMemberIds,
  });

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final _firestoreService = FirestoreService();
  final Map<String, Map<String, dynamic>> _selectedFriends = {};
  bool _isLoading = false;

  void _onFriendSelected(
      bool? isSelected, String friendId, Map<String, dynamic> friendData) {
    setState(() {
      if (isSelected == true) {
        _selectedFriends[friendId] = {
          'uid': friendId,
          'displayName': friendData['displayName'] ?? friendData['email'],
          'email': friendData['email'],
          'photoURL': friendData['photoURL'], 
        };
      } else {
        _selectedFriends.remove(friendId);
      }
    });
  }

  Future<void> _addMembers() async {
    if (_selectedFriends.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);

    final newMembers = _selectedFriends.values.toList();
    await _firestoreService.addMembersToGroup(widget.groupId, newMembers);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Membros'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 24, height: 24, child: CircularProgressIndicator()),
            )
          else
            IconButton(
              icon: const Icon(PhosphorIcons.check),
              onPressed: _addMembers,
              tooltip: 'Adicionar Selecionados',
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _firestoreService.getFriendsNotInGroup(widget.currentMemberIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar amigos.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Todos os seus amigos já estão neste grupo.'));
          }

          final friends = snapshot.data!;
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendData = friends[index];
              final friendId = friendData['uid'] as String;

              return CheckboxListTile(
                title: Text(friendData['displayName'] ?? friendData['email']),
                subtitle: Text(friendData['email']),
                secondary: CircleAvatar(
                  backgroundImage: (friendData['photoURL'] != null)
                      ? NetworkImage(friendData['photoURL'])
                      : null,
                  child: (friendData['photoURL'] == null)
                      ? const Icon(PhosphorIcons.user)
                      : null,
                ),
                value: _selectedFriends.containsKey(friendId),
                onChanged: (isSelected) =>
                    _onFriendSelected(isSelected, friendId, friendData),
              );
            },
          );
        },
      ),
    );
  }
}
