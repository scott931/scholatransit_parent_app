import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/trip_logs_provider.dart';

/// Trip Logs Statistics Widget
///
/// Displays statistics and analytics for trip logs.
class TripLogsStatistics extends ConsumerStatefulWidget {
  const TripLogsStatistics({super.key});

  @override
  ConsumerState<TripLogsStatistics> createState() => _TripLogsStatisticsState();
}

class _TripLogsStatisticsState extends ConsumerState<TripLogsStatistics> {
  @override
  void initState() {
    super.initState();
    // Load statistics when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripLogsProvider.notifier).loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripLogsProvider);
    final statistics = state.statistics;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Trip Logs Statistics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(tripLogsProvider.notifier).loadStatistics();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Cards
          _buildSummaryCards(state),

          const SizedBox(height: 24),

          // Statistics Content
          if (statistics != null) ...[
            _buildStatisticsContent(statistics),
          ] else if (state.isLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            _buildNoStatisticsContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(TripLogsState state) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Trips',
            state.totalCount.toString(),
            Icons.directions_bus,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Filtered',
            state.filteredCount.toString(),
            Icons.filter_list,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent(Map<String, dynamic> statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Distribution
        if (statistics['status_distribution'] != null) ...[
          _buildSectionTitle('Status Distribution'),
          const SizedBox(height: 8),
          _buildStatusDistribution(statistics['status_distribution']),
          const SizedBox(height: 24),
        ],

        // Type Distribution
        if (statistics['type_distribution'] != null) ...[
          _buildSectionTitle('Trip Type Distribution'),
          const SizedBox(height: 8),
          _buildTypeDistribution(statistics['type_distribution']),
          const SizedBox(height: 24),
        ],

        // Time-based Statistics
        if (statistics['time_stats'] != null) ...[
          _buildSectionTitle('Time Statistics'),
          const SizedBox(height: 8),
          _buildTimeStatistics(statistics['time_stats']),
          const SizedBox(height: 24),
        ],

        // Performance Metrics
        if (statistics['performance'] != null) ...[
          _buildSectionTitle('Performance Metrics'),
          const SizedBox(height: 8),
          _buildPerformanceMetrics(statistics['performance']),
        ],
      ],
    );
  }

  Widget _buildNoStatisticsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No statistics available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Statistics will appear here once trip logs are available',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatusDistribution(Map<String, dynamic> distribution) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: distribution.entries.map((entry) {
          final status = entry.key;
          final count = entry.value as int;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(status)),
                Text(
                  count.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeDistribution(Map<String, dynamic> distribution) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: distribution.entries.map((entry) {
          final type = entry.key;
          final count = entry.value as int;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(type)),
                Text(
                  count.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeStatistics(Map<String, dynamic> timeStats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Average Duration',
            '${timeStats['avg_duration'] ?? 'N/A'}',
          ),
          _buildStatRow(
            'Longest Trip',
            '${timeStats['longest_trip'] ?? 'N/A'}',
          ),
          _buildStatRow(
            'Shortest Trip',
            '${timeStats['shortest_trip'] ?? 'N/A'}',
          ),
          _buildStatRow(
            'Total Distance',
            '${timeStats['total_distance'] ?? 'N/A'} km',
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(Map<String, dynamic> performance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Average Speed',
            '${performance['avg_speed'] ?? 'N/A'} km/h',
          ),
          _buildStatRow(
            'Max Speed',
            '${performance['max_speed'] ?? 'N/A'} km/h',
          ),
          _buildStatRow(
            'On-time Rate',
            '${performance['on_time_rate'] ?? 'N/A'}%',
          ),
          _buildStatRow('Delay Rate', '${performance['delay_rate'] ?? 'N/A'}%'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
