import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/phone.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/states.dart';
import '../../auth/domain/user.dart';

final emergencyContactsProvider =
    AsyncNotifierProvider<EmergencyContactsController, List<EmergencyContact>>(
      EmergencyContactsController.new,
    );

final class EmergencyContactsController
    extends AsyncNotifier<List<EmergencyContact>> {
  static const maxContacts = 3;

  @override
  Future<List<EmergencyContact>> build() =>
      ref.read(authRepositoryProvider).emergencyContacts();

  Future<void> add({
    required String name,
    required String phone,
    String? relation,
  }) async {
    final c = await ref
        .read(authRepositoryProvider)
        .addEmergencyContact(name: name, phone: phone, relation: relation);
    state = AsyncData([...state.value ?? const [], c]);
  }

  Future<void> remove(String id) async {
    final before = state.value ?? const <EmergencyContact>[];
    state = AsyncData(before.where((c) => c.id != id).toList());
    try {
      await ref.read(authRepositoryProvider).removeEmergencyContact(id);
    } on Object {
      state = AsyncData(before);
      rethrow;
    }
  }
}

/// Passengers can always see and edit who receives their SOS location.
class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<(String, String, String?)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddContactSheet(),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(emergencyContactsProvider.notifier)
          .add(name: result.$1, phone: result.$2, relation: result.$3);
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final contacts = ref.watch(emergencyContactsProvider);
    final count = contacts.value?.length ?? 0;

    return AppScaffold(
      title: l.emergencyContacts,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              l.emergencyContactsBody,
              style: AppTypography.bodySecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: contacts.when(
              loading: () => const SkeletonList(count: 3),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(emergencyContactsProvider),
              ),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.contact_emergency_outlined,
                      title: l.noContactsYet,
                      body: l.sosNoContactsHint,
                    )
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, i) {
                        final c = list[i];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.dangerSurface,
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.danger,
                            ),
                          ),
                          title: Text(c.name, style: AppTypography.bodyStrong),
                          subtitle: Text(
                            [
                              Formatters.phoneDisplay(c.phone),
                              c.relation,
                            ].whereType<String>().join(' · '),
                          ),
                          trailing: AppIconButton(
                            icon: Icons.delete_outline_rounded,
                            semanticLabel: l.removeContactSemantic(c.name),
                            color: AppColors.neutral500,
                            onPressed: () async {
                              try {
                                await ref
                                    .read(emergencyContactsProvider.notifier)
                                    .remove(c.id);
                              } on Object catch (e) {
                                if (context.mounted) context.showError(e);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottom: AppButton.primary(
        label: l.addContact,
        icon: Icons.person_add_alt_1_rounded,
        onPressed: count >= EmergencyContactsController.maxContacts
            ? null
            : () => _add(context, ref),
      ),
    );
  }
}

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet();

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.addContact, style: AppTypography.headingMd),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.contactNameLabel),
              validator: (v) => (v ?? '').trim().isEmpty ? l.nameInvalid : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.contactPhoneLabel,
                hintText: l.phoneHint,
              ),
              validator: (v) =>
                  BdPhone.isValid(v ?? '') ? null : l.phoneInvalid,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _relation,
              decoration: InputDecoration(labelText: l.contactRelationLabel),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: l.save,
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                Navigator.pop(context, (
                  _name.text.trim(),
                  BdPhone.normalize(_phone.text)!,
                  _relation.text.trim().isEmpty ? null : _relation.text.trim(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
