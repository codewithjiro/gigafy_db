import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'gigafy_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('database');

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const AuthGate());
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    await Future.delayed(const Duration(seconds: 2));
    final box = Hive.box("database");
    if (mounted) {
      setState(() {
        _hasUser = box.get("username") != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: "Gigafy",
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF2E86AB),
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
      ),
      home: _isLoading
          ? const SplashScreen()
          : (_hasUser ? const LoginPage() : const SignupPage()),
    );
  }
}

class ModernBackground extends StatelessWidget {
  final Widget child;
  const ModernBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
        ),
      ),
      child: child,
    );
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: CupertinoColors.white.withOpacity(0.7),
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
            style: const TextStyle(color: Colors.black),
            obscureText: obscureText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(icon, color: CupertinoColors.systemGrey),
            ),
            suffix: suffix,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: ModernBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                    color: const Color(0xFF2E86AB).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF2E86AB).withOpacity(0.2),
                        width: 1)),
                child: const Icon(CupertinoIcons.waveform,
                    color: Color(0xFF2E86AB), size: 80),
              ),
              const SizedBox(height: 25),
              const Text(
                "Gigafy",
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  color: Color(0xFF2E86AB),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 10),
              const CupertinoActivityIndicator(color: Color(0xFF2E86AB))
            ],
          ),
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final box = Hive.box("database");
  bool hidePassword = true;
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Oops"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(ctx),
          )
        ],
      ),
    );
  }

  void _handleSignup() {
    if (_username.text.trim().isEmpty || _password.text.trim().isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    box.put("username", _username.text.trim());
    box.put("password", _password.text.trim());
    box.put("biometrics", false);
    if (box.get("storage") == null) {
      box.put("storage", 0.0);
    }

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Success"),
        content: const Text("Account created successfully!\nPlease sign in to continue."),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Sign In"),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(builder: (context) => const LoginPage()),
              );
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF2D3436);

    return CupertinoPageScaffold(
      child: ModernBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Create\nAccount",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: textColor)),
                const SizedBox(height: 10),
                const Text("Sign up to start your secure cloud storage.",
                    style: TextStyle(
                        fontSize: 16, color: CupertinoColors.systemGrey)),
                const SizedBox(height: 40),
                GlassTextField(
                  controller: _username,
                  placeholder: "Username",
                  icon: CupertinoIcons.person,
                ),
                const SizedBox(height: 15),
                GlassTextField(
                  controller: _password,
                  placeholder: "Password",
                  icon: CupertinoIcons.lock,
                  obscureText: hidePassword,
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                        hidePassword
                            ? CupertinoIcons.eye_fill
                            : CupertinoIcons.eye_slash_fill,
                        color: CupertinoColors.systemGrey),
                    onPressed: () =>
                        setState(() => hidePassword = !hidePassword),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _handleSignup,
                    borderRadius: BorderRadius.circular(15),
                    child: const Text("Get Started",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final box = Hive.box("database");

  bool hidePassword = true;
  bool isProcessing = false;
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  void _showError(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Try Again"),
            onPressed: () => Navigator.pop(ctx),
          )
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (_username.text.trim() == box.get("username") &&
        _password.text.trim() == box.get("password")) {
      if (mounted) {
        Navigator.pushReplacement(context,
            CupertinoPageRoute(builder: (context) => const GigafyApp()));
      }
    } else {
      if (mounted) {
        setState(() => isProcessing = false);
        _showError("Login Failed", "Incorrect username or password.");
      }
    }
  }

  Future<void> _handleBiometrics() async {
    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        _showError("Unavailable", "Biometrics not supported on this device.");
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Unlock your Gigafy Cloud',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuthenticate && mounted) {
        Navigator.pushReplacement(context,
            CupertinoPageRoute(builder: (context) => const GigafyApp()));
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
    }
  }

  // --- NEW: Handle Reset with Biometrics Verification ---
  Future<void> _handleResetWithBiometrics() async {
    bool isAuthorized = false;
    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        // Authenticate the user before allowing them to see the reset dialog
        isAuthorized = await auth.authenticate(
          localizedReason: 'Verify identity to reset app data',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      } else {
        // If device has no biometrics, allow proceed or handle accordingly
        isAuthorized = true;
      }
    } catch (e) {
      debugPrint("Reset Auth Error: $e");
      // Optionally show error to user
      return;
    }

    if (isAuthorized && mounted) {
      _showResetConfirmation();
    }
  }

  void _showResetConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Reset App?"),
        content: const Text(
            "This will permanently delete your login credentials, "
            "biometric settings, and all app configurations. "
            "You will need to create a new account."),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await box.clear();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const SignupPage(),
                  ),
                );
              }
            },
            child: const Text("Reset Everything"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBiometricEnabled = box.get("biometrics") ?? false;
    const Color textColor = Colors.black;

    return CupertinoPageScaffold(
      child: ModernBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.waveform_circle_fill,
                        size: 80, color: Color(0xFF2E86AB)),
                    const SizedBox(height: 20),
                    const Text("Welcome Back",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const Text("Please sign in to continue",
                        style: TextStyle(color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 40),
                    GlassTextField(
                      controller: _username,
                      placeholder: "Username",
                      icon: CupertinoIcons.person_fill,
                    ),
                    const SizedBox(height: 15),
                    GlassTextField(
                      controller: _password,
                      placeholder: "Password",
                      obscureText: hidePassword,
                      icon: CupertinoIcons.lock_fill,
                      suffix: CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(
                              hidePassword
                                  ? CupertinoIcons.eye_fill
                                  : CupertinoIcons.eye_slash_fill,
                              color: CupertinoColors.systemGrey),
                          onPressed: () =>
                              setState(() => hidePassword = !hidePassword)),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: isProcessing ? null : _handleLogin,
                        borderRadius: BorderRadius.circular(15),
                        child: isProcessing
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text("Sign In",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isBiometricEnabled)
                      CupertinoButton(
                        onPressed: _handleBiometrics,
                        child: const Icon(CupertinoIcons.viewfinder,
                            size: 45, color: Color(0xFF2E86AB)),
                      ),
                    const SizedBox(height: 10),
                    CupertinoButton(
                      child: const Text("Reset App Data",
                          style: TextStyle(
                              fontSize: 14, color: CupertinoColors.systemGrey)),
                      onPressed: _handleResetWithBiometrics, // Updated Action
                    )
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
