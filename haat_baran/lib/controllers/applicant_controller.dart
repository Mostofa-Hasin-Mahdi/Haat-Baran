import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/applicant.dart';

class ApplicantController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload image to Supabase Storage - Accepts binary data
  Future<String?> uploadImage(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storagePath = 'uploads/$uniqueName';

      await _supabase.storage
          .from('applicant_photos')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: mimeType,
            ),
          );

      final imageUrl = _supabase.storage
          .from('applicant_photos')
          .getPublicUrl(storagePath);

      print('DEBUG: Uploaded image to $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Get approved applicants
  Future<List<Applicant>> getApprovedApplicants() async {
    try {
      final response = await _supabase
          .from('applicants')
          .select()
          .eq('status', 'APPROVED')
          .order('created_at', ascending: false);

      return (response as List).map((data) => Applicant.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching approved applicants: $e');
      return [];
    }
  }

  // Get pending applicants
  Future<List<Applicant>> getPendingApplicants() async {
    try {
      final response = await _supabase
          .from('applicants')
          .select()
          .eq('status', 'PENDING')
          .order('created_at', ascending: false);

      return (response as List).map((data) => Applicant.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching pending applicants: $e');
      return [];
    }
  }

  // Add new applicant (Volunteer action)
  Future<void> addApplicant(Applicant applicant) async {
    try {
      final data = applicant.toMap();
      await _supabase.from('applicants').insert(data);
    } catch (e) {
      print('Error adding applicant: $e');
      rethrow;
    }
  }

  // Approve applicant (Admin action)
  Future<void> approveApplicant(String applicantId) async {
    try {
      await _supabase
          .from('applicants')
          .update({'status': 'APPROVED'})
          .eq('id', applicantId);
    } catch (e) {
      print('Error approving applicant: $e');
      rethrow;
    }
  }

  // Reject applicant (Admin action)
  Future<void> rejectApplicant(String applicantId) async {
    try {
      await _supabase
          .from('applicants')
          .update({'status': 'REJECTED'})
          .eq('id', applicantId);
    } catch (e) {
      print('Error rejecting applicant: $e');
      rethrow;
    }
  }

  // Delete applicant (Admin action)
  Future<void> deleteApplicant(String applicantId) async {
    try {
      // First delete related donations to avoid foreign key violation
      await _supabase
          .from('donations')
          .delete()
          .eq('applicant_id', applicantId);

      // Then delete the applicant
      await _supabase.from('applicants').delete().eq('id', applicantId);
    } catch (e) {
      print('Error deleting applicant: $e');
      rethrow;
    }
  }

  // Update applicant (Admin edit)
  Future<void> updateApplicant(Applicant applicant) async {
    try {
      final data = applicant.toMap();
      await _supabase.from('applicants').update(data).eq('id', applicant.id);
    } catch (e) {
      print('Error updating applicant: $e');
      rethrow;
    }
  }
}
