import 'package:flutter/material.dart';

class TimezoneDropdownItem extends StatelessWidget {
  final List<Map<String, String>> items;
  final String? value;
  final ValueChanged<String?>? onChanged;

  const TimezoneDropdownItem({
    Key? key,
    required this.items,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        menuMaxHeight: 300, // Limit dropdown height to prevent overlap
        focusColor: Colors.transparent, // Remove focus color
        items: items.map<DropdownMenuItem<String>>((Map<String, String> item) {
          return DropdownMenuItem<String>(
            value: item['name'],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item['name']!,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(
                  item['offset']!,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          );
        }).toList(),
    );
  }
}
