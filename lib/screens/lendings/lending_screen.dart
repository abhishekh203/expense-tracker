import 'package:flutter/material.dart';
import '../../models/lending.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import 'add_lending_screen.dart';
import 'lending_detail_screen.dart';

class LendingScreen extends StatefulWidget {
  const LendingScreen({super.key});

  @override
  State<LendingScreen> createState() => _LendingScreenState();
}

class _LendingScreenState extends State<LendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Lending> _lentLendings = [];
  List<Lending> _borrowedLendings = [];
  Map<String, double> _summary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        DatabaseService.getLendingsByType(LendingType.lent),
        DatabaseService.getLendingsByType(LendingType.borrowed),
        DatabaseService.getLendingSummary(),
      ]);

      setState(() {
        _lentLendings = results[0] as List<Lending>;
        _borrowedLendings = results[1] as List<Lending>;
        _summary = results[2] as Map<String, double>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lendings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lending & Borrowing'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(
              icon: Icon(Icons.arrow_upward),
              text: 'Lent to Others',
            ),
            Tab(
              icon: Icon(Icons.arrow_downward),
              text: 'Borrowed from Others',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddLendingDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Lending',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                _buildSummaryCards(),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLendingList(_lentLendings, LendingType.lent),
                      _buildLendingList(_borrowedLendings, LendingType.borrowed),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLendingDialog(),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildSummaryCard(
                  'Total Lent',
                  _summary['totalLent'] ?? 0.0,
                  _summary['outstandingLent'] ?? 0.0,
                  Colors.green,
                  Icons.arrow_upward,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard(
                  'Total Borrowed',
                  _summary['totalBorrowed'] ?? 0.0,
                  _summary['outstandingBorrowed'] ?? 0.0,
                  Colors.orange,
                  Icons.arrow_downward,
                )),
              ],
            )
          : Column(
              children: [
                _buildSummaryCard(
                  'Total Lent',
                  _summary['totalLent'] ?? 0.0,
                  _summary['outstandingLent'] ?? 0.0,
                  Colors.green,
                  Icons.arrow_upward,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  'Total Borrowed',
                  _summary['totalBorrowed'] ?? 0.0,
                  _summary['outstandingBorrowed'] ?? 0.0,
                  Colors.orange,
                  Icons.arrow_downward,
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double totalAmount,
    double outstandingAmount,
    Color color,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.formatNPR(totalAmount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Outstanding: ${CurrencyFormatter.formatNPR(outstandingAmount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLendingList(List<Lending> lendings, LendingType type) {
    if (lendings.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lendings.length,
        itemBuilder: (context, index) {
          final lending = lendings[index];
          return _buildLendingCard(lending);
        },
      ),
    );
  }

  Widget _buildEmptyState(LendingType type) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(isDesktop ? 48 : 24), // Reduced margin
          padding: EdgeInsets.all(isDesktop ? 48 : 24), // Reduced padding
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == LendingType.lent ? Icons.arrow_upward : Icons.arrow_downward,
                size: isDesktop ? 80 : 48, // Reduced icon size
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12), // Reduced spacing
              Text(
                type == LendingType.lent 
                    ? 'No Money Lent Yet'
                    : 'No Money Borrowed Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith( // Smaller text style
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6), // Reduced spacing
              Text(
                type == LendingType.lent
                    ? 'Start tracking money you lend to others'
                    : 'Start tracking money you borrow from others',
                style: Theme.of(context).textTheme.bodySmall?.copyWith( // Smaller text style
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16), // Reduced spacing
              ElevatedButton.icon(
                onPressed: () => _showAddLendingDialog(type: type),
                icon: const Icon(Icons.add),
                label: Text(
                  type == LendingType.lent 
                      ? 'Add Lending'
                      : 'Add Borrowing',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, // Reduced padding
                    vertical: 10,   // Reduced padding
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLendingCard(Lending lending) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToLendingDetail(lending),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lending.type == LendingType.lent 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        lending.type == LendingType.lent 
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: lending.type == LendingType.lent 
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lending.personName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            lending.type.displayName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (lending.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Overdue',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
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
                            'Total Amount',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatNPR(lending.amount),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
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
                            'Remaining',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatNPR(lending.remainingAmount),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: lending.remainingAmount > 0 
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (lending.amountPaid > 0) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: lending.amountPaid / lending.amount,
                    backgroundColor: colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      lending.type == LendingType.lent 
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
                if (lending.dueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatDate(lending.dueDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: lending.isOverdue 
                              ? Colors.red
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddLendingDialog({LendingType? type}) {
    showDialog(
      context: context,
      builder: (context) => AddLendingScreen(
        initialType: type,
        onLendingAdded: () {
          Navigator.of(context).pop();
          _refreshData();
        },
      ),
    );
  }

  void _navigateToLendingDetail(Lending lending) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LendingDetailScreen(
          lending: lending,
          onLendingUpdated: _refreshData,
        ),
      ),
    );
  }
}
