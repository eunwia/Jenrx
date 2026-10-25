import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'mascot_companion.dart';

/// Interactive 3D Medicine Kit with realistic hinge opening animation,
/// revealing the Pip Health Guardian mascot inside.
class InteractiveMedicineKit extends StatefulWidget {
  final int totalItems;
  final int lowStockCount;
  final VoidCallback? onAddStock;
  final VoidCallback? onAnimationComplete;
  final bool initialOpen;

  const InteractiveMedicineKit({
    super.key,
    required this.totalItems,
    this.lowStockCount = 0,
    this.onAddStock,
    this.onAnimationComplete,
    this.initialOpen = false,
  });

  @override
  State<InteractiveMedicineKit> createState() => InteractiveMedicineKitState();
}

class InteractiveMedicineKitState extends State<InteractiveMedicineKit>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _openController;
  late final AnimationController _idleFloatController;
  late final AnimationController _blinkController;
  late final AnimationController _tapReactionController;

  Timer? _blinkTimer;
  Timer? _autoOpenTimer;
  bool _appIsResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _idleFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _tapReactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scheduleNextBlink();

    _openController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    // Start closed, then smoothly animate open on entry unless reduced motion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion || widget.initialOpen) {
        _openController.value = 1.0;
        widget.onAnimationComplete?.call();
      } else {
        // Slight anticipation pause before opening smoothly
        _autoOpenTimer = Timer(const Duration(milliseconds: 260), () {
          if (mounted && !_openController.isAnimating) {
            _openController.forward();
          }
        });
      }
    });
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(milliseconds: 2800 + math.Random().nextInt(2200)), () {
      if (mounted && _appIsResumed) {
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
      _appIsResumed = true;
      if (!_idleFloatController.isAnimating) _idleFloatController.repeat(reverse: true);
      _scheduleNextBlink();
    } else {
      _appIsResumed = false;
      _idleFloatController.stop();
      _blinkTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoOpenTimer?.cancel();
    _blinkTimer?.cancel();
    _openController.dispose();
    _idleFloatController.dispose();
    _blinkController.dispose();
    _tapReactionController.dispose();
    super.dispose();
  }

  /// Toggles kit open/closed or triggers a joyful mascot reaction if already open
  void toggleKit() {
    if (_openController.isAnimating) return; // prevent conflicting animations

    if (_openController.value < 0.5) {
      _openController.forward();
    } else {
      // If tapped while open, give a joyful bounce reaction
      _tapReactionController.forward(from: 0.0);
    }
  }

  /// Replays the opening animation from the closed state
  void replayOpening() {
    if (_openController.isAnimating) return;
    _openController.reverse().then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) _openController.forward();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Curved animations for realistic physical hinge and overshoot bounce
    final lidAnimation = CurvedAnimation(
      parent: _openController,
      curve: const Interval(0.12, 0.78, curve: Curves.easeInOutCubic),
    );

    final latchAnimation = CurvedAnimation(
      parent: _openController,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );

    final pipPopAnimation = CurvedAnimation(
      parent: _openController,
      curve: const Interval(0.38, 0.90, curve: Curves.easeOutBack),
    );

    final bannerFadeAnimation = CurvedAnimation(
      parent: _openController,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([
        _openController,
        _idleFloatController,
        _blinkController,
        _tapReactionController,
      ]),
      builder: (context, _) {
        final openVal = reduceMotion ? 1.0 : _openController.value;
        final lidVal = reduceMotion ? 1.0 : lidAnimation.value;
        final pipVal = reduceMotion ? 1.0 : pipPopAnimation.value;
        final latchVal = reduceMotion ? 1.0 : latchAnimation.value;
        final bannerVal = reduceMotion ? 1.0 : bannerFadeAnimation.value;

        // 3D Lid rotation angle (from 0 closed to -1.9 radians swung backwards)
        final lidAngle = -1.92 * lidVal;

        // Mascot vertical float & pop calculations
        final floatOffset = (reduceMotion || openVal < 0.8)
            ? 0.0
            : math.sin(_idleFloatController.value * 2 * math.pi) * 3.5;
        final tapReactionY = -6.0 * math.sin(_tapReactionController.value * math.pi);
        // At pipVal=0, tucked inside box (dy: 38); at pipVal=1, standing upright (dy: -24)
        final pipY = (38.0 * (1.0 - pipVal)) + (-24.0 * pipVal) + floatOffset + tapReactionY;
        final pipScale = (0.35 + (0.65 * pipVal)).clamp(0.0, 1.12);

        const kitWidth = 186.0;
        const kitHeight = 114.0;
        const lidHeight = 64.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Medicine Kit 3D Assembly
            GestureDetector(
              onTap: toggleKit,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: kitWidth,
                height: kitHeight + 36, // space for Pip popping above the box
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 1. Soft Ambient Floor Shadow
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: kitWidth * 0.92,
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Interior Tray / Cavity (Velvet lining, compartments)
                    Positioned(
                      bottom: 8,
                      child: CustomPaint(
                        size: const Size(kitWidth, kitHeight),
                        painter: _KitTrayPainter(
                          isDark: isDark,
                          openProgress: openVal,
                        ),
                      ),
                    ),

                    // 3. Rain Health Guardian (Pill character emerging from the cavity)
                    Positioned(
                      bottom: 8 + kitHeight * 0.38,
                      child: Transform.translate(
                        offset: Offset(0, pipY),
                        child: Transform.scale(
                          scale: pipScale,
                          child: Opacity(
                            opacity: pipVal.clamp(0.0, 1.0),
                            child: CustomPaint(
                              size: const Size(54, 62),
                              painter: RainMascotPainter(
                                mood: widget.lowStockCount > 0
                                    ? CompanionMood.upcoming
                                    : CompanionMood.allCompleted,
                                blinkProgress: _blinkController.value,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 4. Front Body of the Kit (overlaps lower half of Pip, with metallic badge & corner brackets)
                    Positioned(
                      bottom: 8,
                      child: CustomPaint(
                        size: const Size(kitWidth, kitHeight),
                        painter: _KitFrontBodyPainter(
                          isDark: isDark,
                          openProgress: openVal,
                          latchProgress: latchVal,
                        ),
                      ),
                    ),

                    // 5. 3D Hinged Lid with Realistic Perspective
                    Positioned(
                      bottom: 8 + (kitHeight - lidHeight),
                      child: Transform(
                        alignment: Alignment.topCenter,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0016) // Subtle 3D perspective
                          ..rotateX(lidAngle),
                        child: CustomPaint(
                          size: const Size(kitWidth, lidHeight),
                          painter: _KitLidPainter(
                            isDark: isDark,
                            angle: lidAngle,
                            latchProgress: latchVal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Companion Greeting & Kit Status Banner
            Opacity(
              opacity: bannerVal,
              child: Transform.translate(
                offset: Offset(0, 8.0 * (1.0 - bannerVal)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: (widget.lowStockCount > 0 ? AppColors.warning : AppColors.primary)
                              .withValues(alpha: isDark ? 0.25 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.lowStockCount > 0
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                          color: widget.lowStockCount > 0 ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Rain • Medicine Kit Guardian',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: replayOpening,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.replay_rounded,
                                          size: 13,
                                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Replay',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.totalItems == 0
                                  ? 'Kit is empty. Tap + at bottom right to log supplies!'
                                  : (widget.lowStockCount > 0
                                      ? 'Careful! ${widget.lowStockCount} medication supply is running low.'
                                      : 'All ${widget.totalItems} supplies safe & accounted for!'),
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.lowStockCount > 0
                                    ? AppColors.warning
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                fontWeight: widget.lowStockCount > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Paints the recessed interior of the medical box where supplies and Pip rest.
class _KitTrayPainter extends CustomPainter {
  final bool isDark;
  final double openProgress;

  _KitTrayPainter({required this.isDark, required this.openProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    // Outer case backplate
    final backplatePaint = Paint()
      ..color = isDark ? const Color(0xFF1E2530) : const Color(0xFFF1F5F9);
    canvas.drawRRect(rrect, backplatePaint);

    if (openProgress > 0.05) {
      // Recessed interior cavity
      final cavityRect = Rect.fromLTWH(10, 10, w - 20, h - 20);
      final cavityRRect = RRect.fromRectAndRadius(cavityRect, const Radius.circular(14));

      final cavityPaint = Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? [const Color(0xFF111722), const Color(0xFF182230)]
              : [const Color(0xFFDFE6F0), const Color(0xFFEEF3F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(cavityRect);
      canvas.drawRRect(cavityRRect, cavityPaint);

      // Inner shadow at the top of cavity
      final innerShadowPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(10, 10, w - 20, 24));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, w - 20, 20), const Radius.circular(14)),
        innerShadowPaint,
      );

      // Subtle compartment divider lines
      final dividerPaint = Paint()
        ..color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(w * 0.28, 14), Offset(w * 0.28, h - 14), dividerPaint);
      canvas.drawLine(Offset(w * 0.72, 14), Offset(w * 0.72, h - 14), dividerPaint);

      // Subtle medical cross watermark on the back wall
      final watermarkPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: isDark ? 0.10 : 0.08)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w / 2 - 10, h * 0.42), Offset(w / 2 + 10, h * 0.42), watermarkPaint);
      canvas.drawLine(Offset(w / 2, h * 0.42 - 10), Offset(w / 2, h * 0.42 + 10), watermarkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KitTrayPainter oldDelegate) {
    return oldDelegate.openProgress != openProgress || oldDelegate.isDark != isDark;
  }
}

/// Paints the front body of the kit which overlaps the bottom half of Pip,
/// anchoring Pip firmly inside the container.
class _KitFrontBodyPainter extends CustomPainter {
  final bool isDark;
  final double openProgress;
  final double latchProgress;

  _KitFrontBodyPainter({
    required this.isDark,
    required this.openProgress,
    required this.latchProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Height of front panel (covers lower 56% of kit)
    final frontH = h * 0.56;
    final frontRect = Rect.fromLTWH(0, h - frontH, w, frontH);
    final frontRRect = RRect.fromRectAndCorners(
      frontRect,
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );

    // Front shell gradient
    final shellPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF263040), const Color(0xFF1E2634)]
            : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(frontRect);
    canvas.drawRRect(frontRRect, shellPaint);

    // Front shell border
    final borderPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(frontRRect, borderPaint);

    // Top rim highlight line
    final rimPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.white
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(4, h - frontH + 1), Offset(w - 4, h - frontH + 1), rimPaint);

    // Horizontal styling groove
    final groovePaint = Paint()
      ..color = isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(14, h - frontH * 0.45), Offset(w - 14, h - frontH * 0.45), groovePaint);

    // Chrome Corner Reinforcements (Bottom-Left and Bottom-Right)
    _drawChromeCorner(canvas, Offset(8, h - 8), isBottomLeft: true);
    _drawChromeCorner(canvas, Offset(w - 8, h - 8), isBottomLeft: false);

    // Front Metallic Latch Receiver
    final latchW = 28.0;
    final latchH = 18.0;
    final latchY = h - frontH - (latchH * 0.35);
    final latchRect = Rect.fromCenter(center: Offset(w / 2, latchY + 8), width: latchW, height: latchH);
    final latchRRect = RRect.fromRectAndRadius(latchRect, const Radius.circular(5));

    final latchPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE0E5EC), Color(0xFFB8C2CC), Color(0xFF9AA5B1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(latchRect);
    canvas.drawRRect(latchRRect, latchPaint);

    final latchBorder = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(latchRRect, latchBorder);

    // Medical Cross Badge in Center of Front Panel
    final badgeCenter = Offset(w / 2, h - (frontH * 0.52));
    final badgeRadius = 14.0;

    // Badge circle
    final badgeBgPaint = Paint()
      ..color = isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primaryLight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, badgeBgPaint);

    final badgeBorderPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(badgeCenter, badgeRadius, badgeBorderPaint);

    // Red / Blue Cross Symbol
    final crossPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(badgeCenter.dx - 6, badgeCenter.dy), Offset(badgeCenter.dx + 6, badgeCenter.dy), crossPaint);
    canvas.drawLine(Offset(badgeCenter.dx, badgeCenter.dy - 6), Offset(badgeCenter.dx, badgeCenter.dy + 6), crossPaint);
  }

  void _drawChromeCorner(Canvas canvas, Offset corner, {required bool isBottomLeft}) {
    final bracketPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: corner, radius: 10));

    final path = Path();
    if (isBottomLeft) {
      path.moveTo(corner.dx - 4, corner.dy - 12);
      path.lineTo(corner.dx - 4, corner.dy + 4);
      path.lineTo(corner.dx + 12, corner.dy + 4);
      path.lineTo(corner.dx + 6, corner.dy - 2);
      path.lineTo(corner.dx + 2, corner.dy - 2);
      path.lineTo(corner.dx + 2, corner.dy - 6);
      path.close();
    } else {
      path.moveTo(corner.dx + 4, corner.dy - 12);
      path.lineTo(corner.dx + 4, corner.dy + 4);
      path.lineTo(corner.dx - 12, corner.dy + 4);
      path.lineTo(corner.dx - 6, corner.dy - 2);
      path.lineTo(corner.dx - 2, corner.dy - 2);
      path.lineTo(corner.dx - 2, corner.dy - 6);
      path.close();
    }
    canvas.drawPath(path, bracketPaint);

    // Tiny rivet dot
    final rivetPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
    canvas.drawCircle(corner, 1.2, rivetPaint);
  }

  @override
  bool shouldRepaint(covariant _KitFrontBodyPainter oldDelegate) {
    return oldDelegate.openProgress != openProgress ||
        oldDelegate.latchProgress != latchProgress ||
        oldDelegate.isDark != isDark;
  }
}

/// Paints the 3D hinged lid, including its top handle, metallic latch, and interior lining.
class _KitLidPainter extends CustomPainter {
  final bool isDark;
  final double angle;
  final double latchProgress;

  _KitLidPainter({
    required this.isDark,
    required this.angle,
    required this.latchProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Check if the front of lid or underside is visible based on rotation angle
    final isUndersideFacing = angle < -math.pi / 2;

    if (!isUndersideFacing) {
      // --- FRONT OF LID (Closed or rotating open) ---
      final lidRect = Rect.fromLTWH(0, 0, w, h);
      final lidRRect = RRect.fromRectAndCorners(
        lidRect,
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      );

      // Lid shell gradient
      final lidPaint = Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C3748), const Color(0xFF222B38)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(lidRect);
      canvas.drawRRect(lidRRect, lidPaint);

      // Outer border
      final borderPaint = Paint()
        ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(lidRRect, borderPaint);

      // Top glossy highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.15 : 0.6)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(18, 2), Offset(w - 18, 2), highlightPaint);

      // Top Carrying Handle (Arched chrome handle)
      final handlePaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFF64748B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(w / 2 - 28, -12, 56, 14))
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final handlePath = Path()
        ..moveTo(w / 2 - 24, 0)
        ..quadraticBezierTo(w / 2 - 24, -10, w / 2 - 14, -10)
        ..lineTo(w / 2 + 14, -10)
        ..quadraticBezierTo(w / 2 + 24, -10, w / 2 + 24, 0);
      canvas.drawPath(handlePath, handlePaint);

      // Handle brackets / rivets
      final rivetPaint = Paint()..color = const Color(0xFF64748B);
      canvas.drawCircle(Offset(w / 2 - 24, 1), 3.0, rivetPaint);
      canvas.drawCircle(Offset(w / 2 + 24, 1), 3.0, rivetPaint);

      // Latch Upper Clamp on Lid
      final latchW = 24.0;
      final latchH = 16.0;
      // When latch unclips, it shifts slightly
      final latchOffset = latchProgress * 4.0;
      final latchRect = Rect.fromCenter(
        center: Offset(w / 2, h - (latchH * 0.3) + latchOffset),
        width: latchW,
        height: latchH,
      );
      final latchRRect = RRect.fromRectAndRadius(latchRect, const Radius.circular(4));

      final latchPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(latchRect);
      canvas.drawRRect(latchRRect, latchPaint);

      final latchBorder = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(latchRRect, latchBorder);
    } else {
      // --- UNDERSIDE OF LID (Facing camera when opened > 90 degrees) ---
      final lidRect = Rect.fromLTWH(0, 0, w, h);
      final lidRRect = RRect.fromRectAndCorners(
        lidRect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(18),
        bottomRight: const Radius.circular(18),
      );

      // Interior lining of lid
      final insidePaint = Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? [const Color(0xFF141C28), const Color(0xFF1C2736)]
              : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(lidRect);
      canvas.drawRRect(lidRRect, insidePaint);

      final insideBorder = Paint()
        ..color = isDark ? Colors.white12 : Colors.black12
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(lidRRect, insideBorder);

      // Elastic pouch / mesh pocket on lid underside
      final meshRect = Rect.fromLTWH(14, 12, w - 28, h - 22);
      final meshRRect = RRect.fromRectAndRadius(meshRect, const Radius.circular(8));
      final meshPaint = Paint()
        ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);
      canvas.drawRRect(meshRRect, meshPaint);

      final elasticBand = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.35)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(14, 14), Offset(w - 14, 14), elasticBand);
    }
  }

  @override
  bool shouldRepaint(covariant _KitLidPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.latchProgress != latchProgress ||
        oldDelegate.isDark != isDark;
  }
}
