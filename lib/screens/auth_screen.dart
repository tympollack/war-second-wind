import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignIn = true;
  bool _loading  = false;
  bool _showPw   = false;
  bool _showCpw  = false;
  String? _error;

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  final _cpwCtrl   = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _pwCtrl.dispose();   _cpwCtrl.dispose();
    super.dispose();
  }

  void _switchMode() => setState(() {
        _isSignIn = !_isSignIn;
        _error    = null;
      });

  Future<void> _submit() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });

    final auth = context.read<AuthService>();
    String? err;

    if (_isSignIn) {
      err = await auth.signIn(
        email:    _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );
    } else {
      if (_pwCtrl.text != _cpwCtrl.text) {
        err = 'Passwords do not match.';
      } else {
        err = await auth.signUp(
          email:       _emailCtrl.text.trim(),
          password:    _pwCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
      }
    }

    if (mounted) setState(() { _loading = false; _error = err; });
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthService>().signInWithGoogle();
    if (mounted) setState(() { _loading = false; _error = err; });
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthService>().resetPassword(email);
    if (!mounted) return;
    setState(() { _loading = false; _error = err; });
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 52),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildModeToggle(),
                const SizedBox(height: 28),
                _buildForm(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBox(message: _error!),
                ],
                const SizedBox(height: 20),
                _buildSubmitButton(),
                const SizedBox(height: 20),
                _buildDivider(),
                const SizedBox(height: 20),
                _buildGoogleButton(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        const Text(
          'WAR',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            letterSpacing: 14,
            color: Color(0xFF1B2B4B),
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'CARD GAME FOR TWO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B2B4B).withOpacity(0.32),
          ),
        ),
      ],
    );
  }

  // ── Mode toggle ───────────────────────────────────────────────────────────
  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ModeTab(label: 'Sign In',        active: _isSignIn,  onTap: _isSignIn  ? null : _switchMode),
          _ModeTab(label: 'Create Account', active: !_isSignIn, onTap: !_isSignIn ? null : _switchMode),
        ],
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (!_isSignIn) ...[
              _Field(
                controller: _nameCtrl,
                label:      'Display name',
                icon:       Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
            ],
            _Field(
              controller:      _emailCtrl,
              label:           'Email',
              icon:            Icons.email_outlined,
              keyboardType:    TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _Field(
              controller:      _pwCtrl,
              label:           'Password',
              icon:            Icons.lock_outline,
              obscure:         !_showPw,
              textInputAction: _isSignIn ? TextInputAction.done : TextInputAction.next,
              onFieldSubmitted: _isSignIn ? (_) => _submit() : null,
              suffix: IconButton(
                icon: Icon(_showPw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20, color: const Color(0xFF8899BB)),
                onPressed: () => setState(() => _showPw = !_showPw),
              ),
            ),
            if (!_isSignIn) ...[
              const SizedBox(height: 12),
              _Field(
                controller:      _cpwCtrl,
                label:           'Confirm password',
                icon:            Icons.lock_outline,
                obscure:         !_showCpw,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffix: IconButton(
                  icon: Icon(_showCpw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20, color: const Color(0xFF8899BB)),
                  onPressed: () => setState(() => _showCpw = !_showCpw),
                ),
              ),
            ],
            if (_isSignIn) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4B6087),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Forgot password?',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B2B4B),
          disabledBackgroundColor: const Color(0xFF1B2B4B).withOpacity(0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white))
            : Text(
                _isSignIn ? 'Sign In' : 'Create Account',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Divider ───────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(children: [
      const Expanded(child: Divider(color: Color(0xFFE0E6F0))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or',
            style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF1B2B4B).withOpacity(0.35),
                fontWeight: FontWeight.w500)),
      ),
      const Expanded(child: Divider(color: Color(0xFFE0E6F0))),
    ]);
  }

  // ── Google button ─────────────────────────────────────────────────────────
  Widget _buildGoogleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _googleSignIn,
        icon: const Text('G',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFDB4437))),
        label: const Text('Continue with Google',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2C3E60))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD8E0EE)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _ModeTab({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [const BoxShadow(
                    color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF1B2B4B) : const Color(0xFF8899BB),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:      controller,
      obscureText:     obscure,
      keyboardType:    keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1B2B4B)),
      decoration: InputDecoration(
        labelText:     label,
        labelStyle:    const TextStyle(fontSize: 14, color: Color(0xFF8899BB)),
        prefixIcon:    Icon(icon, size: 20, color: const Color(0xFF8899BB)),
        suffixIcon:    suffix,
        filled:        true,
        fillColor:     const Color(0xFFF5F6FA),
        border:        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: Color(0xFFE0E6F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: Color(0xFFE0E6F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: Color(0xFF1B2B4B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFFDC2626), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}