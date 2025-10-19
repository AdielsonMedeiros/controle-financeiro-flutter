import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/services/firestore_service.dart';
import '../../data/services/theme_provider.dart';
import '../../theme/financial_gradients.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  late AnimationController _iconController;
  late Animation<double> _iconPulse;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _iconPulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

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
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(isDarkMode ? 0.8 : 0.6),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2.5,
        ),
      ),
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );

    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 18),
      elevation: 8,
      shadowColor: theme.colorScheme.primary.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: StreamBuilder<dynamic>(
          stream: _firestoreService.getUserStream(),
          builder: (context, snapshot) {
            final themeProvider = context.watch<ThemeProvider>();
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
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: FinancialGradients.money,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: theme.colorScheme.surface,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          backgroundImage:
                              (photoURL != null && photoURL.isNotEmpty)
                                  ? NetworkImage(photoURL)
                                  : null,
                          child: (photoURL == null || photoURL.isEmpty)
                              ? AnimatedBuilder(
                                  animation: _iconPulse,
                                  builder: (context, child) => Transform.scale(
                                    scale: _iconPulse.value,
                                    child: Icon(
                                      PhosphorIcons.user,
                                      size: 60,
                                      color: theme.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        userData['email'] ?? 'Carregando...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: inputDecorationTheme.copyWith(
                        labelText: 'Nome de Exibição',
                        prefixIcon: AnimatedBuilder(
                          animation: _iconPulse,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.8 + (_iconPulse.value - 0.9) * 0.5,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF059669).withOpacity(0.2),
                                      const Color(0xFF0891B2).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  PhosphorIcons.userCircle,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: FinancialGradients.success,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: elevatedButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                        shadowColor: MaterialStateProperty.all(Colors.transparent),
                        elevation: MaterialStateProperty.all(0),
                      ),
                      onPressed: _saveProfile,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _iconPulse,
                            builder: (context, child) => Transform.scale(
                              scale: _iconPulse.value,
                              child: const Icon(
                                PhosphorIcons.floppyDisk,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SALVAR ALTERAÇÕES',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: FinancialGradients.cardGradient(context),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Modo Escuro',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        themeProvider.themeMode == ThemeMode.dark
                            ? 'Tema escuro ativado'
                            : 'Tema claro ativado',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (bool value) {
                        themeProvider.toggleTheme(value);
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF059669).withOpacity(0.15),
                              const Color(0xFFD97706).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            themeProvider.themeMode == ThemeMode.dark
                                ? PhosphorIcons.moonFill
                                : PhosphorIcons.sunFill,
                            key: ValueKey(themeProvider.themeMode),
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                      activeColor: theme.colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
