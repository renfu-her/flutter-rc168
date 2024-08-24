import 'package:flutter/material.dart';
import 'package:rc168/responsive_text.dart';

class AddressInfo extends StatelessWidget {
  final Map<String, dynamic> address;
  final Function onEditPressed;

  const AddressInfo({
    Key? key,
    required this.address,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title:
          ResponsiveText('收貨地址', baseFontSize: 34, fontWeight: FontWeight.bold),
      subtitle: ResponsiveText(
        '${address['firstname']} ${address['lastname']} \n' +
            '${address['address_1']} ${address['address_2']} \n' +
            '${address['zone']}, ${address['country']} \n' +
            '${address['postcode']}',
        baseFontSize: 30,
        maxLines: 10,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => onEditPressed(),
      ),
    );
  }
}
