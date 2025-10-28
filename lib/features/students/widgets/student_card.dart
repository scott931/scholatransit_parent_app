import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';

class StudentCard extends StatelessWidget {
  final Student student;

  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/students/${student.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Simple Avatar
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor().withOpacity(0.1),
                ),
                child: student.profileImage != null
                    ? ClipOval(
                        child: Image.network(
                          student.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarFallback(),
                        ),
                      )
                    : _buildAvatarFallback(),
              ),
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Grade ${student.grade}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (student.school != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        student.school!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  _getStatusText(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Text(
        student.firstName[0].toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(),
          fontWeight: FontWeight.w600,
          fontSize: 18.sp,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    final status = _parseStudentStatus(student.status);
    switch (status) {
      case StudentStatus.waiting:
        return AppTheme.studentWaiting;
      case StudentStatus.onBus:
        return AppTheme.studentOnBus;
      case StudentStatus.pickedUp:
        return AppTheme.studentPickedUp;
      case StudentStatus.droppedOff:
        return AppTheme.studentDroppedOff;
      case StudentStatus.absent:
        return AppTheme.errorColor;
    }
  }

  String _getStatusText() {
    final status = _parseStudentStatus(student.status);
    switch (status) {
      case StudentStatus.waiting:
        return 'WAITING';
      case StudentStatus.onBus:
        return 'ON BUS';
      case StudentStatus.pickedUp:
        return 'PICKED UP';
      case StudentStatus.droppedOff:
        return 'DROPPED OFF';
      case StudentStatus.absent:
        return 'ABSENT';
    }
  }

  StudentStatus _parseStudentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return StudentStatus.waiting;
      case 'on_bus':
      case 'onbus':
        return StudentStatus.onBus;
      case 'picked_up':
      case 'pickedup':
        return StudentStatus.pickedUp;
      case 'dropped_off':
      case 'droppedoff':
        return StudentStatus.droppedOff;
      case 'absent':
        return StudentStatus.absent;
      default:
        return StudentStatus.waiting;
    }
  }
}
