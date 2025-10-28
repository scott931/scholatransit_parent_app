import 'package:flutter/material.dart';
import '../../../core/models/trip_log_model.dart';

/// Trip Log Card Widget
///
/// Displays a trip log entry in a card format with key information.
class TripLogCard extends StatelessWidget {
  final TripLog tripLog;
  final VoidCallback? onTap;

  const TripLogCard({super.key, required this.tripLog, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with trip ID and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tripLog.tripId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // Driver and Vehicle info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tripLog.driverName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.directions_bus, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tripLog.vehicleName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Route info
              Row(
                children: [
                  Icon(Icons.route, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tripLog.routeName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  _buildTypeChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // Time information
              _buildTimeInfo(context),

              // Additional info if available
              if (tripLog.actualStart != null || tripLog.actualEnd != null) ...[
                const SizedBox(height: 8),
                _buildActualTimeInfo(context),
              ],

              // Distance and speed info
              if (tripLog.totalDistance != null ||
                  tripLog.averageSpeed != null) ...[
                const SizedBox(height: 8),
                _buildMetricsInfo(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3), width: 1),
      ),
      child: Text(
        tripLog.status.displayName,
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTypeColor().withOpacity(0.3), width: 1),
      ),
      child: Text(
        tripLog.tripType.displayName,
        style: TextStyle(
          color: _getTypeColor(),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scheduled: ${_formatDateTime(tripLog.scheduledStart)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (tripLog.scheduledStart != tripLog.scheduledEnd)
                Text(
                  'End: ${_formatDateTime(tripLog.scheduledEnd)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActualTimeInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tripLog.actualStart != null)
                  Text(
                    'Started: ${_formatDateTime(tripLog.actualStart!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                  ),
                if (tripLog.actualEnd != null)
                  Text(
                    'Ended: ${_formatDateTime(tripLog.actualEnd!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                  ),
                if (tripLog.actualDuration != null)
                  Text(
                    'Duration: ${tripLog.formattedActualDuration}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (tripLog.totalDistance != null) ...[
            Icon(Icons.straighten, size: 16, color: Colors.green[700]),
            const SizedBox(width: 8),
            Text(
              '${tripLog.totalDistance!.toStringAsFixed(1)} km',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.green[700]),
            ),
            const SizedBox(width: 16),
          ],
          if (tripLog.averageSpeed != null) ...[
            Icon(Icons.speed, size: 16, color: Colors.green[700]),
            const SizedBox(width: 8),
            Text(
              '${tripLog.averageSpeed!.toStringAsFixed(1)} km/h',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.green[700]),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (tripLog.status) {
      case TripLogStatus.scheduled:
        return Colors.orange;
      case TripLogStatus.inProgress:
        return Colors.green;
      case TripLogStatus.completed:
        return Colors.blue;
      case TripLogStatus.cancelled:
        return Colors.red;
      case TripLogStatus.delayed:
        return Colors.deepOrange;
    }
  }

  Color _getTypeColor() {
    switch (tripLog.tripType) {
      case TripLogType.studentPickup:
        return Colors.green;
      case TripLogType.studentDropoff:
        return Colors.blue;
      case TripLogType.scheduled:
        return Colors.purple;
      case TripLogType.emergency:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
