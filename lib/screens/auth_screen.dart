import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';
import 'feed_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Helpers.showToast('Please fill all fields');
      return;
    }

    if (!isLogin && _nameController.text.isEmpty) {
      Helpers.showToast('Please enter your name');
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (isLogin) {
        await authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        Helpers.showToast('Login successful!');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FeedScreen()),
          );
        }
      } else {
        await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          collegeName: _collegeController.text.trim(),
          department: _departmentController.text.trim(),
          semester: int.tryParse(_semesterController.text) ?? 1,
          phoneNumber: _phoneController.text.trim(),
        );
        Helpers.showToast('Account created! Please login');
        setState(() {
          isLogin = true;
          _clearFields();
        });
      }
    } on FirebaseAuthException catch (e) {
      Helpers.showToast(e.message ?? 'Authentication failed');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _nicknameController.clear();
    _collegeController.clear();
    _departmentController.clear();
    _semesterController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade900,
              Colors.teal.shade700,
              Colors.green.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BRANDING
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.swap_horiz, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Book Exchange',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? 'Welcome Back!' : 'Join the Community',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // GLASSMORPHIC CARD
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: true,
                            ),
                            if (!isLogin) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _nicknameController,
                                label: 'Nickname',
                                icon: Icons.face_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _collegeController,
                                label: 'College',
                                icon: Icons.school_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildRowFields(
                                _departmentController,
                                'Dept',
                                Icons.category_outlined,
                                _semesterController,
                                'Sem',
                                Icons.numbers_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                            const SizedBox(height: 32),
                            
                            // PREMIUM BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.teal.shade900,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.teal.shade900,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Text(
                                        isLogin ? 'LOG IN' : 'SIGN UP',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // TOGGLE BUTTON
                  GestureDetector(
                    onTap: () => setState(() {
                      isLogin = !isLogin;
                      _clearFields();
                    }),
                    child: RichText(
                      text: TextSpan(
                        text: isLogin ? "Don't have an account? " : "Already have an account? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        children: [
                          TextSpan(
                            text: isLogin ? 'SIGN UP' : 'LOG IN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildRowFields(
    TextEditingController c1, String l1, IconData i1,
    TextEditingController c2, String l2, IconData i2,
  ) {
    return Row(
      children: [
        Expanded(child: _buildTextField(controller: c1, label: l1, icon: i1)),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: _buildTextField(
            controller: c2,
            label: l2,
            icon: i2,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}