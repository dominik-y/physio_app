import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/design_system/week_strip.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/patients/patient_detail_bloc.dart';

class PatientDetailPage extends StatelessWidget {
  final String patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientDetailBloc(
        patientId: patientId,
        patientsRepository: context.read<PatientsRepository>(),
        assignmentsRepository: context.read<AssignmentsRepository>(),
        completionsRepository: context.read<CompletionsRepository>(),
        libraryRepository: context.read<LibraryRepository>(),
      ),
      child: _PatientDetailView(patientId: patientId),
    );
  }
}

class _PatientDetailView extends StatelessWidget {
  final String patientId;

  const _PatientDetailView({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocConsumer<PatientDetailBloc, PatientDetailState>(
        listenWhen: (previous, current) =>
            previous.lastGeneratedCode != current.lastGeneratedCode &&
            current.lastGeneratedCode != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('New invite code: ${state.lastGeneratedCode}')),
          );
        },
        builder: (context, state) {
          if (state.loading || state.patient == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final patient = state.patient!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
            children: [
              _Header(patient: patient, daysSinceLastActive: state.daysSinceLastActive),
              if (!patient.redeemed) ...[
                const SizedBox(height: AppSpacing.md),
                _InvitePanel(patient: patient),
              ],
              const SectionHeader(title: 'Active protocols'),
              if (state.protocols.isEmpty)
                const _EmptySection(message: 'No active protocols yet.')
              else
                for (final p in state.protocols) ...[
                  _ProtocolCard(progress: p),
                  const SizedBox(height: AppSpacing.sm),
                ],
              if (state.singles.isNotEmpty) ...[
                const SectionHeader(title: 'Also assigned'),
                for (final single in state.singles)
                  for (final item in single.items) ...[
                    _SingleRow(
                      item: item,
                      isPrivate: state.privateVideoIds.contains(item.videoId),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
              const SectionHeader(title: 'Private notes'),
              _NotesField(
                key: ValueKey('notes-${patient.id}'),
                initialNotes: state.notes,
                onChanged: (text) => context.read<PatientDetailBloc>().add(NotesChanged(text)),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Assign something',
                onPressed: () => context.go('/physio/patients/$patientId/assign'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Patient patient;
  final int? daysSinceLastActive;

  const _Header({required this.patient, required this.daysSinceLastActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialsAvatar(name: patient.name, size: 56),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Never ellipsize a patient's name — wrap instead.
              Text(patient.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                '${patient.primaryBodyPart ?? '—'} · ${_lastActiveLabel()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _lastActiveLabel() {
    if (!patient.redeemed) return 'invited — code not redeemed';
    final days = daysSinceLastActive;
    if (days == null) return 'no activity yet';
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}

class _InvitePanel extends StatelessWidget {
  final Patient patient;

  const _InvitePanel({required this.patient});

  @override
  Widget build(BuildContext context) {
    final expires = patient.inviteExpiresAt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invite code',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            patient.inviteCode ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.accentDeep,
            ),
          ),
          if (expires != null) ...[
            const SizedBox(height: 2),
            Text('expires ${DateFormat.MMMd().format(expires)}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Regenerate code',
            onPressed: () =>
                context.read<PatientDetailBloc>().add(const RegenerateInvitePressed()),
          ),
        ],
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  final AssignmentProgress progress;

  const _ProtocolCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final a = progress.assignment;
    final pct = progress.adherence;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${a.items.length} exercises · ${progress.doneCount} done · ${progress.skippedCount} skipped',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                WeekStrip(marks: progress.strip),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            pct == null ? '—' : '${(pct * 100).round()}%',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accentDeep),
          ),
        ],
      ),
    );
  }
}

class _SingleRow extends StatelessWidget {
  final ExerciseItem item;
  final bool isPrivate;

  const _SingleRow({required this.item, required this.isPrivate});

  @override
  Widget build(BuildContext context) {
    // Deliberately lighter than protocol cards: singles are secondary content.
    return AppCard(
      color: AppColors.bg,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          VideoThumb(bodyPart: item.bodyPart),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(formatDuration(item.durationSec),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          if (isPrivate) ...[
            const SizedBox(width: AppSpacing.sm),
            const StatusChip.private(),
          ],
        ],
      ),
    );
  }
}

class _NotesField extends StatefulWidget {
  final String initialNotes;
  final ValueChanged<String> onChanged;

  const _NotesField({super.key, required this.initialNotes, required this.onChanged});

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNotes);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: 4,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(hintText: 'Clinical context only you can see…'),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
    );
  }
}
