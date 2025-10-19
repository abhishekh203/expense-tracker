import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/lending.dart';
import '../models/lending_payment.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

class DatabaseService {
  static final SupabaseClient _client = SupabaseService.client;
  
  // User Profile Operations
  
  /// Create user profile
  static Future<UserProfile> createUserProfile(UserProfile profile) async {
    try {
      print('Creating user profile in database: ${profile.email}');
      print('Profile data: ${profile.toJson()}');
      
      final response = await _client
          .from('user_profiles')
          .insert(profile.toJson())
          .select()
          .single();
      
      print('User profile created successfully in database');
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error creating user profile in database: $e');
      throw Exception('Failed to create user profile: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Get user profile
  static Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return response != null ? UserProfile.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to get user profile: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Update user profile
  static Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      final response = await _client
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();
      
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user profile: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  // Category Operations
  
  /// Create default categories for a user
  static Future<void> createDefaultCategories(String userId) async {
    try {
      print('Creating default categories for user: $userId');
      
      // Check if user already has categories
      final existingCategories = await getUserCategories(userId);
      if (existingCategories.isNotEmpty) {
        print('User already has ${existingCategories.length} categories, skipping default creation');
        return;
      }
      
      print('Number of default categories: ${AppConstants.defaultCategories.length}');
      
      final categories = AppConstants.defaultCategories.map((cat) => {
        'user_id': userId,
        'name': cat['name'],
        'name_nepali': cat['name_nepali'],
        'icon': cat['icon'],
        'color': cat['color'],
        'type': cat['type'],
        'is_default': true, // Mark as default categories
        'created_at': DateTime.now().toIso8601String(),
      }).toList();
      
      print('Categories to insert: ${categories.length}');
      print('Category data: $categories');
      await _client.from('categories').insert(categories);
      print('Default categories created successfully');
    } catch (e) {
      print('Error creating default categories: $e');
      throw Exception('Failed to create default categories: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Create default accounts for a user
  static Future<void> createDefaultAccounts(String userId) async {
    try {
      print('Creating default accounts for user: $userId');
      
      // Check if user already has accounts
      final existingAccounts = await getUserAccounts(userId);
      if (existingAccounts.isNotEmpty) {
        print('User already has ${existingAccounts.length} accounts, skipping default creation');
        return;
      }
      
      print('Number of default accounts: ${AppConstants.defaultAccounts.length}');
      
      final accounts = AppConstants.defaultAccounts.map((acc) => {
        'user_id': userId,
        'name': acc['name'],
        'type': acc['type'],
        'balance': acc['balance'],
        'currency': 'NPR', // Add currency field
        'is_active': true, // Add is_active field
        'created_at': DateTime.now().toIso8601String(),
      }).toList();
      
      print('Accounts to insert: ${accounts.length}');
      print('Account data: $accounts');
      await _client.from('accounts').insert(accounts);
      print('Default accounts created successfully');
    } catch (e) {
      print('Error creating default accounts: $e');
      throw Exception('Failed to create default accounts: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Get categories for current user
  static Future<List<Category>> getCategories() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final categories = await getUserCategories(userId);
      
      // If user has no categories, return empty list
      if (categories.isEmpty) {
        print('No categories found for user $userId');
        return [];
      }
      
      return categories;
    } catch (e) {
      print('Error loading categories: $e');
      // Return empty list instead of crashing
      return [];
    }
  }

  /// Get user categories
  static Future<List<Category>> getUserCategories(String userId) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('user_id', userId)
          .order('name');
      
      return response.map<Category>((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get categories: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Create category
  static Future<Category> createCategory(Category category) async {
    try {
      final categoryData = category.toJson();
      categoryData.remove('id'); // Remove id field, let database generate it
      
      final response = await _client
          .from('categories')
          .insert(categoryData)
          .select()
          .single();
      
      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create category: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Update category
  static Future<Category> updateCategory(Category category) async {
    try {
      final response = await _client
          .from('categories')
          .update(category.toJson())
          .eq('id', category.id)
          .select()
          .single();
      
      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update category: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Delete category
  static Future<void> deleteCategory(String categoryId) async {
    try {
      await _client
          .from('categories')
          .delete()
          .eq('id', categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  // Account Operations
  
  /// Get accounts for current user
  static Future<List<Account>> getAccounts() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final accounts = await getUserAccounts(userId);
      
      // If user has no accounts, return empty list
      if (accounts.isEmpty) {
        print('No accounts found for user $userId');
        return [];
      }
      
      return accounts;
    } catch (e) {
      print('Error loading accounts: $e');
      // Return empty list instead of crashing
      return [];
    }
  }

  /// Get user accounts
  static Future<List<Account>> getUserAccounts(String userId) async {
    try {
      final response = await _client
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at');
      
      return response.map<Account>((json) => Account.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get accounts: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Create account
  static Future<Account> createAccount(Account account) async {
    try {
      final accountData = account.toJson();
      accountData.remove('id'); // Remove id field, let database generate it
      
      final response = await _client
          .from('accounts')
          .insert(accountData)
          .select()
          .single();
      
      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create account: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Update account
  static Future<Account> updateAccount(Account account) async {
    try {
      final response = await _client
          .from('accounts')
          .update(account.toJson())
          .eq('id', account.id)
          .select()
          .single();
      
      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update account: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Update account balance
  static Future<Account> updateAccountBalance(String accountId, double newBalance) async {
    try {
      final response = await _client
          .from('accounts')
          .update({'balance': newBalance})
          .eq('id', accountId)
          .select()
          .single();
      
      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update account balance: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Delete account (soft delete)
  static Future<void> deleteAccount(String accountId) async {
    try {
      await _client
          .from('accounts')
          .update({'is_active': false})
          .eq('id', accountId);
    } catch (e) {
      throw Exception('Failed to delete account: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  // Transaction Operations
  
  /// Get user transactions with pagination
  static Future<List<Transaction>> getUserTransactions(
    String userId, {
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
    TransactionType? type,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select('''
            *,
            categories(*),
            accounts(*)
          ''')
          .eq('user_id', userId);
      
      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String().split('T')[0]);
      }
      
      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String().split('T')[0]);
      }
      
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      
      if (accountId != null) {
        query = query.eq('account_id', accountId);
      }
      
      if (type != null) {
        query = query.eq('type', type.toJson());
      }
      
      final response = await query
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return response.map<Transaction>((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get transactions: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Create transaction with parameters
  static Future<Transaction> createTransaction({
    required String accountId,
    required String categoryId,
    required double amount,
    required String type,
    required String description,
    String? notes,
    required DateTime transactionDate,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final transactionData = {
        'user_id': userId,
        'account_id': accountId,
        'category_id': categoryId,
        'amount': amount,
        'type': type,
        'description': description,
        'notes': notes,
        'transaction_date': transactionDate.toIso8601String().split('T')[0],
      };

      final response = await _client
          .from('transactions')
          .insert(transactionData)
          .select('''
            *,
            categories(*),
            accounts(*)
          ''')
          .single();
      
      // Update account balance
      final transaction = Transaction.fromJson(response);
      await _updateAccountBalanceForTransaction(transaction, isCreating: true);
      
      return transaction;
    } catch (e) {
      throw Exception('Failed to create transaction: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Create transaction from model
  static Future<Transaction> createTransactionFromModel(Transaction transaction) async {
    try {
      final response = await _client
          .from('transactions')
          .insert(transaction.toJson())
          .select('''
            *,
            categories(*),
            accounts(*)
          ''')
          .single();
      
      // Update account balance
      await _updateAccountBalanceForTransaction(transaction, isCreating: true);
      
      return Transaction.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create transaction: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Update transaction
  static Future<Transaction> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    try {
      // Revert old transaction's effect on account balance
      await _updateAccountBalanceForTransaction(oldTransaction, isCreating: false);
      
      final response = await _client
          .from('transactions')
          .update(newTransaction.toJson())
          .eq('id', newTransaction.id)
          .select('''
            *,
            categories(*),
            accounts(*)
          ''')
          .single();
      
      // Apply new transaction's effect on account balance
      await _updateAccountBalanceForTransaction(newTransaction, isCreating: true);
      
      return Transaction.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update transaction: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Delete transaction
  static Future<void> deleteTransaction(Transaction transaction) async {
    try {
      await _client
          .from('transactions')
          .delete()
          .eq('id', transaction.id);
      
      // Revert transaction's effect on account balance
      await _updateAccountBalanceForTransaction(transaction, isCreating: false);
    } catch (e) {
      throw Exception('Failed to delete transaction: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Get transaction summary for a date range
  static Future<TransactionSummary> getTransactionSummary(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select('amount, type')
          .eq('user_id', userId);
      
      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String().split('T')[0]);
      }
      
      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String().split('T')[0]);
      }
      
      final response = await query;
      
      double totalIncome = 0;
      double totalExpense = 0;
      
      for (final row in response) {
        final amount = (row['amount'] as num).toDouble();
        final type = TransactionType.fromString(row['type'] as String);
        
        switch (type) {
          case TransactionType.income:
            totalIncome += amount;
            break;
          case TransactionType.expense:
            totalExpense += amount;
            break;
          case TransactionType.transfer:
            // Transfers don't affect overall balance
            break;
        }
      }
      
      return TransactionSummary(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
        transactionCount: response.length,
      );
    } catch (e) {
      throw Exception('Failed to get transaction summary: ${SupabaseService.getErrorMessage(e)}');
    }
  }
  
  /// Update account balance based on transaction
  static Future<void> _updateAccountBalanceForTransaction(
    Transaction transaction, {
    required bool isCreating,
  }) async {
    try {
      // Get current account balance
      final accountResponse = await _client
          .from('accounts')
          .select('balance')
          .eq('id', transaction.accountId)
          .single();
      
      final currentBalance = (accountResponse['balance'] as num).toDouble();
      double newBalance = currentBalance;
      
      // Calculate balance change
      double balanceChange = transaction.amount;
      if (transaction.type == TransactionType.expense) {
        balanceChange = -balanceChange;
      }
      
      // Apply or revert the change
      if (isCreating) {
        newBalance += balanceChange;
      } else {
        newBalance -= balanceChange;
      }
      
      // Update account balance
      await _client
          .from('accounts')
          .update({'balance': newBalance})
          .eq('id', transaction.accountId);
    } catch (e) {
      // Log error but don't throw - balance updates can be corrected manually
      print('Error updating account balance: $e');
    }
  }

  // Budget Operations
  
  /// Get user budgets
  static Future<List<Budget>> getBudgets() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('budgets')
          .select('''
            *,
            categories(*)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return response.map<Budget>((json) => Budget.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get budgets: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get budget by category ID
  static Future<Budget?> getBudgetByCategory(String categoryId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('budgets')
          .select('''
            *,
            categories(*)
          ''')
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .maybeSingle();
      
      return response != null ? Budget.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to get budget: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Create budget
  static Future<Budget> createBudget(Budget budget) async {
    try {
      final budgetData = budget.toJson();
      budgetData.remove('id'); // Remove id field, let database generate it
      
      final response = await _client
          .from('budgets')
          .insert(budgetData)
          .select('''
            *,
            categories(*)
          ''')
          .single();
      
      return Budget.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create budget: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Update budget
  static Future<Budget> updateBudget(Budget budget) async {
    try {
      final budgetData = budget.toJson();
      budgetData['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('budgets')
          .update(budgetData)
          .eq('id', budget.id)
          .select('''
            *,
            categories(*)
          ''')
          .single();
      
      return Budget.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update budget: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Delete budget
  static Future<void> deleteBudget(String budgetId) async {
    try {
      await _client
          .from('budgets')
          .delete()
          .eq('id', budgetId);
    } catch (e) {
      throw Exception('Failed to delete budget: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get budget usage for a specific budget
  static Future<BudgetUsage> getBudgetUsage(Budget budget) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final periodStart = budget.getCurrentPeriodStart();
      final periodEnd = budget.getCurrentPeriodEnd();

      final response = await _client
          .from('transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('category_id', budget.categoryId)
          .eq('type', 'expense')
          .gte('transaction_date', periodStart.toIso8601String().split('T')[0])
          .lte('transaction_date', periodEnd.toIso8601String().split('T')[0]);

      final totalSpent = response.fold<double>(
        0.0,
        (sum, transaction) => sum + (transaction['amount'] as num).toDouble(),
      );

      return BudgetUsage.fromBudgetAndSpent(budget, totalSpent);
    } catch (e) {
      throw Exception('Failed to get budget usage: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get all budget usages for current user
  static Future<List<BudgetUsage>> getAllBudgetUsages() async {
    try {
      final budgets = await getBudgets();
      final usages = <BudgetUsage>[];

      for (final budget in budgets) {
        if (budget.isCurrentlyActive) {
          final usage = await getBudgetUsage(budget);
          usages.add(usage);
        }
      }

      return usages;
    } catch (e) {
      throw Exception('Failed to get budget usages: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get budget suggestions based on historical spending
  static Future<Map<String, double>> getBudgetSuggestions() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get last 3 months of spending data
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      
      final response = await _client
          .from('transactions')
          .select('category_id, amount, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('transaction_date', threeMonthsAgo.toIso8601String().split('T')[0]);

      final categorySpending = <String, List<double>>{};
      
      for (final transaction in response) {
        final categoryId = transaction['category_id'] as String?;
        if (categoryId != null) {
          final amount = (transaction['amount'] as num).toDouble();
          categorySpending.putIfAbsent(categoryId, () => []).add(amount);
        }
      }

      final suggestions = <String, double>{};
      
      for (final entry in categorySpending.entries) {
        final categoryId = entry.key;
        final amounts = entry.value;
        
        // Calculate average monthly spending and add 20% buffer
        final totalSpent = amounts.fold<double>(0.0, (sum, amount) => sum + amount);
        final averageMonthly = totalSpent / 3; // 3 months
        final suggestedBudget = averageMonthly * 1.2; // 20% buffer
        
        suggestions[categoryId] = suggestedBudget;
      }

      return suggestions;
    } catch (e) {
      throw Exception('Failed to get budget suggestions: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  // Lending Operations

  /// Create a new lending
  static Future<Lending> createLending(Lending lending) async {
    try {
      final lendingData = lending.toJson();
      lendingData.remove('id'); // Remove id field, let database generate it
      
      final response = await _client
          .from('lendings')
          .insert(lendingData)
          .select()
          .single();
      
      return Lending.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create lending: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get all lendings for current user
  static Future<List<Lending>> getLendings() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('lendings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map<Lending>((json) => Lending.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get lendings: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get lendings by type (lent or borrowed)
  static Future<List<Lending>> getLendingsByType(LendingType type) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('lendings')
          .select()
          .eq('user_id', userId)
          .eq('type', type.toJson())
          .order('created_at', ascending: false);
      
      return response.map<Lending>((json) => Lending.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get lendings by type: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get lending by ID
  static Future<Lending?> getLendingById(String lendingId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('lendings')
          .select()
          .eq('id', lendingId)
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null ? Lending.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to get lending: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Update lending
  static Future<Lending> updateLending(Lending lending) async {
    try {
      final updates = lending.toJson();
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('lendings')
          .update(updates)
          .eq('id', lending.id)
          .select()
          .single();
      
      return Lending.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update lending: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Delete lending
  static Future<void> deleteLending(String lendingId) async {
    try {
      await _client
          .from('lendings')
          .delete()
          .eq('id', lendingId);
    } catch (e) {
      throw Exception('Failed to delete lending: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Add payment to lending
  static Future<LendingPayment> addPayment(LendingPayment payment) async {
    try {
      final paymentData = payment.toJson();
      paymentData.remove('id'); // Remove id field, let database generate it
      
      final response = await _client
          .from('lending_payments')
          .insert(paymentData)
          .select()
          .single();
      
      // Update the lending's amount_paid
      await _updateLendingAmountPaid(payment.lendingId);
      
      return LendingPayment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add payment: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get payments for a lending
  static Future<List<LendingPayment>> getLendingPayments(String lendingId) async {
    try {
      final response = await _client
          .from('lending_payments')
          .select()
          .eq('lending_id', lendingId)
          .order('payment_date', ascending: false);
      
      return response.map<LendingPayment>((json) => LendingPayment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get lending payments: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Delete payment
  static Future<void> deletePayment(String paymentId) async {
    try {
      // Get payment to find lending_id
      final payment = await _client
          .from('lending_payments')
          .select('lending_id')
          .eq('id', paymentId)
          .single();
      
      // Delete the payment
      await _client
          .from('lending_payments')
          .delete()
          .eq('id', paymentId);
      
      // Update the lending's amount_paid
      await _updateLendingAmountPaid(payment['lending_id']);
    } catch (e) {
      throw Exception('Failed to delete payment: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Update lending amount_paid based on payments
  static Future<void> _updateLendingAmountPaid(String lendingId) async {
    try {
      // Calculate total payments
      final payments = await _client
          .from('lending_payments')
          .select('amount')
          .eq('lending_id', lendingId);
      
      final totalPaid = payments.fold<double>(
        0.0, 
        (sum, payment) => sum + (payment['amount'] as num).toDouble()
      );
      
      // Update lending
      await _client
          .from('lendings')
          .update({
            'amount_paid': totalPaid,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', lendingId);
    } catch (e) {
      print('Error updating lending amount_paid: $e');
    }
  }

  /// Get lending summary statistics
  static Future<Map<String, double>> getLendingSummary() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final lendings = await getLendings();
      
      double totalLent = 0.0;
      double totalBorrowed = 0.0;
      double totalLentPaid = 0.0;
      double totalBorrowedPaid = 0.0;
      double outstandingLent = 0.0;
      double outstandingBorrowed = 0.0;
      
      for (final lending in lendings) {
        if (lending.type == LendingType.lent) {
          totalLent += lending.amount;
          totalLentPaid += lending.amountPaid;
          outstandingLent += lending.remainingAmount;
        } else {
          totalBorrowed += lending.amount;
          totalBorrowedPaid += lending.amountPaid;
          outstandingBorrowed += lending.remainingAmount;
        }
      }
      
      return {
        'totalLent': totalLent,
        'totalBorrowed': totalBorrowed,
        'totalLentPaid': totalLentPaid,
        'totalBorrowedPaid': totalBorrowedPaid,
        'outstandingLent': outstandingLent,
        'outstandingBorrowed': outstandingBorrowed,
      };
    } catch (e) {
      throw Exception('Failed to get lending summary: ${SupabaseService.getErrorMessage(e)}');
    }
  }

  /// Get overdue lendings
  static Future<List<Lending>> getOverdueLendings() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('lendings')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .lt('due_date', DateTime.now().toIso8601String().split('T')[0])
          .gt('amount_paid', 0) // Not fully paid
          .order('due_date', ascending: true);
      
      return response.map<Lending>((json) => Lending.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get overdue lendings: ${SupabaseService.getErrorMessage(e)}');
    }
  }
}
