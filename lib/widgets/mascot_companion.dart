import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CompanionMood {
  allCompleted, // All doses taken for today
  upcoming,     // Doses pending / next dose approaching
  celebrating,  // Just marked a dose as taken
  resting,      // No medications scheduled
}

class MascotCompanion extends StatefulWidget {
  final CompanionMood mood;
  final String? nextMedName;
  final String? nextMedTime;
  final int dosesRemaining;
  final VoidCallback? onTap;

  const MascotCompanion({
    super.key,
    required this.mood,
    this.nextMedName,
    this.nextMedTime,
    this.dosesRemaining = 0,
    this.onTap,
  });

  @override
  State<MascotCompanion> createState() => _MascotCompanionState();
}

class _MascotCompanionState extends State<MascotCompanion>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _floatController;
  late final AnimationController _blinkController;
  late final AnimationController _bounceController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Floating / breathing idle animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Periodic eye blink
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // Bounce / reaction when tapped or dose recorded
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scheduleNextBlink();

    if (widget.mood == CompanionMood.celebrating) {
      _triggerCelebration();
    }
  }

  @override
  void didUpdateWidget(covariant MascotCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == CompanionMood.celebrating &&
        oldWidget.mood != CompanionMood.celebrating) {
      _triggerCelebration();
    }
  }

  void _triggerCelebration() {
    _bounceController.forward(from: 0.0);
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(milliseconds: 2600 + math.Random().nextInt(2000)), () {
      if (mounted) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse().then((_) => _scheduleNextBlink());
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_floatController.isAnimating) _floatController.repeat(reverse: true);
      _scheduleNextBlink();
    } else {
      _floatController.stop();
      _blinkTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkTimer?.cancel();
    _floatController.dispose();
    _blinkController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward(from: 0.0);
    widget.onTap?.call();
  }

  String _getBubbleMessage() {
    switch (widget.mood) {
      case CompanionMood.allCompleted:
        return 'All done for today! You’re taking wonderful care of yourself ✨';
      case CompanionMood.celebrating:
        return 'Awesome job! Dose recorded 🎉';
      case CompanionMood.upcoming:
        if (widget.nextMedName != null && widget.nextMedTime != null) {
          return 'Next dose: ${widget.nextMedName} at ${widget.nextMedTime} ⏰';
        }
        return '${widget.dosesRemaining} dose${widget.dosesRemaining == 1 ? '' : 's'} remaining today. I’ll keep watch!';
      case CompanionMood.resting:
        return 'No meds scheduled today. Stay hydrated and rest well! 💙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.9),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated Mascot Character
          GestureDetector(
            onTap: _handleTap,
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatController, _bounceController]),
              builder: (context, child) {
                final floatOffset = reduceMotion ? 0.0 : math.sin(_floatController.value * 2 * math.pi) * 3.0;
                final totalOffset = floatOffset + bounceAnimation.value;

                return Transform.translate(
                  offset: Offset(0, totalOffset),
                  child: child,
                );
              },
              child: AnimatedBuilder(
                animation: _blinkController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(54, 62),
                    painter: _PipMascotPainter(
                      mood: widget.mood,
                      blinkProgress: _blinkController.value,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Speech Bubble Message & Companion Identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 11, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text(
                            'PIP • HEALTH GUARDIAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (widget.mood == CompanionMood.allCompleted)
                      const Text('🌟', style: TextStyle(fontSize: 13))
                    else if (widget.mood == CompanionMood.upcoming)
                      const Text('⏰', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _getBubbleMessage(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    height: 1.35,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PipMascotPainter extends CustomPainter {
  final CompanionMood mood;
  final double blinkProgress;
  final bool isDark;

  _PipMascotPainter({
    required this.mood,
    required this.blinkProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Capsule dimensions
    final pillRect = Rect.fromLTWH(6, 4, w - 12, h - 8);
    final r = pillRect.width / 2;

    // Shadow under feet
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - 2), width: w - 18, height: 5),
      shadowPaint,
    );

    // Save layer for clipped pill body
    canvas.save();
    final bodyRRect = RRect.fromRectAndRadius(pillRect, Radius.circular(r));
    canvas.clipRRect(bodyRRect);

    // Top half: Premium Health Blue / Teal
    final topHalfPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF007AFF), Color(0xFF0056D2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(pillRect);
    canvas.drawRect(
      Rect.fromLTWH(pillRect.left, pillRect.top, pillRect.width, pillRect.height / 2),
      topHalfPaint,
    );

    // Bottom half: Pure Soft Warm White / Subtle Tint
    final bottomHalfPaint = Paint()
      ..color = isDark ? const Color(0xFFE4E9F2) : const Color(0xFFF9FBFF);
    canvas.drawRect(
      Rect.fromLTWH(pillRect.left, pillRect.top + pillRect.height / 2, pillRect.width, pillRect.height / 2),
      bottomHalfPaint,
    );

    // Subtle divider line across middle
    final dividerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(pillRect.left, pillRect.top + pillRect.height / 2),
      Offset(pillRect.right, pillRect.top + pillRect.height / 2),
      dividerPaint,
    );

    // Soft highlight glare on upper left
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(pillRect.left + 6, pillRect.top + 6, 8, 14),
      glarePaint,
    );

    canvas.restore();

    // Subtle pill outer border
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.2 : 0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bodyRRect, borderPaint);

    // --- FACE & EXPRESSIONS ---
    final eyeY = pillRect.top + pillRect.height * 0.36;
    final leftEyeX = w / 2 - 8;
    final rightEyeX = w / 2 + 8;

    // Rosy blushing cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF6B8B).withValues(alpha: mood == CompanionMood.allCompleted ? 0.55 : 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(leftEyeX - 6, eyeY + 7), 3.0, blushPaint);
    canvas.drawCircle(Offset(rightEyeX + 6, eyeY + 7), 3.0, blushPaint);

    if (mood == CompanionMood.allCompleted || mood == CompanionMood.celebrating) {
      // Joyful happy curved crescent eyes (^ ^)
      final happyEyePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final leftPath = Path()
        ..moveTo(leftEyeX - 4, eyeY + 1)
        ..quadraticBezierTo(leftEyeX, eyeY - 4, leftEyeX + 4, eyeY + 1);
      final rightPath = Path()
        ..moveTo(rightEyeX - 4, eyeY + 1)
        ..quadraticBezierTo(rightEyeX, eyeY - 4, rightEyeX + 4, eyeY + 1);

      canvas.drawPath(leftPath, happyEyePaint);
      canvas.drawPath(rightPath, happyEyePaint);

      // Cute open smile
      final mouthPath = Path()
        ..moveTo(w / 2 - 3.5, eyeY + 6)
        ..quadraticBezierTo(w / 2, eyeY + 10, w / 2 + 3.5, eyeY + 6);
      canvas.drawPath(mouthPath, happyEyePaint);
    } else {
      // Round attentive eyes with animated blink
      final eyeHeight = math.max(0.6, 5.0 * (1.0 - blinkProgress));
      final eyePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(leftEyeX, eyeY), width: 4.8, height: eyeHeight),
        eyePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rightEyeX, eyeY), width: 4.8, height: eyeHeight),
        eyePaint,
      );

      // Pupil gleam when open
      if (blinkProgress < 0.3) {
        final gleamPaint = Paint()..color = const Color(0xFF003D99);
        canvas.drawCircle(Offset(leftEyeX + 0.8, eyeY - 0.8), 1.2, gleamPaint);
        canvas.drawCircle(Offset(rightEyeX + 0.8, eyeY - 0.8), 1.2, gleamPaint);
      }

      // Friendly smile
      final smilePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(w / 2 - 3, eyeY + 7)
        ..quadraticBezierTo(w / 2, eyeY + 10, w / 2 + 3, eyeY + 7);
      canvas.drawPath(smilePath, smilePaint);
    }

    // --- CHEST EMBLEM ---
    // Tiny Medical Plus / Heart on the bottom half
    final chestY = pillRect.top + pillRect.height * 0.72;
    final chestPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.85)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Plus sign emblem
    canvas.drawLine(Offset(w / 2 - 4, chestY), Offset(w / 2 + 4, chestY), chestPaint);
    canvas.drawLine(Offset(w / 2, chestY - 4), Offset(w / 2, chestY + 4), chestPaint);
  }

  @override
  bool shouldRepaint(covariant _PipMascotPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.isDark != isDark;
  }
}
