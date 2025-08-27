// two_fa_settings.dart
import 'package:flutter/material.dart';
import 'package:hanabudget/database/mongo_database.dart';
import 'package:hanabudget/services/auth_service.dart';

class TwoFASettingsScreen extends StatefulWidget {
  @override
  _TwoFASettingsScreenState createState() => _TwoFASettingsScreenState();
}

class _TwoFASettingsScreenState extends State<TwoFASettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _is2FAEnabled = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentUser = currentUser;
        });
        _check2FAStatus();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _check2FAStatus() async {
    if (_currentUser == null) return;

    try {
      final isEnabled = await MongoDBService().is2FAEnabled(_currentUser!['id']);
      setState(() {
        _is2FAEnabled = isEnabled;
      });
    } catch (e) {
      print('Error checking 2FA status: $e');
    }
  }

  Future<void> _toggle2FA(bool value) async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await MongoDBService().toggle2FA(_currentUser!['id'], value);
      if (success) {
        setState(() {
          _is2FAEnabled = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('2FA ${value ? 'enabled' : 'disabled'} successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update 2FA settings')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two-Factor Authentication'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Card(
              child: ListTile(
                title: Text('Two-Factor Authentication'),
                subtitle: Text('Add an extra layer of security to your account'),
                trailing: Switch(
                  value: _is2FAEnabled,
                  onChanged: _toggle2FA,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'When enabled, you will receive a verification code via email whenever you sign in.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}