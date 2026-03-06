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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _notifiedRequestKeys = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _availableStudents;
    return _availableStudents.where((s) {
      final q = _searchQuery;
      return s.fullName.toLowerCase().contains(q) ||
          s.firstName.toLowerCase().contains(q) ||
          s.lastName.toLowerCase().contains(q) ||
          s.grade.toLowerCase().contains(q) ||
          s.schoolName.toLowerCase().contains(q) ||
          s.studentId.toLowerCase().contains(q);
    }).toList();
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
    final myRequests = myResp.success && myResp.data != null ? myResp.data! : <Map<String, dynamic>>[];
    setState(() {
      _loading = false;
      if (availResp.success && availResp.data != null) {
        _availableStudents = availResp.data!;
        _error = null;
      } else {
        _error = availResp.error ?? 'Failed to load students';
      }
      _myRequests = myRequests;
    });
    _showApprovedRejectedNotifications(myRequests);
  }

  void _showApprovedRejectedNotifications(List<Map<String, dynamic>> requests) {
    final approved = requests.where((r) => (r['status'] as String?) == 'approved').toList();
    final rejected = requests.where((r) => (r['status'] as String?) == 'rejected').toList();
    if (approved.isEmpty && rejected.isEmpty) return;
    final newApproved = approved.where((r) {
      final key = '${r['id'] ?? ''}_${r['student_name']}_${r['created_at']}';
      if (_notifiedRequestKeys.contains(key)) return false;
      _notifiedRequestKeys.add(key);
      return true;
    }).toList();
    final newRejected = rejected.where((r) {
      final key = '${r['id'] ?? ''}_${r['student_name']}_${r['created_at']}';
      if (_notifiedRequestKeys.contains(key)) return false;
      _notifiedRequestKeys.add(key);
      return true;
    }).toList();
    if (newApproved.isEmpty && newRejected.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final parentNotifier = ref.read(parentProvider.notifier);

      if (newApproved.isNotEmpty) {
        final names = newApproved.map((r) => r['student_name'] ?? 'student').join(', ');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              newApproved.length == 1
                  ? 'Link request for $names was approved.'
                  : 'Link requests for $names were approved.',
            ),
            backgroundColor: Colors.green[700],
          ),
        );
        for (final r in newApproved) {
          final name = r['student_name'] ?? 'student';
          final parentId = ref.read(parentProvider).parent?.id;
          parentNotifier.addNotificationFromExternalSource({
            'id': 'link_approved_${r['id'] ?? ''}_${r['student_name']}_${r['created_at']}',
            'title': 'Link Request Approved',
            'body': 'Link request for $name was approved.',
            'is_read': false,
            'notification_type': 'link_request',
            if (parentId != null) 'parent_id': parentId,
          });
        }
      }
      if (newRejected.isNotEmpty) {
        final names = newRejected.map((r) => r['student_name'] ?? 'student').join(', ');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              newRejected.length == 1
                  ? 'Link request for $names was rejected.'
                  : 'Link requests for $names were rejected.',
            ),
            backgroundColor: Colors.red[700],
          ),
        );
        for (final r in newRejected) {
          final name = r['student_name'] ?? 'student';
          final parentId = ref.read(parentProvider).parent?.id;
          parentNotifier.addNotificationFromExternalSource({
            'id': 'link_rejected_${r['id'] ?? ''}_${r['student_name']}_${r['created_at']}',
            'title': 'Link Request Rejected',
            'body': 'Link request for $name was rejected.',
            'is_read': false,
            'notification_type': 'link_request',
            if (parentId != null) 'parent_id': parentId,
          });
        }
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

  List<Map<String, dynamic>> get _pendingRequests =>
      _myRequests.where((r) => (r['status'] as String?) == 'pending').toList();

  Widget _buildContent(BuildContext context) {
    final hasRequests = _pendingRequests.isNotEmpty;
    final hasAvailable = _availableStudents.isNotEmpty;
    final filtered = _filteredStudents;
    final hasFiltered = filtered.isNotEmpty;

    if (!hasRequests && !hasAvailable) return _buildEmpty(context);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
        children: [
          if (hasRequests) _buildMyRequestsSection(context),
          if (hasRequests && hasAvailable) SizedBox(height: 24.h),
          if (hasAvailable) ...[
            _buildSearchBar(context),
            SizedBox(height: 12.h),
            _buildAvailableSectionHeader(context),
            if (hasFiltered)
              ...filtered.map((s) => _buildStudentCard(context, s))
            else
              _buildNoSearchResults(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, grade, or school...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF0052CC)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Color(0xFF0052CC)),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      style: TextStyle(fontSize: 15.sp),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildNoSearchResults(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.h),
          Text(
            'No students match "$_searchQuery"',
            style: TextStyle(fontSize: 15.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsSection(BuildContext context) {
    final pending = _pendingRequests;
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
        SizedBox(height: 6.h),
        ...pending.map((r) => _buildRequestCard(context, r)),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> r) {
    final studentName = r['student_name'] as String? ?? 'Student';
    final createdAt = r['created_at'] as String?;
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
                Icons.schedule,
                color: Colors.orange,
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
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Pending',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.orange),
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
