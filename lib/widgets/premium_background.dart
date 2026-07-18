import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────
// PREMIUM BACKGROUND
// ─────────────────────────────────────────────────────────────

/// Premium AMOLED background with animated floating neon bubbles,
/// dot-matrix corner grids, custom particle systems, and an
/// animated interactive light mesh network.
class PremiumBackground extends StatefulWidget {
  final Widget child;
  final bool showOrbs;
  final bool showMesh;
  final bool showGrid;

  const PremiumBackground({
    Key? key,
    required this.child,
    this.showOrbs = true,
    this.showMesh = true,
    this.showGrid = true,
  }) : super(key: key);

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _floatAnims;
  late final AnimationController _meshController;
  late final Animation<double> _meshAnim;

  // Optimized bubble configuration to fit neon blue, cyan, violet, and magenta aesthetic
  // Each bubble: [size, red, green, blue, opacity, blurSigma, durationSec, floatRange]
  static const _bubbles = [
    [280.0, 213,   0, 249, 0.35, 45.0,  8.0, 24.0], // Electric Violet
    [220.0,  41, 121, 255, 0.28, 40.0, 10.0, 18.0], // Neon Blue
    [260.0,   0, 229, 255, 0.30, 42.0,  9.0, 22.0], // Cyan
    [200.0, 255,   0, 127, 0.24, 38.0, 11.0, 16.0], // Neon Magenta
    [160.0, 124,  77, 255, 0.22, 35.0, 12.0, 14.0], // Violet-Blue
    [130.0, 224, 247, 250, 0.15, 48.0, 14.0, 12.0], // Soft Cyan
  ];

  @override
  void initState() {
    super.initState();
    _controllers = _bubbles.map((b) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (b[6] * 1000).toInt()),
      )..repeat(reverse: true);
    }).toList();

    _floatAnims = _controllers.map((c) {
      return Tween<double>(begin: -1.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _meshAnim = CurvedAnimation(parent: _meshController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    _meshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Deep AMOLED base gradient
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF020617), // Deepest black-slate
                Color(0xFF070B19), // Dark space navy
                Color(0xFF0C1024), // Medium space navy
                Color(0xFF13113C), // Dark cyber indigo hue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // 2. Animated floating neon bubbles
        if (widget.showOrbs) ...[
          // Electric Violet Bubble
          _AnimatedBubble(
            anim: _floatAnims[0],
            floatRange: _bubbles[0][7] as double,
            left: null,
            right: -60,
            top: -60,
            bottom: null,
            size: _bubbles[0][0] as double,
            color: Color.fromARGB(255, _bubbles[0][1].toInt(), _bubbles[0][2].toInt(), _bubbles[0][3].toInt()),
            opacity: _bubbles[0][4] as double,
            blurSigma: _bubbles[0][5] as double,
          ),

          // Neon Blue Bubble
          _AnimatedBubble(
            anim: _floatAnims[1],
            floatRange: _bubbles[1][7] as double,
            left: -70,
            right: null,
            top: size.height * 0.08,
            bottom: null,
            size: _bubbles[1][0] as double,
            color: Color.fromARGB(255, _bubbles[1][1].toInt(), _bubbles[1][2].toInt(), _bubbles[1][3].toInt()),
            opacity: _bubbles[1][4] as double,
            blurSigma: _bubbles[1][5] as double,
          ),

          // Cyan Bubble
          _AnimatedBubble(
            anim: _floatAnims[2],
            floatRange: _bubbles[2][7] as double,
            left: -60,
            right: null,
            top: null,
            bottom: -70,
            size: _bubbles[2][0] as double,
            color: Color.fromARGB(255, _bubbles[2][1].toInt(), _bubbles[2][2].toInt(), _bubbles[2][3].toInt()),
            opacity: _bubbles[2][4] as double,
            blurSigma: _bubbles[2][5] as double,
          ),

          // Neon Magenta Bubble
          _AnimatedBubble(
            anim: _floatAnims[3],
            floatRange: _bubbles[3][7] as double,
            left: null,
            right: -60,
            top: null,
            bottom: size.height * 0.05,
            size: _bubbles[3][0] as double,
            color: Color.fromARGB(255, _bubbles[3][1].toInt(), _bubbles[3][2].toInt(), _bubbles[3][3].toInt()),
            opacity: _bubbles[3][4] as double,
            blurSigma: _bubbles[3][5] as double,
          ),

          // Violet-Blue Bubble
          _AnimatedBubble(
            anim: _floatAnims[4],
            floatRange: _bubbles[4][7] as double,
            left: null,
            right: -40,
            top: size.height * 0.45,
            bottom: null,
            size: _bubbles[4][0] as double,
            color: Color.fromARGB(255, _bubbles[4][1].toInt(), _bubbles[4][2].toInt(), _bubbles[4][3].toInt()),
            opacity: _bubbles[4][4] as double,
            blurSigma: _bubbles[4][5] as double,
          ),

          // Soft Cyan Bubble
          _AnimatedBubble(
            anim: _floatAnims[5],
            floatRange: _bubbles[5][7] as double,
            left: size.width * 0.25,
            right: null,
            top: size.height * 0.32,
            bottom: null,
            size: _bubbles[5][0] as double,
            color: Color.fromARGB(255, _bubbles[5][1].toInt(), _bubbles[5][2].toInt(), _bubbles[5][3].toInt()),
            opacity: _bubbles[5][4] as double,
            blurSigma: _bubbles[5][5] as double,
          ),
        ],

        // 3. Dot-matrix corner grid
        if (widget.showGrid)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: GridPainter()),
            ),
          ),

        // 4. Subtle animated light mesh network, nodes & particles
        if (widget.showMesh)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _meshAnim,
                builder: (_, __) => CustomPaint(
                  painter: MeshPainter(_meshAnim.value),
                ),
              ),
            ),
          ),

        // 5. Foreground content
        widget.child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANIMATED BUBBLE
