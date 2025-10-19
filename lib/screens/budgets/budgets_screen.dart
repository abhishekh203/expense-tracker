import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/currency_formatter.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<BudgetUsage> _budgetUsages = [];
  List<Category> _categories = [];
  Map<String, double> _budgetSuggestions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    try {
      setState(() => _isLoading = true);

      final usagesFuture = DatabaseService.getAllBudgetUsages();
      final categoriesFuture = DatabaseService.getCategories();
      final suggestionsFuture = DatabaseService.getBudgetSuggestions();

      final results = await Future.wait([
        usagesFuture,
        categoriesFuture,
        suggestionsFuture,
      ]);

      setState(() {
        _budgetUsages = results[0] as List<BudgetUsage>;
        _categories = results[1] as List<Category>;
        _budgetSuggestions = results[2] as Map<String, double>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budgets: $e')),
        );
      }
    }
  }

  Future<void> _showAddBudgetDialog() async {
    // Get categories that don't have budgets yet
    final existingBudgetCategoryIds = _budgetUsages.map((u) => u.budget.categoryId).toSet();
    final availableCategories = _categories
        .where((c) => c.type == 'expense' && !existingBudgetCategoryIds.contains(c.id))
        .toList();

    if (availableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All expense categories already have budgets')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddBudgetDialog(
        categories: availableCategories,
        suggestions: _budgetSuggestions,
      ),
    );

    if (result == true) {
      _loadBudgetData();
    }
  }

  Future<void> _editBudget(BudgetUsage usage) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditBudgetDialog(
        budget: usage.budget,
        suggestion: _budgetSuggestions[usage.budget.categoryId],
      ),
    );

    if (result == true) {
      _loadBudgetData();
    }
  }

  Future<void> _deleteBudget(BudgetUsage usage) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete the budget for "${usage.budget.category?.name}"?',
        ),
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
        await DatabaseService.deleteBudget(usage.budget.id);
        _loadBudgetData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting budget: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBudgetDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBudgetData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudgetData,
              child: _budgetUsages.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        // Summary Card
                        _buildSummaryCard(),
                        
                        // Budget List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _budgetUsages.length,
                            itemBuilder: (context, index) {
                              final usage = _budgetUsages[index];
                              return BudgetCard(
                                usage: usage,
                                onEdit: () => _editBudget(usage),
                                onDelete: () => _deleteBudget(usage),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No budgets yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Set budgets for your expense categories to track your spending',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddBudgetDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_budgetUsages.isEmpty) return const SizedBox.shrink();

    final totalBudget = _budgetUsages.fold<double>(0.0, (sum, usage) => sum + usage.budget.amount);
    final totalSpent = _budgetUsages.fold<double>(0.0, (sum, usage) => sum + usage.spent);
    final totalRemaining = totalBudget - totalSpent;
    final overBudgetCount = _budgetUsages.where((u) => u.isOverBudget).length;
    final alertCount = _budgetUsages.where((u) => u.shouldAlert).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings,
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
                      'Total Budget',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatNPR(totalBudget),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Spent',
                  CurrencyFormatter.formatNPR(totalSpent),
                  Colors.white.withOpacity(0.9),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Remaining',
                  CurrencyFormatter.formatNPR(totalRemaining),
                  totalRemaining >= 0 ? Colors.white : Colors.red[200]!,
                ),
              ),
            ],
          ),
          if (overBudgetCount > 0 || alertCount > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (overBudgetCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$overBudgetCount over budget',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (overBudgetCount > 0 && alertCount > 0) const SizedBox(width: 8),
                if (alertCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$alertCount need attention',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class BudgetCard extends StatelessWidget {
  final BudgetUsage usage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.usage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final budget = usage.budget;
    final category = budget.category!;
    
    final statusColor = Color(int.parse(usage.statusColor.replaceAll('#', '0xFF')));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
                const SizedBox(width: 12),
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
                      Text(
                        '${budget.period.displayName} • ${budget.periodDisplayText}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
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
            const SizedBox(height: 16),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${CurrencyFormatter.formatNPR(usage.spent)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Budget: ${CurrencyFormatter.formatNPR(budget.amount)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: usage.percentage.clamp(0.0, 1.0),
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        usage.statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Text(
                      '${(usage.percentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Remaining Amount
            if (!usage.isOverBudget) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remaining: ${CurrencyFormatter.formatNPR(usage.remaining)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 20,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Over budget by ${CurrencyFormatter.formatNPR(usage.remaining.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Alert Indicator
            if (usage.shouldAlert && !usage.isOverBudget) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Approaching budget limit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddBudgetDialog extends StatefulWidget {
  final List<Category> categories;
  final Map<String, double> suggestions;

  const AddBudgetDialog({
    super.key,
    required this.categories,
    required this.suggestions,
  });

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  Category? _selectedCategory;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  bool _alertEnabled = true;
  double _alertThreshold = 0.8; // 80%
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(Category? category) {
    setState(() {
      _selectedCategory = category;
      if (category != null && widget.suggestions.containsKey(category.id)) {
        _amountController.text = widget.suggestions[category.id]!.toStringAsFixed(0);
      }
    });
  }

  Future<void> _createBudget() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final now = DateTime.now();

      final budget = Budget(
        id: '',
        userId: userId,
        categoryId: _selectedCategory!.id,
        amount: amount,
        period: _selectedPeriod,
        startDate: now,
        endDate: null,
        isActive: true,
        alertEnabled: _alertEnabled,
        alertThreshold: _alertThreshold,
        createdAt: now,
        updatedAt: now,
      );

      await DatabaseService.createBudget(budget);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSuggestion = _selectedCategory != null && 
                         widget.suggestions.containsKey(_selectedCategory!.id);

    return AlertDialog(
      title: const Text('Create Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Selection
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: widget.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon ?? '📝', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(category.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onCategoryChanged,
              validator: (value) => value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),

            // Budget Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Budget Amount',
                prefixText: 'रू ',
                border: const OutlineInputBorder(),
                helperText: hasSuggestion 
                    ? 'Suggested: ${CurrencyFormatter.formatNPR(widget.suggestions[_selectedCategory!.id]!)}'
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 16),

            // Budget Period
            DropdownButtonFormField<BudgetPeriod>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Budget Period',
                border: OutlineInputBorder(),
              ),
              items: BudgetPeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period.displayName),
                );
              }).toList(),
              onChanged: (period) {
                if (period != null) {
                  setState(() => _selectedPeriod = period);
                }
              },
            ),
            const SizedBox(height: 16),

            // Alert Settings
            Row(
              children: [
                Checkbox(
                  value: _alertEnabled,
                  onChanged: (value) {
                    setState(() => _alertEnabled = value ?? false);
                  },
                ),
                const Expanded(
                  child: Text('Enable budget alerts'),
                ),
              ],
            ),
            if (_alertEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Alert at: '),
                  Expanded(
                    child: Slider(
                      value: _alertThreshold,
                      min: 0.5,
                      max: 0.95,
                      divisions: 9,
                      label: '${(_alertThreshold * 100).toInt()}%',
                      onChanged: (value) {
                        setState(() => _alertThreshold = value);
                      },
                    ),
                  ),
                  Text('${(_alertThreshold * 100).toInt()}%'),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createBudget,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class EditBudgetDialog extends StatefulWidget {
  final Budget budget;
  final double? suggestion;

  const EditBudgetDialog({
    super.key,
    required this.budget,
    this.suggestion,
  });

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  late BudgetPeriod _selectedPeriod;
  late bool _alertEnabled;
  late double _alertThreshold;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.budget.amount.toString();
    _selectedPeriod = widget.budget.period;
    _alertEnabled = widget.budget.alertEnabled;
    _alertThreshold = widget.budget.alertThreshold;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _updateBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));

      final updatedBudget = widget.budget.copyWith(
        amount: amount,
        period: _selectedPeriod,
        alertEnabled: _alertEnabled,
        alertThreshold: _alertThreshold,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.updateBudget(updatedBudget);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.budget.category!;

    return AlertDialog(
      title: Row(
        children: [
          Text(category.icon ?? '📝', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(child: Text('Edit ${category.name} Budget')),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Budget Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Budget Amount',
                prefixText: 'रू ',
                border: const OutlineInputBorder(),
                helperText: widget.suggestion != null 
                    ? 'Suggested: ${CurrencyFormatter.formatNPR(widget.suggestion!)}'
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 16),

            // Budget Period
            DropdownButtonFormField<BudgetPeriod>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Budget Period',
                border: OutlineInputBorder(),
              ),
              items: BudgetPeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period.displayName),
                );
              }).toList(),
              onChanged: (period) {
                if (period != null) {
                  setState(() => _selectedPeriod = period);
                }
              },
            ),
            const SizedBox(height: 16),

            // Alert Settings
            Row(
              children: [
                Checkbox(
                  value: _alertEnabled,
                  onChanged: (value) {
                    setState(() => _alertEnabled = value ?? false);
                  },
                ),
                const Expanded(
                  child: Text('Enable budget alerts'),
                ),
              ],
            ),
            if (_alertEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Alert at: '),
                  Expanded(
                    child: Slider(
                      value: _alertThreshold,
                      min: 0.5,
                      max: 0.95,
                      divisions: 9,
                      label: '${(_alertThreshold * 100).toInt()}%',
                      onChanged: (value) {
                        setState(() => _alertThreshold = value);
                      },
                    ),
                  ),
                  Text('${(_alertThreshold * 100).toInt()}%'),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateBudget,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
