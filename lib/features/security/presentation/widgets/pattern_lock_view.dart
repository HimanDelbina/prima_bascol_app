import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PatternLockView extends StatefulWidget {
  final ValueChanged<List<int>> onPatternComplete;
  final bool isError;
  final bool isEnabled;
  final double dimension;
  final Color? normalDotColor;
  final Color? activeDotColor;
  final Color? errorColor;

  const PatternLockView({
    super.key,
    required this.onPatternComplete,
    this.isError = false,
    this.isEnabled = true,
    this.dimension = 280,
    this.normalDotColor,
    this.activeDotColor,
    this.errorColor,
  });

  @override
  State<PatternLockView> createState() => PatternLockViewState();
}

class PatternLockViewState extends State<PatternLockView>
    with SingleTickerProviderStateMixin {
  final List<int> _selectedIndices = [];
  Offset? _currentDragPos;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant PatternLockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void clearPattern() {
    setState(() {
      _selectedIndices.clear();
      _currentDragPos = null;
    });
  }

  int? _findHitNode(Offset localPos, double size) {
    final cellWidth = size / 3;
    final cellHeight = size / 3;
    const hitRadius = 32.0;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final center = Offset(
          col * cellWidth + cellWidth / 2,
          row * cellHeight + cellHeight / 2,
        );
        if ((localPos - center).distance <= hitRadius) {
          return row * 3 + col;
        }
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled) return;
    final hit = _findHitNode(details.localPosition, widget.dimension);
    setState(() {
      _selectedIndices.clear();
      if (hit != null) {
        _selectedIndices.add(hit);
      }
      _currentDragPos = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) return;
    final hit = _findHitNode(details.localPosition, widget.dimension);
    setState(() {
      _currentDragPos = details.localPosition;
      if (hit != null && !_selectedIndices.contains(hit)) {
        _selectedIndices.add(hit);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled) return;
    setState(() {
      _currentDragPos = null;
    });
    if (_selectedIndices.isNotEmpty) {
      widget.onPatternComplete(List<int>.from(_selectedIndices));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalColor = widget.normalDotColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey.shade600
            : Colors.grey.shade400);
    final activeColor = widget.activeDotColor ?? AppColors.primary;
    final errColor = widget.errorColor ?? AppColors.error;

    return Directionality(
      textDirection: TextDirection.ltr, // Preserve fixed spatial geometry
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: SizedBox(
          width: widget.dimension,
          height: widget.dimension,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              size: Size(widget.dimension, widget.dimension),
              painter: _PatternPainter(
                selectedIndices: _selectedIndices,
                currentDragPos: _currentDragPos,
                isError: widget.isError,
                normalColor: normalColor,
                activeColor: activeColor,
                errorColor: errColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> selectedIndices;
  final Offset? currentDragPos;
  final bool isError;
  final Color normalColor;
  final Color activeColor;
  final Color errorColor;

  _PatternPainter({
    required this.selectedIndices,
    required this.currentDragPos,
    required this.isError,
    required this.normalColor,
    required this.activeColor,
    required this.errorColor,
  });

  Offset _getNodeCenter(int index, Size size) {
    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;
    final row = index ~/ 3;
    final col = index % 3;
    return Offset(
      col * cellWidth + cellWidth / 2,
      row * cellHeight + cellHeight / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveColor = isError ? errorColor : activeColor;

    // 1. Draw connecting lines between selected nodes
    if (selectedIndices.isNotEmpty) {
      final linePaint = Paint()
        ..color = effectiveColor.withValues(alpha: 0.8)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final firstPoint = _getNodeCenter(selectedIndices.first, size);
      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < selectedIndices.length; i++) {
        final pt = _getNodeCenter(selectedIndices[i], size);
        path.lineTo(pt.dx, pt.dy);
      }

      if (currentDragPos != null) {
        path.lineTo(currentDragPos!.dx, currentDragPos!.dy);
      }

      canvas.drawPath(path, linePaint);
    }

    // 2. Draw 9 nodes
    for (int i = 0; i < 9; i++) {
      final center = _getNodeCenter(i, size);
      final isSelected = selectedIndices.contains(i);

      if (isSelected) {
        // Outer halo
        final haloPaint = Paint()
          ..color = effectiveColor.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 24, haloPaint);

        // Outer ring
        final ringPaint = Paint()
          ..color = effectiveColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center, 24, ringPaint);

        // Center dot
        final centerDotPaint = Paint()
          ..color = effectiveColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 8, centerDotPaint);
      } else {
        // Inactive small dot
        final dotPaint = Paint()
          ..color = normalColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 6.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return true;
  }
}
