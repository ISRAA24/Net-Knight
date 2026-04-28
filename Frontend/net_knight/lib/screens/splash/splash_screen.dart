import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/splash_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _service = SplashService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final hasUsers = await _service.hasUsers();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      hasUsers ? '/login' : '/signup',
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff0a0e1a),
              Color(0xff0d1b2e),
              Color(0xff0a1628),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Logo ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xfffafafa).withOpacity(0.05),
                      border: Border.all(
                        color: const Color(0xff0077c0).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0077c0).withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/Logo.png',
                      height: 110,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── App Name ──────────────────────────────────
                  Text(
                    'NetKnight',
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 40,
                      color: Color(0xfffafafa).withOpacity(0.9),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ─── Divider ───────────────────────────────────
                  Container(
                    width: 60,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xff0077c0),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─── Tagline ───────────────────────────────────
                  Text(
                    'YOUR JOURNEY BEGINS NOW',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xff0077c0),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Power. Knowledge. Destiny.\nAll in your hands.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Color(0xfffafafa).withOpacity(0.6),
                      height: 1.8,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ─── Loading ───────────────────────────────────
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: const Color(0xff0077c0).withOpacity(0.7),
                      strokeWidth: 1.5,
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
}
