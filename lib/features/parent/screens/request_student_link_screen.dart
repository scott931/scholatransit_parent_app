import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/parent_student_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/parent_provider.dart';

/// Screen for parent to request linking to an existing student (from their school).
/// Lists available students; parent selects one and submits a link request for school approval.
class RequestStudentLinkScreen extends ConsumerStatefulWidget {
  const RequestStudentLinkScreen({super.key});

  @override
  ConsumerState<RequestStudentLinkScreen> createState() =>
      _RequestStudentLinkScreenState();
}

class _RequestStudentLinkScreenState
    extends ConsumerState<RequestStudentLinkScreen> {
  List<Student> _availableStudents = [];
  List<Map<String, dynamic>> _myRequests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      ParentStudentService.getAvailableStudents(),
      ParentStudentService.getMyLinkRequests(),
    ]);
    if (!mounted) return;
    final availResp = results[0] as ApiResponse<List<Student>>;
    final myResp = results[1] as ApiResponse<List<Map<String, dynamic>>>;
    setState(() {
      _loading = false;
      if (availResp.success && availResp.data != null) {
        _availableStudents = availResp.data!;
        _error = null;
      } else {
        _error = availResp.error ?? 'Failed to load students';
      }
      if (myResp.success && myResp.data != null) {
        _myRequests = myResp.data!;
      } else {
        _myRequests = [];
      }
    });
  }

  Future<void> _loadAvailableStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await ParentStudentService.getAvailableStudents();
    if (mounted) {
      setState(() {
        _loading = false;
        if (response.success && response.data != null) {
          _availableStudents = response.data!;
          _error = null;
        } else {
          _error = response.error ?? 'Failed to load students';
        }
      });
    }
  }

  void _showRequestSheet(BuildContext context, Student student) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LinkRequestSheet(
        student: student,
        onSuccess: () {
          ref.read(parentProvider.notifier).refreshStudents();
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Link to a student'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0052CC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(context),
                ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasRequests = _myRequests.isNotEmpty;
    final hasAvailable = _availableStudents.isNotEmpty;
    if (!hasRequests && !hasAvailable) return _buildEmpty(context);

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        if (hasRequests) _buildMyRequestsSection(context),
        if (hasRequests && hasAvailable) SizedBox(height: 24.h),
        if (hasAvailable) _buildAvailableSectionHeader(context),
        if (hasAvailable) ..._availableStudents.map((s) => _buildStudentCard(context, s)),
      ],
    );
  }

  Widget _buildMyRequestsSection(BuildContext context) {
    final pending = _myRequests.where((r) => (r['status'] as String?) == 'pending').toList();
    final other = _myRequests.where((r) => (r['status'] as String?) != 'pending').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My requests',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0052CC),
          ),
        ),
        SizedBox(height: 12.h),
        ...pending.map((r) => _buildRequestCard(context, r, isPending: true)),
        ...other.map((r) => _buildRequestCard(context, r, isPending: false)),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> r, {required bool isPending}) {
    final status = r['status'] as String? ?? '';
    final studentName = r['student_name'] as String? ?? 'Student';
    final createdAt = r['created_at'] as String?;
    String statusLabel = status;
    Color statusColor = Colors.grey;
    if (status == 'pending') {
      statusLabel = 'Pending';
      statusColor = Colors.orange;
    } else if (status == 'approved') {
      statusLabel = 'Approved';
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusLabel = 'Rejected';
      statusColor = Colors.red;
    }
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0052CC).withOpacity(0.2),
              child: Icon(
                isPending ? Icons.schedule : (status == 'approved' ? Icons.check_circle : Icons.cancel),
                color: statusColor,
                size: 22.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                  ),
                  if (createdAt != null)
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildAvailableSectionHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        'Available to link',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0052CC),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Student student) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0052CC).withOpacity(0.2),
          child: Text(
            student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : '?',
            style: TextStyle(
              color: const Color(0xFF0052CC),
              fontWeight: FontWeight.w600,
              fontSize: 18.sp,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
        ),
        subtitle: Text(
          [
            if (student.grade.isNotEmpty) 'Grade ${student.grade}',
            student.schoolName,
          ].join(' • '),
          style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showRequestSheet(context, student),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: Colors.red[400]),
            SizedBox(height: 16.h),
            Text(
              _error!,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 80.w,
              color: const Color(0xFF0052CC).withOpacity(0.6),
            ),
            SizedBox(height: 20.h),
            Text(
              'No students available to link',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0052CC),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'All students from your school that you can link to are already linked to your account, or there are none yet. If you expect to see someone here, contact your school.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet content for submitting a link request with options.
class _LinkRequestSheet extends StatefulWidget {
  final Student student;
  final VoidCallback onSuccess;

  const _LinkRequestSheet({
    required this.student,
    required this.onSuccess,
  });

  @override
  State<_LinkRequestSheet> createState() => _LinkRequestSheetState();
}

class _LinkRequestSheetState extends State<_LinkRequestSheet> {
  bool isPrimaryContact = false;
  bool canPickup = true;
  bool canDropoff = true;
  bool submitting = false;

  Future<void> _submit() async {
    setState(() => submitting = true);
    final resp = await ParentStudentService.requestStudentLink(
      studentId: widget.student.id,
      isPrimaryContact: isPrimaryContact,
      canPickup: canPickup,
      canDropoff: canDropoff,
    );
    if (!mounted) return;
    setState(() => submitting = false);
    Navigator.of(context).pop();
    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Request sent. The school will review and notify you when approved.',
          ),
          backgroundColor: Colors.green[700],
        ),
      );
      widget.onSuccess();
    } else {
      final err = resp.error ?? 'Request failed';
      final isDuplicate = err.toLowerCase().contains('pending') ||
          err.toLowerCase().contains('already exists');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDuplicate
                ? 'You already have a pending request for this student. The school will review it.'
                : err,
          ),
          backgroundColor: isDuplicate ? Colors.orange[800] : Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    return Container(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewPadding.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Request to link to ${student.fullName}',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (student.grade.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Grade ${student.grade} • ${student.schoolName}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
          SizedBox(height: 20.h),
          SwitchListTile(
            title: Text(
              'Primary contact',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              'You will be the main contact for this student',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            value: isPrimaryContact,
            onChanged: (v) => setState(() => isPrimaryContact = v),
          ),
          SwitchListTile(
            title: Text(
              'Can pick up',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              'Authorized to pick up this student',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            value: canPickup,
            onChanged: (v) => setState(() => canPickup = v),
          ),
          SwitchListTile(
            title: Text(
              'Can drop off',
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              'Authorized to drop off this student',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            value: canDropoff,
            onChanged: (v) => setState(() => canDropoff = v),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              backgroundColor: const Color(0xFF0052CC),
              foregroundColor: Colors.white,
            ),
            child: submitting
                ? SizedBox(
                    height: 22.h,
                    width: 22.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit request'),
          ),
        ],
      ),
    );
  }
}
