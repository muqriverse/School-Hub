import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'lost_found_repository.dart' show schoolIdForName;
import 'schools.dart';

const _allSchoolsId = 'all-schools';
const maxAnnouncementImageBytes = 700000;
const maxFacilityReportImageBytes = 280000;

class SchoolServiceEntry {
  const SchoolServiceEntry({
    required this.id,
    required this.title,
    required this.detail,
    required this.status,
    required this.dateLabel,
    this.beforeImageBytes,
    this.completionImageBytes,
  });

  final String id;
  final String title;
  final String detail;
  final String status;
  final String dateLabel;
  final Uint8List? beforeImageBytes;
  final Uint8List? completionImageBytes;

  factory SchoolServiceEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document, {
    required String detailField,
  }) {
    final data = document.data();
    final createdAt = data['createdAt'];
    return SchoolServiceEntry(
      id: document.id,
      title: data['title'] as String,
      detail: detailField == 'date'
          ? _formatBookingDetail(data)
          : data[detailField] as String? ?? '',
      status: data['status'] as String? ?? '',
      dateLabel: createdAt is Timestamp
          ? _formatDate(createdAt.toDate())
          : 'Baru sahaja',
      beforeImageBytes: (data['beforeImage'] as Blob?)?.bytes,
      completionImageBytes: (data['completionImage'] as Blob?)?.bytes,
    );
  }
}

class SchoolAnnouncement {
  const SchoolAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.dateLabel,
    required this.eventDate,
    required this.createdAt,
    required this.schoolId,
    this.imageBytes,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final String dateLabel;
  final DateTime eventDate;
  final DateTime createdAt;
  final String schoolId;
  final Uint8List? imageBytes;

  factory SchoolAnnouncement.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document, {
    required String schoolId,
  }) {
    final data = document.data();
    final eventDate = data['eventDate'];
    final createdAt = data['createdAt'];
    final parsedEventDate = eventDate is Timestamp
        ? eventDate.toDate()
        : createdAt is Timestamp
        ? createdAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    return SchoolAnnouncement(
      id: document.id,
      title: data['title'] as String,
      body: data['body'] as String,
      category: data['category'] as String? ?? 'MAKLUMAN',
      dateLabel: eventDate is Timestamp
          ? _formatCalendarDate(eventDate.toDate())
          : createdAt is Timestamp
          ? _formatDate(createdAt.toDate())
          : 'Baru sahaja',
      eventDate: parsedEventDate,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      schoolId: document.id.startsWith('global_') ? _allSchoolsId : schoolId,
      imageBytes: (data['image'] as Blob?)?.bytes,
    );
  }
}

class SchoolServicesRepository {
  SchoolServicesRepository({
    required FirebaseFirestore firestore,
    required this.schoolId,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final String schoolId;

  CollectionReference<Map<String, dynamic>> get _school =>
      _firestore.collection('schools').doc(schoolId).collection('services');

  Stream<List<SchoolServiceEntry>> watchFacilityReports() =>
      _watchEntries('facilityReports', detailField: 'location');

  Stream<List<SchoolServiceEntry>> watchBookings() =>
      _watchEntries('bookings', detailField: 'date');

  Stream<List<SchoolAnnouncement>> watchAnnouncements() =>
      _watchAnnouncementsFrom(schoolId);

  Stream<List<SchoolAnnouncement>> watchAllAnnouncements() {
    return Stream.multi((controller) {
      final announcementStreams = [
        for (final school in supportedSchools)
          _watchAnnouncementsFrom(schoolIdForName(school)),
        _watchAnnouncementsFrom(_allSchoolsId),
      ];
      final announcementsByStream = <int, List<SchoolAnnouncement>>{};

      void emitAnnouncements() {
        if (announcementsByStream.length != announcementStreams.length) return;
        final announcementsById = <String, List<SchoolAnnouncement>>{};
        for (final items in announcementsByStream.values) {
          for (final item in items) {
            announcementsById.putIfAbsent(item.id, () => []).add(item);
          }
        }
        final announcements =
            announcementsById.values.map((copies) {
              final announcement = copies.first;
              if (copies.length == 1 ||
                  announcement.schoolId == _allSchoolsId) {
                return announcement;
              }
              return SchoolAnnouncement(
                id: announcement.id,
                title: announcement.title,
                body: announcement.body,
                category: announcement.category,
                dateLabel: announcement.dateLabel,
                eventDate: announcement.eventDate,
                createdAt: announcement.createdAt,
                schoolId: _allSchoolsId,
                imageBytes: announcement.imageBytes,
              );
            }).toList()..sort(
              (first, second) => second.createdAt.compareTo(first.createdAt),
            );
        controller.add(announcements);
      }

      final subscriptions = [
        for (var index = 0; index < announcementStreams.length; index++)
          announcementStreams[index].listen(
            (items) {
              announcementsByStream[index] = items;
              emitAnnouncements();
            },
            onError: (Object error, StackTrace stackTrace) {
              controller.addError(error, stackTrace);
            },
          ),
      ];

      controller.onCancel = () async {
        await Future.wait(
          subscriptions.map((subscription) => subscription.cancel()),
        );
      };
    });
  }

  Stream<List<SchoolAnnouncement>> _watchAnnouncementsFrom(
    String announcementSchoolId,
  ) => _firestore
      .collection('schools')
      .doc(announcementSchoolId)
      .collection('services')
      .doc('announcements')
      .collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (document) => SchoolAnnouncement.fromDocument(
                document,
                schoolId: announcementSchoolId,
              ),
            )
            .toList(growable: false),
      );

