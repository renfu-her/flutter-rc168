import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseFontSize; // Base font size at your chosen breakpoint
  final FontWeight fontWeight;
  final Color color;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;
  final TextDecoration decoration;

  ResponsiveText(
    this.text, {
    this.baseFontSize = 16, // Choose a reasonable default size
    this.fontWeight = FontWeight.normal,
    this.color = Colors.black,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines = 1,
    this.decoration = TextDecoration.none,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    double baseWidth =
        360; // Base width could be 360px for standard mobile devices

    // Adjust font size relative to the base width
    double fontSize = (screenWidth / baseWidth) *
        baseFontSize *
        textScaleFactor /
        devicePixelRatio;

    return Text(
      text,
      style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          decoration: decoration),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
