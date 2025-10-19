

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/models/boleto_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../friends/friends_screen.dart';
import '../groups/groups_screen.dart';
import '../metrics/metrics_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/share_boletos_screen.dart';
import '../requests/requests_screen.dart';
import 'summary_screen.dart';
import 'widgets/add_boleto_dialog.dart';
import '../../theme/financial_gradients.dart';
import 'widgets/boleto_card.dart';
import 'widgets/paid_boleto_card.dart';
import 'widgets/share_boleto_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  final _searchQuery = ValueNotifier<String>('');
  final _searchController = TextEditingController();

  late final TabController _tabController;

  StreamSubscription? _sentBoletosSubscription;
  final List<String> _processedPaidRequests = [];
  bool _isHeaderExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text.toLowerCase();
    });

    _setupSentBoletosListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    _tabController.dispose();
    _sentBoletosSubscription?.cancel();
    super.dispose();
  }

  void _setupSentBoletosListener() {
    _sentBoletosSubscription?.cancel();

    _sentBoletosSubscription =
        _firestoreService.getSentBoletoRequests().listen((snapshot) {
      if (!mounted) return;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final isPaid = data['isPaidByRecipient'] ?? false;
        final status = data['status'];
        final originalBoletoId = data['boletoData']?['originalSenderBoletoId'];

        if (status == 'accepted' &&
            isPaid &&
            originalBoletoId != null &&
            !_processedPaidRequests.contains(doc.id)) {
          _firestoreService.markAsPaid(originalBoletoId);
          _processedPaidRequests.add(doc.id);
        }
      }
    });
  }

  Widget _buildBoletoList(
      {required Stream<QuerySnapshot> stream, required bool isPaidList}) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPaidList
                            ? [
                                theme.colorScheme.primary.withOpacity(0.15),
                                theme.colorScheme.tertiary.withOpacity(0.1),
                              ]
                            : [
                                Colors.green.shade400.withOpacity(0.2),
                                Colors.green.shade300.withOpacity(0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      isPaidList
                          ? PhosphorIcons.receiptFill
                          : PhosphorIcons.checkCircleFill,
                      size: 72,
                      color: isPaidList
                          ? theme.colorScheme.primary
                          : Colors.green.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPaidList ? 'Nenhum boleto pago' : 'Tudo em dia!',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPaidList
                        ? 'Seu histórico de boletos pagos aparecerá aqui.'
                        : 'Você não tem boletos pendentes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        final allDocs = snapshot.data!.docs;

        return ValueListenableBuilder<String>(
          valueListenable: _searchQuery,
          builder: (context, searchQuery, child) {
            final filteredDocs = allDocs.where((doc) {
              final boleto = Boleto.fromFirestore(doc);
              final description = boleto.description.toLowerCase();
              final tag = boleto.tag.toLowerCase();

              return searchQuery.isEmpty ||
                  description.contains(searchQuery) ||
                  tag.contains(searchQuery);
            }).toList();

            if (filteredDocs.isEmpty) {
              return Center(
                child: Text(searchQuery.isNotEmpty
                    ? 'Nenhum boleto encontrado para a sua busca.'
                    : ''),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                final boleto = Boleto.fromFirestore(doc);

                if (isPaidList) {
                  return PaidBoletoCard(boleto: boleto);
                } else {
                  final isOverdue = boleto.dueDate
                      .isBefore(DateUtils.dateOnly(DateTime.now()));
                  return BoletoCard(
                    boleto: boleto,
                    isOverdue: isOverdue,
                    onMarkAsPaid: () => _firestoreService.markAsPaid(boleto.id),
                    onDelete: () => _firestoreService.deleteBoleto(boleto.id),
                    onSend: () => showDialog(
                      context: context,
                      builder: (context) => ShareBoletoDialog(boleto: boleto),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
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
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: _isHeaderExpanded
              ? const SizedBox.shrink()
              : Image.asset(
                  'assets/icon_logo.png',
                  height: 45,
                  color: isDarkMode ? Colors.white : null,
                  key: const ValueKey('logo'),
                ),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF059669).withOpacity(0.1),
                const Color(0xFFD97706).withOpacity(0.05),
                const Color(0xFF0891B2).withOpacity(0.03),
              ],
            ),
          ),
        ),
        actions: [
          if (_isHeaderExpanded)
            _AnimatedIconButton(
              icon: PhosphorIcons.chartBarFill,
              tooltip: 'Métricas',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const MetricsScreen())),
              theme: theme,
            ),
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getFriendRequests(),
            builder: (context, friendSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getBoletoRequests(),
                builder: (context, boletoSnapshot) {
                  final friendRequestCount = friendSnapshot.hasData
                      ? friendSnapshot.data!.docs.length
                      : 0;
                  final boletoRequestCount = boletoSnapshot.hasData
                      ? boletoSnapshot.data!.docs.length
                      : 0;
                  final totalCount = friendRequestCount + boletoRequestCount;

                  return _isHeaderExpanded
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            _AnimatedIconButton(
                              icon: PhosphorIcons.bellFill,
                              tooltip: 'Solicitações',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RequestsScreen(),
                                ),
                              ),
                              theme: theme,
                            ),
                            if (totalCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$totalCount',
                                    style: TextStyle(
                                      color: theme.colorScheme.onError,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink();
                },
              );
            },
          ),
          if (_isHeaderExpanded)
            _AnimatedIconButton(
              icon: PhosphorIcons.usersThreeFill,
              tooltip: 'Grupos',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupsScreen()),
              ),
              theme: theme,
            ),
          if (_isHeaderExpanded)
            _AnimatedIconButton(
              icon: PhosphorIcons.usersFill,
              tooltip: 'Amigos',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsScreen()),
              ),
              theme: theme,
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.tertiary.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  _isHeaderExpanded ? PhosphorIcons.x : PhosphorIcons.squaresFour,
                  key: ValueKey(_isHeaderExpanded),
                ),
              ),
              onPressed: () => setState(() => _isHeaderExpanded = !_isHeaderExpanded),
              tooltip: _isHeaderExpanded ? 'Fechar menu' : 'Abrir menu',
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.getUserStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest),
                );
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final photoURL = userData['photoURL'] as String?;

              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'summary') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SummaryScreen()));
                  } else if (value == 'profile') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()));
                  } else if (value == 'sent') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ShareBoletosScreen()));
                  } else if (value == 'logout') {
                    _authService.signOut();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'summary',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.chartPieSliceFill),
                      title: Text('Resumo Financeiro'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.userCircleFill),
                      title: Text('Perfil'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sent',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.paperPlaneTiltFill),
                      title: Text('Boletos Enviados'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.signOutBold),
                      title: Text('Sair'),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: (photoURL == null || photoURL.isEmpty)
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.2),
                                theme.colorScheme.tertiary.withOpacity(0.1),
                              ],
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: (photoURL == null || photoURL.isEmpty)
                          ? Colors.transparent
                          : theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                          ? NetworkImage(photoURL)
                          : null,
                      child: (photoURL == null || photoURL.isEmpty)
                          ? Icon(
                              PhosphorIcons.userCircleFill,
                              color: theme.colorScheme.primary,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(
              icon: Icon(PhosphorIcons.hourglassMediumFill),
              text: 'Pendentes',
            ),
            Tab(
              icon: Icon(PhosphorIcons.checkCircleFill),
              text: 'Pagos',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinancialGradients.backgroundSubtle(context),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: inputDecorationTheme.copyWith(
                  labelText: 'Buscar por descrição ou tag...',
                  prefixIcon: Container(
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
                      PhosphorIcons.magnifyingGlassBold,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, value, child) {
                    return value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(PhosphorIcons.xCircleFill),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : const SizedBox.shrink();
                  },
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildBoletoList(
                    stream: _firestoreService.getUnpaidBoletosStream(),
                    isPaidList: false,
                  ),
                  _buildBoletoList(
                    stream: _firestoreService.getPaidBoletosStream(),
                    isPaidList: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF10B981),
              Color(0xFF059669),
              Color(0xFF047857),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddBoletoDialog(),
            );
          },
          tooltip: 'Adicionar Boleto',
          icon: const Icon(PhosphorIcons.plus, size: 24),
          label: const Text(
            'Novo Boleto',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),
      ),
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ThemeData theme;

  const _AnimatedIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.theme,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.theme.colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: Icon(widget.icon),
            tooltip: widget.tooltip,
            onPressed: () {
              _controller.forward().then((_) => _controller.reset());
              widget.onPressed();
            },
          ),
        ),
      ),
    );
  }
}
