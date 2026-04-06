import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

typedef AsyncItemsLoader<T> = Future<List<T>> Function();
typedef AsyncItemLabel<T> = String Function(T item);

class AppDropdownAsync<T> extends StatefulWidget {
  final T? value;
  final String label;
  final AsyncItemsLoader<T> loader;
  final AsyncItemLabel<T> labelBuilder;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const AppDropdownAsync({
    super.key,
    required this.value,
    required this.label,
    required this.loader,
    required this.labelBuilder,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<AppDropdownAsync<T>> createState() => _AppDropdownAsyncState<T>();
}

class _AppDropdownAsyncState<T> extends State<AppDropdownAsync<T>> {
  List<T> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.loader();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return InputDecorator(
        decoration: InputDecoration(labelText: widget.label),
        child: const SizedBox(
          height: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return InkWell(
        onTap: _load,
        child: InputDecorator(
          decoration: InputDecoration(labelText: widget.label),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Không tải được dữ liệu',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const Icon(Icons.refresh, color: Colors.white54, size: 18),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<T>(
      initialValue: widget.value,
      isExpanded: true,
      decoration: InputDecoration(labelText: widget.label),
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white),
      items: _items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                widget.labelBuilder(item),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: widget.enabled ? widget.onChanged : null,
    );
  }
}
