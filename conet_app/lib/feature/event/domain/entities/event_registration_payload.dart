import 'package:equatable/equatable.dart';

class EventRegistrationPayload extends Equatable {
  final String? teamId;
  final int? teamSize;
  final String? enrollmentNumber;
  final String? contactNumber;
  final int? semester;
  final String? branch;
  final String? paymentProofUrl;
  final String? paymentProofFileName;
  final String? paymentProofFilePath;
  final List<int>? paymentProofFileBytes;
  final int? paymentProofFileSize;
  final String? transactionId;
  final Map<String, dynamic> customFieldResponses;
  final List<String> memberUserIds;

  const EventRegistrationPayload({
    this.teamId,
    this.teamSize,
    this.enrollmentNumber,
    this.contactNumber,
    this.semester,
    this.branch,
    this.paymentProofUrl,
    this.paymentProofFileName,
    this.paymentProofFilePath,
    this.paymentProofFileBytes,
    this.paymentProofFileSize,
    this.transactionId,
    this.customFieldResponses = const {},
    this.memberUserIds = const [],
  });

  Map<String, dynamic> toJson() {
    String? normalizeText(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final normalizedResponses = <String, dynamic>{};
    customFieldResponses.forEach((key, value) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          normalizedResponses[key] = trimmed;
        }
        return;
      }

      if (value is List) {
        if (value.isNotEmpty) {
          normalizedResponses[key] = value;
        }
        return;
      }

      if (value != null) {
        normalizedResponses[key] = value;
      }
    });

    final normalizedMemberIds = memberUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return {
      if (normalizeText(teamId) != null) 'team_id': normalizeText(teamId),
      if (teamSize != null) 'team_size': teamSize,
      if (normalizeText(enrollmentNumber) != null)
        'enrollment_number': normalizeText(enrollmentNumber),
      if (normalizeText(contactNumber) != null)
        'contact_number': normalizeText(contactNumber),
      if (semester != null) 'semester': semester,
      if (normalizeText(branch) != null) 'branch': normalizeText(branch),
      if (normalizeText(paymentProofUrl) != null)
        'payment_proof_url': normalizeText(paymentProofUrl),
      if (normalizeText(transactionId) != null)
        'transaction_id': normalizeText(transactionId),
      if (normalizedResponses.isNotEmpty)
        'custom_field_responses': normalizedResponses,
      if (normalizedMemberIds.isNotEmpty)
        'member_user_ids': normalizedMemberIds,
    };
  }

  @override
  List<Object?> get props => [
    teamId,
    teamSize,
    enrollmentNumber,
    contactNumber,
    semester,
    branch,
    paymentProofUrl,
    paymentProofFileName,
    paymentProofFilePath,
    paymentProofFileBytes,
    paymentProofFileSize,
    transactionId,
    customFieldResponses,
    memberUserIds,
  ];
}
