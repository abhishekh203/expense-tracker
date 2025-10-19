import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';

class TransactionFilterSheet extends StatefulWidget {
  final List<Category> categories;
  final List<Account> accounts;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedCategoryId;
  final String? selectedAccountId;
  final TransactionType? selectedType;
  final Function(DateTime?, DateTime?, String?, String?, TransactionType?) onApplyFilters;
  final VoidCallback onClearFilters;

  const TransactionFilterSheet({
    super.key,
    required this.categories,
    required this.accounts,
    this.startDate,
    this.endDate,
    this.selectedCategoryId,
    this.selectedAccountId,
    this.selectedType,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  TransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedAccountId = widget.selectedAccountId;
    _selectedType = widget.selectedType;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _applyFilters() {
    widget.onApplyFilters(_startDate, _endDate, _selectedCategoryId, _selectedAccountId, _selectedType);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCategoryId = null;
      _selectedAccountId = null;
      _selectedType = null;
    });
    widget.onClearFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Filter Transactions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Date Range
          Text(
            'Date Range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectStartDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 16,
                            color: _startDate != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectEndDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 16,
                            color: _endDate != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Transaction Type
          Text(
            'Transaction Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (selected) {
                  setState(() => _selectedType = selected ? null : _selectedType);
                },
              ),
              ...TransactionType.values.map((type) {
                return FilterChip(
                  label: Text(type.displayName),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() => _selectedType = selected ? type : null);
                  },
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 24),

          // Category
          if (widget.categories.isNotEmpty) ...[
            Text(
              'Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  hint: const Text('Select category'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...widget.categories.map((category) {
                      return DropdownMenuItem<String?>(
                        value: category.id,
                        child: Row(
                          children: [
                            Text(category.icon ?? '📝', style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Account
          if (widget.accounts.isNotEmpty) ...[
            Text(
              'Account',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedAccountId,
                  isExpanded: true,
                  hint: const Text('Select account'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All accounts'),
                    ),
                    ...widget.accounts.map((account) {
                      return DropdownMenuItem<String?>(
                        value: account.id,
                        child: Row(
                          children: [
                            Text(account.type.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(account.name),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedAccountId = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
