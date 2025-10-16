// lib/presentation/friends/friends_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  bool _searchAttempted = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        setState(() {
          _searchResults.clear();
          _searchAttempted = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchAttempted = true;
    });

    final results = await _firestoreService.searchUsersByEmail(searchTerm);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
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
      appBar: AppBar(title: const Text('Amigos')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: inputDecorationTheme.copyWith(
                labelText: 'Buscar usuário por e-mail',
                prefixIcon: const Icon(PhosphorIcons.magnifyingGlass),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(PhosphorIcons.x),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _searchUsers(),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchAttempted && _searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.smileySad,
                  size: 60, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              const Text(
                'Nenhum usuário encontrado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifique o e-mail digitado e tente novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    }
    return _buildFriendsList();
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context); // ALTERAÇÃO: Acessa o tema
    final isDarkMode =
        theme.brightness == Brightness.dark; // ALTERAÇÃO: Verifica o modo

    // ALTERAÇÃO: Cria o estilo do botão "Adicionar"
    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: isDarkMode
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.primary,
      foregroundColor: isDarkMode
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Resultados da Busca',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final user = _searchResults[index];
              final userData = user.data() as Map<String, dynamic>;
              final photoURL = userData['photoURL'] as String?;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                        ? NetworkImage(photoURL)
                        : null,
                    child: (photoURL == null || photoURL.isEmpty)
                        ? const Icon(PhosphorIcons.user)
                        : null,
                  ),
                  title: Text(userData['displayName'] ?? user['email']),
                  subtitle: Text(user['email']),
                  trailing: ElevatedButton(
                    // ALTERAÇÃO: Aplica o novo estilo
                    style: elevatedButtonStyle,
                    child: const Text('Adicionar'),
                    onPressed: () async {
                      final result = await _firestoreService.sendFriendRequest(
                          user.id, user['email']);
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(result)));
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Meus Amigos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getFriendsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Você ainda não tem amigos.\nUse a busca acima para encontrar e adicionar alguém!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final friendDoc = snapshot.data!.docs[index];
                  final friendData = friendDoc.data() as Map<String, dynamic>;
                  final friendEmail =
                      friendData['email'] ?? 'E-mail indisponível';
                  final displayName = friendData['displayName'] ?? friendEmail;

                  return Card(
                    child: ListTile(
                      leading:
                          const CircleAvatar(child: Icon(PhosphorIcons.user)),
                      title: Text(displayName),
                      subtitle: Text(friendEmail),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
