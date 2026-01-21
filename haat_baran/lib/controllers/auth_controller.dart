import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user.dart';

class AuthController {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  // Sign in with email and password
  Future<User?> login(String email, String password) async {
    try {
      print('Attempting Login with: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        print('Login Failed: response.user is null');
        return null;
      }
      print('Auth Success. User ID: ${response.user!.id}');

      // Fetch user details from public.users table to get the role
      print('Fetching user role from DB...');
      final userData = await _supabase
          .from('users')
          .select()
          .eq('user_id', response.user!.id)
          .single();

      print('User Data fetched: $userData');

      return User.fromMap(userData);
    } catch (e) {
      // Check if it's a login error or other error
      print('Login Error: $e');
      return null;
    }
  }

  // Sign up for Donors
  Future<User?> signUp({
    required String email,
    required String password,
    required String username,
    String? phone,
  }) async {
    try {
      print('Attempting SignUp with:');
      print('Email: "$email"');
      print('Username: "$username"');
      print('Phone: "$phone"');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'phone': phone},
      );

      if (response.user == null) {
        return null;
      }

      // User creation matches trigger logic now.

      return User(id: response.user!.id, email: email, type: UserType.donor);
    } catch (e) {
      print('SignUp Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    // Note: This returns the Auth user, not our domain User with role.
    // To get full User with role, you'd usually fetch it or cache it.
    // For simplicity in this sync method, we might return null or a partial user if needed.
    // But for the login flow, we rely on the returned User from login().
    return null;
  }
}
