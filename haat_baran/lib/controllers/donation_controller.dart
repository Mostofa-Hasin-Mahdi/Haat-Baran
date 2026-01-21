import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/donation.dart';

class DonationController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Donor: Request to donate
  Future<void> requestDonation(String applicantId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _supabase.from('donations').insert({
        'donor_id': user.id,
        'applicant_id': applicantId,
        'status': 'PENDING',
      });
    } catch (e) {
      print('Error requesting donation: $e');
      rethrow;
    }
  }

  // Admin: Get all pending requests with applicant details
  Future<List<Donation>> getPendingDonations() async {
    try {
      final response = await _supabase
          .from('donations')
          .select('*, applicants(name, photo, business_goal)')
          .eq('status', 'PENDING')
          .order('created_at', ascending: false);

      return (response as List).map((data) => Donation.fromMap(data)).toList();
    } catch (e) {
      print('Error getting pending donations: $e');
      return [];
    }
  }

  // Admin: Approve donation
  Future<void> approveDonation(String donationId) async {
    try {
      await _supabase
          .from('donations')
          .update({'status': 'APPROVED'})
          .eq('id', donationId);
    } catch (e) {
      print('Error approving donation: $e');
      rethrow;
    }
  }

  // Admin: Reject donation
  Future<void> rejectDonation(String donationId) async {
    try {
      await _supabase
          .from('donations')
          .update({'status': 'REJECTED'})
          .eq('id', donationId);
    } catch (e) {
      print('Error rejecting donation: $e');
      rethrow;
    }
  }

  // Donor: Request Meet & Pay
  Future<void> requestMeeting(String donationId) async {
    try {
      await _supabase
          .from('donations')
          .update({'status': 'MEETING_REQUESTED'})
          .eq('id', donationId);
    } catch (e) {
      print('Error requesting meeting: $e');
      rethrow;
    }
  }

  // Stream: Donor - Get my approved interactions
  // Reverting to Future for consistency if requested, but keeping stream name?
  // User asked to revert real-time, so we go back to Future.
  Future<List<Donation>> getMyDonationInteractions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('donations')
          .select('*, applicants(name, photo, business_goal)')
          .eq('donor_id', user.id)
          .inFilter('status', [
            'APPROVED',
            'MEETING_REQUESTED',
            'SCHEDULED',
            'COMPLETED',
          ])
          .order('updated_at', ascending: false);

      return (response as List).map((data) => Donation.fromMap(data)).toList();
    } catch (e) {
      print('Error getting my donations: $e');
      return [];
    }
  }

  // Admin: Get Incoming Donations
  Future<List<Donation>> getIncomingDonations() async {
    try {
      final response = await _supabase
          .from('donations')
          .select('*, applicants(name, photo, business_goal)')
          .inFilter('status', ['MEETING_REQUESTED', 'SCHEDULED'])
          .order('updated_at', ascending: false);

      return (response as List).map((data) => Donation.fromMap(data)).toList();
    } catch (e) {
      print('Error getting incoming donations: $e');
      return [];
    }
  }

  // Admin: Schedule Meeting
  Future<void> scheduleMeeting(
    String donationId,
    DateTime dateTime,
    String location,
  ) async {
    try {
      await _supabase
          .from('donations')
          .update({
            'status': 'SCHEDULED',
            'scheduled_at': dateTime.toIso8601String(),
            'scheduled_location': location,
          })
          .eq('id', donationId);
    } catch (e) {
      print('Error scheduling meeting: $e');
      rethrow;
    }
  }

  // Admin: Get Completed Donations
  Future<List<Donation>> getCompletedDonations() async {
    try {
      final response = await _supabase
          .from('donations')
          .select('*, applicants(name, photo, business_goal)')
          .eq('status', 'COMPLETED')
          .order('updated_at', ascending: false);

      return (response as List).map((data) => Donation.fromMap(data)).toList();
    } catch (e) {
      print('Error getting completed donations: $e');
      return [];
    }
  }

  // Admin: Confirm Donation (Complete)
  Future<void> confirmDonation(
    String donationId,
    String applicantId,
    double amount,
  ) async {
    try {
      // 1. Update Donation to COMPLETED and set Amount
      await _supabase
          .from('donations')
          .update({'status': 'COMPLETED', 'amount': amount})
          .eq('id', donationId);

      // 2. Fetch current funding of applicant
      final applicantRes = await _supabase
          .from('applicants')
          .select('current_funding')
          .eq('id', applicantId)
          .single();

      final currentFunding = (applicantRes['current_funding'] ?? 0).toDouble();
      final newFunding = currentFunding + amount;

      // 3. Update Applicant Funding
      await _supabase
          .from('applicants')
          .update({'current_funding': newFunding})
          .eq('id', applicantId);
    } catch (e) {
      print('Error confirming donation: $e');
      rethrow;
    }
  }

  // Donor: Process App Payment (Success)
  Future<void> processAppPayment(
    String donationId,
    String applicantId,
    double amount,
  ) async {
    try {
      // Use RPC to secure the transaction and bypass RLS for funding update
      await _supabase.rpc(
        'process_app_payment',
        params: {
          'p_donation_id': donationId,
          'p_applicant_id': applicantId,
          'p_amount': amount,
        },
      );
    } catch (e) {
      print('Error processing app payment: $e');
      rethrow;
    }
  }
}
