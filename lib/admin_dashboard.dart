import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'data/lost_found_repository.dart';
import 'data/school_services_repository.dart';
import 'data/school_transfer_repository.dart';
import 'data/schools.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.user,
    required this.displayName,
    required this.onOpenModule,
    required this.onCreateAnnouncement,
  });

  final User? user;
  final String displayName;
  final void Function(String module, String school) onOpenModule;
  final VoidCallback onCreateAnnouncement;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final Map<String, _SchoolStreams> _schoolStreams = {
    for (final school in supportedSchools)
      school: _SchoolStreams(
        schoolServices: SchoolServicesRepository(
          firestore: FirebaseFirestore.instance,
          schoolId: schoolIdForName(school),
        ),
        lostFound: LostFoundRepository(
          firestore: FirebaseFirestore.instance,
          schoolId: schoolIdForName(school),
        ),
      ),
  };

  late final Stream<List<SchoolTransferRequest>>? _pendingTransfers =
      widget.user == null
      ? null
      : SchoolTransferRepository(
          firestore: FirebaseFirestore.instance,
        ).watchPendingRequests();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final contentWidth = (constraints.maxWidth - 56)
          .clamp(0.0, 1320.0)
          .toDouble();
      final columns = contentWidth >= 1120
          ? 3
          : contentWidth >= 720
          ? 2
          : 1;
      final cardWidth = (contentWidth - (columns - 1) * 16) / columns;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 27, 28, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat kembali, ${widget.displayName.split(' ').first}',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pantau perkembangan dan urusan sekolah dari satu tempat.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8A7E74),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: widget.onCreateAnnouncement,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Buat pengumuman'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9A7E68),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _TransferSummary(
                  stream: _pendingTransfers,
                  onTap: () => widget.onOpenModule(
                    'Kelulusan tukar sekolah',
                    'Semua sekolah',
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'RINGKASAN SEKOLAH',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF8A7E74),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final school in supportedSchools)
                      SizedBox(
                        width: cardWidth,
                        child: _SchoolSummaryCard(
                          school: school,
                          streams: _schoolStreams[school]!,
                          onOpenModule: (module) =>
                              widget.onOpenModule(module, school),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _QuickActions(
                  onOpenNotices: () =>
                      widget.onOpenModule('Pengumuman', 'Semua sekolah'),
                  onOpenTransfers: () => widget.onOpenModule(
                    'Kelulusan tukar sekolah',
                    'Semua sekolah',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SchoolStreams {
  const _SchoolStreams({required this.schoolServices, required this.lostFound});

  final SchoolServicesRepository schoolServices;
  final LostFoundRepository lostFound;
}

class _TransferSummary extends StatelessWidget {
  const _TransferSummary({required this.stream, required this.onTap});

  final Stream<List<SchoolTransferRequest>>? stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF0EAE2)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDFE5DA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.fact_check_rounded,
                color: Color(0xFF4A4038),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permohonan pertukaran',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Semakan menunggu daripada semua sekolah',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (stream == null)
              const Text('Log masuk diperlukan')
            else
              StreamBuilder<List<SchoolTransferRequest>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Tooltip(
                      message: 'Permohonan tidak dapat dimuatkan.',
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFAD5050),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return Text(
                    '${snapshot.data!.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 25),
                  );
                },
              ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, color: Color(0xFF9A7E68)),
          ],
        ),
      ),
    ),
  );
}

class _SchoolSummaryCard extends StatelessWidget {
  const _SchoolSummaryCard({
    required this.school,
    required this.streams,
    required this.onOpenModule,
  });

  final String school;
  final _SchoolStreams streams;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFF0EAE2)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: school,
          child: Text(
            schoolDisplayName(school),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            _LiveMetric<SchoolServiceEntry>(
              label: 'Aduan aktif',
              icon: Icons.handyman_outlined,
              stream: streams.schoolServices.watchFacilityReports(),
              count: (entries) =>
                  entries.where((entry) => entry.status != 'Done').length,
            ),
            _LiveMetric<SchoolServiceEntry>(
              label: 'Tempahan pending',
              icon: Icons.calendar_month_outlined,
              stream: streams.schoolServices.watchBookings(),
              count: (entries) =>
                  entries.where((entry) => entry.status == 'Pending').length,
            ),
            _LiveMetric<LostFoundItem>(
              label: 'Barang belum dituntut',
              icon: Icons.backpack_outlined,
              stream: streams.lostFound.watchItems(),
              count: (items) => items.where((item) => !item.claimed).length,
            ),
          ],
        ),
        const Divider(height: 24),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _OpenModuleButton(
              label: 'Aduan',
              onPressed: () => onOpenModule('Aduan fasiliti'),
            ),
            _OpenModuleButton(
              label: 'Tempahan',
              onPressed: () => onOpenModule('Tempahan'),
            ),
            _OpenModuleButton(
              label: 'Lost & Found',
              onPressed: () => onOpenModule('Lost & Found'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LiveMetric<T> extends StatelessWidget {
  const _LiveMetric({
    required this.label,
    required this.icon,
    required this.stream,
    required this.count,
  });

  final String label;
  final IconData icon;
  final Stream<List<T>> stream;
  final int Function(List<T> items) count;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<T>>(
    stream: stream,
    builder: (context, snapshot) {
      final value = snapshot.hasError
          ? 'Ralat'
          : snapshot.hasData
          ? '${count(snapshot.data!)}'
          : '–';
      return Tooltip(
        message: snapshot.hasError ? 'Data tidak dapat dimuatkan.' : label,
        child: SizedBox(
          width: 138,
          child: Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF9A7E68)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$value $label',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OpenModuleButton extends StatelessWidget {
  const _OpenModuleButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF7E6655),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    ),
    child: Text(label),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOpenNotices,
    required this.onOpenTransfers,
  });

  final VoidCallback onOpenNotices;
  final VoidCallback onOpenTransfers;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final actions = [
        OutlinedButton.icon(
          onPressed: onOpenNotices,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Urus pengumuman'),
        ),
        OutlinedButton.icon(
          onPressed: onOpenTransfers,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Semak permohonan'),
        ),
      ];
      if (constraints.maxWidth < 480) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [actions[0], const SizedBox(height: 8), actions[1]],
        );
      }
      return Row(
        children: [
          Expanded(child: actions[0]),
          const SizedBox(width: 12),
          Expanded(child: actions[1]),
        ],
      );
    },
  );
}
