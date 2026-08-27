import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/app/language_toggle.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/firebase/auth_cubit.dart';
import 'package:physio_app/firebase/auth_failure_l10n.dart';
import 'package:physio_app/firebase/auth_service.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Client-side shape check only — never asks the backend whether an
/// account exists (Firebase deliberately returns the same error for wrong
/// email and wrong password; anything else enables user enumeration).
bool looksLikeEmail(String s) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

/// The signed-out gate: Prijava, with "Imam pozivni kod" as a local flip
/// (no Navigator — the whole gate gets swapped out by the bootstrap the
/// moment AuthCubit lands on AuthReady).
class SignedOutFlow extends StatefulWidget {
  const SignedOutFlow({super.key});

  @override
  State<SignedOutFlow> createState() => _SignedOutFlowState();
}

class _SignedOutFlowState extends State<SignedOutFlow> {
  var _showInvite = false;

  @override
  Widget build(BuildContext context) {
    return _showInvite
        ? InviteScreen(onBack: () => setState(() => _showInvite = false))
        : LoginScreen(onInvite: () => setState(() => _showInvite = true));
  }
}

class GateSplash extends StatelessWidget {
  const GateSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onInvite;

  const LoginScreen({super.key, required this.onInvite});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = l.fieldRequired);
      return;
    }
    if (!looksLikeEmail(_email.text)) {
      setState(() => _error = l.errInvalidEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure =
        await context.read<AuthCubit>().signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure?.message(l);
    });
    // Success needs nothing here: the auth stream drives the bootstrap.
  }

  Future<void> _forgotPassword() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_email.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.resetEmailEnterFirst)));
      return;
    }
    final failure =
        await context.read<AuthCubit>().sendPasswordReset(_email.text);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(failure == null
            ? l.resetEmailSent
            : failure.message(AppLocalizations.of(context)))));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GateScaffold(
      children: [
        Text(l.signInTitle,
            textAlign: TextAlign.center, style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(l.signInSubtitle,
            textAlign: TextAlign.center, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l.emailLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _busy ? null : _submit(),
          decoration: InputDecoration(labelText: l.passwordLabel),
        ),
        _StatusSlot(error: _error),
        PrimaryButton(
            label: l.signInButton,
            busy: _busy,
            onPressed: _busy ? null : _submit),
        TextButton(
            onPressed: _busy ? null : _forgotPassword,
            child: Text(l.forgotPassword)),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
            label: l.haveInviteCode,
            expanded: true,
            onPressed: _busy ? null : widget.onInvite),
      ],
    );
  }
}

/// Invite redemption. [onBack] null means the notLinked recovery variant:
/// the user is already signed in, only the code is asked for, and the exit
/// is sign-out instead of back-to-login.
class InviteScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const InviteScreen({super.key, this.onBack});

  bool get forCurrentUser => onBack == null;

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final cubit = context.read<AuthCubit>();
    if (_code.text.trim().isEmpty ||
        (!widget.forCurrentUser &&
            (_email.text.trim().isEmpty || _password.text.isEmpty))) {
      setState(() => _error = l.fieldRequired);
      return;
    }
    if (!widget.forCurrentUser && !looksLikeEmail(_email.text)) {
      setState(() => _error = l.errInvalidEmail);
      return;
    }
    if (!widget.forCurrentUser && _password.text != _confirm.text) {
      setState(() => _error = l.passwordsDontMatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = widget.forCurrentUser
        ? await cubit.redeemForCurrentUser(_code.text)
        : await cubit.redeemInvite(
            code: _code.text, email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure?.message(l);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GateScaffold(
      children: [
        Text(widget.forCurrentUser ? l.notLinkedTitle : l.inviteTitle,
            textAlign: TextAlign.center, style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(widget.forCurrentUser ? l.notLinkedBody : l.inviteSubtitle,
            textAlign: TextAlign.center, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          textInputAction: widget.forCurrentUser
              ? TextInputAction.done
              : TextInputAction.next,
          decoration: InputDecoration(labelText: l.inviteCodeLabel),
        ),
        if (!widget.forCurrentUser) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.emailLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.passwordLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _confirm,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _submit(),
            decoration: InputDecoration(labelText: l.confirmPasswordLabel),
          ),
        ],
        _StatusSlot(error: _error),
        PrimaryButton(
            label: l.createAccountButton,
            busy: _busy,
            onPressed: _busy ? null : _submit),
        const SizedBox(height: AppSpacing.sm),
        if (widget.forCurrentUser)
          TextButton(
              onPressed:
                  _busy ? null : () => context.read<AuthCubit>().signOut(),
              child: Text(l.signOutLabel))
        else
          TextButton(
              onPressed: _busy ? null : widget.onBack,
              child: Text(l.backToSignIn)),
      ],
    );
  }
}

/// Signed in but identity resolution failed for a non-notLinked reason
/// (typically offline first boot on this device).
class ResolveErrorScreen extends StatelessWidget {
  final AuthFailure failure;

  const ResolveErrorScreen({super.key, required this.failure});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GateScaffold(
      children: [
        Text(failure.message(l),
            textAlign: TextAlign.center, style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
            label: l.retryButton,
            onPressed: () => context.read<AuthCubit>().retryResolve()),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
            onPressed: () => context.read<AuthCubit>().signOut(),
            child: Text(l.signOutLabel)),
      ],
    );
  }
}

/// Shared gate chrome: Tendo logo over a centered, width-capped column —
/// the same visual language as the demo's role gate.
class GateScaffold extends StatelessWidget {
  final List<Widget> children;

  const GateScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.md,
              child: LanguageToggle(),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label: 'Poliklinika Tendo',
                        image: true,
                        child: Image.asset(
                          'assets/branding/tendo_logo_light.png',
                          width: 220,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Always-present error slot between the fields and the submit button.
/// Reserving the height keeps the centered column from jumping when an
/// error appears, is cleared on retry, or comes back (observed on-device
/// as a ~10 px flicker of the whole gate).
class _StatusSlot extends StatelessWidget {
  final String? error;

  const _StatusSlot({required this.error});

  @override
  Widget build(BuildContext context) {
    final text = error;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: text == null
          ? const SizedBox.shrink()
          : Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
    );
  }
}
