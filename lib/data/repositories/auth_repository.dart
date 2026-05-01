import '../../core/cloud/supabase_service.dart';

class AuthRepository {
  bool get isConfigured => SupabaseService.isConfigured;

  bool get isSignedIn {
    if (!isConfigured) {
      return false;
    }

    return SupabaseService.client.auth.currentUser != null;
  }

  String? get currentUserId => SupabaseService.client.auth.currentUser?.id;

  Future<void> signIn({required String email, required String password}) async {
    await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    await SupabaseService.client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    if (!isConfigured) {
      return;
    }

    await SupabaseService.client.auth.signOut();
  }
}
