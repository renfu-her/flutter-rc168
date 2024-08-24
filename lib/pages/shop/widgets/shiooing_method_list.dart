import 'package:flutter/material.dart';
import '../models/shipping_method.dart';
import 'package:rc168/responsive_text.dart';

class ShippingMethodList extends StatelessWidget {
  final List<ShippingMethod> methods;
  final int? selectedMethodCode;
  final Function(int?) onMethodSelected;

  const ShippingMethodList({
    Key? key,
    required this.methods,
    required this.selectedMethodCode,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: ResponsiveText(
            '物流方式',
            baseFontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...methods.map((method) {
          return ListTile(
            leading: Radio<int>(
              value: method.sortOrder!,
              groupValue: selectedMethodCode,
              onChanged: (int? value) => onMethodSelected(value),
            ),
            title: ResponsiveText(
              method.title,
              baseFontSize: 32,
            ),
            trailing: ResponsiveText(
              'NT\$${method.cost}',
              baseFontSize: 34,
              fontWeight: FontWeight.bold,
            ),
            onTap: () => onMethodSelected(method.sortOrder),
          );
        }).toList(),
      ],
    );
  }
}
