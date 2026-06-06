import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Sterne-Bewertung mit Halbsterne-Anzeige; Tap setzt ganze Sterne.
class StarRatingInput extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;
  final double size;
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => GestureDetector(
            onTap: () => onChanged((i + 1).toDouble()),
            child: Icon(
              rating >= i + 1
                  ? Icons.star
                  : rating >= i + 0.5
                      ? Icons.star_half
                      : Icons.star_border,
              color: TraumColors.amberGold,
              size: size,
            ),
          ),
        ),
      );
}

InputDecoration mapInputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'DMSans',
        color: TraumColors.onBackgroundSubtle,
        fontSize: 14,
      ),
      filled: true,
      fillColor: TraumColors.surfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TraumColors.cyanBlue, width: 1.5),
      ),
    );

/// Kleines Megapixel-Label (z. B. „12,2 MP") für Foto-Overlays.
class MegapixelBadge extends StatelessWidget {
  final String text;
  const MegapixelBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
