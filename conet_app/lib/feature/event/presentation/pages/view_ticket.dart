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

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A101828),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Present this QR at check-in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Event ID', value: ticket.eventId),
                        _InfoRow(label: 'User ID', value: ticket.userId),
                        _InfoRow(
                          label: 'Ticket ID',
                          value: ticketId?.isNotEmpty == true
                              ? ticketId!
                              : ticket.ticketId,
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
                    color: const Color(0xFFECFDF3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFABEFC6)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: FaIcon(
                          FontAwesomeIcons.circleInfo,
                          size: 14,
                          color: Color(0xFF067647),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your ticket payload uses event id, user id, and registration id. Keep this QR private.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF067647),
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
