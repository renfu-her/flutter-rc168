import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:rc168/responsive_text.dart';
import 'package:rc168/main.dart';

class ProductListItem extends StatelessWidget {
  final Product product;

  const ProductListItem({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        '${imgUrl}' + product.thumbUrl,
        width: 80,
      ),
      title: ResponsiveText(
        product.name,
        baseFontSize: 36,
        maxLines: 4,
      ),
      subtitle: Row(
        children: [
          ResponsiveText('數量: ${product.quantity}', baseFontSize: 28),
        ],
      ),
      trailing: ResponsiveText(
          product.special != false
              ? 'NT\$${(product.special * product.quantity).toString()}'
              : 'NT\$${(product.price * product.quantity).toString()}',
          baseFontSize: 28,
          fontWeight: FontWeight.bold),
    );
  }
}
