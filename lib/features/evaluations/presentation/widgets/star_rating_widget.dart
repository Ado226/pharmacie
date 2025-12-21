// Fichier: lib/features/evaluations/presentation/widgets/star_rating_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StarRatingWidget extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int>? onRatingChanged;
  final bool readOnly;

  const StarRatingWidget({
    Key? key,
    required this.rating,
    this.maxRating = 5,
    this.size = 32,
    this.activeColor = const Color(0xFFFFB800),
    this.inactiveColor = const Color(0xFFE2E8F0),
    this.onRatingChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starIndex = index + 1;
        final isActive = starIndex <= rating;

        return GestureDetector(
          onTap: readOnly
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onRatingChanged?.call(starIndex);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isActive ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

class AnimatedStarRating extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int>? onRatingChanged;

  const AnimatedStarRating({
    Key? key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 40,
    this.activeColor = const Color(0xFFFFB800),
    this.inactiveColor = const Color(0xFFE2E8F0),
    this.onRatingChanged,
  }) : super(key: key);

  @override
  State<AnimatedStarRating> createState() => _AnimatedStarRatingState();
}

class _AnimatedStarRatingState extends State<AnimatedStarRating> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starIndex = index + 1;
        final isActive = starIndex <= _currentRating;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _currentRating = starIndex);
            widget.onRatingChanged?.call(starIndex);
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: isActive ? 1.2 : 1.0),
            duration: const Duration(milliseconds: 150),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: widget.size,
                    color: isActive ? widget.activeColor : widget.inactiveColor,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
