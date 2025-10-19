import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _setupAuthListener();
  }

  void _checkAuthState() {
    setState(() {
      _isAuthenticated = AuthService.isAuthenticated();
      _isLoading = false;
    });
  }

  void _setupAuthListener() {
    SupabaseService.authStateChanges.listen((AuthState data) {
      if (mounted) {
        setState(() {
          _isAuthenticated = data.session != null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
