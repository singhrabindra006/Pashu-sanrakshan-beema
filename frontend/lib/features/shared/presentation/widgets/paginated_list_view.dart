import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../core/widgets/error/empty_state.dart';
import '../../../../core/widgets/loading/shimmer_loader.dart';

/// Renders a [ListState] with the four states every list screen needs: first
/// load, empty, error and loaded-with-infinite-scroll.
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 96),
  });

  final ListState<T> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  /// Pinned above the scroll area (search fields, filter chips).
  final Widget? header;
  final EdgeInsets padding;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final threshold = _controller.position.maxScrollExtent - 320;
    if (_controller.position.pixels >= threshold) widget.onLoadMore();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    Widget body;
    if (state.isFirstLoad) {
      body = const ShimmerListLoader();
    } else if (state.status == ListStatus.failure && state.items.isEmpty) {
      body = EmptyState.error(
        title: 'Could not load this list',
        message: state.message,
        onAction: widget.onRefresh,
      );
    } else if (state.items.isEmpty) {
      body = RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 420,
              child: EmptyState(
                title: widget.emptyTitle,
                message: widget.emptyMessage,
                icon: widget.emptyIcon,
                actionLabel: 'Refresh',
                onAction: widget.onRefresh,
              ),
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView.separated(
          controller: _controller,
          padding: widget.padding,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return widget.itemBuilder(context, state.items[index]);
          },
        ),
      );
    }

    if (widget.header == null) return body;
    return Column(
      children: [
        widget.header!,
        Expanded(child: body),
      ],
    );
  }
}

/// Debounced search bar used by the admin lists.
class SearchHeader extends StatefulWidget {
  const SearchHeader({super.key, required this.hint, required this.onChanged, this.trailing});

  final String hint;
  final ValueChanged<String> onChanged;
  final Widget? trailing;

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _emit(String value) {
    _debounce?.cancel();
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _emit,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _emit('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (value) {
                setState(() {});
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () => widget.onChanged(value));
              },
            ),
          ),
          if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!],
        ],
      ),
    );
  }
}
