import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/models/pin_model.dart';
import '../../../core/models/qrcode_model.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Shows **existing** bus check-in QR and PIN from the server (created by school/global admin).
/// Parents cannot create credentials here — only **display** for the driver.
class BusCheckinCredentialsSection extends ConsumerStatefulWidget {
  final int studentId;

  const BusCheckinCredentialsSection({super.key, required this.studentId});

  @override
  ConsumerState<BusCheckinCredentialsSection> createState() =>
      _BusCheckinCredentialsSectionState();
}

class _BusCheckinCredentialsSectionState
    extends ConsumerState<BusCheckinCredentialsSection> {
  bool _pinVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final notifier = ref.read(studentProvider.notifier);
    await notifier.listStudentQrCodes(studentId: widget.studentId, isActive: true);
    await notifier.listStudentPins(studentId: widget.studentId, isActive: true);
  }

  QrCodeInfo? _qrForStudent(List<QrCodeInfo> list) {
    for (final q in list) {
      final sid = q.student['id'];
      final id = sid is int ? sid : int.tryParse(sid?.toString() ?? '');
      if (id == widget.studentId) return q;
    }
    return list.isNotEmpty ? list.first : null;
  }

  PinInfo? _pinForStudent(List<PinInfo> list) {
    for (final p in list) {
      final sid = p.student['id'];
      final id = sid is int ? sid : int.tryParse(sid?.toString() ?? '');
      if (id == widget.studentId) return p;
    }
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentProvider);

    final qrSize = (MediaQuery.sizeOf(context).shortestSide * 0.55).clamp(160.0, 260.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus_filled_outlined,
                  color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bus check-in',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                onPressed: state.isLoading ? null : _load,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your school admin issues these credentials. Show the QR or say the PIN to the driver; they scan or enter it — you do not verify check-in here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.error!,
                style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
              ),
            ),
          _buildQr(context, state, qrSize),
          const SizedBox(height: 20),
          _buildPin(context, state),
        ],
      ),
    );
  }

  Widget _buildQr(BuildContext context, StudentState state, double qrSize) {
    final qr = _qrForStudent(state.qrCodes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR code',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (qr == null || qr.qrCodeData.isEmpty)
          Text(
            'No QR code yet. School or global admin must create one for this student in the admin portal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          )
        else
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.textTertiary.withValues(alpha: 0.3)),
                  ),
                  child: QrImageView(
                    data: qr.qrCodeData,
                    version: QrVersions.auto,
                    size: qrSize,
                    gapless: true,
                    backgroundColor: Colors.white,
                  ),
                ),
                if (qr.qrCodeUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Also available from school portal',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPin(BuildContext context, StudentState state) {
    final pin = _pinForStudent(state.pins);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PIN (backup)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (pin == null)
          Text(
            'No PIN yet. School or global admin must create one for this student in the admin portal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          )
        else if (pin.pinCode == null || pin.pinCode!.isEmpty)
          Text(
            'PIN is on file but not shown here. Contact your school admin if you need the digits.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _pinVisible ? pin.pinCode! : '•' * pin.pinCode!.length,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            letterSpacing: _pinVisible ? 4 : 2,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _pinVisible = !_pinVisible),
                    icon: Icon(
                      _pinVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ],
              ),
              if (!pin.isValid)
                Text(
                  'Expired or locked — ask your school admin to renew.',
                  style: TextStyle(color: AppTheme.warningColor, fontSize: 12),
                ),
            ],
          ),
      ],
    );
  }
}
