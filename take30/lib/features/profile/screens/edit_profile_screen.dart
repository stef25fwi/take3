import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import '../providers/take60_profile_providers.dart';
import 'take60_profile_screen_scaffold.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarController;

  bool _isSaving = false;
  String? _saveError;
  bool _saved = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _avatarController = TextEditingController();
  }

  void _ensureInitialized() {
    if (_initialized) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _displayNameController.text = user.displayName;
    _usernameController.text = user.username;
    _bioController.text = user.bio;
    _avatarController.text = user.avatarUrl;
    _initialized = true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    if (user == null || _isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
      _saved = false;
    });

    final patch = <String, dynamic>{
      'displayName': _displayNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
      'avatarUrl': _avatarController.text.trim(),
    };

    try {
      await ref.read(apiServiceProvider).users.updateProfile(user.id, patch);
      await ref.read(apiServiceProvider).refreshCurrentUser();
      ref.read(profileProvider(user.id).notifier).load();
      ref.invalidate(currentTake60UserProfileProvider);
      if (!mounted) return;
      setState(() {
        _saved = true;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    final user = ref.watch(authProvider).user;
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);

    if (user == null) {
      return Take60ProfileScreenScaffold(
        title: 'Modifier mon profil',
        subtitle: 'Connecte-toi pour modifier tes informations.',
        children: [
          ElevatedButton(
            onPressed: () => context.go('/auth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.navy,
            ),
            child: Text(
              'Aller a la connexion',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }

    return Take60ProfileScreenScaffold(
      title: 'Modifier mon profil',
      subtitle:
          'Mets a jour les informations publiques de ton profil Take60. Les changements sont synchronises immediatement avec Firestore.',
      icon: Icons.edit_rounded,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileTextField(
                controller: _displayNameController,
                label: 'Nom affiche',
                hint: 'Ex: Lina Take60',
                maxLength: 60,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Le nom affiche est requis.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _ProfileTextField(
                controller: _usernameController,
                label: 'Pseudo (@username)',
                hint: 'Ex: lina_take60',
                maxLength: 30,
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) {
                    return 'Le pseudo est requis.';
                  }
                  if (v.contains(' ')) {
                    return 'Pas d\'espace dans le pseudo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _ProfileTextField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Quelques mots sur ton univers...',
                maxLines: 4,
                maxLength: 240,
              ),
              const SizedBox(height: 14),
              _ProfileTextField(
                controller: _avatarController,
                label: 'Lien de l\'avatar',
                hint: 'https://...',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.navy,
                          ),
                        )
                      : Text(
                          'Enregistrer',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Erreur : ${_saveError!}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_saved) ...[
                const SizedBox(height: 14),
                Text(
                  'Profil mis a jour.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Informations sensibles',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'L\'email et le mot de passe se modifient depuis l\'ecran "Confidentialite et securite" pour preserver l\'integrite du compte.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  height: 1.5,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeTokens.primaryText(context);
    final secondary = AppThemeTokens.secondaryText(context);
    final border = AppThemeTokens.border(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: primary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppThemeTokens.tertiaryText(context),
            ),
            counterText: '',
            filled: true,
            fillColor: AppThemeTokens.surfaceMuted(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.yellow),
            ),
          ),
        ),
      ],
    );
  }
}
