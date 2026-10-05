import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/chat_message.dart';

/// Reads and writes the conversation with the AI chef at
/// `users/{uid}/chat/{messageId}`.
class ChatService {
  ChatService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Messages kept on screen; older ones stay stored but are not loaded.
  static const shownMessages = 60;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _db.collection('users').doc(uid).collection('chat');

  /// The latest messages, oldest first.
  Stream<List<ChatMessage>> watch(String uid) => _col(uid)
      .orderBy('at')
      .limitToLast(shownMessages)
      .snapshots()
      .map((snap) => [for (final doc in snap.docs) ChatMessage.fromMap(doc.id, doc.data())]);

  Future<void> save(String uid, ChatMessage message) async {
    try {
      await _col(uid).doc(message.id).set(message.toMap());
    } catch (e) {
      debugPrint('[ChatService] save failed: $e');
      rethrow;
    }
  }

  /// Marks proposals left pending by a closed app as expired: what they
  /// would have run is gone with it.
  Future<void> expirePending(String uid) async {
    try {
      final pending = await _col(
        uid,
      ).where('action.status', whereIn: [ActionStatus.pending.id, ActionStatus.running.id]).get();
      if (pending.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in pending.docs) {
        batch.update(doc.reference, {'action.status': ActionStatus.expired.id});
      }
      await batch.commit();
      debugPrint('[ChatService] expired ${pending.docs.length} pending actions');
    } catch (e) {
      debugPrint('[ChatService] expirePending failed: $e');
    }
  }
}
