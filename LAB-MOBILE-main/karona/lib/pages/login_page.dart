// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

Future<void> _login() async {
  final prefs = await SharedPreferences.getInstance();
  final storedUser = prefs.getString('username');
  final storedPass = prefs.getString('password');
  final userType = prefs.getString('userType');

  if (_usernameController.text == storedUser &&
      _passwordController.text == storedPass) {
    if (userType == 'cliente') {
      Navigator.pushReplacementNamed(context, '/cliente');
    } else if (userType == 'motorista') {
      Navigator.pushReplacementNamed(context, '/motorista');
    }
  } else {
    setState(() {
      _error = 'Usuário ou senha inválidos';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Usuário'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: Text('Entrar')),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              ),
              child: Text('Cadastrar-se'),
            ),
          ],
        ),
      ),
    );
  }
}
