import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../widgets/premium_background.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final UserModel user;

  const WelcomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sceneCtrl;
  late final AnimationController _textCtrl;
  late final Animation<double> _imageFade;

  // Staggered text animations — each line appears one by one
  late final Animation<double> _line1Fade;
  late final Animation<Offset> _line1Slide;
  late final Animation<double> _line2Fade;
  late final Animation<Offset> _line2Slide;
  late final Animation<double> _line3Fade;
  late final Animation<Offset> _line3Slide;
  late final Animation<double> _textShimmer;

  @override
  void initState() {
    super.initState();

    // Scene animation controller (drives custom painter particle motion)
    _sceneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Text sequence animation controller — 2 seconds total for staggered reveal
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Image fades in first (0% -> 40%)
    _imageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Line 1: "Welcome [Name]" — appears at 15% -> 45%
    _line1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );
    _line1Slide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // Line 2: "to the Resource Sharing Hub" — appears at 35% -> 65%
    _line2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _line2Slide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Line 3: "Let's make today productive" — appears at 55% -> 85%
    _line3Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _line3Slide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Shimmer gradient sweep on main text (60% -> 100%)
    _textShimmer = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();

    // Wait for animations to complete then hold for 5 seconds total before transition
    await Future.delayed(const Duration(milliseconds: 5000));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => HomeScreen(user: widget.user),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _sceneCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayName = 'Student';
    if (widget.user.name.trim().isNotEmpty) {
      displayName = widget.user.name.split(' ').first;
    } else if (widget.user.email.isNotEmpty) {
      final prefix = widget.user.email.split('@').first;
      if (prefix.isNotEmpty) {
        displayName = prefix[0].toUpperCase() + prefix.substring(1);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: PremiumBackground(
        showOrbs: false,
        showMesh: false,
        showGrid: false,
        child: Stack(
          children: [
            // ── Full Screen Background Image with Immersive Blur and Blend ──
            Positioned.fill(
              child: FadeTransition(
                opacity: _imageFade,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/holographic_students.png',
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF020617).withOpacity(0.15),
                                const Color(0xFF020617).withOpacity(0.30),
                                const Color(0xFF020617).withOpacity(0.55),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),



            // ── Soft Bottom Text Readability Scrim ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF020617).withOpacity(0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Center Welcome Text ──
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome Text Column directly floating
                    SlideTransition(
                      position: _line1Slide,
                      child: FadeTransition(
                        opacity: _line1Fade,
                        child: AnimatedBuilder(
                          animation: _textShimmer,
                          builder: (context, _) {
                            final shimmer = _textShimmer.value;
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: const [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF2979FF),
                                    Color(0xFF00E5FF),
                                    Color(0xFFFF007F),
                                    Color(0xFF8B5CF6),
                                  ],
                                  stops: [
                                    0.0,
                                    0.25 * shimmer,
                                    0.5 * shimmer + 0.1,
                                    0.75 * shimmer + 0.2,
                                    1.0,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                'Welcome $displayName',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Line 2: "to the Resource Sharing Hub"
                    SlideTransition(
                      position: _line2Slide,
                      child: FadeTransition(
                        opacity: _line2Fade,
                        child: AnimatedBuilder(
                          animation: _textShimmer,
                          builder: (context, _) {
                            final shimmer = _textShimmer.value;
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: const [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF2979FF),
                                    Color(0xFF00E5FF),
                                    Color(0xFFFF007F),
                                    Color(0xFF8B5CF6),
                                  ],
                                  stops: [
                                    0.0,
                                    0.25 * shimmer,
                                    0.5 * shimmer + 0.1,
                                    0.75 * shimmer + 0.2,
                                    1.0,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                'to the Resource Sharing Hub ✨',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Line 3: Subtitle
                    SlideTransition(
                      position: _line3Slide,
                      child: FadeTransition(
                        opacity: _line3Fade,
                        child: Text(
                          "Your collaborative classroom — where knowledge flows freely.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.90),
                            letterSpacing: 0.1,
                            height: 1.5,
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 12),
                              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Line 4: Feature hint
                    FadeTransition(
                      opacity: _line3Fade,
                      child: Text(
                        "Upload notes • Share resources • Connect with peers",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFCBD5E1),
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.9), blurRadius: 16),
                            Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Line 5: Motivational
                    FadeTransition(
                      opacity: _line3Fade,
                      child: Text(
                        "Let’s make today productive 🚀",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA5B4FC),
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.9), blurRadius: 16),
                            Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOLOGRAPHIC LEARNING SCENE PAINTER
// ─────────────────────────────────────────────────────────────

class HolographicPainter extends CustomPainter {
  final double t; // loops 0.0 -> 1.0

  HolographicPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── CHARACTER 1 (Left): Notes interaction ─────────────────
    final leftYOffset = math.sin(t * 2 * math.pi) * 8.0;
    final leftPos = Offset(w * 0.22, h * 0.42 + leftYOffset);
    
    // Draw Floating Holographic Notes
    final notePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF00E5FF).withOpacity(0.08);
    final noteBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF00E5FF).withOpacity(0.50);

    for (int i = 0; i < 3; i++) {
      final noteAngle = (t * 2 * math.pi) + (i * 2.09);
      final noteX = leftPos.dx + 40.0 + math.cos(noteAngle) * 8.0;
      final noteY = leftPos.dy + (i * 28.0) - 36.0 + math.sin(noteAngle * 1.5) * 6.0;
      
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(noteX, noteY, 44, 22),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, notePaint);
      canvas.drawRRect(rect, noteBorderPaint);
      
      // Horizontal text lines inside notes
      final linesPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = const Color(0xFF00E5FF).withOpacity(0.6);
      canvas.drawLine(Offset(noteX + 6, noteY + 6), Offset(noteX + 38, noteY + 6), linesPaint);
      canvas.drawLine(Offset(noteX + 6, noteY + 11), Offset(noteX + 32, noteY + 11), linesPaint);
      canvas.drawLine(Offset(noteX + 6, noteY + 16), Offset(noteX + 22, noteY + 16), linesPaint);
    }

    // ── CHARACTER 2 (Center) position reference ──────────────
    final centerYOffset = math.sin(t * 2 * math.pi + 1.5) * 7.0;
    final centerPos = Offset(w * 0.5, h * 0.35 + centerYOffset);

    // ── CHARACTER 3 (Right): Orbiting elements ───────────────
    final rightYOffset = math.sin(t * 2 * math.pi + 3.0) * 8.0;
    final rightPos = Offset(w * 0.78, h * 0.44 + rightYOffset);

    // Orbiting rings (holographic orbital path)
    final orbitPath = Path();
    orbitPath.addOval(Rect.fromCenter(
      center: Offset(rightPos.dx, rightPos.dy - 6),
      width: 80,
      height: 38,
    ));
    
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF8B5CF6).withOpacity(0.24);
    canvas.drawPath(orbitPath, orbitPaint);

    // Orbiting glowing dots
    for (int i = 0; i < 3; i++) {
      final angle = (t * 2 * math.pi) + (i * 2.094);
      final rx = 40 * math.cos(angle);
      final ry = 19 * math.sin(angle);
      final itemPos = Offset(rightPos.dx + rx, rightPos.dy - 6 + ry);
      
      final itemGlow = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF8B5CF6).withOpacity(0.50);
      canvas.drawCircle(itemPos, 4.0, itemGlow);
    }

    // ── AMBIENT CONNECTING MESH LINES ─────────────────────────
    final connPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = const LinearGradient(
        colors: [
          Color(0x2A00E5FF),
          Color(0x2AFF007F),
          Color(0x2A8B5CF6),
        ],
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.5));

    final connPath = Path();
    connPath.moveTo(leftPos.dx, leftPos.dy + 40);
    connPath.quadraticBezierTo(
      (leftPos.dx + centerPos.dx) / 2,
      (leftPos.dy + centerPos.dy) / 2 - 20 + math.sin(t * 2 * math.pi) * 15,
      centerPos.dx,
      centerPos.dy + 40,
    );
    connPath.quadraticBezierTo(
      (centerPos.dx + rightPos.dx) / 2,
      (centerPos.dy + rightPos.dy) / 2 - 20 + math.cos(t * 2 * math.pi) * 15,
      rightPos.dx,
      rightPos.dy + 40,
    );
    canvas.drawPath(connPath, connPaint);

    // Floating micro dust/particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final randColors = [
      const Color(0xFF00E5FF),
      const Color(0xFFFF007F),
      const Color(0xFF8B5CF6),
    ];
    for (int i = 0; i < 20; i++) {
      final angle = (t * 2 * math.pi) + (i * 0.8);
      final px = w * 0.5 + math.sin(angle * 1.5 + i) * (w * 0.45);
      final py = h * 0.4 + math.cos(angle * 1.1 - i) * (h * 0.22);
      final dotSize = 1.0 + (i % 3) * 0.8;
      final opacity = 0.20 + math.sin(t * 2 * math.pi + i) * 0.15;
      
      particlePaint.color = randColors[i % randColors.length].withOpacity(opacity);
      canvas.drawCircle(Offset(px, py), dotSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HolographicPainter oldDelegate) => oldDelegate.t != t;
}
