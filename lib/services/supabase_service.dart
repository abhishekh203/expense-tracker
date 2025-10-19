import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }
  
  /// Get current user
  static User? get currentUser => client.auth.currentUser;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
  
  /// Get current user ID
  static String? get currentUserId => currentUser?.id;
  
  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Sign out current user
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  /// Get storage bucket
  static SupabaseStorageClient get storage => client.storage;
  
  /// Get realtime client
  static RealtimeClient get realtime => client.realtime;
  
  /// Handle Supabase errors
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    } else if (error is PostgrestException) {
      return _getPostgrestErrorMessage(error);
    } else if (error is StorageException) {
      return _getStorageErrorMessage(error);
    } else {
      return error.toString();
    }
  }
  
  static String _getAuthErrorMessage(AuthException error) {
    switch (error.message.toLowerCase()) {
      case 'invalid login credentials':
        return 'Invalid email or password. Please try again.';
      case 'email not confirmed':
        return 'Please check your email and click the confirmation link.';
      case 'user already registered':
        return 'An account with this email already exists.';
      case 'password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';
      case 'signup is disabled':
        return 'Account registration is currently disabled.';
      case 'email rate limit exceeded':
        return 'Too many requests. Please wait before trying again.';
      default:
        return error.message;
    }
  }
  
  static String _getPostgrestErrorMessage(PostgrestException error) {
    switch (error.code) {
      case '23505': // Unique constraint violation
        return 'This record already exists.';
      case '23503': // Foreign key constraint violation
        return 'Cannot delete this record as it is being used elsewhere.';
      case '42501': // Insufficient privilege
        return 'You do not have permission to perform this action.';
      default:
        return error.message;
    }
  }
  
  static String _getStorageErrorMessage(StorageException error) {
    switch (error.statusCode) {
      case '413':
        return 'File is too large. Please choose a smaller file.';
      case '415':
        return 'File type is not supported.';
      case '404':
        return 'File not found.';
      default:
        return error.message;
    }
  }
}
