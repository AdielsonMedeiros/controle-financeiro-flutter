

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _firestoreService = FirestoreService();

  final Map<String, Map<String, dynamic>> _selectedFriends = {};
  bool _isLoading = false;

  void _onFriendSelected(bool? isSelected, String friendId,
      Map<String, dynamic> friendData) async {
    if (isSelected == true) {
      
      final userDoc = await _firestoreService.getUserById(friendId);
      final userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _selectedFriends[friendId] = {
          'uid': friendId,
          'displayName': userData['displayName'] ?? userData['email'],
          'email': userData['email'],
          'photoURL': userData['photoURL'], 
        };
      });
    } else {
      setState(() {
        _selectedFriends.remove(friendId);
      });
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione pelo menos um amigo para o grupo.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final groupName = _groupNameController.text.trim();
    final selectedFriendsList = _selectedFriends.values.toList();

    await _firestoreService.createGroup(groupName, selectedFriendsList);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Grupo'),
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
              onPressed: _createGroup,
              tooltip: 'Salvar Grupo',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Grupo',
                  prefixIcon: Icon(PhosphorIcons.tag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira um nome para o grupo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Text('Adicionar Amigos',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                height: 400,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getFriendsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('Você não tem amigos para adicionar.'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final friendDoc = snapshot.data!.docs[index];
                        final friendData =
                            friendDoc.data() as Map<String, dynamic>;
                        final friendId = friendDoc.id;

                        return CheckboxListTile(
                          title: Text(
                              friendData['displayName'] ?? friendData['email']),
                          subtitle: Text(friendData['email']),
                          value: _selectedFriends.containsKey(friendId),
                          onChanged: (isSelected) => _onFriendSelected(
                              isSelected, friendId, friendData),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
