

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
                  Icon(
                    isPaidList
                        ? PhosphorIcons.receipt
                        : PhosphorIcons.checkCircleFill,
                    size: 100,
                    color: isPaidList
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.green.shade400,
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
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
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
        title: Image.asset(
          'assets/icon_logo.png',
          height: 45,
          color: isDarkMode ? Colors.white : null,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIcons.chartBar),
            tooltip: 'Métricas',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MetricsScreen())),
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

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(PhosphorIcons.bell),
                        tooltip: 'Solicitações',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RequestsScreen(),
                          ),
                        ),
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
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(PhosphorIcons.usersThree),
            tooltip: 'Grupos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(PhosphorIcons.users),
            tooltip: 'Amigos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FriendsScreen()),
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
                      leading: Icon(PhosphorIcons.chartPieSlice),
                      title: Text('Resumo Financeiro'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.user),
                      title: Text('Perfil'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sent',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.paperPlaneTilt),
                      title: Text('Boletos Enviados'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.signOut),
                      title: Text('Sair'),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                        ? NetworkImage(photoURL)
                        : null,
                    child: (photoURL == null || photoURL.isEmpty)
                        ? Icon(
                            PhosphorIcons.user,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 22,
                          )
                        : null,
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
              icon: Icon(PhosphorIcons.hourglass),
              text: 'Pendentes',
            ),
            Tab(
              icon: Icon(PhosphorIcons.check),
              text: 'Pagos',
            ),
          ],
        ),
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
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, value, child) {
                    return value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(PhosphorIcons.xCircle),
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
      floatingActionButton: FloatingActionButton.extended(
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
        elevation: 4,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
