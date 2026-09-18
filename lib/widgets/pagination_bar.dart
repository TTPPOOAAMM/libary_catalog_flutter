import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Строк на странице: '),
              DropdownButton<int>(
                value: size,
                items: const [10, 25, 50].map((s) {
                  return DropdownMenuItem(value: s, child: Text('$s'));
                }).toList(),
                onChanged: (val) {
                  if (val != null && val != size) onSizeChanged(val);
                },
              ),
              const SizedBox(width: 16),
              Text('Всего: $total'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                tooltip: 'Первая',
                onPressed: page > 1 ? () => onPageChanged(1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Предыдущая',
                onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Стр. $page из $totalPages'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Следующая',
                onPressed:
                    page < totalPages ? () => onPageChanged(page + 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                tooltip: 'Последняя',
                onPressed:
                    page < totalPages ? () => onPageChanged(totalPages) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
