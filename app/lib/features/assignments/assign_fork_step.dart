import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/features/assignments/assign_flow_bloc.dart';

/// Fork screen (spec §4.5, §6.3): the three assign paths, with recent
/// templates listed directly beneath so the common case is one tap.
class AssignForkStep extends StatelessWidget {
  const AssignForkStep({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AssignFlowBloc>();
    return BlocBuilder<AssignFlowBloc, AssignFlowState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              color: AppColors.accentDeep,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('From a template',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onAccent)),
                  const SizedBox(height: 2),
                  Text('${state.templates.length} saved · pick one below',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: AppColors.onAccent.withOpacity(0.75))),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              onTap: () => bloc.add(const StartedCustom()),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Build a custom protocol',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Pick videos from the library, set order and dosage',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              onTap: () => bloc.add(const StartedSingle()),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send a single video',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('One clip, no protocol, no dosage ceremony',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SectionHeader(title: 'Recent templates'),
            if (state.templates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('No templates yet — build a custom protocol and save it as one.',
                    style: TextStyle(color: AppColors.textMuted)),
              )
            else
              for (final template in state.templates) ...[
                _TemplateRow(template: template, onTap: () => bloc.add(StartedFromTemplate(template))),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        );
      },
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final ProtocolTemplate template;
  final VoidCallback onTap;

  const _TemplateRow({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${template.bodyPart} · ${template.items.length} exercises',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
