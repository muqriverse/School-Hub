import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schoolhub/admin_school_selector.dart';
import 'package:schoolhub/data/school_services_repository.dart';
import 'package:schoolhub/data/schools.dart';
import 'package:schoolhub/main.dart';

void main() {
  test('active announcements include today and future dates only', () {
    final now = DateTime(2026, 11, 6, 15);
    SchoolAnnouncement announcement(String id, DateTime eventDate) =>
        SchoolAnnouncement(
          id: id,
          title: id,
          body: '',
          category: 'MAKLUMAN',
          dateLabel: '',
          eventDate: eventDate,
          createdAt: now,
          schoolId: 'school',
        );

    final active = activeAnnouncements([
      announcement('past', DateTime(2026, 11, 5)),
      announcement('today', DateTime(2026, 11, 6)),
      announcement('future', DateTime(2026, 11, 7)),
    ], now: now);

    expect(active.map((item) => item.id), ['today', 'future']);
  });

  testWidgets('app requests Firebase setup before Google login', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SchoolHubApp());
    await tester.pumpAndSettle();

    expect(find.text('SchoolHub'), findsOneWidget);
    expect(find.text('Google belum disambungkan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard renders and navigation opens noticeboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    expect(find.text('SchoolHub'), findsOneWidget);
    expect(find.text('Apa yang anda perlukan?'), findsOneWidget);
    expect(find.text('Hari Sukan Tahunan 2025'), findsNothing);
    final today = DateTime.now();
    const weekdays = [
      'ISNIN',
      'SELASA',
      'RABU',
      'KHAMIS',
      'JUMAAT',
      'SABTU',
      'AHAD',
    ];
    const months = [
      'JANUARI',
      'FEBRUARI',
      'MAC',
      'APRIL',
      'MEI',
      'JUN',
      'JULAI',
      'OGOS',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DISEMBER',
    ];
    expect(
      find.text(
        '${weekdays[today.weekday - 1]}, ${today.day} ${months[today.month - 1]}',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Notis'));
    await tester.pumpAndSettle();

    expect(find.text('Papan notis'), findsOneWidget);
    expect(find.text('Hari Sukan Tahunan 2025'), findsOneWidget);
  });

  testWidgets('dashboard has no overflow on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('profile lets a user edit their display name', (
    WidgetTester tester,
  ) async {
    String? savedName;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          role: 'Guru',
          school: supportedSchools.first,
          user: null,
          displayName: 'Nama Lama',
          onUpdateDisplayName: (name) async => savedName = name,
          onSignOut: () async {},
        ),
      ),
    );
    await tester.tap(find.text('Nama paparan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nama Baharu');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(savedName, 'Nama Baharu');
    expect(tester.takeException(), isNull);
  });

  testWidgets('school selector opens and selects a full school name', (
    WidgetTester tester,
  ) async {
    var selectedSchool = supportedSchools.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 260,
              child: AdminSchoolSelector(
                selectedSchool: selectedSchool,
                onSelected: (school) => selectedSchool = school,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(schoolDisplayName(supportedSchools.first)));
    await tester.pumpAndSettle();

    expect(find.text('Pilih sekolah'), findsOneWidget);
    expect(find.text(supportedSchools.first), findsOneWidget);
    expect(find.text(supportedSchools.last), findsOneWidget);

    await tester.tap(find.text(supportedSchools[1]));
    await tester.pumpAndSettle();

    expect(selectedSchool, supportedSchools[1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent services are limited to read-only modules', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ServicesPage(role: 'Ibu bapa', onOpenModule: (_) {}),
      ),
    );

    expect(find.text('Permohonan tukar sekolah'), findsNothing);
    expect(find.text('Aduan fasiliti'), findsNothing);
    expect(find.text('Tempahan & pinjaman'), findsNothing);
    expect(find.text('Lost & Found'), findsOneWidget);
    expect(find.text('Pengumuman'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: ModulePage(
          module: 'Aduan fasiliti',
          role: 'Ibu bapa',
          school: 'Sekolah Menengah Kebangsaan Cochrane',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Servis ini tidak tersedia'), findsOneWidget);
  });

  testWidgets('PK HEM can manage school services and request changes', (
    WidgetTester tester,
  ) async {
    String? openedModule;
    await tester.pumpWidget(
      MaterialApp(
        home: ServicesPage(
          role: 'PK HEM',
          onOpenModule: (module) => openedModule = module,
        ),
      ),
    );

    expect(find.text('Tempahan & pinjaman'), findsOneWidget);
    expect(find.text('Permohonan tukar sekolah'), findsOneWidget);
    await tester.tap(find.text('Aduan fasiliti'));
    expect(openedModule, 'Aduan fasiliti');

    await tester.pumpWidget(
      MaterialApp(
        home: ModulePage(
          module: 'Aduan fasiliti',
          role: 'PK HEM',
          school: 'Sekolah Menengah Kebangsaan Cochrane',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai').last);
    await tester.pumpAndSettle();

    expect(find.text('Selesai'), findsWidgets);
  });

  testWidgets('Admin can update facility report status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ModulePage(
          module: 'Aduan fasiliti',
          role: 'Admin',
          school: 'Sekolah Menengah Kebangsaan Cochrane',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai').last);
    await tester.pumpAndSettle();

    expect(find.text('Selesai'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('facility reports show the four tracking stages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ModulePage(
          module: 'Aduan fasiliti',
          role: 'Guru',
          school: 'Sekolah Menengah Kebangsaan Cochrane',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diterima'), findsWidgets);
    expect(find.text('Dalam Siasatan'), findsWidgets);
    expect(find.text('Sedang Dibaiki'), findsWidgets);
    expect(find.text('Selesai'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('facility report requires a damage photo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ModulePage(
          module: 'Aduan fasiliti',
          role: 'Guru',
          school: 'Sekolah Menengah Kebangsaan Cochrane',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat aduan'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Lampu rosak');
    await tester.enterText(find.byType(TextField).at(1), 'Blok A');
    await tester.tap(find.text('Hantar aduan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sila muat naik gambar kerosakan untuk aduan ini.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking form asks for start and end times', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ModulePage(
          module: 'Tempahan',
          role: 'Guru',
          school: 'Sekolah Menengah Kebangsaan Cochrane',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tempahan baharu'));
    await tester.pumpAndSettle();

    expect(find.text('Masa tempahan'), findsOneWidget);
    expect(find.text('Dari Pilih masa'), findsOneWidget);
    expect(find.text('Sampai Pilih masa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('found item can be reported and claimed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lost & Found').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laporkan barang'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Payung merah');
    await tester.enterText(find.byType(TextField).at(1), 'Gam warna biru');
    await tester.enterText(find.byType(TextField).at(2), 'Perpustakaan');
    await tester.tap(find.text('Hantar laporan'));
    await tester.pumpAndSettle();

    expect(find.text('Payung merah'), findsOneWidget);
    expect(find.text('Perpustakaan'), findsOneWidget);

    final itemTitle = tester.getTopLeft(find.text('Payung merah'));
    await tester.tapAt(itemTitle.translate(-45, 20));
    await tester.pumpAndSettle();
    expect(find.text('Gam warna biru'), findsOneWidget);
    expect(find.text('Perpustakaan'), findsWidgets);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tuntut').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, tuntut'));
    await tester.pumpAndSettle();
    expect(find.text('Dituntut'), findsWidgets);
  });

  testWidgets('parent can view found items but cannot report or claim', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ModulePage(
          module: 'Lost & Found',
          role: 'Ibu bapa',
          school: 'Sekolah Kebangsaan Seri Melur',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Botol air pastel'), findsOneWidget);
    expect(find.text('Tuntut'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Komen'), findsWidgets);

    await tester.tap(find.text('Komen').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Komen ini boleh dilihat oleh warga sekolah yang sama.'),
      findsOneWidget,
    );
    expect(find.text('Log masuk untuk meninggalkan komen.'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('teachers and PK HEM can open found item comments', (
    WidgetTester tester,
  ) async {
    for (final role in ['Guru', 'PK HEM']) {
      await tester.pumpWidget(
        MaterialApp(
          home: ModulePage(
            module: 'Lost & Found',
            role: role,
            school: 'Sekolah Kebangsaan Seri Melur',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Komen'), findsWidgets);
      await tester.tap(find.text('Komen').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Komen ini boleh dilihat oleh warga sekolah yang sama.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });
}
