// lib/page_selector.dart
import 'package:flutter/material.dart';

class PageSelector extends StatefulWidget {
  final int totalPages;
  final Function(int) onPageSelected;
  final VoidCallback onCancel;

  const PageSelector({
    Key? key,
    required this.totalPages,
    required this.onPageSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  PageSelectorState createState() => PageSelectorState();
}

class PageSelectorState extends State<PageSelector> {
  final TextEditingController _pageController = TextEditingController();
  final FocusNode _pageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_pageFocusNode);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCancel,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 300,
              maxHeight: 200,
            ),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _pageController,
                  focusNode: _pageFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                    'Enter a page number: 1 ~ ${widget.totalPages}',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final page = int.tryParse(_pageController.text);
                    if (page != null && page > 0 && page <= widget.totalPages) {
                      widget.onPageSelected(page);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid page number')),
                      );
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
