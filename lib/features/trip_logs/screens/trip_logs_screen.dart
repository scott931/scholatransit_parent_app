import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/trip_logs_provider.dart';
import '../../../core/models/trip_log_model.dart';
import '../widgets/trip_log_card.dart';
import '../widgets/trip_logs_filters.dart';
import '../widgets/trip_logs_search.dart';
import '../widgets/trip_logs_statistics.dart';
import '../widgets/trip_log_details_dialog.dart';

/// Trip Logs Screen
///
/// Displays a list of trip logs with filtering, searching, and pagination capabilities.
class TripLogsScreen extends ConsumerStatefulWidget {
  const TripLogsScreen({super.key});

  @override
  ConsumerState<TripLogsScreen> createState() => _TripLogsScreenState();
}

class _TripLogsScreenState extends ConsumerState<TripLogsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripLogsProvider.notifier).loadTripLogs();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(tripLogsProvider.notifier).loadMoreTripLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripLogsState = ref.watch(tripLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Logs'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(tripLogsProvider.notifier).refreshTripLogs();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFiltersDialog();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportTripLogs();
                  break;
                case 'statistics':
                  _showStatisticsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export CSV'),
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Statistics'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Trips', icon: Icon(Icons.list)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripLogsList(tripLogsState),
          _buildStatisticsTab(tripLogsState),
        ],
      ),
      floatingActionButton: tripLogsState.hasActiveFilters
          ? FloatingActionButton(
              onPressed: () {
                ref.read(tripLogsProvider.notifier).clearFilters();
              },
              tooltip: 'Clear Filters',
              child: const Icon(Icons.clear),
            )
          : null,
    );
  }

  Widget _buildTripLogsList(TripLogsState state) {
    return Column(
      children: [
        // Search bar
        const TripLogsSearch(),

        // Filters summary
        if (state.hasActiveFilters) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${state.filteredCount} of ${state.totalCount} trips',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(tripLogsProvider.notifier).clearFilters();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ],

        // Trip logs list
        Expanded(child: _buildTripLogsContent(state)),
      ],
    );
  }

  Widget _buildTripLogsContent(TripLogsState state) {
    if (state.isLoading && state.tripLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.tripLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading trip logs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(tripLogsProvider.notifier).loadTripLogs();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.tripLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No trip logs found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search criteria',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(tripLogsProvider.notifier).refreshTripLogs();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.tripLogs.length + (state.canLoadMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.tripLogs.length) {
            // Loading indicator for pagination
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final tripLog = state.tripLogs[index];
          return TripLogCard(
            tripLog: tripLog,
            onTap: () => _showTripLogDetails(tripLog),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab(TripLogsState state) {
    return const TripLogsStatistics();
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TripLogsFilters(),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => const TripLogsStatistics(),
    );
  }

  void _showTripLogDetails(TripLog tripLog) {
    showDialog(
      context: context,
      builder: (context) => TripLogDetailsDialog(tripLog: tripLog),
    );
  }

  void _exportTripLogs() async {
    final notifier = ref.read(tripLogsProvider.notifier);
    final csvData = await notifier.exportTripLogs();

    if (csvData != null) {
      // TODO: Implement CSV export functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip logs exported successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export trip logs')),
      );
    }
  }
}
