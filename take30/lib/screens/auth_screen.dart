import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';
import '../widgets/take30_logo.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.initialTab = 'login',
    this.redirectTo,
  });

  final String initialTab;
  final String? redirectTo;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'register' ? 1 : 0,
    );
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = ref.read(authProvider.notifier);
    if (_tabs.index == 0) {
      await auth.login(_emailCtrl.text, _passwordCtrl.text);
    } else {
      await auth.register(
        _usernameCtrl.text.isEmpty ? 'LunaAct' : _usernameCtrl.text,
        _emailCtrl.text,
        _passwordCtrl.text,
      );
    }
    if (mounted) {
      final state = ref.read(authProvider);
      if (state.isAuthenticated) {
        context.go(_destinationAfterAuth(state));
      }
    }
  }

  Future<void> _openDemo() async {
    await ref.read(authProvider.notifier).loginDemo();
    if (mounted) {
      final state = ref.read(authProvider);
      if (state.isAuthenticated) {
        context.go(_destinationAfterAuth(state));
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    await ref.read(authProvider.notifier).loginWithGoogle();
    if (mounted) {
      final state = ref.read(authProvider);
      if (state.isAuthenticated) {
        context.go(_destinationAfterAuth(state));
      }
    }
  }

  Future<void> _loginWithApple() async {
    await ref.read(authProvider.notifier).loginWithApple();
    if (mounted) {
      final state = ref.read(authProvider);
      if (state.isAuthenticated) {
        context.go(_destinationAfterAuth(state));
      }
    }
  }

  String _destinationAfterAuth(AuthState state) {
    final requestedPath = widget.redirectTo;
    if (requestedPath != null && requestedPath.startsWith('/')) {
      return requestedPath;
    }
    if (state.user?.isAdmin ?? false) {
      return '/admin';
    }
    return '/home';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(gradient: AppThemeTokens.pageGradient(context)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppThemeTokens.pageHorizontalPadding,
            ),
            child: Column(
              children: [
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.topCenter,
                child: Take30Logo(height: 72),
              ),
              const SizedBox(height: 10),
              Text(
                'Prouve ton talent en 60 secondes',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppThemeTokens.primaryText(context),
                ),
              ),
              const SizedBox(height: 36),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppThemeTokens.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.navy,
                  unselectedLabelColor: AppThemeTokens.tertiaryText(context),
                  labelStyle: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Connexion'),
                    Tab(text: 'Inscription'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (_tabs.index == 1) ...[
                _field(
                  ctrl: _usernameCtrl,
                  label: 'Nom d\'utilisateur',
                  hint: '@monpseudo',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
              ],
              _field(
                ctrl: _emailCtrl,
                label: _tabs.index == 0
                    ? 'Email / nom d\'utilisateur'
                    : 'Email',
                hint: _tabs.index == 0 ? 'ton@email.com ou tonpseudo' : 'ton@email.com',
                icon: Icons.email_outlined,
                type: _tabs.index == 0
                    ? TextInputType.text
                    : TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _field(
                ctrl: _passwordCtrl,
                label: 'Mot de passe',
                hint: '••••••••',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              if (authState.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navy,
                          ),
                        )
                      : Text(
                          _tabs.index == 0 ? 'Se connecter' : 'Créer un compte',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                ),
              ),
                    const SizedBox(height: 14),
                    _SocialAuthButton(
                      label: 'Continuer avec Google',
                      icon: Icons.g_mobiledata_rounded,
                      onTap: authState.isLoading ? null : _loginWithGoogle,
                    ),
                    const SizedBox(height: 10),
                    _SocialAuthButton(
                      label: 'Continuer avec Apple',
                      icon: Icons.apple_rounded,
                      onTap: authState.isLoading ? null : _loginWithApple,
                    ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: authState.isLoading ? null : _openDemo,
                child: Text(
                  'Accès démo →',
                  style: GoogleFonts.dmSans(
                    color: AppColors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () => context.go(AppRouter.admin),
                child: Text(
                  'Accès admin →',
                  style: GoogleFonts.dmSans(
                    color: AppColors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/onboarding'),
                child: Text(
                  '← Retour',
                  style: GoogleFonts.dmSans(
                    color: AppThemeTokens.secondaryText(context),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppThemeTokens.secondaryText(context),
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl,
          obscureText: isPassword && _obscure,
          keyboardType: type,
          style: TextStyle(color: AppThemeTokens.primaryText(context)),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppThemeTokens.tertiaryText(context),
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppThemeTokens.tertiaryText(context),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: AppThemeTokens.primaryText(context), size: 22),
        label: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppThemeTokens.primaryText(context),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppThemeTokens.border(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
