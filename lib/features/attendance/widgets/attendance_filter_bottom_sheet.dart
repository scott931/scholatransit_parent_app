import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/attendance_history_model.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceFilterBottomSheet extends StatefulWidget {
  final AttendanceStatus? selectedStatus;
  final DateTime? selectedDate;
  final Function(AttendanceStatus?) onStatusChanged;
  final Function(DateTime?) onDateChanged;
  final VoidCallback onClearFilters;

  const AttendanceFilterBottomSheet({
    super.key,
    required this.selectedStatus,
    required this.selectedDate,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.onClearFilters,
  });

  @override
  State<AttendanceFilterBottomSheet> createState() =>
      _AttendanceFilterBottomSheetState();
}

class _AttendanceFilterBottomSheetState
    extends State<AttendanceFilterBottomSheet> {
  AttendanceStatus? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Text(
                  'Filter Attendance',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedDate = null;
                    });
                    widget.onClearFilters();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Filter
          _buildStatusFilter(),

          SizedBox(height: 20.h),

          // Date Filter
          _buildDateFilter(),

          SizedBox(height: 20.h),

          // Apply Button
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  widget.onStatusChanged(_selectedStatus);
                  widget.onDateChanged(_selectedDate);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildStatusChip(AttendanceStatus.present),
              _buildStatusChip(AttendanceStatus.absent),
              _buildStatusChip(AttendanceStatus.late),
              _buildStatusChip(AttendanceStatus.earlyPickup),
              _buildStatusChip(AttendanceStatus.noShow),
              _buildStatusChip(AttendanceStatus.cancelled),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = isSelected ? null : status;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? status.color : status.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? status.color : status.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.icon,
              size: 16.w,
              color: isSelected ? Colors.white : status.color,
            ),
            SizedBox(width: 6.w),
            Text(
              status.displayName,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : status.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20.w,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select a date',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: _selectedDate != null
                          ? Colors.grey[900]
                          : Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDate != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      child: Icon(
                        Icons.clear,
                        size: 20.w,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
