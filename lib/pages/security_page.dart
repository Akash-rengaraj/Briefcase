import 'package:briefcase/services/security_service.dart';
import 'package:briefcase/main_wrapper.dart';
import 'package:flutter/material.dart';

enum SecurityMode { setup, login, change }

class SecurityPage extends StatefulWidget {
  final SecurityMode mode;
  final VoidCallback? onSuccess; // Callback for success (e.g., login or change)

  const SecurityPage({super.key, required this.mode, this.onSuccess});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController(); // For setup/change
  final _oldPasswordController = TextEditingController(); // For change
  final _securityService = SecurityService();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _oldPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      if (widget.mode == SecurityMode.setup) {
        if (_passwordController.text.length < 4) {
          setState(() => _errorMessage = 'Password must be at least 4 characters');
          return;
        }
        if (_passwordController.text != _confirmController.text) {
          setState(() => _errorMessage = 'Passwords do not match');
          return;
        }
        print('SecurityPage: Saving password...');
        await _securityService.savePassword(_passwordController.text).timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('SecurityPage: Timeout saving password');
                throw Exception('Timeout saving password. Is libsecret installed?');
              },
            );
        print('SecurityPage: Password saved.');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainWrapper()),
          );
        }
      } else if (widget.mode == SecurityMode.login) {
        print('SecurityPage: Checking password...');
        final isValid = await _securityService.checkPassword(_passwordController.text).timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('SecurityPage: Timeout checking password');
                throw Exception('Timeout checking password. Is libsecret installed?');
              },
            );
        print('SecurityPage: Password valid? $isValid');
        if (isValid) {
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainWrapper()),
              );
            }
          }
        } else {
          setState(() => _errorMessage = 'Incorrect password');
        }
      } else if (widget.mode == SecurityMode.change) {
        if (_passwordController.text.length < 4) {
          setState(() => _errorMessage = 'New Password must be at least 4 characters');
          return;
        }
        if (_passwordController.text != _confirmController.text) {
          setState(() => _errorMessage = 'New Passwords do not match');
          return;
        }
        final success = await _securityService
            .updatePassword(_oldPasswordController.text, _passwordController.text)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw Exception('Timeout updating password. Is libsecret installed?');
              },
            );
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password updated successfully')),
            );
            Navigator.pop(context);
          }
        } else {
          setState(() => _errorMessage = 'Incorrect old password');
        }
      }
    } catch (e) {
      print('SecurityPage: Error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: $e. If on Linux, ensure libsecret-1-dev is installed.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    String buttonText = '';

    switch (widget.mode) {
      case SecurityMode.setup:
        title = 'Set App Password';
        buttonText = 'Set Password';
        break;
      case SecurityMode.login:
        title = 'Enter Password';
        buttonText = 'Unlock';
        break;
      case SecurityMode.change:
        title = 'Change Password';
        buttonText = 'Update Password';
        break;
    }

    return Scaffold(
      appBar: widget.mode == SecurityMode.change
          ? AppBar(title: const Text('Security'))
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.mode != SecurityMode.change) ...[
                  const Icon(Icons.lock_outline, size: 80, color: Colors.blueGrey),
                  const SizedBox(height: 24),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (widget.mode == SecurityMode.change)
                  TextField(
                    controller: _oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Old Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_open),
                    ),
                  ),
                if (widget.mode == SecurityMode.change) const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: widget.mode == SecurityMode.change ? 'New Password' : 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                if (widget.mode == SecurityMode.setup || widget.mode == SecurityMode.change) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_clock),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(buttonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
