import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/app/role_menu.dart';
import 'package:physio_app/core/result.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/design_system/week_strip.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/patients/patients_bloc.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientsBloc(
        patientsRepository: context.read<PatientsRepository>(),
        assignmentsRepository: context.read<AssignmentsRepository>(),
        completionsRepository: context.read<CompletionsRepository>(),
      ),
      child: const _PatientsView(),
    );
  }
}

class _PatientsView extends StatelessWidget {
  const _PatientsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: const [RoleMenuButton(name: DemoData.physioName)],
      ),
      body: BlocBuilder<PatientsBloc, PatientsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.rows.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              message: 'No patients yet',
              detail: 'Add a patient to send them an invite code.',
            );
          }
          return ListView.separated(
            // Bottom padding clears the extended FAB so it never covers a row.
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
            itemCount: state.rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _PatientCard(row: state.rows[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPatientDialog(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add patient'),
      ),
    );
  }

  Future<void> _showAddPatientDialog(BuildContext context) async {
    final repo = context.read<PatientsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    final result = await showDialog<Result<Patient>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final r = await repo.addPatient(
                name: nameController.text,
                email: emailController.text,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(r);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null) return;
    result.when(
      ok: (patient) => messenger.showSnackBar(
        SnackBar(content: Text('Invite code for ${patient.name}: ${patient.inviteCode}')),
      ),
      err: (message) => messenger.showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(message)),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientRow row;

  const _PatientCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final patient = row.patient;
    return AppCard(
      onTap: () => context.go('/physio/patients/${patient.id}'),
      child: Row(
        children: [
          InitialsAvatar(name: patient.name),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Names always show in full — wrap before truncating
                // (owner call 2026-08-25: never ellipsize a patient's name).
                Text(patient.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  row.isSilent
                      ? '${row.daysSilent} days silent'
                      : '${patient.primaryBodyPart ?? '—'} · ${_lastActiveLabel(row)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: row.isSilent ? AppColors.danger : AppColors.textMuted,
                    fontWeight: row.isSilent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          row.invited
              ? const StatusChip.invited()
              // Bigger triage dots where width allows; names win on narrow phones.
              : WeekStrip(
                  marks: row.strip,
                  dotSize: MediaQuery.sizeOf(context).width < 360 ? 9 : 10,
                ),
        ],
      ),
    );
  }

  String _lastActiveLabel(PatientRow row) {
    if (!row.patient.redeemed) return 'invited — code not redeemed';
    final days = row.daysSinceLastActive;
    if (days == null) return 'not started';
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}
