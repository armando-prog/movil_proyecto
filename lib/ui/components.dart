import 'package:flutter/material.dart';

import '../data/models.dart';
import 'image_support.dart';
import 'theme.dart';

class BroteMark extends StatelessWidget {
  const BroteMark({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? paper : ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.13) : forest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.eco_rounded,
            color: light ? const Color(0xFFD8E1C5) : const Color(0xFFE9E9CC),
            size: compact ? 21 : 25,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'brote',
          style: TextStyle(
            color: foreground,
            fontSize: compact ? 22 : 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = mutedInk});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
    ),
  );
}

class PlantArtwork extends StatelessWidget {
  const PlantArtwork({
    super.key,
    required this.plant,
    this.height = 144,
    this.radius = 18,
  });

  final Plant plant;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imagePath = plant.imagePath;
    final image = imagePath == null ? null : plantImageProvider(imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: image != null
            ? Image(image: image, fit: BoxFit.cover)
            : _IllustratedPlant(name: plant.name),
      ),
    );
  }
}

class _IllustratedPlant extends StatelessWidget {
  const _IllustratedPlant({required this.name});
  final String name;

  static const palettes = [
    [Color(0xFFE6E8D8), Color(0xFFD4DCC7), Color(0xFF486E51)],
    [Color(0xFFF0E1CF), Color(0xFFE8D3BB), Color(0xFF96734F)],
    [Color(0xFFDDE7E2), Color(0xFFCADBD3), Color(0xFF47766C)],
    [Color(0xFFE9DFE1), Color(0xFFDDCAD0), Color(0xFF7C5F6C)],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = palettes[name.hashCode.abs() % palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette[0], palette[1]],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -17,
            top: -34,
            child: _orb(100, palette[0].withValues(alpha: 0.62)),
          ),
          Positioned(
            right: -15,
            bottom: -34,
            child: _orb(110, Colors.white.withValues(alpha: 0.24)),
          ),
          Icon(Icons.spa_rounded, size: 76, color: palette[2]),
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: palette[2],
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class EmptyGarden extends StatelessWidget {
  const EmptyGarden({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFE4E9D8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, size: 36, color: forest),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    ),
  );
}
