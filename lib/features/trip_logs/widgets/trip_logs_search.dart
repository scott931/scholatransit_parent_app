import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/trip_logs_provider.dart';

/// Trip Logs Search Widget
///
/// Provides search functionality for trip logs.
class TripLogsSearch extends ConsumerStatefulWidget {
  const TripLogsSearch({super.key});

  @override
  ConsumerState<TripLogsSearch> createState() => _TripLogsSearchState();
}

class _TripLogsSearchState extends ConsumerState<TripLogsSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize with current search query
    final state = ref.read(tripLogsProvider);
    _searchController.text = state.searchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search trip logs...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
  }

  void _onSearchSubmitted(String value) {
    _performSearch();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    ref.read(tripLogsProvider.notifier).setSearchQuery(null);
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    ref
        .read(tripLogsProvider.notifier)
        .setSearchQuery(query.isEmpty ? null : query);
  }
}
