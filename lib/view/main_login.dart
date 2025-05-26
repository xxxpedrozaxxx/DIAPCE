// view/main_login.dart
import 'package:diapce_aplicationn/view/Create_count.dart'; // Asegúrate de que Create() tenga su Scaffold
import 'package:diapce_aplicationn/view/hall.dart';         // Asegúrate de que Hall() tenga su Scaffold
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
      final email = _emailController.text;
      final password = _passwordController.text;
      print('Email: $email, Password: $password');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Hall()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Puedes definir un backgroundColor para el Scaffold si lo deseas,
      // o dejar el color por defecto del tema.
      // backgroundColor: Colors.grey[200], // Ejemplo
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Padding original
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Inicio de Sesión",
                      style: TextStyle( // Estilo original
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        height: 5, // Este 'height' es un multiplicador de la altura de línea.
                                  // Considera usar SizedBox para espaciado vertical explícito si este no da el efecto deseado.
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40), // Espaciado original
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration( // Decoración original
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
                    const SizedBox(height: 24), // Espaciado original
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration( // Decoración original (con el IconButton para el suffixIcon)
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
                    const SizedBox(height: 32), // Espaciado original
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom( // Estilo original
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        // Si tenías un color específico aquí, añádelo. Ejemplo:
                        // backgroundColor: Colors.blue,
                        // foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Ingresar',
                        style: TextStyle(fontSize: 18), // Estilo original
                      ),
                    ),
                    const SizedBox(height: 16), // Espaciado original
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("¿No tienes cuenta?"), // Estilo original
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Create()),
                            );
                          },
                          // Si tenías un estilo específico para el TextButton, añádelo. Ejemplo:
                          // style: TextButton.styleFrom(foregroundColor: Colors.blue),
                          child: const Text("Regístrate"), // Estilo original
                        ),
                      ],
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