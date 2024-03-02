import 'package:flutter/material.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color; // 新增颜色参数
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  ResponsiveText(
    this.text, {
    this.fontSize = 20, // 默认字体大小
    this.fontWeight = FontWeight.normal, // 默认字重
    this.color = Colors.black, // 默认颜色
    this.textAlign = TextAlign.start, // 默认居中
    this.overflow = TextOverflow.clip, // 默认以省略号处理溢出文本
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    // 获取屏幕的宽度
    double screenWidth = MediaQuery.of(context).size.width;
    // 根据屏幕宽度设置文字大小
    double fontSize = screenWidth / (600 / this.fontSize); // 假设以600为基准进行调整

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
