import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundItem {
  const LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.dateLabel,
    required this.claimed,
    required this.imageBytes,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String dateLabel;
  final bool claimed;
  final Uint8List? imageBytes;

  factory LostFoundItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    final dateLabel = createdAt is Timestamp
        ? _formatDate(createdAt.toDate())
        : 'Baru sahaja';

    return LostFoundItem(
      id: document.id,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      location: data['location'] as String,
      dateLabel: dateLabel,
      claimed: data['claimed'] as bool? ?? false,
      imageBytes: (data['image'] as Blob?)?.bytes,
    );
  }
}

class LostFoundComment {
  const LostFoundComment({
    required this.id,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String message;
  final DateTime createdAt;

  factory LostFoundComment.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    return LostFoundComment(
      id: document.id,
      authorName: data['authorName'] as String? ?? 'Pengguna sekolah',
      message: data['message'] as String? ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class LostFoundRepository {
  LostFoundRepository({
    required FirebaseFirestore firestore,
    required this.schoolId,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final String schoolId;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('schools').doc(schoolId).collection('lostItems');

  CollectionReference<Map<String, dynamic>> _comments(String itemId) =>
      _items.doc(itemId).collection('comments');

  Stream<List<LostFoundItem>> watchItems() => _items
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(LostFoundItem.fromDocument)
            .toList(growable: false),
      );

  Future<void> addItem({
    required String title,
    required String description,
    required String location,
    required String userId,
    Uint8List? imageBytes,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'location': location,
      'claimed': false,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (imageBytes != null) data['image'] = Blob(imageBytes);
    await _items.add(data);
  }

  Future<void> claimItem({
    required String itemId,
    required String userId,
  }) async {
    await _items.doc(itemId).update({
      'claimed': true,
      'claimedBy': userId,
      'claimedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<LostFoundComment>> watchComments(String itemId) =>
      _comments(itemId)
          .orderBy('createdAt')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(LostFoundComment.fromDocument)
                .toList(growable: false),
          );

  Future<void> addComment({
    required String itemId,
    required String userId,
    required String authorName,
    required String message,
  }) => _comments(itemId).add({
    'authorId': userId,
    'authorName': authorName,
    'message': message,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteItem(String itemId) async {
    final comments = _comments(itemId);
    while (true) {
      final snapshot = await comments.limit(450).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final comment in snapshot.docs) {
        batch.delete(comment.reference);
      }
      await batch.commit();
    }
    await _items.doc(itemId).delete();
  }
}

String schoolIdForName(String schoolName) => schoolName
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

String _formatDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
