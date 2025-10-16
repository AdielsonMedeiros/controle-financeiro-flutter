import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/models/boleto_model.dart';
import '../../data/services/firestore_service.dart';
import 'add_members_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();
  bool _isEditMode = false;
  bool _isMembersExpanded = true; 

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final result =
          await _firestoreService.uploadGroupPhoto(widget.groupId, pickedFile);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
      }
    }
  }

  void _confirmRemoveMember(String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Membro'),
        content: Text('Tem certeza que deseja remover $memberName do grupo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _firestoreService.removeMemberFromGroup(
                  widget.groupId, memberId);
            },
            child: Text('Remover',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Grupo'),
        content: const Text(
            'Esta ação é irreversível. Tem certeza que deseja excluir este grupo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              await _firestoreService.deleteGroup(widget.groupId);
            },
            child: Text('Excluir',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getGroupStream(widget.groupId),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) {
          return Scaffold(
              appBar: AppBar(title: Text(widget.groupName)),
              body: const Center(child: CircularProgressIndicator()));
        }
        if (!groupSnapshot.data!.exists) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text("Este grupo não existe mais.")));
        }

        final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
        final ownerId = groupData['ownerId'] as String;
        final isOwner = FirebaseAuth.instance.currentUser?.uid == ownerId;
        final membersMap = groupData['members'] as Map<String, dynamic>;
        final groupPhotoURL = groupData['groupPhotoURL'] as String?;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(isOwner, groupPhotoURL, groupData),
              _buildMembersSectionHeader(membersMap.length),
              if (_isMembersExpanded)
                _buildMembersList(membersMap, isOwner),
              
              // ALTERAÇÃO: Adiciona uma divisória entre as seções
              const SliverToBoxAdapter(child: Divider(height: 32, indent: 16, endIndent: 16)),

              _buildSectionHeader('Boletos Compartilhados'),
              _buildSharedBoletosList(membersMap, widget.groupId),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(
      bool isOwner, String? groupPhotoURL, Map<String, dynamic> groupData) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(widget.groupName,
            style: const TextStyle(shadows: [Shadow(blurRadius: 4)])),
        background: Stack(
          fit: StackFit.expand,
          children: [
            groupPhotoURL != null && groupPhotoURL.isNotEmpty
                ? Image.network(groupPhotoURL,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error))
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest),
            Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent
            ], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
            if (isOwner)
              Positioned(
                top: 40,
                right: 50,
                child: IconButton(
                  icon: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(PhosphorIcons.camera,
                          size: 20, color: Colors.white)),
                  onPressed: _pickAndUploadImage,
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (isOwner)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddMembersScreen(
                            groupId: widget.groupId,
                            currentMemberIds: (groupData['memberIds'] as List)
                                .cast<String>())));
              } else if (value == 'remove') {
                setState(() => _isEditMode = !_isEditMode);
              } else if (value == 'delete') {
                _confirmDeleteGroup();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'add',
                  child: ListTile(
                      leading: Icon(PhosphorIcons.userPlus),
                      title: Text('Adicionar Membros'))),
              PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                      leading: Icon(PhosphorIcons.userMinus),
                      title: Text(_isEditMode
                          ? 'Concluir Edição'
                          : 'Remover Membros'))),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(PhosphorIcons.trash, color: Colors.red),
                      title: Text('Excluir Grupo',
                          style: TextStyle(color: Colors.red)))),
            ],
          )
      ],
    );
  }
  
  // ALTERAÇÃO: Cabeçalho da seção de membros agora usa ListTile para melhor aparência
  Widget _buildMembersSectionHeader(int memberCount) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(height: 8), // Pequeno espaço após a AppBar
          ListTile(
            leading: const Icon(PhosphorIcons.users),
            title: Text('Membros ($memberCount)', style: Theme.of(context).textTheme.titleLarge),
            trailing: Icon(
              _isMembersExpanded
                  ? PhosphorIcons.caretUp
                  : PhosphorIcons.caretDown,
            ),
            onTap: () {
              setState(() {
                _isMembersExpanded = !_isMembersExpanded;
              });
            },
          ),
          if (!_isMembersExpanded) const Divider(indent: 16, endIndent: 16, height: 1),
        ],
      ),
    );
  }

  // ALTERAÇÃO: Cabeçalho genérico também usa ListTile para consistência
  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: ListTile(
        leading: const Icon(PhosphorIcons.files),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }

  Widget _buildMembersList(Map<String, dynamic> membersMap, bool isOwner) {
    final members = membersMap.entries.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final member = members[index];
          final memberId = member.key;
          final memberData = member.value as Map<String, dynamic>;
          final photoURL = memberData['photoURL'] as String?;
          final displayName =
              memberData['displayName'] ?? memberData['email'] ?? 'Usuário';

          final bool hasPhoto = photoURL != null && photoURL.isNotEmpty;
          
          // Adiciona uma divisória entre os membros, exceto no último
          final isLastItem = index == members.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                leading: CircleAvatar(
                  backgroundImage: hasPhoto ? NetworkImage(photoURL) : null,
                  child: !hasPhoto ? const Icon(PhosphorIcons.user) : null,
                ),
                title: Text(displayName),
                subtitle: Text(memberData['email']),
                trailing: (_isEditMode &&
                        isOwner &&
                        memberId != FirebaseAuth.instance.currentUser!.uid)
                    ? IconButton(
                        icon: Icon(PhosphorIcons.xCircleFill,
                            color: Theme.of(context).colorScheme.error),
                        onPressed: () =>
                            _confirmRemoveMember(memberId, displayName),
                      )
                    : null,
              ),
              if (!isLastItem)
                const Divider(height: 1, indent: 80, endIndent: 16),
            ],
          );
        },
        childCount: members.length,
      ),
    );
  }

  Widget _buildSharedBoletosList(
      Map<String, dynamic> membersMap, String groupId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getSharedBoletosStream(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator())));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(32, 8, 32, 32), // Ajuste no padding
                      child: Text('Nenhum boleto compartilhado.'))));
        }

        final sharedBoletos = snapshot.data!.docs;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = sharedBoletos[index];
                final data = doc.data() as Map<String, dynamic>;
                final boleto = Boleto.fromFirestore(
                    _MockDocumentSnapshot(doc.id, data['boletoData']));

                return _SharedBoletoCard(
                  boleto: boleto,
                  sharerData:
                      membersMap[data['sharedBy']] as Map<String, dynamic>?,
                  payerData:
                      membersMap[data['paidByUid']] as Map<String, dynamic>?,
                  boletoData: data,
                  groupId: groupId,
                  sharedBoletoId: doc.id,
                );
              },
              childCount: sharedBoletos.length,
            ),
          ),
        );
      },
    );
  }
}

