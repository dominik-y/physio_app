import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/app/role_menu.dart';
import 'package:physio_app/app/session_scope.dart';
import 'package:physio_app/core/result.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/design_system/week_strip.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/patients/patients_bloc.dart';
import 'package:physio_app/l10n/body_parts.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

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
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.patientsTitle),
        actions: [
          RoleMenuButton(
              name: SessionScope.maybeOf(context)?.displayName ??
                  DemoData.physioName),
        ],
      ),
      body: BlocBuilder<PatientsBloc, PatientsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.rows.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline_rounded,
              message: l.noPatientsYet,
              detail: l.addPatientDetail,
            );
          }
          return ContentColumn(
            child: ListView.separated(
              // Bottom padding clears the extended FAB so it never covers a row.
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              itemCount: state.rows.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) =>
                  _DismissiblePatientCard(row: state.rows[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPatientDialog(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(l.addPatient),
      ),
    );
  }

  Future<void> _showAddPatientDialog(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<PatientsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    final result = await showDialog<Result<Patient>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.addPatient),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: l.nameLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l.emailLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final r = await repo.addPatient(
                name: nameController.text,
                email: emailController.text,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(r);
            },
            child: Text(l.add),
          ),
        ],
      ),
    );

    if (result == null) return;
    result.when(
      ok: (patient) => messenger.showSnackBar(
        SnackBar(
            content:
                Text(l.inviteCodeFor(patient.name, patient.inviteCode ?? ''))),
      ),
      err: (message) => messenger.showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(message)),
      ),
    );
  }
}

/// Swipe left to remove a patient (owner request 2026-08-25), with a
/// confirmation dialog — a mis-swipe must never silently drop someone.
class _DismissiblePatientCard extends StatelessWidget {
  final PatientRow row;

  const _DismissiblePatientCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dismissible(
      key: ValueKey('dismiss-${row.patient.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: AppColors.onAccent),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.removePatient),
          content: Text(l.removePatientConfirm(row.patient.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.removeAction),
            ),
          ],
        ),
      ).then((confirmed) => confirmed ?? false),
      onDismissed: (_) =>
          context.read<PatientsRepository>().deletePatient(row.patient.id),
      // Own semantics boundary: without it the Dismissible merges the card
      // into one label-only node and the tap action disappears (web).
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: _PatientCard(row: row),
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
                      ? AppLocalizations.of(context)
                          .daysSilent(row.daysSilent ?? 0)
                      : '${_localizedBodyPart(context, patient.primaryBodyPart)} · ${_lastActiveLabel(context, row)}',
                  // The triage signal must survive 320px — wrap, don't cut.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        row.isSilent ? AppColors.danger : AppColors.textMuted,
                    fontWeight:
                        row.isSilent ? FontWeight.w600 : FontWeight.w400,
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

  String _localizedBodyPart(BuildContext context, String? bodyPart) {
    if (bodyPart == null) return '—';
    return localizedBodyPart(AppLocalizations.of(context), bodyPart);
  }

  String _lastActiveLabel(BuildContext context, PatientRow row) {
    final l = AppLocalizations.of(context);
    if (!row.patient.redeemed) return l.invitedNotRedeemed;
    final days = row.daysSinceLastActive;
    if (days == null) return l.notStarted;
    if (days <= 0) return l.today;
    if (days == 1) return l.yesterday;
    return l.daysAgo(days);
  }
}
