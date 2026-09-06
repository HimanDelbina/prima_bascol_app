import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/debouncer.dart';

class SearchableSelectItem<T> {
  final T id;
  final String title;
  final String? subtitle;
  final dynamic extra;

  SearchableSelectItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.extra,
  });
}

class SearchableSelectField<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final T? initialValue;
  final String? initialDisplay;
  final Future<List<SearchableSelectItem<T>>> Function(String query) onSearch;
  final void Function(SearchableSelectItem<T>? selected) onSelected;
  final bool isRequired;
  final String? errorText;
  final VoidCallback? onAddNew;
  final void Function(String query)? onAddNewWithQuery;
  final String? addNewText;

  const SearchableSelectField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.initialDisplay,
    required this.onSearch,
    required this.onSelected,
    this.isRequired = false,
    this.errorText,
    this.onAddNew,
    this.onAddNewWithQuery,
    this.addNewText,
  });

  @override
  State<SearchableSelectField<T>> createState() => _SearchableSelectFieldState<T>();
}

class _SearchableSelectFieldState<T> extends State<SearchableSelectField<T>> {
  SearchableSelectItem<T>? _selectedItem;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialDisplay != null) {
      _selectedItem = SearchableSelectItem(
        id: widget.initialValue as T,
        title: widget.initialDisplay!,
      );
    }
  }

  void _openSelectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _SearchDialog<T>(
        title: widget.label,
        onSearch: widget.onSearch,
        onItemSelected: (item) {
          setState(() {
            _selectedItem = item;
          });
          widget.onSelected(item);
        },
        onAddNew: widget.onAddNew,
        onAddNewWithQuery: widget.onAddNewWithQuery,
        addNewText: widget.addNewText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.label,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (widget.isRequired)
              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _openSelectionDialog,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: widget.errorText != null ? theme.colorScheme.error : theme.dividerColor,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedItem?.title ?? widget.hint ?? "برای جستجو و انتخاب کلیک کنید...",
                    style: TextStyle(
                      color: _selectedItem != null
                          ? theme.textTheme.bodyLarge?.color
                          : theme.hintColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedItem != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _selectedItem = null;
                      });
                      widget.onSelected(null);
                    },
                  )
                else
                  const Icon(Icons.arrow_drop_down_rounded, size: 22),
              ],
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  final String title;
  final Future<List<SearchableSelectItem<T>>> Function(String query) onSearch;
  final void Function(SearchableSelectItem<T> item) onItemSelected;
  final VoidCallback? onAddNew;
  final void Function(String query)? onAddNewWithQuery;
  final String? addNewText;

  const _SearchDialog({
    required this.title,
    required this.onSearch,
    required this.onItemSelected,
    this.onAddNew,
    this.onAddNewWithQuery,
    this.addNewText,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 350);
  List<SearchableSelectItem<T>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _performSearch("");
  }

  void _performSearch(String query) {
    setState(() => _isLoading = true);
    widget.onSearch(query).then((res) {
      if (mounted) {
        setState(() {
          _items = res;
          _isLoading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title.startsWith("انتخاب") ? widget.title : "انتخاب ${widget.title}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "عبارت جستجو را وارد کنید...",
                ),
                onChanged: (val) {
                  _debouncer.run(() => _performSearch(val));
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppDimensions.md),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("موردی یافت نشد."),
                                  if (widget.onAddNew != null || widget.onAddNewWithQuery != null) ...[
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add, size: 18),
                                      label: Text(widget.addNewText ?? "ثبت مورد جدید"),
                                      onPressed: () {
                                        final q = _searchController.text.trim();
                                        Navigator.pop(context);
                                        if (widget.onAddNewWithQuery != null) {
                                          widget.onAddNewWithQuery!(q);
                                        } else {
                                          widget.onAddNew?.call();
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final item = _items[i];
                              return ListTile(
                                title: Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: item.subtitle != null ? Text(item.subtitle!, style: const TextStyle(fontSize: 11)) : null,
                                onTap: () {
                                  widget.onItemSelected(item);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