  Stream<List<SchoolServiceEntry>> _watchEntries(
    String collection, {
    required String detailField,
  }) => _school
      .doc(collection)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (document) => SchoolServiceEntry.fromDocument(
                document,
                detailField: detailField,
              ),
            )
            .toList(growable: false),
      );

  Future<void> addFacilityReport({
    required String title,
    required String location,
    required String userId,
    required Uint8List beforeImageBytes,
  }) async {
    if (beforeImageBytes.length > maxFacilityReportImageBytes) {
      throw ArgumentError('Saiz gambar aduan terlalu besar.');
    }
    await _addEntry('facilityReports', {
      'title': title,
      'location': location,
      'status': 'Reported',
      'beforeImage': Blob(beforeImageBytes),
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addBooking({
    required String title,
    required String date,
    required String startTime,
    required String endTime,
    required String userId,
  }) => _addEntry('bookings', {
    'title': title,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'status': 'Pending',
    'createdBy': userId,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> _addEntry(String collection, Map<String, dynamic> data) =>
      _school.doc(collection).collection('items').add(data);

  Future<void> deleteFacilityReport(String itemId) =>
      _deleteEntry('facilityReports', itemId);

  Future<void> deleteBooking(String itemId) => _deleteEntry('bookings', itemId);

  Future<void> deleteAnnouncement(String itemId) => schoolId == _allSchoolsId
      ? _deleteAnnouncementFromAllSchools(itemId)
      : _deleteEntry('announcements', itemId);

  Future<void> _deleteAnnouncementFromAllSchools(String itemId) async {
    final batch = _firestore.batch();
    for (final school in supportedSchools) {
      batch.delete(
        _firestore
            .collection('schools')
            .doc(schoolIdForName(school))
            .collection('services')
            .doc('announcements')
            .collection('items')
            .doc(itemId),
      );
    }
    batch.delete(
      _firestore
          .collection('schools')
          .doc(_allSchoolsId)
          .collection('services')
          .doc('announcements')
          .collection('items')
          .doc(itemId),
    );
    await batch.commit();
  }

  Future<void> _deleteEntry(String collection, String itemId) =>
      _school.doc(collection).collection('items').doc(itemId).delete();

  Future<void> updateFacilityReportStatus({
    required String itemId,
    required String status,
    required String userId,
    Uint8List? completionImageBytes,
  }) async {
    if (status == 'Done' && completionImageBytes == null) {
      throw ArgumentError('Gambar bukti siap diperlukan.');
    }
    if (completionImageBytes != null &&
        completionImageBytes.length > maxFacilityReportImageBytes) {
      throw ArgumentError('Saiz gambar bukti siap terlalu besar.');
    }
    final update = <String, dynamic>{
      'status': status,
      'updatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
      if (completionImageBytes != null)
        'completionImage': Blob(completionImageBytes)
      else if (status != 'Done')
        'completionImage': FieldValue.delete(),
    };
    await _school
        .doc('facilityReports')
        .collection('items')
        .doc(itemId)
        .update(update);
  }

  Future<void> updateBookingStatus({
    required String itemId,
    required String status,
    required String userId,
  }) =>
      _updateStatus('bookings', itemId: itemId, status: status, userId: userId);

  Future<void> _updateStatus(
    String collection, {
    required String itemId,
    required String status,
    required String userId,
  }) => _school.doc(collection).collection('items').doc(itemId).update({
    'status': status,
    'updatedBy': userId,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> addAnnouncement({
    required String title,
    required String body,
    required String category,
    required DateTime eventDate,
    required String userId,
    Uint8List? imageBytes,
  }) async {
    if (imageBytes != null && imageBytes.length > maxAnnouncementImageBytes) {
      throw ArgumentError('Saiz gambar pengumuman terlalu besar.');
    }

    final data = <String, dynamic>{
      'title': title,
      'body': body,
      'category': category,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (imageBytes != null) data['image'] = Blob(imageBytes);

    if (schoolId != _allSchoolsId) {
      await _school.doc('announcements').collection('items').add(data);
      return;
    }

    final announcementId =
        'global_${_school.doc('announcements').collection('items').doc().id}';
    final batch = _firestore.batch();
    for (final school in supportedSchools) {
      batch.set(
        _firestore
            .collection('schools')
            .doc(schoolIdForName(school))
            .collection('services')
            .doc('announcements')
            .collection('items')
            .doc(announcementId),
        data,
      );
    }
    await batch.commit();
  }
}

List<SchoolAnnouncement> activeAnnouncements(
  Iterable<SchoolAnnouncement> announcements, {
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  return announcements
      .where((announcement) {
        final eventDay = DateTime(
          announcement.eventDate.year,
          announcement.eventDate.month,
          announcement.eventDate.day,
        );
        return !eventDay.isBefore(today);
      })
      .toList(growable: false);
}

String _formatBookingDetail(Map<String, dynamic> data) {
  final date = data['date'] as String? ?? '';
  final startTime = data['startTime'] as String?;
  final endTime = data['endTime'] as String?;
  if (startTime == null || endTime == null) return date;
  return '$date · $startTime – $endTime';
}

String _formatDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _formatCalendarDate(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';