// O restante do arquivo (_SharedBoletoCard e _MockDocumentSnapshot) permanece o mesmo
class _SharedBoletoCard extends StatelessWidget {
  final Boleto boleto;
  final Map<String, dynamic>? sharerData;
  final Map<String, dynamic>? payerData;
  final Map<String, dynamic> boletoData;
  final String groupId;
  final String sharedBoletoId;

  const _SharedBoletoCard({
    required this.boleto,
    required this.sharerData,
    required this.payerData,
    required this.boletoData,
    required this.groupId,
    required this.sharedBoletoId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final theme = Theme.of(context);

    final localSharerData = sharerData;
    String sharerName = 'Membro desconhecido';
    if (localSharerData != null) {
      if (localSharerData['displayName'] != null &&
          (localSharerData['displayName'] as String).isNotEmpty) {
        sharerName = localSharerData['displayName'];
      } else {
        sharerName = localSharerData['email'] ?? 'Membro desconhecido';
      }
    }

    final sharedAt = (boletoData['sharedAt'] as Timestamp).toDate();
    final status = boletoData['status'] as String? ?? 'Pendente';

    final bool isPaid = status == 'Pago';

    final sharerPhotoURL = sharerData?['photoURL'] as String?;
    final bool hasSharerPhoto =
        sharerPhotoURL != null && sharerPhotoURL.isNotEmpty;

    void confirmMarkAsPaid() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Pagamento'),
          content: const Text(
              'Você tem certeza que deseja marcar este boleto como pago?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                firestoreService.markSharedBoletoAsPaid(
                    groupId, sharedBoletoId);
              },
              child: const Text('Sim, paguei'),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isPaid ? Colors.green.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage:
                    hasSharerPhoto ? NetworkImage(sharerPhotoURL) : null,
                child: !hasSharerPhoto ? const Icon(PhosphorIcons.user) : null,
              ),
              title: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                        text: sharerName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' compartilhou:'),
                  ],
                ),
              ),
              subtitle:
                  Text(DateFormat("dd/MM/yy 'às' HH:mm").format(sharedAt)),
            ),
            const Divider(height: 16, thickness: 0.5),
            Text(boleto.description,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Valor:'),
                Text(
                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                        .format(boleto.value),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vencimento:'),
                Text(DateFormat('dd/MM/yyyy').format(boleto.dueDate),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            if (isPaid)
              _buildPaidStatus(context)
            else
              _buildPendingStatus(context, confirmMarkAsPaid),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidStatus(BuildContext context) {
    final localPayerData = payerData;
    String payerName = 'Não identificado';
    if (localPayerData != null) {
      if (localPayerData['displayName'] != null &&
          (localPayerData['displayName'] as String).isNotEmpty) {
        payerName = localPayerData['displayName'];
      } else {
        payerName = localPayerData['email'] ?? 'Não identificado';
      }
    }

    final paidAt = (boletoData['paidAt'] as Timestamp?)?.toDate();

    return Row(
      children: [
        Icon(PhosphorIcons.checkCircleFill, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                const TextSpan(text: 'Pago por: '),
                TextSpan(
                    text: payerName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              if (paidAt != null)
                Text(
                  DateFormat("dd/MM/yy 'às' HH:mm").format(paidAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingStatus(BuildContext context, VoidCallback onMarkAsPaid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.clock, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            const Text('Status: Pendente',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        ElevatedButton(
          onPressed: onMarkAsPaid,
          child: const Text('Marcar como Pago'),
        ),
      ],
    );
  }
}

class _MockDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic> _data;
  _MockDocumentSnapshot(this.id, this._data);
  @override
  dynamic get(Object field) => _data[field];
  @override
  dynamic operator [](Object field) => _data[field as String];
  @override
  Map<String, dynamic> data() => _data;
  @override
  bool get exists => true;
  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
  @override
  DocumentReference<Object?> get reference => throw UnimplementedError();
}