import 'package:briefcase/theme/app_theme.dart';
import 'package:briefcase/pages/security_page.dart';
import 'package:briefcase/services/security_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Flutter App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SecurityCheckRoot(),
    );
  }
}

class SecurityCheckRoot extends StatefulWidget {
  const SecurityCheckRoot({super.key});

  @override
  State<SecurityCheckRoot> createState() => _SecurityCheckRootState();
}

class _SecurityCheckRootState extends State<SecurityCheckRoot> {
  final _securityService = SecurityService();
  bool? _isPasswordSet;

  @override
  void initState() {
    super.initState();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    print('SecurityCheck: Starting check...');
    try {
      final isSet = await _securityService.isPasswordSet().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('SecurityCheck: Timeout waiting for password check');
          throw Exception('Timeout');
        },
      );
      print('SecurityCheck: Password set? $isSet');
      if (mounted) {
        setState(() {
          _isPasswordSet = isSet;
        });
      }
    } catch (e, stack) {
      print('SecurityCheck: Error checking security: $e');
      print(stack);
      // Fallback: Assume no password set or show error
      if (mounted) {
        setState(() {
           // For debugging, let's force setup if it fails, or maybe just proceed
           // But better to show the error
           _isPasswordSet = false; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Security check failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPasswordSet == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isPasswordSet!) {
      return const SecurityPage(mode: SecurityMode.login);
    } else {
      return const SecurityPage(mode: SecurityMode.setup);
    }
  }
}
