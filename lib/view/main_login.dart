import 'package:diapce_aplicationn/view/hall.dart';
import 'package:flutter/material.dart';

class MainLogin extends StatefulWidget {
  const MainLogin({super.key});

  @override
  State<MainLogin> createState() => _MainLoginState();
}

class _MainLoginState extends State<MainLogin> {
   final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Lógica para manejar el login
      final email = _emailController.text;
      final password = _passwordController.text;
      print('Email: $email, Password: $password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Inicio de Sesión",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                height: 5
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Correo Electrónico",
                hintText: "ejemplo@correo.com",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
            const SizedBox(height: 24),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Contraseña",
                hintText: "Ingresa tu contraseña",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: _obscurePassword,
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (){Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Hall()),
    );},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Ingresar',
                style: TextStyle(fontSize: 18),
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}