import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/providers.dart';
import '../../../router/router.dart';
import '../../../theme/app_theme.dart';
import 'take60_profile_screen_scaffold.dart';

class Take60SecurityScreen extends ConsumerStatefulWidget {
  const Take60SecurityScreen({super.key});

  @override
  ConsumerState<Take60SecurityScreen> createState() =>
      _Take60SecurityScreenState();
}

class _Take60SecurityScreenState extends ConsumerState<Take60SecurityScreen> {
  bool _sendingResetEmail = false;
  String? _statusMessage;
  bool _statusIsError = false;

  Future<void> _sendPasswordReset() async {
    final user = ref.read(authProvider).user;
    final email = user?.email?.trim();
    if (email == null || email.isEmpty) {
      setState(() {
        _statusIsError = true;
        _statusMessage =
            'Aucun email associe a ce compte. Modifie ton profil pour ajouter un email avant de reinitialiser le mot de passe.';
      });
      return;
    }

    setState(() {
      _sendingResetEmail = true;
      _statusMessage = null;
    });

    try {
      await fb_auth.FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _sendingResetEmail = false;
        _statusIsError = false;
        _statusMessage =
            'Email envoye a $email. Suis le lien recu pour creer un nouveau mot de passe.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sendingResetEmail = false;
        _statusIsError = true;
        _statusMessage = 'Erreur Firebase Auth : $error';
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Se deconnecter ?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tu reviendras sur l\'ecran de connexion. Aucune donnee ne sera supprimee.',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se deconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go(AppRouter.auth);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final email = user?.email;
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    final emailVerified = fbUser?.emailVerified ?? false;

    return Take60ProfileScreenScaffold(
      title: 'Confidentialite et securite',
      subtitle:
          'Gere les informations sensibles de ton compte Take60 et reinitialise rapidement ton mot de passe via Firebase Auth.',
      icon: Icons.lock_rounded,
      children: [
        Take60InfoCard(
          icon: Icons.alternate_email_rounded,
          title: email == null || email.isEmpty
              ? 'Aucun email associe'
              : email,
          description: emailVerified
              ? 'Email confirme et utilise pour la recuperation de compte.'
              : 'Email non verifie. Pense a confirmer le lien envoye lors de la creation du compte.',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _sendingResetEmail ? null : _sendPasswordReset,
            icon: _sendingResetEmail
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navy,
                    ),
                  )
                : const Icon(Icons.lock_reset_rounded),
            label: Text(
              'Reinitialiser le mot de passe',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppThemeTokens.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _statusIsError
                    ? AppColors.red
                    : AppThemeTokens.border(context),
              ),
            ),
            child: Text(
              _statusMessage!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _statusIsError
                    ? AppColors.red
                    : AppThemeTokens.primaryText(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Take60InfoCard(
          icon: Icons.shield_rounded,
          title: 'Authentification renforcee',
          description:
              'Active l\'authentification a deux facteurs depuis Firebase Console pour les comptes admins.',
        ),
        const SizedBox(height: 10),
        const Take60InfoCard(
          icon: Icons.history_rounded,
          title: 'Connexions recentes',
          description:
              'Le journal des connexions est conserve cote Firebase Auth. Contacte le support pour un export.',
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              'Se deconnecter',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
