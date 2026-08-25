import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/templates/templates_bloc.dart';

/// Read-only template list (spec §4.5.2 — templates are created via the
/// assign flow's "save as template", not authored here).
class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TemplatesBloc(
        templatesRepository: context.read<TemplatesRepository>(),
        libraryRepository: context.read<LibraryRepository>(),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Templates')),
        body: BlocBuilder<TemplatesBloc, TemplatesState>(
          builder: (context, state) {
            if (state.loading) return const SizedBox.shrink();
            if (state.rows.isEmpty) {
              return const EmptyState(
                icon: Icons.assignment_outlined,
                message: 'No templates yet',
                detail: 'Save one from the assign flow after building a protocol.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final row in state.rows) ...[
                  _TemplateCard(row: row),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.md),
                // Soft anchor so a short list reads as calm, not unfinished.
                const Center(
                  child: Text(
                    'New templates are saved from the assign flow',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateRow row;

  const _TemplateCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final t = row.template;
    final count = t.items.length;
    final subtitle = row.totalDurationSec == null
        ? '$count exercises'
        : '${t.bodyPart} · $count exercises · ~${(row.totalDurationSec! / 60).ceil()} min';
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
