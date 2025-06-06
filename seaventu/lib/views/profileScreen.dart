import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaventu/services/auth_service.dart';
import 'package:seaventu/views/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricEnabled = false;
  bool _isLoading = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    
    if (user == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final canUseBio = await authService.canUseBiometrics();
      final isEnabled = await authService.isBiometricEnabledForUser(user.uid);
      
      if (mounted) {
        setState(() {
          _biometricEnabled = canUseBio && isEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleBiometricAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    
    if (user == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_biometricEnabled) {
        await authService.setBiometricEnabledForUser(user.uid, false);
        setState(() => _biometricEnabled = false);
      } else {
        final authenticated = await authService.authenticateWithBiometrics();
        if (authenticated) {
          await authService.setBiometricEnabledForUser(user.uid, true);
          if (mounted) {
            setState(() => _biometricEnabled = true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    
    setState(() => _isLoggingOut = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile information widgets...
            
            SwitchListTile(
              title: const Text('Enable Biometric Authentication'),
              value: _biometricEnabled,
              onChanged: _isLoading ? null : (value) => _toggleBiometricAuth(),
            ),
            
            const Divider(),
            ListTile(
              leading: _isLoggingOut
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.logout, color: Colors.red),
              title: _isLoggingOut
                  ? const Text('Logging out...')
                  : const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
              onTap: _isLoggingOut ? null : _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}