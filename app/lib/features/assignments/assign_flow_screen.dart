import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:physio_app/design_system/colors.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/assignments/assign_flow_bloc.dart';
import 'package:physio_app/features/assignments/assign_fork_step.dart';
import 'package:physio_app/features/assignments/dosage_editor_step.dart';
import 'package:physio_app/features/assignments/video_picker_step.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// The single routed widget for the whole assign flow (plan amendment 7):
/// fork → picker → dosage, navigated internally via bloc state, not
/// go_router sub-routes.
class AssignFlowScreen extends StatelessWidget {
  final String patientId;

  const AssignFlowScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AssignFlowBloc(
        patientId,
        context.read<AssignmentsRepository>(),
        context.read<TemplatesRepository>(),
        context.read<LibraryRepository>(),
        context.read<PatientsRepository>(),
      ),
      child: const _AssignFlowView(),
    );
  }
}

class _AssignFlowView extends StatelessWidget {
  const _AssignFlowView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AssignFlowBloc>();
    return BlocConsumer<AssignFlowBloc, AssignFlowState>(
      listenWhen: (previous, current) => previous.submitStatus != current.submitStatus,
      listener: (context, state) {
        final l = AppLocalizations.of(context);
        if (state.submitStatus == AssignSubmitStatus.success) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.assignedToast)));
          context.pop();
        } else if (state.submitStatus == AssignSubmitStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Text(state.failureMessage ?? l.somethingWentWrong),
            ),
          );
        }
      },
      builder: (context, state) {
        final atFork = state.step == AssignFlowStep.fork;
        return PopScope(
          canPop: atFork,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) bloc.add(const BackPressed());
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(_titleFor(context, state)),
              leading: IconButton(
                icon: Icon(atFork ? Icons.close : Icons.arrow_back),
                onPressed: () {
                  if (atFork) {
                    context.pop();
                  } else {
                    bloc.add(const BackPressed());
                  }
                },
              ),
            ),
            body: ContentColumn(
              child: switch (state.step) {
                AssignFlowStep.fork => const AssignForkStep(),
                AssignFlowStep.picker => const VideoPickerStep(),
                AssignFlowStep.dosage => const DosageEditorStep(),
              },
            ),
          ),
        );
      },
    );
  }

  String _titleFor(BuildContext context, AssignFlowState state) {
    final l = AppLocalizations.of(context);
    switch (state.step) {
      case AssignFlowStep.fork:
        return l.assignTitle;
      case AssignFlowStep.picker:
        return state.type == AssignmentType.single ? l.sendAVideo : l.chooseVideos;
      case AssignFlowStep.dosage:
        return state.patientName.isEmpty ? l.adjustDosage : l.adjustFor(state.patientName);
    }
  }
}
