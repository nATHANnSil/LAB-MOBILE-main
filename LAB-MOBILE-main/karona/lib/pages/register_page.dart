// lib/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _userType;
  String? _success;
  String? _error;

  Future<void> _register() async {
    if (_userType == null) {
      setState(() {
        _error = 'Por favor, selecione o tipo de usuário.';
        _success = null;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('userType', _userType!);

    setState(() {
      _success = 'Usuário cadastrado com sucesso!';
      _error = null;
    });

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // Volta para o login
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            if (_success != null)
              Text(_success!, style: TextStyle(color: Colors.green)),
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
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Tipo de Usuário'),
              value: _userType,
              items: const [
                DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                DropdownMenuItem(value: 'motorista', child: Text('Motorista')),
              ],
              onChanged: (value) {
                setState(() {
                  _userType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _register, child: Text('Cadastrar')),
          ],
        ),
      ),
    );
  }
}
