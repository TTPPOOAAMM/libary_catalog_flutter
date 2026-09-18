import 'dart:async';
import 'package:flutter/material.dart';

class DebounceSearchField extends StatefulWidget {
  final String initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;
  final Duration debounceDuration;

  const DebounceSearchField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hintText = 'Поиск...',
    this.debounceDuration = const Duration(milliseconds: 350),
  });

  @override
  State<DebounceSearchField> createState() => _DebounceSearchFieldState();
}

class _DebounceSearchFieldState extends State<DebounceSearchField> {
  late final TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant DebounceSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String val) {
    _timer?.cancel();
    _timer = Timer(widget.debounceDuration, () {
      widget.onChanged(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: widget.hintText,
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
      onChanged: _onTextChanged,
    );
  }
}