// ─────────────────────────────────────────────────────────────

class _AnimatedBubble extends StatelessWidget {
  final Animation<double> anim;
  final double floatRange;
  final double? left, right, top, bottom;
  final double size;
  final Color color;
  final double opacity;
  final double blurSigma;

  const _AnimatedBubble({
    Key? key,
    required this.anim,
    required this.floatRange,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
    required this.blurSigma,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final offset = anim.value * floatRange;
        return Positioned(
          left: left,
          right: right,
          top: top != null ? top! + offset : null,
          bottom: bottom != null ? bottom! - offset : null,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(opacity),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MESH PAINTER — Subtle animated node connection network & particles
// ─────────────────────────────────────────────────────────────

class MeshPainter extends CustomPainter {
  final double t; // 0.0 to 1.0 animation value
  MeshPainter(this.t);

  // Seed node positions (expressed fractionally relative to size)
  static final List<Offset> _baseNodes = [
    const Offset(0.08, 0.22),
    const Offset(0.24, 0.14),
    const Offset(0.38, 0.28),
    const Offset(0.12, 0.48),
    const Offset(0.28, 0.58),
    const Offset(0.18, 0.78),
    const Offset(0.42, 0.88),
    const Offset(0.58, 0.12),
    const Offset(0.72, 0.24),
    const Offset(0.88, 0.18),
    const Offset(0.62, 0.48),
    const Offset(0.92, 0.54),
    const Offset(0.78, 0.72),
    const Offset(0.56, 0.82),
    const Offset(0.86, 0.88),
    const Offset(0.48, 0.44),
  ];

  // Neon palette matching requested colors
  static const List<Color> _nodeColors = [
    Color(0xFF2979FF), // Neon Blue
    Color(0xFF00E5FF), // Cyan
    Color(0xFFD500F9), // Violet
    Color(0xFFFF007F), // Neon Magenta
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate animated node locations
    final List<Offset> nodes = [];
    for (int i = 0; i < _baseNodes.length; i++) {
      final base = _baseNodes[i];
      // Slow organic movements using trigonometric functions
      final angle = (t * 2 * math.pi) + (i * 1.618);
      final dx = math.sin(angle) * 16.0;
      final dy = math.cos(angle * 1.2) * 16.0;
      nodes.add(Offset(
        base.dx * size.width + dx,
        base.dy * size.height + dy,
      ));
    }

    // 2. Draw lines connecting nodes that are close to each other
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        final maxDist = size.width * 0.24; // Connection distance threshold
        if (dist < maxDist) {
          final opacity = (1.0 - (dist / maxDist)) * 0.08; // Decreases with distance
          if (opacity > 0.0) {
            final color1 = _nodeColors[i % _nodeColors.length];
            final color2 = _nodeColors[j % _nodeColors.length];
            
            linePaint.shader = LinearGradient(
              colors: [color1.withOpacity(opacity), color2.withOpacity(opacity)],
            ).createShader(Rect.fromPoints(nodes[i], nodes[j]));

            canvas.drawLine(nodes[i], nodes[j], linePaint);
          }
        }
      }
    }

    // 3. Draw connected node cores & outer ambient halos
    final corePaint = Paint()..style = PaintingStyle.fill;
    final haloPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < nodes.length; i++) {
      final pos = nodes[i];
      final color = _nodeColors[i % _nodeColors.length];
      
      // Pulsing halo
      final pulseFactor = math.sin(t * 2 * math.pi + i) * 1.5;
      haloPaint.color = color.withOpacity(0.12);
      canvas.drawCircle(pos, 5.0 + pulseFactor, haloPaint);
      
      // Solid node core
      corePaint.color = color.withOpacity(0.38);
      canvas.drawCircle(pos, 2.0, corePaint);
    }

    // 4. Draw drifting particles with smooth fade out
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 22; i++) {
      final baseProgress = (t + (i * 0.045)) % 1.0;
      // Start near bottom, drift slowly upward
      final px = ((i * 43) % 100) / 100.0 * size.width + math.sin(baseProgress * 2 * math.pi + i) * 12.0;
      final py = size.height - (baseProgress * size.height);
      final visibility = math.sin(baseProgress * math.pi); // Fade in at middle, fade out at edges
      
      final color = _nodeColors[i % _nodeColors.length];
      particlePaint.color = color.withOpacity(visibility * 0.10);
      
      canvas.drawCircle(Offset(px, py), 1.2 + (i % 3) * 0.6, particlePaint);
    }

    // 5. Original abstract curves shifted slowly for breathing effect
    final shift = math.sin(t * math.pi) * 14.0;
    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        colors: [
          const Color(0x1F2979FF),
          const Color(0x1AD500F9),
          const Color(0x0400E5FF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path();
    path1.moveTo(0, size.height * 0.15);
    path1.cubicTo(
      size.width * 0.4, size.height * 0.1 + shift,
      size.width * 0.5, size.height * 0.7 - shift,
      size.width, size.height * 0.82,
    );
    canvas.drawPath(path1, curvePaint);
  }

  @override
  bool shouldRepaint(MeshPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────
// GRID PAINTER (dot-matrix corner design)
// ─────────────────────────────────────────────────────────────

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0D94A3B8)
      ..style = PaintingStyle.fill;

    const double spacing = 18.0;
    const double radius = 0.85;

    for (double x = 20; x < size.width * 0.35; x += spacing) {
      for (double y = 60; y < size.height * 0.22; y += spacing) {
        double distance = math.sqrt(x * x + y * y);
        if (distance < 240) canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }

    for (double x = size.width - 20; x > size.width * 0.65; x -= spacing) {
      for (double y = size.height - 20; y > size.height * 0.78; y -= spacing) {
        double dx = size.width - x;
        double dy = size.height - y;
        double distance = math.sqrt(dx * dx + dy * dy);
        if (distance < 240) canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// GLASS CARD — Stateful card with floating and sweeping reflection
// ─────────────────────────────────────────────────────────────

class GlassCard extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;
  final double blur;
  final Border? customBorder;
  final bool floating;
  final bool sweep;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.glowColor,
    this.blur = 22.0,
    this.customBorder,
    this.floating = true,
    this.sweep = true,
  }) : super(key: key);

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with TickerProviderStateMixin {
  late final AnimationController? _floatCtrl;
  late final Animation<double>? _floatAnim;
  late final AnimationController? _sweepCtrl;
  late final Animation<double>? _sweepAnim;

  @override
  void initState() {
    super.initState();
    if (widget.floating) {
      final floatCtrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      );
      _floatAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
        CurvedAnimation(parent: floatCtrl, curve: Curves.easeInOut),
      );
      // Offset start positions so they don't float in sync
      floatCtrl.value = math.Random().nextDouble();
      floatCtrl.repeat(reverse: true);
      _floatCtrl = floatCtrl;
    } else {
      _floatCtrl = null;
      _floatAnim = null;
    }

    if (widget.sweep) {
      final sweepCtrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
      );
      _sweepAnim = Tween<double>(begin: -2.5, end: 2.5).animate(
        CurvedAnimation(parent: sweepCtrl, curve: Curves.linear),
      );
      // Offset sweep start positions
      sweepCtrl.value = math.Random().nextDouble();
      sweepCtrl.repeat();
      _sweepCtrl = sweepCtrl;
    } else {
      _sweepCtrl = null;
      _sweepAnim = null;
    }
  }

  @override
  void dispose() {
    _floatCtrl?.dispose();
    _sweepCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final glow = widget.glowColor ?? const Color(0xFF6366F1);

    Widget cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Stronger glass frosted dark gradient interior
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withOpacity(0.65), // Brighter frosted slate
            const Color(0xFF0F172A).withOpacity(0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: resolvedRadius,
        border: widget.customBorder ?? Border.all(
          color: glow.withOpacity(0.24), // Soft neon glowing border
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Glossy top sheen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: resolvedRadius.topLeft,
                  topRight: resolvedRadius.topRight,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.00),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Gentle light sweep reflection animation
          if (widget.sweep && _sweepAnim != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sweepAnim,
                builder: (context, child) {
                  return FractionalTranslation(
                    translation: Offset(_sweepAnim.value, 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.01),
                            Colors.white.withOpacity(0.15), // Soft white sheen line
                            Colors.white.withOpacity(0.01),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Actual card content
          widget.child,
        ],
      ),
    );

    // Subtle up/down floating motion wrapper
    if (widget.floating && _floatAnim != null) {
      cardContent = AnimatedBuilder(
        animation: _floatAnim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: child,
          );
        },
        child: cardContent,
      );
    }

    return Container(
      margin: widget.margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        boxShadow: [
          // Deep base drop shadows
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          // Neon edge ambient glow
          BoxShadow(
            color: glow.withOpacity(0.20),
            blurRadius: 24,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
          // Subtle top outline depth
          BoxShadow(
            color: Colors.white.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: resolvedRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: cardContent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRESS SCALE WIDGET — Subtle scale-down on tap
// ─────────────────────────────────────────────────────────────

class PressScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressScaleWidget({Key? key, required this.child, this.onTap})
      : super(key: key);

  @override
  State<PressScaleWidget> createState() => _PressScaleWidgetState();
}

class _PressScaleWidgetState extends State<PressScaleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        HapticFeedback.lightImpact();
        await _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHIMMER CARD — Animated skeleton loading placeholder
// ─────────────────────────────────────────────────────────────

class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerCard({
    Key? key,
    this.height = 80,
    this.width,
    this.borderRadius,
    this.margin,
  }) : super(key: key);

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: const [
              Color(0xFF161E35),
              Color(0xFF252D4A),
              Color(0xFF161E35),
            ],
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREMIUM PAGE ROUTE — Fade + subtle upward slide transition
// ─────────────────────────────────────────────────────────────

class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  PremiumPageRoute({required Widget page})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────
// PREMIUM EMPTY STATE — Pulsing glow icon + polished empty UI
// ─────────────────────────────────────────────────────────────

class PremiumEmptyState extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const PremiumEmptyState({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  State<PremiumEmptyState> createState() => _PremiumEmptyStateState();
}

class _PremiumEmptyStateState extends State<PremiumEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [widget.iconColor.withOpacity(0.18), widget.iconColor.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: widget.iconColor.withOpacity(0.30), width: 1.5),
                boxShadow: [BoxShadow(color: widget.iconColor.withOpacity(_pulse.value * 0.28), blurRadius: 32, spreadRadius: 6)],
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 44),
            ),
          ),
          const SizedBox(height: 24),
          Text(widget.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(widget.subtitle, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
