import 'package:diapce_aplicationn/components/app_button.dart';
import 'package:diapce_aplicationn/components/fade_slide_in.dart';
import 'package:diapce_aplicationn/core/database_helper.dart';
import 'package:diapce_aplicationn/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class Create extends StatefulWidget {
  const Create({super.key});

  @override
  State<Create> createState() => _CreateState();
}

class _CreateState extends State<Create> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text;
      final password = _passwordController.text;
      final dbHelper = DatabaseHelper();
      setState(() => _loading = true);
      try {
        // Verificar si el usuario ya existe
        final existingUser = await dbHelper.getUserByEmailAndPassword(email, password);
        if (!mounted) return;
        if (existingUser != null) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El usuario ya existe. Usa otro correo.')),
          );
          return;
        }
        await dbHelper.insertUser({
          'email': email,
          'password': password,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado correctamente. Inicia sesión.')),
        );
        Navigator.pop(context); // Regresa a la pantalla de login
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar usuario: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(
                      index: 0,
                      child: Text('Crea tu cuenta.', style: text.displayMedium),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FadeSlideIn(
                      index: 1,
                      child: Text(
                        'Guarda tus proyectos y consulta tus predicciones desde cualquier dispositivo.',
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeSlideIn(
                      index: 2,
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'ejemplo@correo.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo electrónico';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      index: 3,
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: 'Mínimo 6 caracteres',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      index: 4,
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          hintText: 'Repite tu contraseña',
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitForm(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirma tu contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeSlideIn(
                      index: 5,
                      child: AppButton(
                        label: 'Crear cuenta',
                        loading: _loading,
                        onPressed: _submitForm,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FadeSlideIn(
                      index: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes una cuenta?',
                            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          AppButton.text(
                            label: 'Inicia sesión',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
