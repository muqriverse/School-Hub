import 'package:cloud_firestore/cloud_firestore.dart';

import 'lost_found_repository.dart';

class SchoolTransferRequest {
  const SchoolTransferRequest({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.teacherEmail,
    required this.requesterRole,
    required this.toRole,
    required this.fromSchoolName,
    required this.fromSchoolId,
    required this.toSchoolName,
    required this.toSchoolId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String teacherId;
  final String teacherName;
  final String teacherEmail;
  final String requesterRole;
  final String toRole;
  final String fromSchoolName;
  final String fromSchoolId;
  final String toSchoolName;
  final String toSchoolId;
  final String reason;
  final String status;
  final DateTime createdAt;

  factory SchoolTransferRequest.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return SchoolTransferRequest(
      id: document.id,
      teacherId: data['teacherId'] as String,
      teacherName: data['teacherName'] as String? ?? 'Guru',
      teacherEmail: data['teacherEmail'] as String? ?? '',
      requesterRole: data['requesterRole'] as String? ?? 'Guru',
      toRole:
          data['toRole'] as String? ??
          data['requesterRole'] as String? ??
          'Guru',
      fromSchoolName: data['fromSchoolName'] as String,
      fromSchoolId: data['fromSchoolId'] as String,
      toSchoolName: data['toSchoolName'] as String,
      toSchoolId: data['toSchoolId'] as String,
      reason: data['reason'] as String,
      status: data['status'] as String,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SchoolTransferRepository {
  SchoolTransferRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('schoolTransferRequests');

  Stream<List<SchoolTransferRequest>> watchUserRequests(String teacherId) =>
      _requests.where('teacherId', isEqualTo: teacherId).snapshots().map((
        snapshot,
      ) {
        final requests = snapshot.docs
            .map(SchoolTransferRequest.fromDocument)
            .toList();
        requests.sort(
          (first, second) => second.createdAt.compareTo(first.createdAt),
        );
        return requests;
      });

  Stream<List<SchoolTransferRequest>> watchPendingRequests() => _requests
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
        final requests = snapshot.docs
            .map(SchoolTransferRequest.fromDocument)
            .toList();
        requests.sort(
          (first, second) => first.createdAt.compareTo(second.createdAt),
        );
        return requests;
      });

  Future<void> createRequest({
    required String teacherId,
    required String teacherName,
    required String teacherEmail,
    required String requesterRole,
    required String toRole,
    required String fromSchoolName,
    required String toSchoolName,
    required String reason,
  }) async {
    final fromSchoolId = schoolIdForName(fromSchoolName);
    final toSchoolId = schoolIdForName(toSchoolName);
    if (fromSchoolId.isEmpty || toSchoolId.isEmpty) {
      throw ArgumentError('Nama sekolah tidak sah.');
    }
    if (!['Guru', 'Ibu bapa', 'PK HEM'].contains(requesterRole) ||
        !['Guru', 'Ibu bapa', 'PK HEM'].contains(toRole)) {
      throw ArgumentError('Jawatan tidak sah.');
    }
    if (fromSchoolId == toSchoolId && requesterRole == toRole) {
      throw ArgumentError('Pilih sekolah atau jawatan yang berbeza.');
    }

    await _requests.add({
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherEmail': teacherEmail,
      'requesterRole': requesterRole,
      'toRole': toRole,
      'fromSchoolName': fromSchoolName,
      'fromSchoolId': fromSchoolId,
      'toSchoolName': toSchoolName,
      'toSchoolId': toSchoolId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reviewRequest({
    required SchoolTransferRequest request,
    required String adminId,
    required bool approve,
  }) async {
    final batch = _firestore.batch();
    final requestReference = _requests.doc(request.id);
    batch.update(requestReference, {
      'status': approve ? 'approved' : 'rejected',
      'reviewedBy': adminId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    if (approve) {
      batch.update(_firestore.collection('users').doc(request.teacherId), {
        'schoolId': request.toSchoolId,
        'schoolName': request.toSchoolName,
        'role': request.toRole,
        'lastSchoolTransferRequestId': request.id,
      });
    }
    await batch.commit();
  }
}
