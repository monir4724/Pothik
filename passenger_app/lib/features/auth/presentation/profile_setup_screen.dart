import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/auth/domain/user.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/states.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'auth_controller.dart';

/// Used both for first-run profile completion and later edits.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({this.isEdit = false, super.key});

  final bool isEdit;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final User? _current = ref
      .read(authControllerProvider.notifier)
      .currentUser;
  late final _name = TextEditingController(text: _current?.name ?? '');
  late final _email = TextEditingController(text: _current?.email ?? '');
  late final _username = TextEditingController(text: _current?.username ?? '');
  late String? _photoUrl = _current?.photoUrl;
  late Gender? _gender = _current?.gender;
  late DateTime? _dob = _current?.dateOfBirth;
  bool _saving = false;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _username.dispose();
    super.dispose();
  }

  User get _preview => User(
    id: _current?.id ?? '',
    phone: _current?.phone ?? '',
    name: _name.text,
    email: _current?.email,
    locale: _current?.locale,
    photoUrl: _photoUrl,
    username: _username.text,
    gender: _gender,
    dateOfBirth: _dob,
  );

  Future<void> _photoSheet() async {
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.addPhoto),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (_photoUrl != null && _photoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(l.removePhoto),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'delete') {
      setState(() => _photoUrl = null);
      return;
    }
    await _pickPhoto(
      choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final l = AppLocalizations.of(context);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || !mounted) return;
      setState(() {
        _photoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    } on Object {
      if (mounted) context.showSnack(l.photoPickFailed);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 12, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            name: _name.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            photoUrl: _photoUrl,
            clearPhoto: _photoUrl == null || _photoUrl!.isEmpty,
            username: _username.text.trim().isEmpty
                ? null
                : _username.text.trim(),
            gender: _gender,
            dateOfBirth: _dob,
            clearDateOfBirth: _dob == null,
          );
      if (!mounted) return;
      if (widget.isEdit) {
        context.showSnack(AppLocalizations.of(context).profileSaved);
        context.pop();
      }
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return AppScaffold(
      title: widget.isEdit ? l.editProfile : '',
      showBack: widget.isEdit,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isEdit) ...[
                Text(l.profileSetupTitle, style: AppTypography.headingLg),
                const SizedBox(height: AppSpacing.sm),
                Text(l.profileSetupBody, style: AppTypography.bodySecondary),
                const SizedBox(height: AppSpacing.xl),
              ],
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        UserAvatar(user: _preview, radius: 48),
                        Material(
                          color: AppColors.amber500,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _photoSheet,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _photoSheet,
                      child: Text(
                        _photoUrl == null || _photoUrl!.isEmpty
                            ? l.addPhoto
                            : l.changePhoto,
                      ),
                    ),
                    Text(l.cropPhotoHint, style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                autofocus: !widget.isEdit,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(labelText: l.nameLabel),
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? l.nameInvalid : null,
                onChanged: (_) => setState(() {}),
              ),
              if (widget.isEdit) ...[
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _username,
                  decoration: InputDecoration(
                    labelText: l.usernameLabel,
                    hintText: l.usernameHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.phoneLabel,
                    suffixIcon: Chip(
                      label: Text(l.phoneVerified),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.successSurface,
                      labelStyle: AppTypography.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  child: Text(
                    _current == null
                        ? ''
                        : Formatters.phoneDisplay(_current.phone),
                    style: AppTypography.body,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l.emailLabel),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  return _emailRe.hasMatch(t) ? null : l.emailInvalid;
                },
              ),
              if (widget.isEdit) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l.genderLabel, style: AppTypography.bodySecondary),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final g in Gender.values)
                      ChoiceChip(
                        label: Text(switch (g) {
                          Gender.male => l.genderMale,
                          Gender.female => l.genderFemale,
                          Gender.other => l.genderOther,
                        }),
                        selected: _gender == g,
                        onSelected: (v) =>
                            setState(() => _gender = v ? g : null),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.dateOfBirth),
                  subtitle: Text(
                    _dob == null
                        ? l.notSet
                        : DateFormat.yMMMMd(locale).format(_dob!),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDob,
                ),
              ],
            ],
          ),
        ),
      ),
      bottom: AppButton.primary(
        label: widget.isEdit ? l.save : l.continueLabel,
        onPressed: _save,
        isLoading: _saving,
      ),
    );
  }
}
