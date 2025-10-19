import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://emhdutfpwzrjrtgahtrj.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtaGR1dGZwd3pyanJ0Z2FodHJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjc5NTIsImV4cCI6MjA2ODYwMzk1Mn0.9hRikXnCJ3RDt3iI9pACURTifS-M7V3_ddhXBVCaQLs',
    );
    
    print('✅ Supabase initialized successfully!');
    
    // Test database connection
    final response = await Supabase.instance.client
        .from('user_profiles')
        .select('count')
        .count();
    
    print('✅ Database connection successful!');
    print('📊 User profiles count: ${response.count}');
    
    print('🎉 All tests passed! Your Supabase setup is working correctly.');
    
  } catch (e) {
    print('❌ Error: $e');
    print('🔧 Please check your Supabase configuration and database setup.');
  }
}
