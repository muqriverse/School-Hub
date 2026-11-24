import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data/schools.dart';

const _selectorInk = Color(0xFF4A4038);
const _selectorMuted = Color(0xFF8A7E74);
const _selectorPaper = Color(0xFFFAF7F2);
const _selectorPurple = Color(0xFF9A7E68);

class AdminSchoolSelector extends StatelessWidget {
  const AdminSchoolSelector({
    super.key,
    required this.selectedSchool,
    required this.onSelected,
  });

  final String selectedSchool;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: selectedSchool,
    child: Material(
      color: _selectorPaper,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () => _selectSchool(context),
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEKOLAH UNTUK SERVIS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _selectorMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schoolDisplayName(selectedSchool),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _selectorInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.unfold_more_rounded, color: _selectorMuted),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _selectSchool(BuildContext context) async {
    final listHeight = math.min(
      420.0,
      math.max(180.0, MediaQuery.sizeOf(context).height - 210),
    );
    final school = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pilih sekolah'),
        content: SizedBox(
          width: 480,
          height: listHeight,
          child: ListView.separated(
            itemCount: supportedSchools.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final school = supportedSchools[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(school, softWrap: true),
                trailing: school == selectedSchool
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: _selectorPurple,
                      )
                    : null,
                onTap: () => Navigator.of(dialogContext).pop(school),
              );
            },
          ),
        ),
      ),
    );
    if (school != null) onSelected(school);
  }
}
