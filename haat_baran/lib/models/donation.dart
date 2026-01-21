enum DonationStatus {
  pending,
  approved,
  meetingRequested,
  scheduled,
  completed,
  rejected,
}

class Donation {
  final String id;
  final String donorId;
  final String applicantId;
  final double amount;
  final DonationStatus status;
  final DateTime? scheduledAt;
  final String? scheduledLocation;
  final DateTime createdAt;

  // Optional: Expanded info for UI (fetched via joins or separate calls)
  final String? applicantName;
  final String? applicantPhoto;
  final String? applicantCategory;

  Donation({
    required this.id,
    required this.donorId,
    required this.applicantId,
    this.amount = 0.0,
    this.status = DonationStatus.pending,
    this.scheduledAt,
    this.scheduledLocation,
    required this.createdAt,
    this.applicantName,
    this.applicantPhoto,
    this.applicantCategory,
  });

  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id']?.toString() ?? '',
      donorId: map['donor_id']?.toString() ?? '',
      applicantId: map['applicant_id']?.toString() ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'])
          : null,
      scheduledLocation: map['scheduled_location'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      // Handle joined applicant data if present
      applicantName: map['applicants']?['name'],
      applicantPhoto: map['applicants']?['photo'],
      applicantCategory: map['applicants']?['business_goal'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donor_id': donorId,
      'applicant_id': applicantId,
      'amount': amount,
      'status': _statusToString(status),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'scheduled_location': scheduledLocation,
    };
  }

  static DonationStatus _parseStatus(String? status) {
    switch (status) {
      case 'APPROVED':
        return DonationStatus.approved;
      case 'MEETING_REQUESTED':
        return DonationStatus.meetingRequested;
      case 'SCHEDULED':
        return DonationStatus.scheduled;
      case 'COMPLETED':
        return DonationStatus.completed;
      case 'REJECTED':
        return DonationStatus.rejected;
      case 'PENDING':
      default:
        return DonationStatus.pending;
    }
  }

  static String _statusToString(DonationStatus status) {
    switch (status) {
      case DonationStatus.approved:
        return 'APPROVED';
      case DonationStatus.meetingRequested:
        return 'MEETING_REQUESTED';
      case DonationStatus.scheduled:
        return 'SCHEDULED';
      case DonationStatus.completed:
        return 'COMPLETED';
      case DonationStatus.rejected:
        return 'REJECTED';
      case DonationStatus.pending:
        return 'PENDING';
    }
  }
}
