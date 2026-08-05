import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ===== User Profile =====
  static Future<void> saveUserProfile({
    required String phoneNumber,
    String? name,
  }) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set({
      'phone_number': phoneNumber,
      'name': name,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (_uid == null) return null;
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data();
  }

  // ===== Notifications (real-time) =====
  static Stream<QuerySnapshot> notificationsStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots();
  }

  // ===== Chat =====
  static Stream<QuerySnapshot> chatStream(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots();
  }

  static Future<void> sendChatMessage({
    required String roomId,
    required String text,
  }) async {
    if (_uid == null) return;
    await _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'sender_uid': _uid,
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ===== Inspection Booking Status (real-time) =====
  static Stream<DocumentSnapshot> inspectionStatusStream(String inspectionId) {
    return _db.collection('inspections').doc(inspectionId).snapshots();
  }
}
