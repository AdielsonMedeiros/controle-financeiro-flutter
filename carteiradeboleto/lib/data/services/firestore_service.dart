// lib/data/services/firestore_service.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/boleto_model.dart';
import 'notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Adicionado para facilitar o acesso

  // --- LÓGICA DE USUÁRIO ---
  Stream<DocumentSnapshot> getUserStream() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado.");
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  Future<String> uploadProfileImage(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuário não logado.";
    try {
      final ref =
          _storage.ref().child('profile_images').child('${user.uid}.jpg');
      await ref.putFile(File(imageFile.path));
      final photoURL = await ref.getDownloadURL();
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
      });
      return "Foto atualizada com sucesso!";
    } catch (e) {
      return "Erro ao atualizar a foto.";
    }
  }

  Future<String> updateUserProfile(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuário não logado.";
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
      });
      return "Perfil atualizado com sucesso!";
    } catch (e) {
      return "Erro ao atualizar o perfil.";
    }
  }

  Future<DocumentSnapshot> getUserById(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  // --- LÓGICA DE BOLETOS ---
  CollectionReference _boletosCollection() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado.");
    return _firestore.collection('users').doc(user.uid).collection('boletos');
  }

  Stream<QuerySnapshot> getUnpaidBoletosStream() => _boletosCollection()
      .where('isPaid', isEqualTo: false)
      .orderBy('dueDate')
      .snapshots();

  Stream<QuerySnapshot> getPaidBoletosStream() {
    return _boletosCollection()
        .where('isPaid', isEqualTo: true)
        .orderBy('paidAt', descending: true)
        .snapshots();
  }

  Future<void> addBoleto(Boleto boleto) async {
    final docRef = await _boletosCollection().add(boleto.toMap());
    await docRef.update({'id': docRef.id});
    final newBoleto = boleto.copyWith(id: docRef.id);
    NotificationService().scheduleBoletoNotification(newBoleto);
  }

  Future<void> markAsPaid(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final boletoRef = _boletosCollection().doc(docId);
    final boletoDoc = await boletoRef.get();

    if (!boletoDoc.exists) return;

    final boleto = Boleto.fromFirestore(boletoDoc);
    final batch = _firestore.batch();

    batch.update(boletoRef, {
      'isPaid': true,
      'paidAt': Timestamp.now(),
    });

    final sharedBoletosQuery = await _firestore
        .collectionGroup('sharedBoletos')
        .where('originalBoletoId', isEqualTo: docId)
        .where('sharedBy', isEqualTo: user.uid)
        .get();

    for (final doc in sharedBoletosQuery.docs) {
      batch.update(doc.reference, {
        'status': 'Pago',
        'paidAt': Timestamp.now(),
        'paidByUid': user.uid,
      });
    }

    if (boleto.sentFromId != null && boleto.originalRequestId != null) {
      final senderRequestRef = _firestore
          .collection('users')
          .doc(boleto.sentFromId)
          .collection('sentBoletoRequests')
          .doc(boleto.originalRequestId);

      batch.update(senderRequestRef, {'isPaidByRecipient': true});
    }

    await batch.commit();
  }

  Future<void> deleteBoleto(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    final originalBoletoRef = _boletosCollection().doc(docId);
    batch.delete(originalBoletoRef);

    final sharedBoletosQuery = await _firestore
        .collectionGroup('sharedBoletos')
        .where('originalBoletoId', isEqualTo: docId)
        .where('sharedBy', isEqualTo: user.uid)
        .get();

    for (final doc in sharedBoletosQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Stream<QuerySnapshot> getUnpaidBoletosForCurrentMonthStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    return _boletosCollection()
        .where('isPaid', isEqualTo: false)
        .where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots();
  }

  Stream<QuerySnapshot> getOverdueBoletosStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final today = DateUtils.dateOnly(DateTime.now());
    final startOfToday = Timestamp.fromDate(today);
    return _boletosCollection()
        .where('isPaid', isEqualTo: false)
        .where('dueDate', isLessThan: startOfToday)
        .snapshots();
  }

  Stream<QuerySnapshot> getPaidBoletosForCurrentMonthStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    return _boletosCollection()
        .where('isPaid', isEqualTo: true)
        .where('paidAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('paidAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots();
  }

  Future<List<Boleto>> getPaidBoletosByDateRange(
      DateTime start, DateTime end) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _boletosCollection()
        .where('isPaid', isEqualTo: true)
        .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('paidAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return querySnapshot.docs.map((doc) => Boleto.fromFirestore(doc)).toList();
  }

  // --- LÓGICA DE AMIZADE ---
  Future<List<QueryDocumentSnapshot>> searchUsersByEmail(String email) async {
    final user = _auth.currentUser;
    String searchTerm = email.toLowerCase().trim();
    if (searchTerm.isEmpty || searchTerm == user?.email?.toLowerCase().trim()) {
      return [];
    }

    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: searchTerm)
        .where('email', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .get();

    return querySnapshot.docs
        .where((doc) => doc['email'] != user?.email)
        .toList();
  }

  Stream<QuerySnapshot> getFriendsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .snapshots();
  }

  Future<String> sendFriendRequest(
      String recipientId, String recipientEmail) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuário não logado.";
    final currentUserId = user.uid;

    if (recipientId == currentUserId) {
      return "Você não pode adicionar a si mesmo.";
    }

    try {
      final friendDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(recipientId)
          .get();

      if (friendDoc.exists) {
        return "Vocês já são amigos.";
      }

      final requestSentQuery = await _firestore
          .collection('friendRequests')
          .where('fromId', isEqualTo: currentUserId)
          .where('toId', isEqualTo: recipientId)
          .limit(1)
          .get();

      if (requestSentQuery.docs.isNotEmpty) {
        return "Você já solicitou o pedido de amizade para essa pessoa";
      }

      final requestReceivedQuery = await _firestore
          .collection('friendRequests')
          .where('fromId', isEqualTo: recipientId)
          .where('toId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (requestReceivedQuery.docs.isNotEmpty) {
        return "Este usuário já te enviou um pedido. Verifique suas solicitações.";
      }

      final requestData = {
        'fromId': currentUserId,
        'fromEmail': user.email,
        'toId': recipientId,
        'toEmail': recipientEmail,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('friendRequests').add(requestData);

      return "Pedido de amizade enviado!";
    } catch (e) {
      return "Erro ao enviar pedido.";
    }
  }

  Stream<QuerySnapshot> getFriendRequests() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('friendRequests')
        .where('toId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptFriendRequest(String requestId, String fromId,
      String fromEmail, String toId, String toEmail) async {
    final fromUserDoc = await _firestore.collection('users').doc(fromId).get();
    final toUserDoc = await _firestore.collection('users').doc(toId).get();

    final fromDisplayName =
        (fromUserDoc.data() as Map<String, dynamic>)['displayName'] ??
            fromEmail;
    final toDisplayName =
        (toUserDoc.data() as Map<String, dynamic>)['displayName'] ?? toEmail;

    final WriteBatch batch = _firestore.batch();
    batch.set(
        _firestore
            .collection('users')
            .doc(toId)
            .collection('friends')
            .doc(fromId),
        {'email': fromEmail, 'displayName': fromDisplayName});
    batch.set(
        _firestore
            .collection('users')
            .doc(fromId)
            .collection('friends')
            .doc(toId),
        {'email': toEmail, 'displayName': toDisplayName});
    batch.delete(_firestore.collection('friendRequests').doc(requestId));
    await batch.commit();
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': 'declined'});
  }

  Future<List<Map<String, dynamic>>> getFriendsNotInGroup(
      List<String> memberIds) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final friendsSnapshot = await getFriendsStream().first;
    final List<Map<String, dynamic>> friendsList = [];

    for (final friendDoc in friendsSnapshot.docs) {
      if (!memberIds.contains(friendDoc.id)) {
        final userDoc =
            await _firestore.collection('users').doc(friendDoc.id).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          friendsList.add({
            'uid': userDoc.id,
            'displayName': userData['displayName'] ?? userData['email'],
            'email': userData['email'],
            'photoURL': userData['photoURL'],
          });
        }
      }
    }
    return friendsList;
  }

  // --- LÓGICA DE SOLICITAÇÃO DE BOLETOS ---
  Future<String> sendBoletoRequest(
      Boleto boleto, String friendId, String friendEmail) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuário não logado.";

    try {
      bool requestExists = false;

      if (boleto.barcode != null && boleto.barcode!.isNotEmpty) {
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sentBoletoRequests')
            .where('toId', isEqualTo: friendId)
            .where('boletoData.barcode', isEqualTo: boleto.barcode)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) requestExists = true;
      } else {
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sentBoletoRequests')
            .where('toId', isEqualTo: friendId)
            .where('boletoData.description', isEqualTo: boleto.description)
            .where('boletoData.value', isEqualTo: boleto.value)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) requestExists = true;
      }

      if (requestExists) {
        return "Você já mandou esse boleto para esse usuário";
      }

      final batch = _firestore.batch();
      final requestId = _firestore.collection('boletoRequests').doc().id;

      final boletoData = {
        'description': boleto.description,
        'value': boleto.value,
        'dueDate': boleto.dueDate,
        'barcode': boleto.barcode,
        'tag': boleto.tag,
        'originalSenderBoletoId': boleto.id,
      };

      final recipientRequestRef = _firestore
          .collection('users')
          .doc(friendId)
          .collection('boletoRequests')
          .doc(requestId);

      final recipientRequestData = {
        'fromId': user.uid,
        'fromEmail': user.email,
        'boletoData': boletoData,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      };

      batch.set(recipientRequestRef, recipientRequestData);

      final senderRequestRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sentBoletoRequests')
          .doc(requestId);

      final senderRequestData = {
        'toId': friendId,
        'toEmail': friendEmail,
        'boletoData': boletoData,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      };

      batch.set(senderRequestRef, senderRequestData);

      await batch.commit();

      return "Solicitação de boleto enviada!";
    } catch (e) {
      return "Erro ao enviar solicitação.";
    }
  }

  Stream<QuerySnapshot> getBoletoRequests() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('boletoRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getSentBoletoRequests() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sentBoletoRequests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> acceptBoletoRequest(
      String requestId, Map<String, dynamic> requestData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final fromId = requestData['fromId'] as String;
    final boletoData = requestData['boletoData'] as Map<String, dynamic>;

    final batch = _firestore.batch();

    final newBoleto = Boleto(
      id: '',
      description: boletoData['description'] as String,
      value: (boletoData['value'] as num).toDouble(),
      dueDate: (boletoData['dueDate'] as Timestamp).toDate(),
      barcode: boletoData['barcode'] as String?,
      isPaid: false,
      paidAt: null,
      tag: boletoData['tag'] as String,
      originalRequestId: requestId,
      sentFromId: fromId,
      originalSenderBoletoId: boletoData['originalSenderBoletoId'],
    );
    final newBoletoRef = _boletosCollection().doc();
    batch.set(newBoletoRef, newBoleto.copyWith(id: newBoletoRef.id).toMap());

    final recipientRequestRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('boletoRequests')
        .doc(requestId);
    batch.update(recipientRequestRef, {'status': 'accepted'});

    final senderRequestRef = _firestore
        .collection('users')
        .doc(fromId)
        .collection('sentBoletoRequests')
        .doc(requestId);
    batch.update(senderRequestRef, {'status': 'accepted'});

    await batch.commit();
  }

  Future<void> declineBoletoRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final requestDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('boletoRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) return;

    final fromId = requestDoc.data()!['fromId'] as String;

    final batch = _firestore.batch();

    final recipientRequestRef = requestDoc.reference;
    batch.update(recipientRequestRef, {'status': 'declined'});

    final senderRequestRef = _firestore
        .collection('users')
        .doc(fromId)
        .collection('sentBoletoRequests')
        .doc(requestId);
    batch.update(senderRequestRef, {'status': 'declined'});

    await batch.commit();
  }

  // --- LÓGICA DE GRUPOS ---
  Future<String> createGroup(
      String groupName, List<Map<String, dynamic>> selectedFriends) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado.");

    final newGroupRef = _firestore.collection('groups').doc();
    final creatorDoc = await _firestore.collection('users').doc(user.uid).get();
    final creatorData = creatorDoc.data() as Map<String, dynamic>;

    List<Map<String, dynamic>> allMembersInfo = [
      {
        'uid': user.uid,
        'displayName': creatorData['displayName'] ?? user.email,
        'email': user.email,
        'photoURL': creatorData['photoURL'],
      }
    ];
    allMembersInfo.addAll(selectedFriends);

    List<String> memberIds =
        allMembersInfo.map((user) => user['uid'] as String).toSet().toList();

    Map<String, dynamic> membersMap = {
      for (var user in allMembersInfo)
        user['uid']: {
          'displayName': user['displayName'],
          'email': user['email'],
          'photoURL': user['photoURL'],
        }
    };

    await newGroupRef.set({
      'groupName': groupName,
      'ownerId': user.uid,
      'createdAt': Timestamp.now(),
      'memberIds': memberIds,
      'members': membersMap,
      'groupPhotoURL': null,
    });

    return newGroupRef.id;
  }

  Stream<QuerySnapshot> getGroupsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getGroupStream(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots();
  }

  Future<void> shareBoletoWithGroup(String groupId, Boleto boleto) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sharedBoletoData = {
      'boletoData': boleto.toMap(),
      'originalBoletoId': boleto.id,
      'sharedBy': user.uid,
      'sharedAt': Timestamp.now(),
      'status': 'Pendente',
    };

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('sharedBoletos')
        .add(sharedBoletoData);
  }

  Stream<QuerySnapshot> getSharedBoletosStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('sharedBoletos')
        .orderBy('sharedAt', descending: true)
        .snapshots();
  }

  Future<String> uploadGroupPhoto(String groupId, XFile imageFile) async {
    try {
      final ref = _storage.ref().child('group_images').child('$groupId.jpg');
      await ref.putFile(File(imageFile.path));
      final photoURL = await ref.getDownloadURL();
      await _firestore.collection('groups').doc(groupId).update({
        'groupPhotoURL': photoURL,
      });
      return "Foto do grupo atualizada!";
    } catch (e) {
      return "Erro ao atualizar a foto.";
    }
  }

  Future<void> addMembersToGroup(
      String groupId, List<Map<String, dynamic>> newMembers) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    final newMemberIds = newMembers.map((m) => m['uid'] as String).toList();

    final newMembersMap = {
      for (var member in newMembers)
        'members.${member['uid']}': {
          'displayName': member['displayName'],
          'email': member['email'],
          'photoURL': member['photoURL'],
        }
    };

    await groupRef.update({
      'memberIds': FieldValue.arrayUnion(newMemberIds),
      ...newMembersMap,
    });
  }

  Future<void> removeMemberFromGroup(
      String groupId, String memberIdToRemove) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    await groupRef.update({
      'memberIds': FieldValue.arrayRemove([memberIdToRemove]),
      'members.$memberIdToRemove': FieldValue.delete(),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }

  Future<void> markSharedBoletoAsPaid(
      String groupId, String sharedBoletoId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sharedBoletoRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('sharedBoletos')
        .doc(sharedBoletoId);

    final sharedBoletoDoc = await sharedBoletoRef.get();
    if (!sharedBoletoDoc.exists) return;

    final data = sharedBoletoDoc.data() as Map<String, dynamic>;
    final originalBoletoId = data['originalBoletoId'] as String?;
    final sharedByUid = data['sharedBy'] as String?;

    if (originalBoletoId == null || sharedByUid == null) {
      await sharedBoletoRef.update({
        'status': 'Pago',
        'paidByUid': user.uid,
        'paidAt': Timestamp.now(),
      });
      return;
    }

    final originalBoletoRef = _firestore
        .collection('users')
        .doc(sharedByUid)
        .collection('boletos')
        .doc(originalBoletoId);

    final batch = _firestore.batch();

    batch.update(sharedBoletoRef, {
      'status': 'Pago',
      'paidByUid': user.uid,
      'paidAt': Timestamp.now(),
    });

    batch.update(originalBoletoRef, {
      'isPaid': true,
      'paidAt': Timestamp.now(),
    });

    await batch.commit();
  }
}