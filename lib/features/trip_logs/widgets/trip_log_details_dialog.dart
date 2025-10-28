import 'package:flutter/material.dart';
import '../../../core/models/trip_log_model.dart';

/// Trip Log Details Dialog
///
/// Shows detailed information about a specific trip log.
class TripLogDetailsDialog extends StatelessWidget {
  final TripLog tripLog;

  const TripLogDetailsDialog({super.key, required this.tripLog});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripLog.tripId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tripLog.driverName} • ${tripLog.vehicleName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and Type
                    _buildStatusSection(context),

                    const SizedBox(height: 20),

                    // Route Information
                    _buildRouteSection(context),

                    const SizedBox(height: 20),

                    // Schedule Information
                    _buildScheduleSection(context),

                    const SizedBox(height: 20),

                    // Actual Times
                    if (tripLog.actualStart != null ||
                        tripLog.actualEnd != null) ...[
                      _buildActualTimesSection(context),
                      const SizedBox(height: 20),
                    ],

                    // Performance Metrics
                    if (tripLog.totalDistance != null ||
                        tripLog.averageSpeed != null ||
                        tripLog.maxSpeed != null) ...[
                      _buildPerformanceSection(context),
                      const SizedBox(height: 20),
                    ],

                    // Location Information
                    if (tripLog.startLocation != null ||
                        tripLog.endLocation != null ||
                        tripLog.currentLocation != null) ...[
                      _buildLocationSection(context),
                      const SizedBox(height: 20),
                    ],

                    // Notes and Delay Reason
                    if (tripLog.notes != null ||
                        tripLog.delayReason != null) ...[
                      _buildNotesSection(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return _buildSection(context, 'Status & Type', [
      _buildInfoRow('Status', tripLog.status.displayName, _getStatusColor()),
      _buildInfoRow('Type', tripLog.tripType.displayName, _getTypeColor()),
    ]);
  }

  Widget _buildRouteSection(BuildContext context) {
    return _buildSection(context, 'Route Information', [
      _buildInfoRow('Route', tripLog.routeName),
      _buildInfoRow('Driver', tripLog.driverName),
      _buildInfoRow('Vehicle', tripLog.vehicleName),
    ]);
  }

  Widget _buildScheduleSection(BuildContext context) {
    return _buildSection(context, 'Schedule', [
      _buildInfoRow('Scheduled Start', _formatDateTime(tripLog.scheduledStart)),
      _buildInfoRow('Scheduled End', _formatDateTime(tripLog.scheduledEnd)),
      _buildInfoRow('Scheduled Duration', tripLog.formattedScheduledDuration),
    ]);
  }

  Widget _buildActualTimesSection(BuildContext context) {
    return _buildSection(context, 'Actual Times', [
      if (tripLog.actualStart != null)
        _buildInfoRow('Actual Start', _formatDateTime(tripLog.actualStart!)),
      if (tripLog.actualEnd != null)
        _buildInfoRow('Actual End', _formatDateTime(tripLog.actualEnd!)),
      if (tripLog.actualDuration != null)
        _buildInfoRow('Actual Duration', tripLog.formattedActualDuration),
    ]);
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return _buildSection(context, 'Performance Metrics', [
      if (tripLog.totalDistance != null)
        _buildInfoRow(
          'Total Distance',
          '${tripLog.totalDistance!.toStringAsFixed(2)} km',
        ),
      if (tripLog.averageSpeed != null)
        _buildInfoRow(
          'Average Speed',
          '${tripLog.averageSpeed!.toStringAsFixed(2)} km/h',
        ),
      if (tripLog.maxSpeed != null)
        _buildInfoRow(
          'Max Speed',
          '${tripLog.maxSpeed!.toStringAsFixed(2)} km/h',
        ),
    ]);
  }

  Widget _buildLocationSection(BuildContext context) {
    return _buildSection(context, 'Location Information', [
      if (tripLog.startLocation != null)
        _buildInfoRow(
          'Start Location',
          _formatLocation(tripLog.startLocation!),
        ),
      if (tripLog.endLocation != null)
        _buildInfoRow('End Location', _formatLocation(tripLog.endLocation!)),
      if (tripLog.currentLocation != null)
        _buildInfoRow(
          'Current Location',
          _formatLocation(tripLog.currentLocation!),
        ),
    ]);
  }

  Widget _buildNotesSection(BuildContext context) {
    return _buildSection(context, 'Additional Information', [
      if (tripLog.notes != null && tripLog.notes!.isNotEmpty)
        _buildInfoRow('Notes', tripLog.notes!),
      if (tripLog.delayReason != null && tripLog.delayReason!.isNotEmpty)
        _buildInfoRow('Delay Reason', tripLog.delayReason!),
    ]);
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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

  String _formatLocation(String location) {
    // Parse WKT coordinates and format them nicely
    final coords = TripLog.parseWktCoordinates(location);
    if (coords != null) {
      return '${coords['latitude']!.toStringAsFixed(6)}, ${coords['longitude']!.toStringAsFixed(6)}';
    }
    return location;
  }
}
