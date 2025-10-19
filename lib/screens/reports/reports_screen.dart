import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  bool _isLoading = true;
  
  // Date range for reports
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365)); // Last year
  DateTime _endDate = DateTime.now();
  
  // Processed data for charts
  Map<String, double> _categorySpending = {};
  Map<String, double> _monthlyIncome = {};
  Map<String, double> _monthlyExpenses = {};
  List<MonthlyData> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportsData() async {
    try {
      setState(() => _isLoading = true);

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Load all data
      final categoriesFuture = DatabaseService.getCategories();
      final accountsFuture = DatabaseService.getAccounts();
      final transactionsFuture = DatabaseService.getUserTransactions(
        userId,
        limit: 10000, // Get all transactions in date range
        offset: 0,
        startDate: _startDate,
        endDate: _endDate,
      );

      final results = await Future.wait([
        categoriesFuture,
        accountsFuture,
        transactionsFuture,
      ]);

      final categories = results[0] as List<Category>;
      final accounts = results[1] as List<Account>;
      final transactions = results[2] as List<Transaction>;

      // Process data for charts
      _processTransactionData(transactions, categories);

      setState(() {
        _categories = categories;
        _accounts = accounts;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  void _processTransactionData(List<Transaction> transactions, List<Category> categories) {
    Map<String, double> categorySpending = {};
    Map<String, double> monthlyIncome = {};
    Map<String, double> monthlyExpenses = {};
    Map<String, MonthlyData> monthlyDataMap = {};

    for (final transaction in transactions) {
      final monthKey = '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';
      
      if (transaction.type == TransactionType.expense) {
        // Category spending
        if (transaction.category != null) {
          final categoryName = transaction.category!.name;
          categorySpending[categoryName] = (categorySpending[categoryName] ?? 0) + transaction.amount;
        }
        
        // Monthly expenses
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + transaction.amount;
      } else if (transaction.type == TransactionType.income) {
        // Monthly income
        monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + transaction.amount;
      }

      // Monthly data for combined charts
      if (!monthlyDataMap.containsKey(monthKey)) {
        monthlyDataMap[monthKey] = MonthlyData(
          month: monthKey,
          income: 0,
          expense: 0,
          date: DateTime(transaction.transactionDate.year, transaction.transactionDate.month),
        );
      }
      
      if (transaction.type == TransactionType.income) {
        monthlyDataMap[monthKey]!.income += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        monthlyDataMap[monthKey]!.expense += transaction.amount;
      }
    }

    _categorySpending = categorySpending;
    _monthlyIncome = monthlyIncome;
    _monthlyExpenses = monthlyExpenses;
    _monthlyData = monthlyDataMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Categories'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'Compare'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Accounts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Range Display
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_transactions.length} transactions',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryTab(),
                      _buildTrendsTab(),
                      _buildCompareTab(),
                      _buildAccountsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryTab() {
    if (_categorySpending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No expense data available'),
            Text('Add some transactions to see category breakdown'),
          ],
        ),
      );
    }

    final sortedCategories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatNPR(_categorySpending.values.fold(0.0, (a, b) => a + b)),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pie Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending by Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: ResponsiveHelper.getChartHeight(context),
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        centerSpaceRadius: context.isMobile ? 40 : 60,
                        sectionsSpace: context.isMobile ? 1 : 2,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch interactions for mobile
                          },
                          enabled: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ...sortedCategories.map((entry) {
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
                    
                    final percentage = (entry.value / _categorySpending.values.fold(0.0, (a, b) => a + b)) * 100;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse(category.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                category.icon ?? '📝',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatNPR(entry.value),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (_monthlyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No trend data available'),
            Text('Add transactions over multiple months to see trends'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Trends Line Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Trends',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  CurrencyFormatter.formatCompact(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _monthlyData.length) {
                                  final date = _monthlyData[index].date;
                                  return Text(
                                    '${date.month}/${date.year.toString().substring(2)}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          // Income line
                          LineChartBarData(
                            spots: _monthlyData.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value.income);
                            }).toList(),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                          // Expense line
                          LineChartBarData(
                            spots: _monthlyData.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value.expense);
                            }).toList(),
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Income', Colors.green),
                      const SizedBox(width: 24),
                      _buildLegendItem('Expenses', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Summary Cards
          ...(_monthlyData.reversed.take(6).map((data) {
            final isPositive = data.income > data.expense;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_getMonthName(data.date.month)} ${data.date.year}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            CurrencyFormatter.formatNPR(data.income - data.expense),
                            style: TextStyle(
                              color: isPositive ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Income',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatNPR(data.income),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expenses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatNPR(data.expense),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildCompareTab() {
    if (_monthlyData.length < 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Not enough data for comparison'),
            Text('Add transactions over multiple months to compare'),
          ],
        ),
      );
    }

    final currentMonth = _monthlyData.isNotEmpty ? _monthlyData.last : null;
    final previousMonth = _monthlyData.length > 1 ? _monthlyData[_monthlyData.length - 2] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentMonth != null && previousMonth != null) ...[
            // Month Comparison
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Month-over-Month Comparison',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildComparisonCard(
                            'Current Month',
                            '${_getMonthName(currentMonth.date.month)} ${currentMonth.date.year}',
                            currentMonth.income,
                            currentMonth.expense,
                            true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildComparisonCard(
                            'Previous Month',
                            '${_getMonthName(previousMonth.date.month)} ${previousMonth.date.year}',
                            previousMonth.income,
                            previousMonth.expense,
                            false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildChangeIndicators(currentMonth, previousMonth),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bar Chart Comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income vs Expenses Comparison',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _monthlyData.map((e) => [e.income, e.expense].reduce((a, b) => a > b ? a : b)).reduce((a, b) => a > b ? a : b) * 1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  CurrencyFormatter.formatCompact(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _monthlyData.length) {
                                  final date = _monthlyData[index].date;
                                  return Text(
                                    '${date.month}/${date.year.toString().substring(2)}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _monthlyData.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.income,
                                color: Colors.green,
                                width: 12,
                              ),
                              BarChartRodData(
                                toY: entry.value.expense,
                                color: Colors.red,
                                width: 12,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Income', Colors.green),
                      const SizedBox(width: 24),
                      _buildLegendItem('Expenses', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsTab() {
    if (_accounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No accounts available'),
            Text('Add some accounts to see account analytics'),
          ],
        ),
      );
    }

    final totalBalance = _accounts.fold(0.0, (sum, account) => sum + account.balance);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Balance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Portfolio Value',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatNPR(totalBalance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: totalBalance >= 0 ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Distribution Pie Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Distribution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: ResponsiveHelper.getChartHeight(context),
                    child: PieChart(
                      PieChartData(
                        sections: _buildAccountPieChartSections(),
                        centerSpaceRadius: context.isMobile ? 40 : 60,
                        sectionsSpace: context.isMobile ? 1 : 2,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch interactions for mobile
                          },
                          enabled: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._accounts.map((account) {
                    final percentage = totalBalance != 0 ? (account.balance / totalBalance) * 100 : 0.0;
                    final isPositive = account.balance >= 0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                account.type.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${percentage.abs().toStringAsFixed(1)}% • ${account.type.displayName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatNPR(account.balance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = _categorySpending.values.fold(0.0, (a, b) => a + b);
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return (_categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
      .asMap()
      .entries
      .map((entry) {
        final index = entry.key;
        final categoryEntry = entry.value;
        final percentage = (categoryEntry.value / total) * 100;
        
        return PieChartSectionData(
          color: colors[index % colors.length],
          value: categoryEntry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: context.isMobile ? 80 : 100,
          titleStyle: TextStyle(
            fontSize: context.isMobile ? 10.0 : 12.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
  }

  List<PieChartSectionData> _buildAccountPieChartSections() {
    final total = _accounts.fold(0.0, (sum, account) => sum + account.balance.abs());
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    return _accounts.asMap().entries.map((entry) {
      final index = entry.key;
      final account = entry.value;
      final percentage = total != 0 ? (account.balance.abs() / total) * 100 : 0.0;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: account.balance.abs(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildComparisonCard(String title, String subtitle, double income, double expense, bool isCurrent) {
    final net = income - expense;
    final isPositive = net >= 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Net: ${CurrencyFormatter.formatNPR(net)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Income: ${CurrencyFormatter.formatNPR(income)}',
            style: TextStyle(fontSize: 12, color: Colors.green[700]),
          ),
          Text(
            'Expenses: ${CurrencyFormatter.formatNPR(expense)}',
            style: TextStyle(fontSize: 12, color: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeIndicators(MonthlyData current, MonthlyData previous) {
    final incomeChange = current.income - previous.income;
    final expenseChange = current.expense - previous.expense;
    final netChange = (current.income - current.expense) - (previous.income - previous.expense);

    return Column(
      children: [
        _buildChangeRow('Income Change', incomeChange, incomeChange >= 0),
        _buildChangeRow('Expense Change', expenseChange, expenseChange <= 0),
        _buildChangeRow('Net Change', netChange, netChange >= 0),
      ],
    );
  }

  Widget _buildChangeRow(String label, double change, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                CurrencyFormatter.formatNPR(change.abs()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class MonthlyData {
  final String month;
  double income;
  double expense;
  final DateTime date;

  MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
    required this.date,
  });
}
