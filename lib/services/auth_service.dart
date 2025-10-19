import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'database_service.dart';

class AuthService {
  static final SupabaseClient _client = SupabaseService.client;
  
  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      
      // Create profile immediately after signup, regardless of email confirmation
      if (response.user != null) {
        await _createUserProfile(response.user!, fullName);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Save user data to local storage
      if (response.user != null) {
        await _saveUserToLocalStorage(response.user!);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await _clearLocalStorage();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update password
  static Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update user profile
  static Future<UserResponse> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? email,
  }) async {
    try {
      final attributes = <String, dynamic>{};
      if (fullName != null) attributes['full_name'] = fullName;
      if (avatarUrl != null) attributes['avatar_url'] = avatarUrl;
      
      final response = await _client.auth.updateUser(
        UserAttributes(data: attributes),
      );
      
      // Also update the user_profiles table
      if (response.user != null) {
        final currentProfile = await DatabaseService.getUserProfile(response.user!.id);
        if (currentProfile != null) {
          final updatedProfile = currentProfile.copyWith(
            fullName: fullName,
            avatarUrl: avatarUrl,
            email: email,
            updatedAt: DateTime.now(),
          );
          await DatabaseService.updateUserProfile(updatedProfile);
        }
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get current user
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }
  
  /// Check if user is authenticated
  static bool isAuthenticated() {
    return getCurrentUser() != null;
  }
  
  /// Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;
    
    try {
      return await DatabaseService.getUserProfile(user.id);
    } catch (e) {
      return null;
    }
  }
  
  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  /// Create user profile in database
  static Future<void> _createUserProfile(User user, String? fullName) async {
    try {
      print('Creating user profile for: ${user.email} (ID: ${user.id})');
      print('User email from Supabase: ${user.email}');
      print('User email confirmed at: ${user.emailConfirmedAt}');
      
      // Ensure email is not null
      final userEmail = user.email;
      if (userEmail == null) {
        print('WARNING: User email is null!');
        return;
      }
      
      await DatabaseService.createUserProfile(UserProfile(
        id: user.id,
        fullName: fullName ?? user.userMetadata?['full_name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        email: userEmail, // Use the verified email
        currency: AppConstants.defaultCurrency,
        language: 'en',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      
      print('User profile created successfully');
      
      // Create default categories for the user
      await DatabaseService.createDefaultCategories(user.id);
      
      // Create default accounts for the user
      await DatabaseService.createDefaultAccounts(user.id);
      
      print('Default categories and accounts created successfully');
    } catch (e) {
      // Log error but don't throw - profile creation can be retried later
      print('Error creating user profile: $e');
    }
  }
  
  /// Save user data to local storage
  static Future<void> _saveUserToLocalStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, user.id);
      await prefs.setString(AppConstants.keyUserEmail, user.email ?? '');
      
      final fullName = user.userMetadata?['full_name'] as String?;
      if (fullName != null) {
        await prefs.setString(AppConstants.keyUserName, fullName);
      }
    } catch (e) {
      // Non-critical error
      print('Error saving user to local storage: $e');
    }
  }
  
  /// Clear local storage
  static Future<void> _clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserEmail);
      await prefs.remove(AppConstants.keyUserName);
    } catch (e) {
      // Non-critical error
      print('Error clearing local storage: $e');
    }
  }
  
  /// Check if this is the first time user is opening the app
  static Future<bool> isFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.keyIsFirstTime) ?? true;
    } catch (e) {
      return true;
    }
  }
  
  /// Mark that user has completed first-time setup
  static Future<void> setFirstTimeComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsFirstTime, false);
    } catch (e) {
      // Non-critical error
      print('Error setting first time complete: $e');
    }
  }
  
  /// Get user's preferred language
  static Future<String> getPreferredLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.keySelectedLanguage) ?? 'en';
    } catch (e) {
      return 'en';
    }
  }
  
  /// Set user's preferred language
  static Future<void> setPreferredLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keySelectedLanguage, language);
      
      // Also update in database if user is authenticated
      final user = getCurrentUser();
      if (user != null) {
        final currentProfile = await DatabaseService.getUserProfile(user.id);
        if (currentProfile != null) {
          final updatedProfile = currentProfile.copyWith(
            language: language,
            updatedAt: DateTime.now(),
          );
          await DatabaseService.updateUserProfile(updatedProfile);
        }
      }
    } catch (e) {
      print('Error setting preferred language: $e');
    }
  }
  
  /// Get user's preferred currency
  static Future<String> getPreferredCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.keySelectedCurrency) ?? AppConstants.defaultCurrency;
    } catch (e) {
      return AppConstants.defaultCurrency;
    }
  }
  
  /// Set user's preferred currency
  static Future<void> setPreferredCurrency(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keySelectedCurrency, currency);
      
      // Also update in database if user is authenticated
      final user = getCurrentUser();
      if (user != null) {
        final currentProfile = await DatabaseService.getUserProfile(user.id);
        if (currentProfile != null) {
          final updatedProfile = currentProfile.copyWith(
            currency: currency,
            updatedAt: DateTime.now(),
          );
          await DatabaseService.updateUserProfile(updatedProfile);
        }
      }
    } catch (e) {
      print('Error setting preferred currency: $e');
    }
  }
}
