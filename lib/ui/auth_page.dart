import 'package:flutter/material.dart';

import '../data/database_service.dart';
import '../data/models.dart';
import 'components.dart';
import 'theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.database, required this.onSignedIn});
  final DatabaseService database;
  final Future<void> Function(BroteUser user) onSignedIn;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _isRegistering = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = _isRegistering
          ? await widget.database.register(
              name: _name.text,
              email: _email.text,
              password: _password.text,
            )
          : await widget.database.signIn(
              email: _email.text,
              password: _password.text,
            );
      await widget.onSignedIn(user);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Escribe $label.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: EdgeInsets.all(isWide ? 28 : 18),
              child: isWide
                  ? Row(
                      children: [
                        Expanded(child: _welcomePanel()),
                        const SizedBox(width: 24),
                        Expanded(child: _formPanel()),
                      ],
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 16),
                        _mobileWelcome(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(child: _formPanel()),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileWelcome() => Row(
    children: [
      const BroteMark(),
      const Spacer(),
      Text(
        _isRegistering ? 'EMPIEZA AQUÍ' : 'TU RINCÓN VERDE',
        style: const TextStyle(
          fontSize: 9,
          color: mutedInk,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _welcomePanel() => Container(
    height: double.infinity,
    padding: const EdgeInsets.all(34),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Stack(
      children: [
        Positioned(
          top: 5,
          right: 0,
          child: Icon(
            Icons.spa_rounded,
            size: 160,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BroteMark(light: true),
            const Spacer(),
            const Eyebrow('UNA PAUSA PARA CRECER', color: Color(0xFFB7C7A8)),
            const SizedBox(height: 15),
            Text(
              _isRegistering
                  ? 'Hazle espacio\na algo vivo.'
                  : 'Un poco de cuidado,\nmucho de verde.',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(color: paper, fontSize: 43),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu bitácora sencilla para saber qué tienes, qué necesita y cuándo volver a mirarlo.',
              style: TextStyle(
                color: Color(0xFFD4D8CF),
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const Spacer(),
            const Row(
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 17,
                  color: Color(0xFFD6DCA9),
                ),
                SizedBox(width: 8),
                Text(
                  'Menos recordatorios. Más ritual.',
                  style: TextStyle(color: Color(0xFFD4D8CF), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  Widget _formPanel() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (MediaQuery.sizeOf(context).width >= 760) ...[
              const Eyebrow('BIENVENIDA A CASA'),
              const SizedBox(height: 12),
            ],
            Text(
              _isRegistering ? 'Crea tu cuenta' : 'Qué gusto verte',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 7),
            Text(
              _isRegistering
                  ? 'Tu colección empieza con un primer brote.'
                  : 'Entra y revisamos juntas cómo va todo.',
              style: const TextStyle(color: mutedInk),
            ),
            const SizedBox(height: 24),
            if (_isRegistering) ...[
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Cómo te llamas',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => _required(value, 'tu nombre'),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe tu correo.';
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value.trim())) {
                  return 'Revisa el formato del correo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: _isRegistering
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Escribe tu contraseña.';
                }
                if (_isRegistering && value.length < 8) {
                  return 'Usa al menos 8 caracteres.';
                }
                return null;
              },
            ),
            if (_isRegistering) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmation,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirma tu contraseña',
                  prefixIcon: Icon(Icons.check_circle_outline_rounded),
                ),
                validator: (value) {
                  if (value != _password.text) {
                    return 'Las contraseñas no coinciden.';
                  }
                  return null;
                },
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isRegistering ? 'Crear cuenta' : 'Entrar'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _isRegistering = !_isRegistering;
                      _error = null;
                    }),
              child: Text(
                _isRegistering
                    ? 'Ya tengo cuenta · Iniciar sesión'
                    : '¿Primera vez por aquí? Crear cuenta',
              ),
            ),
            if (!_isRegistering) ...[
              const SizedBox(height: 8),
              const Text(
                'Tus datos se quedan en este dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedInk, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
