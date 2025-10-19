import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import '../../constants/app_constants.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../models/user_profile.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/edit_transaction_screen.dart';
import '../transactions/transaction_card.dart';
import '../transactions/transaction_filter_sheet.dart';
import '../categories/add_category_screen.dart';
import '../categories/edit_category_screen.dart';
import '../accounts/add_account_screen.dart';
import '../accounts/edit_account_screen.dart';
import '../reports/reports_screen.dart';
import '../budgets/budgets_screen.dart';
import '../lendings/lending_screen.dart';
import '../lendings/add_lending_screen.dart';
import '../../models/lending.dart';
import '../settings/profile_screen.dart';
import '../chat/budget_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const TransactionsTab(),
    const CategoriesTab(),
    const AccountsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(
                  transactionType: 'expense',
                ),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: context.isMobile ? 70.0 : 80.0,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
          height: context.isMobile ? 70.0 : 80.0,
          labelBehavior: context.isMobile 
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
          NavigationDestination(
              icon: Icon(
                Icons.dashboard_outlined,
                size: context.isMobile ? 24.0 : 28.0,
              ),
              selectedIcon: Icon(
                Icons.dashboard,
                size: context.isMobile ? 24.0 : 28.0,
              ),
            label: 'Dashboard',
          ),
          NavigationDestination(
              icon: Icon(
                Icons.receipt_long_outlined,
                size: context.isMobile ? 24.0 : 28.0,
              ),
              selectedIcon: Icon(
                Icons.receipt_long,
                size: context.isMobile ? 24.0 : 28.0,
              ),
            label: 'Transactions',
          ),
          NavigationDestination(
              icon: Icon(
                Icons.category_outlined,
                size: context.isMobile ? 24.0 : 28.0,
              ),
              selectedIcon: Icon(
                Icons.category,
                size: context.isMobile ? 24.0 : 28.0,
              ),
            label: 'Categories',
          ),
          NavigationDestination(
              icon: Icon(
                Icons.account_balance_wallet_outlined,
                size: context.isMobile ? 24.0 : 28.0,
              ),
              selectedIcon: Icon(
                Icons.account_balance_wallet,
                size: context.isMobile ? 24.0 : 28.0,
              ),
            label: 'Accounts',
          ),
          NavigationDestination(
              icon: Icon(
                Icons.settings_outlined,
                size: context.isMobile ? 24.0 : 28.0,
              ),
              selectedIcon: Icon(
                Icons.settings,
                size: context.isMobile ? 24.0 : 28.0,
              ),
            label: 'Settings',
          ),
        ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<Account> _accounts = [];
  List<Transaction> _recentTransactions = [];
  List<Category> _categories = [];
  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  Map<String, double> _categorySpending = {};
  bool _isLoading = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Load all data in parallel
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final accountsFuture = DatabaseService.getAccounts();
      final categoriesFuture = DatabaseService.getCategories();
      final userProfileFuture = DatabaseService.getUserProfile(userId);
      final recentTransactionsFuture = DatabaseService.getUserTransactions(
        userId,
        limit: 5,
        offset: 0,
      );
      final monthlyTransactionsFuture = DatabaseService.getUserTransactions(
        userId,
        limit: 1000, // Get all transactions for the month
        offset: 0,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      final results = await Future.wait([
        accountsFuture,
        categoriesFuture,
        userProfileFuture,
        recentTransactionsFuture,
        monthlyTransactionsFuture,
      ]);

      final accounts = results[0] as List<Account>;
      final categories = results[1] as List<Category>;
      final userProfile = results[2] as UserProfile?;
      final recentTransactions = results[3] as List<Transaction>;
      final monthlyTransactions = results[4] as List<Transaction>;

      // Calculate totals
      final totalBalance = accounts.fold(0.0, (sum, account) => sum + account.balance);
      
      double monthlyIncome = 0.0;
      double monthlyExpense = 0.0;
      Map<String, double> categorySpending = {};

      for (final transaction in monthlyTransactions) {
        if (transaction.type == TransactionType.income) {
          monthlyIncome += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          monthlyExpense += transaction.amount;
          
          // Track spending by category
          if (transaction.category != null) {
            final categoryName = transaction.category!.name;
            categorySpending[categoryName] = (categorySpending[categoryName] ?? 0) + transaction.amount;
          }
        }
      }

      setState(() {
        _accounts = accounts;
        _categories = categories;
        _recentTransactions = recentTransactions;
        _totalBalance = totalBalance;
        _monthlyIncome = monthlyIncome;
        _monthlyExpense = monthlyExpense;
        _categorySpending = categorySpending;
        _userName = userProfile?.fullName ?? userProfile?.firstName ?? 'User';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: ResponsiveHelper.getScrollPhysics(),
                    padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.secondary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.waving_hand,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${_userName ?? 'User'}!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Here\'s your financial overview',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Balance Cards
                        context.isMobile
                            ? Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.primary.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.account_balance_wallet,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total Balance',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  CurrencyFormatter.formatNPR(_totalBalance),
                                                  style: theme.textTheme.headlineSmall?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _monthlyExpense > _monthlyIncome 
                                            ? [
                                                Colors.red.withOpacity(0.1),
                                                Colors.red.withOpacity(0.05),
                                              ]
                                            : [
                                                Colors.green.withOpacity(0.1),
                                                Colors.green.withOpacity(0.05),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _monthlyExpense > _monthlyIncome 
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.green.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _monthlyExpense > _monthlyIncome 
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              _monthlyExpense > _monthlyIncome 
                                                  ? Icons.trending_down
                                                  : Icons.trending_up,
                                              color: _monthlyExpense > _monthlyIncome 
                                                  ? Colors.red[700]
                                                  : Colors.green[700],
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'This Month',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: _monthlyExpense > _monthlyIncome 
                                                        ? Colors.red[700]
                                                        : Colors.green[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  CurrencyFormatter.formatNPR(_monthlyIncome - _monthlyExpense),
                                                  style: theme.textTheme.headlineSmall?.copyWith(
                                                    color: _monthlyExpense > _monthlyIncome 
                                                        ? Colors.red[700]
                                                        : Colors.green[700],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
              children: [
                Expanded(
                  child: Card(
                                      elevation: context.cardElevation,
                                      color: colorScheme.primaryContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(context.borderRadius),
                                      ),
                    child: Padding(
                                        padding: context.responsivePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                                    color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Balance',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                                    CurrencyFormatter.formatNPR(_totalBalance),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                            color: _monthlyExpense > _monthlyIncome 
                                ? colorScheme.errorContainer
                                : colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                                    _monthlyExpense > _monthlyIncome 
                                        ? Icons.trending_down
                                        : Icons.trending_up,
                                    color: _monthlyExpense > _monthlyIncome 
                                        ? colorScheme.onErrorContainer
                                        : colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This Month',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _monthlyExpense > _monthlyIncome 
                                          ? colorScheme.onErrorContainer
                                          : colorScheme.onTertiaryContainer,
                            ),
                          ),
                          Text(
                                    CurrencyFormatter.formatNPR(_monthlyIncome - _monthlyExpense),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: _monthlyExpense > _monthlyIncome 
                                          ? colorScheme.onErrorContainer
                                          : colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

                    // Monthly Summary Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.1),
                                    Colors.green.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.arrow_upward,
                                        color: Colors.green[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Income',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.formatNPR(_monthlyIncome),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.1),
                                    Colors.red.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.arrow_downward,
                                        color: Colors.red[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Expenses',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.formatNPR(_monthlyExpense),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Spending Categories
                    if (_categorySpending.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Top Spending Categories',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: (_categorySpending.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value)))
                                .take(3)
                                .map((entry) {
                              final category = _categories.firstWhere(
                                (c) => c.name == entry.key,
                                orElse: () => Category(
                                  id: '',
                                  userId: '',
                                  name: entry.key,
                                  icon: '📝',
                                  color: '#6b7280',
                                  type: 'expense',
                                  isDefault: false,
                                  createdAt: DateTime.now(),
                                ),
                              );
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(category.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          category.icon ?? '📝',
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(entry.value / _monthlyExpense * 100).toStringAsFixed(1)}% of expenses',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatNPR(entry.value),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Recent Transactions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_recentTransactions.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                // Navigate to transactions tab
                                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                                homeState?.setState(() {
                                  homeState._selectedIndex = 1; // Transactions tab
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('View All'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_recentTransactions.isEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No transactions yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start by adding your first transaction',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _recentTransactions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final transaction = entry.value;
                            final isExpense = transaction.type == TransactionType.expense;
                            final isIncome = transaction.type == TransactionType.income;
                            
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isExpense 
                                              ? Colors.red.withOpacity(0.1)
                                              : isIncome 
                                                  ? Colors.green.withOpacity(0.1)
                                                  : colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            transaction.category?.icon ?? transaction.type.icon,
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transaction.displayTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${transaction.displaySubtitle} • ${_getRelativeDate(transaction.transactionDate)}',
                                              style: TextStyle(
                                                color: colorScheme.onSurfaceVariant,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${isExpense ? '-' : isIncome ? '+' : ''}${CurrencyFormatter.formatNPR(transaction.amount)}',
                                        style: TextStyle(
                                          color: isExpense 
                                              ? Colors.red[700]
                                              : isIncome 
                                                  ? Colors.green[700]
                                                  : colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index < _recentTransactions.length - 1)
                                  Divider(
                                    height: 1,
                                    color: colorScheme.outline.withOpacity(0.1),
                                    indent: 20,
                                    endIndent: 20,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
            const SizedBox(height: 16),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: context.isMobile
                  ? Column(
                      children: [
                        // First row: Expense and Income
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                'Add Expense',
                                Icons.remove_circle_outline,
                                Colors.red,
                                () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddTransactionScreen(
                                        transactionType: 'expense',
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadDashboardData();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                'Add Income',
                                Icons.add_circle_outline,
                                Colors.green,
                                () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddTransactionScreen(
                                        transactionType: 'income',
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadDashboardData();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Second row: Transfer and Lend Money
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                'Transfer Money',
                                Icons.swap_horiz,
                                colorScheme.primary,
                                () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddTransactionScreen(
                                        transactionType: 'transfer',
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadDashboardData();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                'Lend Money',
                                Icons.arrow_upward,
                                Colors.blue,
                                () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const AddLendingScreen(
                                      initialType: LendingType.lent,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Third row: Borrow Money and View Lendings
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                'Borrow Money',
                                Icons.arrow_downward,
                                Colors.orange,
                                () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const AddLendingScreen(
                                      initialType: LendingType.borrowed,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                'View Lendings',
                                Icons.account_balance_wallet,
                                Colors.purple,
                                () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LendingScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // First row: Expense, Income, Transfer
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                'Add Expense',
                                Icons.remove_circle_outline,
                                Colors.red,
                                () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddTransactionScreen(
                                        transactionType: 'expense',
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadDashboardData();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                'Add Income',
                                Icons.add_circle_outline,
                                Colors.green,
                                () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddTransactionScreen(
                                        transactionType: 'income',
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadDashboardData();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                'Transfer Money',
                                Icons.swap_horiz,
                                colorScheme.primary,
                                () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddTransactionScreen(
                                        transactionType: 'transfer',
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadDashboardData();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Second row: Lend Money, Borrow Money, View Lendings
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                'Lend Money',
                                Icons.arrow_upward,
                                Colors.blue,
                                () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const AddLendingScreen(
                                      initialType: LendingType.lent,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                'Borrow Money',
                                Icons.arrow_downward,
                                Colors.orange,
                                () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const AddLendingScreen(
                                      initialType: LendingType.borrowed,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                'View Lendings',
                                Icons.account_balance_wallet,
                                Colors.purple,
                                () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LendingScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 90,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  // Search and filter state
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  TransactionType? _selectedType;
  
  // Pagination
  static const int _pageSize = 20;
  int _currentOffset = 0;
  bool _hasMoreData = true;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _currentOffset = 0;
        _hasMoreData = true;
      });

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Load categories and accounts for filters
      final categoriesFuture = DatabaseService.getCategories();
      final accountsFuture = DatabaseService.getAccounts();
      final transactionsFuture = DatabaseService.getUserTransactions(
        userId,
        limit: _pageSize,
        offset: 0,
        startDate: _startDate,
        endDate: _endDate,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        type: _selectedType,
      );

      final results = await Future.wait([categoriesFuture, accountsFuture, transactionsFuture]);
      
      setState(() {
        _categories = results[0] as List<Category>;
        _accounts = results[1] as List<Account>;
        _transactions = results[2] as List<Transaction>;
        _currentOffset = _transactions.length;
        _hasMoreData = _transactions.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      setState(() => _isLoadingMore = true);

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      final newTransactions = await DatabaseService.getUserTransactions(
        userId,
        limit: _pageSize,
        offset: _currentOffset,
        startDate: _startDate,
        endDate: _endDate,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        type: _selectedType,
      );

      setState(() {
        _transactions.addAll(newTransactions);
        _currentOffset = _transactions.length;
        _hasMoreData = newTransactions.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  List<Transaction> get _filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    
    return _transactions.where((transaction) {
      final searchLower = _searchQuery.toLowerCase();
      return transaction.displayTitle.toLowerCase().contains(searchLower) ||
             (transaction.notes?.toLowerCase().contains(searchLower) ?? false) ||
             (transaction.category?.name.toLowerCase().contains(searchLower) ?? false) ||
             (transaction.account?.name.toLowerCase().contains(searchLower) ?? false);
    }).toList();
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this ${transaction.type.displayName.toLowerCase()}?\n\n"${transaction.displayTitle}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await DatabaseService.deleteTransaction(transaction);
        await _loadInitialData(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionFilterSheet(
        categories: _categories,
        accounts: _accounts,
        startDate: _startDate,
        endDate: _endDate,
        selectedCategoryId: _selectedCategoryId,
        selectedAccountId: _selectedAccountId,
        selectedType: _selectedType,
        onApplyFilters: (startDate, endDate, categoryId, accountId, type) {
          setState(() {
            _startDate = startDate;
            _endDate = endDate;
            _selectedCategoryId = categoryId;
            _selectedAccountId = accountId;
            _selectedType = type;
          });
          _loadInitialData();
        },
        onClearFilters: () {
          setState(() {
            _startDate = null;
            _endDate = null;
            _selectedCategoryId = null;
            _selectedAccountId = null;
            _selectedType = null;
          });
          _loadInitialData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredTransactions = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
            onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filter Chips
          if (_hasActiveFilters) ...[
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_startDate != null || _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_getDateRangeText()),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          _loadInitialData();
                        },
                      ),
                    ),
                  if (_selectedCategoryId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_categories.firstWhere((c) => c.id == _selectedCategoryId).name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _selectedCategoryId = null);
                          _loadInitialData();
                        },
                      ),
                    ),
                  if (_selectedAccountId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_accounts.firstWhere((a) => a.id == _selectedAccountId).name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _selectedAccountId = null);
                          _loadInitialData();
                        },
                      ),
                    ),
                  if (_selectedType != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_selectedType!.displayName),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _selectedType = null);
                          _loadInitialData();
                        },
                      ),
          ),
        ],
      ),
            ),
          ],

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _hasActiveFilters
                                  ? 'No transactions found'
                                  : 'No transactions yet',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _hasActiveFilters
                                  ? 'Try adjusting your search or filters'
                                  : 'Start by adding your first transaction',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInitialData,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredTransactions.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredTransactions.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final transaction = filteredTransactions[index];
                            return TransactionCard(
                              transaction: transaction,
                              onEdit: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditTransactionScreen(transaction: transaction),
                                  ),
                                );
                                if (result == true) {
                                  _loadInitialData();
                                }
                              },
                              onDelete: () => _deleteTransaction(transaction),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters {
    return _startDate != null ||
           _endDate != null ||
           _selectedCategoryId != null ||
           _selectedAccountId != null ||
           _selectedType != null;
  }

  String _getDateRangeText() {
    if (_startDate != null && _endDate != null) {
      return '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}';
    } else if (_startDate != null) {
      return 'From ${_startDate!.day}/${_startDate!.month}';
    } else if (_endDate != null) {
      return 'Until ${_endDate!.day}/${_endDate!.month}';
    }
    return '';
  }
}

class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DatabaseService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await DatabaseService.deleteCategory(category.id);
        await _loadCategories(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${category.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting category: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCategoryScreen(),
                ),
              );
              if (result == true) {
                _loadCategories(); // Refresh the list
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No categories yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first category',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final color = Color(int.parse(category.color.replaceAll('#', '0xFF')));
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                category.icon ?? '📝',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (category.nameNepali != null && category.nameNepali!.isNotEmpty)
                                Text(category.nameNepali!),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: category.type == 'expense' 
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: category.type == 'expense' 
                                        ? Colors.red[700]
                                        : Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditCategoryScreen(category: category),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadCategories();
                                    }
                                  } else if (value == 'delete') {
                                    _deleteCategory(category);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  if (!category.isDefault) // Don't allow deleting default categories
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class AccountsTab extends StatefulWidget {
  const AccountsTab({super.key});

  @override
  State<AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends State<AccountsTab> {
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await DatabaseService.getAccounts();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accounts: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(Account account) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"?\n\nThis action cannot be undone and will affect all related transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await DatabaseService.deleteAccount(account.id);
        await _loadAccounts(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${account.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  double get _totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAccountScreen(),
                ),
              );
              if (result == true) {
                _loadAccounts(); // Refresh the list
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total Balance Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Balance',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatNPR(_totalBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_accounts.length} accounts',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Accounts List
                Expanded(
                  child: _accounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No accounts yet',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first account',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAccounts,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) {
                              final account = _accounts[index];
                              final isPositive = account.balance >= 0;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        account.type.icon,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    account.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        account.type.displayName,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        CurrencyFormatter.formatNPR(account.balance),
                                        style: TextStyle(
                                          color: isPositive ? Colors.green[700] : Colors.red[700],
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditAccountScreen(account: account),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadAccounts();
                                        }
                                      } else if (value == 'adjust_balance') {
                                        _showBalanceAdjustmentDialog(account);
                                      } else if (value == 'delete') {
                                        _deleteAccount(account);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'adjust_balance',
                                        child: Row(
                                          children: [
                                            Icon(Icons.account_balance, size: 20),
                                            SizedBox(width: 8),
                                            Text('Adjust Balance'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showBalanceAdjustmentDialog(Account account) {
    final controller = TextEditingController(text: account.balance.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Balance - ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ${CurrencyFormatter.formatNPR(account.balance)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'New Balance',
                prefixText: 'रू ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newBalance = double.tryParse(controller.text);
              if (newBalance != null) {
                try {
                  await DatabaseService.updateAccountBalance(account.id, newBalance);
                  Navigator.of(context).pop();
                  _loadAccounts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Balance updated for ${account.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating balance: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text('Budget Management'),
            subtitle: const Text('Set and track spending budgets per category'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('AI Budget Assistant'),
            subtitle: const Text('Ask questions about your finances'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationalBudgetAssistantScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Reports & Analytics'),
            subtitle: const Text('View detailed spending reports and charts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: const Text('Manage your profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show language selector
            },
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text(AppConstants.defaultCurrency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show currency selector
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Sync'),
            subtitle: const Text('Manage your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to backup settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            subtitle: const Text('Password and security settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to security settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show about dialog
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () async {
              final shouldSignOut = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (shouldSignOut == true) {
                await AuthService.signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}
