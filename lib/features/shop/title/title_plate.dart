import 'package:flutter/material.dart';

/// 称号プレート。教科別プレート画像の上に称号名を重ねる。
class TitlePlate extends StatelessWidget {
  const TitlePlate({super.key, required this.name, this.width = 110});

  final String name;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '称号 $name',
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: 768 / 269,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/title_plate/plate_programming.webp',
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B2A14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
