import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/trip_logs_provider.dart';
import '../../../core/models/trip_log_model.dart';

/// Trip Logs Filters Widget
///
/// Provides filtering options for trip logs including status, type, date range, etc.
class TripLogsFilters extends ConsumerStatefulWidget {
  const TripLogsFilters({super.key});

  @override
  ConsumerState<TripLogsFilters> createState() => _TripLogsFiltersState();
}

class _TripLogsFiltersState extends ConsumerState<TripLogsFilters> {
  TripLogStatus? _selectedStatus;
  TripLogType? _selectedType;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;

  @override
  void initState() {
    super.initState();
    final state = ref.read(tripLogsProvider);
    _selectedStatus = state.statusFilter;
    _selectedType = state.typeFilter;
    _selectedDateFrom = state.dateFromFilter;
    _selectedDateTo = state.dateToFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Filter Trip Logs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  _buildStatusFilter(),

                  const SizedBox(height: 24),

                  // Type Filter
                  _buildTypeFilter(),

                  const SizedBox(height: 24),

                  // Date Range Filter
                  _buildDateRangeFilter(),

                  const SizedBox(height: 24),

                  // Driver Filter (placeholder for future implementation)
                  _buildDriverFilter(),

                  const SizedBox(height: 24),

                  // Vehicle Filter (placeholder for future implementation)
                  _buildVehicleFilter(),
                ],
              ),
            ),
          ),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TripLogStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return FilterChip(
              label: Text(status.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TripLogType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = selected ? type : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDateFrom,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDateFrom != null
                              ? '${_selectedDateFrom!.day}/${_selectedDateFrom!.month}/${_selectedDateFrom!.year}'
                              : 'From Date',
                          style: TextStyle(
                            color: _selectedDateFrom != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectDateTo,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDateTo != null
                              ? '${_selectedDateTo!.day}/${_selectedDateTo!.month}/${_selectedDateTo!.year}'
                              : 'To Date',
                          style: TextStyle(
                            color: _selectedDateTo != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedDateFrom != null || _selectedDateTo != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearDateRange,
            child: const Text('Clear Date Range'),
          ),
        ],
      ],
    );
  }

  Widget _buildDriverFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Driver',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.person, size: 16),
              SizedBox(width: 8),
              Text('Driver filter coming soon...'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.directions_bus, size: 16),
              SizedBox(width: 8),
              Text('Vehicle filter coming soon...'),
            ],
          ),
        ),
      ],
    );
  }

  void _selectDateFrom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDateFrom = date;
        // If to date is before from date, clear it
        if (_selectedDateTo != null && _selectedDateTo!.isBefore(date)) {
          _selectedDateTo = null;
        }
      });
    }
  }

  void _selectDateTo() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTo ?? _selectedDateFrom ?? DateTime.now(),
      firstDate: _selectedDateFrom ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDateTo = date;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedType = null;
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
  }

  void _applyFilters() {
    final notifier = ref.read(tripLogsProvider.notifier);

    // Apply status filter
    notifier.setStatusFilter(_selectedStatus);

    // Apply type filter
    notifier.setTypeFilter(_selectedType);

    // Apply date range filter
    notifier.setDateRangeFilter(_selectedDateFrom, _selectedDateTo);

    // Close the bottom sheet
    Navigator.of(context).pop();
  }
}
