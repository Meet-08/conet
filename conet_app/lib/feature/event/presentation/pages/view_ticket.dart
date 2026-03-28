import 'dart:convert';

import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_ticket.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_registration_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ViewTicket extends StatefulWidget {
  final String eventId;
  final String? ticketId;

  const ViewTicket({super.key, required this.eventId, this.ticketId});

  @override
  State<ViewTicket> createState() => _ViewTicketState();
}

class _ViewTicketState extends State<ViewTicket> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventRegistrationBloc>().add(
        EventRegistrationFetchTicketEvent(widget.eventId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ViewTicketBody(eventId: widget.eventId, ticketId: widget.ticketId);
  }
}

class _ViewTicketBody extends StatelessWidget {
  final String eventId;
  final String? ticketId;

  const _ViewTicketBody({required this.eventId, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(title: const Text('My Ticket'), centerTitle: true),
      body: BlocConsumer<EventRegistrationBloc, EventRegistrationState>(
        listener: (context, state) {
          if (state is EventRegistrationFailure) {
            AppToast.showError(context, state.message);
          }

          if (state is EventRegistrationAttendanceSuccess) {
            final toast = state.result.success
                ? AppToast.showSuccess
                : AppToast.showInfo;
            toast(context, state.result.message);
          }
        },
        builder: (context, state) {
          if (state is EventRegistrationLoading ||
              state is EventRegistrationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventRegistrationFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.ticket,
                      size: 30,
                      color: Color(0xFF98A2B3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<EventRegistrationBloc>().add(
                          EventRegistrationFetchTicketEvent(eventId),
                        );
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.rotateRight,
                        size: 14,
                      ),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          EventRegistrationTicket? ticket;
          if (state is EventRegistrationTicketLoaded) {
            ticket = state.ticket;
          } else if (state is EventRegistrationAttendanceLoading ||
              state is EventRegistrationAttendanceSuccess) {
            final prev = context.read<EventRegistrationBloc>().state;
            if (prev is EventRegistrationTicketLoaded) {
              ticket = prev.ticket;
            }
          }

          if (ticket == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final payload = {
            'event_id': ticket.eventId,
            'user_id': ticket.userId,
            'registration_id': ticket.registrationId,
          };

          final qrData = jsonEncode(payload);
          final safeTicketReference = _maskedTicketReference(
            ticketId?.isNotEmpty == true ? ticketId! : ticket.ticketId,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A111827),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF0E7490)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.shieldHalved,
                                    size: 14,
                                    color: Color(0xFFCCFBF1),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Verified Entry Pass',
                                    style: TextStyle(
                                      color: Color(0xFFCCFBF1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Present this code at check-in',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                safeTicketReference,
                                style: const TextStyle(
                                  color: Color(0xFFCCFBF1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 240,
                            gapless: false,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF111827),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _TicketHintRow(
                          icon: FontAwesomeIcons.userShield,
                          text:
                              'Sensitive identifiers are hidden for your privacy.',
                        ),
                        const SizedBox(height: 10),
                        const _TicketHintRow(
                          icon: FontAwesomeIcons.mobileScreen,
                          text:
                              'Show this screen only to event staff at entry.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: FaIcon(
                          FontAwesomeIcons.circleInfo,
                          size: 14,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keep your QR private. Anyone with access to this code may attempt check-in on your behalf.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _maskedTicketReference(String id) {
    if (id.length <= 6) {
      return 'Ticket reference: ${'*' * id.length}';
    }

    final suffix = id.substring(id.length - 4);
    return 'Ticket reference ending in $suffix';
  }
}

class _TicketHintRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TicketHintRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: FaIcon(icon, size: 12, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
