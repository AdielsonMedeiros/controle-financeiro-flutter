import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/services/firestore_service.dart';
import '../../data/services/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _nameController = TextEditingController();



  Future<void> _saveProfile() async {
    final result =
        await _firestoreService.updateUserProfile(_nameController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2.0,
        ),
      ),
    );

    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: isDarkMode
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.primary,
      foregroundColor: isDarkMode
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: StreamBuilder<dynamic>(
        stream: _firestoreService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data.data() as Map<String, dynamic>;
          final photoURL = userData['photoURL'] as String?;
          if (_nameController.text.isEmpty) {
            _nameController.text = userData['displayName'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // O widget Stack foi substituído por um CircleAvatar simples.
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    backgroundImage:
                        (photoURL != null && photoURL.isNotEmpty)
                            ? NetworkImage(photoURL)
                            : null,
                    child: (photoURL == null || photoURL.isEmpty)
                        ? Icon(PhosphorIcons.user,
                            size: 60,
                            color: theme.colorScheme.onSecondaryContainer)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    userData['email'] ?? 'Carregando...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: inputDecorationTheme.copyWith(
                    labelText: 'Nome de Exibição',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: elevatedButtonStyle,
                  onPressed: _saveProfile,
                  child: const Text('SALVAR ALTERAÇÕES'),
                ),
                const Divider(height: 48),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: SwitchListTile(
                    title: const Text('Modo Escuro'),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      themeProvider.toggleTheme(value);
                    },
                    secondary: Icon(
                      themeProvider.themeMode == ThemeMode.dark
                          ? PhosphorIcons.moonFill
                          : PhosphorIcons.sunFill,
                      color: theme.colorScheme.primary,
                    ),
                    activeThumbColor: theme.colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}