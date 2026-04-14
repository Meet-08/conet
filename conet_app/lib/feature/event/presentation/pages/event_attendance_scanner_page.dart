import 'dart:convert';

import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_registration_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EventAttendanceScannerPage extends StatefulWidget {
  final String eventId;
  final String? eventTitle;

  const EventAttendanceScannerPage({
    super.key,
    required this.eventId,
    this.eventTitle,
  });

  @override
  State<EventAttendanceScannerPage> createState() =>
      _EventAttendanceScannerPageState();
}

class _EventAttendanceScannerPageState
    extends State<EventAttendanceScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessingScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingScan) return;

    final value = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (value == null || value.isEmpty) return;

    final payload = _tryParsePayload(value);
    if (payload == null) {
      AppToast.showError(context, 'Invalid QR payload.');
      return;
    }

    final qrEventId = payload['event_id'];
    final userId = payload['user_id'];
    final registrationId = payload['registration_id'];

    if (qrEventId != widget.eventId) {
      AppToast.showError(context, 'This ticket is for a different event.');
      return;
    }

    if (userId == null || registrationId == null) {
      AppToast.showError(context, 'Missing user or registration id in QR.');
      return;
    }

    setState(() {
      _isProcessingScan = true;
    });

    context.read<EventRegistrationBloc>().add(
      EventRegistrationMarkAttendanceEvent(
        eventId: widget.eventId,
        userId: userId,
        registrationId: registrationId,
      ),
    );
  }

  Map<String, String>? _tryParsePayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final eventId = decoded['event_id']?.toString();
      final userId = decoded['user_id']?.toString();
      final registrationId = decoded['registration_id']?.toString();

      if (eventId == null || userId == null || registrationId == null) {
        return null;
      }

      return {
        'event_id': eventId,
        'user_id': userId,
        'registration_id': registrationId,
      };
    } catch (_) {
      return null;
    }
  }

  bool _shouldShowAlreadyRegisteredAsError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already') &&
        (normalized.contains('register') || normalized.contains('attend'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Tickets'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Toggle torch',
            onPressed: _scannerController.toggleTorch,
            icon: const FaIcon(FontAwesomeIcons.bolt, size: 18),
          ),
        ],
      ),
      body: BlocListener<EventRegistrationBloc, EventRegistrationState>(
        listener: (context, state) {
          if (state is EventRegistrationFailure) {
            AppToast.showError(context, state.message);
            setState(() {
              _isProcessingScan = false;
            });
          }

          if (state is EventRegistrationAttendanceSuccess) {
            if (_shouldShowAlreadyRegisteredAsError(state.result.message)) {
              AppToast.showError(context, state.result.message);
            } else if (state.result.success) {
              AppToast.showSuccess(context, state.result.message);
            } else {
              AppToast.showError(context, state.result.message);
            }
            setState(() {
              _isProcessingScan = false;
            });
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _scannerController, onDetect: _onDetect),
            _ScannerOverlay(
              eventTitle: widget.eventTitle,
              semantic:
                  Theme.of(context).extension<AppSemanticColors>() ??
                  AppSemanticColors.light,
            ),
            if (_isProcessingScan)
              Container(
                color:
                    (Theme.of(context)
                                .extension<AppSemanticColors>()
                                ?.backgroundInverse ??
                            AppSemanticColors.light.backgroundInverse)
                        .withValues(alpha: 0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final String? eventTitle;
  final AppSemanticColors semantic;

  const _ScannerOverlay({this.eventTitle, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: semantic.backgroundInverse.withValues(alpha: 0.67),
                borderRadius: AppRadius.mdAll,
              ),
              child: Column(
                children: [
                  Text(
                    eventTitle?.isNotEmpty == true
                        ? 'Scanning for ${eventTitle!}'
                        : 'Scan attendee ticket QR',
                    style: AppTextStyles.button.copyWith(
                      color: semantic.textInverse,
                      fontWeight: AppTypographyTokens.weightBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Align QR inside the frame to mark attendance',
                    style: AppTextStyles.caption.copyWith(
                      color: semantic.textInverse.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: semantic.textInverse, width: 2),
              borderRadius: AppRadius.xlAll,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Text(
              'Only event organizer/co-host can mark attendance',
              style: AppTextStyles.caption.copyWith(
                color: semantic.textInverse.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
