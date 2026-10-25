import 'package:flutter/material.dart';

import '../../core/network/api_auth_service.dart';
import '../../core/network/auth_session.dart';
import '../../l10n/app_localizations.dart';

class AuthSettingsSection extends StatefulWidget {
  const AuthSettingsSection({super.key, this.authService, this.session});

  final ApiAuthService? authService;
  final AuthSession? session;

  @override
  State<AuthSettingsSection> createState() => _AuthSettingsSectionState();
}

class _AuthSettingsSectionState extends State<AuthSettingsSection> {
  late final AuthSession _session;
  late final ApiAuthService _authService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  ApiAuthFailure? _failure;

  @override
  void initState() {
    super.initState();
    _session =
        widget.session ?? widget.authService?.session ?? AuthSession.shared;
    _authService = widget.authService ?? ApiAuthService(session: _session);
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  void _onCredentialsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text;
    final password = _passwordController.text;
    _passwordController.clear();
    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      await _authService.login(email: email, password: password);
    } on ApiAuthException catch (error) {
      if (mounted) setState(() => _failure = error.failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _failureMessage(AppLocalizations l10n) => switch (_failure) {
    ApiAuthFailure.httpsRequired => l10n.authHttpsSetupNeeded,
    ApiAuthFailure.invalidToken => l10n.authInvalidTokenResponse,
    ApiAuthFailure.unauthorized ||
    ApiAuthFailure.requestFailed => l10n.authLoginFailed,
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final signInReady = _authService.isSignInConfigured;
    final signedIn = _session.isSignedIn;
    final failureMessage = _failureMessage(l10n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.authSettingsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (signedIn) ...[
              Text(l10n.authSignedInMemory),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () {
                    _authService.logout();
                    _passwordController.clear();
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.authSignOutAction),
                ),
              ),
            ] else if (!signInReady) ...[
              Text(
                l10n.authHttpsSetupNeeded,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ] else ...[
              if (_authService.usesInsecureHttp) ...[
                Text(
                  l10n.authHttpRiskNotice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                onChanged: (_) => _onCredentialsChanged(),
                decoration: InputDecoration(labelText: l10n.authEmailLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => _onCredentialsChanged(),
                decoration: InputDecoration(labelText: l10n.authPasswordLabel),
              ),
              if (failureMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  failureMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed:
                      _submitting ||
                              _emailController.text.trim().isEmpty ||
                              _passwordController.text.isEmpty
                          ? null
                          : _signIn,
                  icon:
                      _submitting
                          ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.login),
                  label: Text(
                    _submitting ? l10n.authSigningIn : l10n.authSignInAction,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
