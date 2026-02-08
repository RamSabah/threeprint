import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _isDeleting = false;
  bool _isSendingVerification = false;
  bool _isCheckingVerification = false;
  bool _verificationSent = false;
  bool _pendingVerification = false;
  bool _isForgotPasswordMode = false;
  bool _resetEmailSent = false;
  String? _pendingEmail;
  String? _pendingPassword;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await _authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (userCredential != null) {
          // Block login if email is not verified
          if (userCredential.user?.emailVerified == false) {
            setState(() {
              _pendingVerification = true;
              _pendingEmail = _emailController.text.trim();
              _pendingPassword = _passwordController.text;
              _currentUser = null;
            });
            await _authService.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please verify your email before logging in.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          setState(() {
            _currentUser = userCredential.user;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await _authService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (userCredential != null) {
          // Try to send verification email, but don't block registration if it fails
          bool emailSent = false;
          try {
            await _authService.sendEmailVerification();
            emailSent = true;
          } catch (_) {
            // Rate-limited or other transient error — user can resend later
          }

          await _authService.signOut();

          setState(() {
            _currentUser = null;
            _pendingVerification = true;
            _pendingEmail = _emailController.text.trim();
            _pendingPassword = _passwordController.text;
            _verificationSent = emailSent;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(emailSent
                  ? 'Verification email sent. Check your inbox.'
                  : 'Account created. Tap "Resend" to get the verification email.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSendingVerification) {
      return;
    }

    setState(() {
      _isSendingVerification = true;
    });

    try {
      await _authService.sendEmailVerification();
      setState(() {
        _verificationSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingVerification = false;
        });
      }
    }
  }

  Future<void> _checkEmailVerified() async {
    if (_isCheckingVerification) {
      return;
    }

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      // If we are in the pending-verification flow, sign in silently to check
      if (_pendingVerification && _pendingEmail != null && _pendingPassword != null) {
        final cred = await _authService.signInWithEmailAndPassword(
          email: _pendingEmail!,
          password: _pendingPassword!,
        );

        if (cred != null && cred.user?.emailVerified == true) {
          setState(() {
            _currentUser = cred.user;
            _pendingVerification = false;
            _pendingEmail = null;
            _pendingPassword = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified. You are now logged in!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Still not verified — sign out again
          await _authService.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Check your inbox.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Logged-in user checking verification status
        final updatedUser = await _authService.reloadCurrentUser();
        setState(() {
          _currentUser = updatedUser;
        });

        if (_currentUser?.emailVerified == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified. Thank you!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      setState(() {
        _currentUser = null;
      });
      
      _emailController.clear();
      _passwordController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    if (_currentUser == null || _isDeleting) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This action is permanent and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _authService.deleteCurrentUser();
      setState(() {
        _currentUser = null;
      });

      _emailController.clear();
      _passwordController.clear();
      _usernameController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Account'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _currentUser != null
            ? _buildLoggedInView()
            : _pendingVerification
                ? _buildVerificationPendingView()
                : _isForgotPasswordMode
                    ? _buildForgotPasswordView()
                    : _buildLoginView(),
      ),
    );
  }

  Widget _buildVerificationPendingView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify your email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a verification link to',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _pendingEmail ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Click the link in the email, then tap the button below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCheckingVerification ? null : _checkEmailVerified,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isCheckingVerification
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("I've verified, log me in"),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSendingVerification ? null : _resendVerificationEmail,
              child: _isSendingVerification
                  ? const Text('Sending...')
                  : const Text('Resend verification email'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _pendingVerification = false;
                  _pendingEmail = null;
                  _pendingPassword = null;
                  _verificationSent = false;
                });
              },
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    if (_isSendingVerification || _pendingEmail == null || _pendingPassword == null) {
      return;
    }

    setState(() {
      _isSendingVerification = true;
    });

    try {
      // Sign in briefly to resend, then sign out
      final cred = await _authService.signInWithEmailAndPassword(
        email: _pendingEmail!,
        password: _pendingPassword!,
      );
      if (cred != null) {
        await _authService.sendEmailVerification();
        await _authService.signOut();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingVerification = false;
        });
      }
    }
  }

  Widget _buildLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // User Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _currentUser?.email ?? 'No email',
            style: TextStyle(
              fontSize: 16, 
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade400 
                  : Colors.grey
            ),
          ),
          const SizedBox(height: 10),
          if (_currentUser?.emailVerified == false)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Email not verified',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          if (_currentUser?.emailVerified == false) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSendingVerification ? null : _sendVerificationEmail,
              child: Text(
                _verificationSent ? 'Resend verification email' : 'Send verification email',
              ),
            ),
            TextButton(
              onPressed: _isCheckingVerification ? null : _checkEmailVerified,
              child: _isCheckingVerification
                  ? const Text('Checking...')
                  : const Text('I verified my email'),
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('Logout'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isDeleting ? null : _deleteAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: _isDeleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Delete account'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginView() {
    return Center(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 100),
              const SizedBox(height: 20),
              Text(
                _isRegisterMode ? 'Create your account' : 'Login to your account',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 30),
              if (_isRegisterMode)
                Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isRegisterMode ? _register : _login),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isRegisterMode ? 'Register' : 'Login'),
                ),
              ),
              if (!_isRegisterMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _isForgotPasswordMode = true;
                        _resetEmailSent = false;
                      });
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                    _formKey.currentState?.reset();
                    _verificationSent = false;
                  });
                },
                child: Text(
                  _isRegisterMode ? 'Already have an account? Login' : 'or Register',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordView() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    final resetFormKey = GlobalKey<FormState>();

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _resetEmailSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _resetEmailSent ? 'Check your email' : 'Reset password',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _resetEmailSent
                      ? 'We sent a password reset link to your email. Open it, set your new password, then come back to log in.'
                      : 'Enter your email and we\'ll send a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                if (!_resetEmailSent)
                  Form(
                    key: resetFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: resetEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (resetFormKey.currentState!.validate()) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      try {
                                        await _authService.sendPasswordResetEmail(
                                          email: resetEmailController.text.trim(),
                                        );
                                        setState(() {
                                          _resetEmailSent = true;
                                        });
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Send reset link'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_resetEmailSent)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isForgotPasswordMode = false;
                          _resetEmailSent = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back to login'),
                    ),
                  ),
                if (!_resetEmailSent)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isForgotPasswordMode = false;
                        _resetEmailSent = false;
                      });
                    },
                    child: const Text('Back to login'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _pendingEmail = null;
    _pendingPassword = null;
    super.dispose();
  }
}