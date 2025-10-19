import 'package:flutter/material.dart';
import '../../models/lending.dart';
import '../../models/lending_payment.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import 'add_payment_screen.dart';

class LendingDetailScreen extends StatefulWidget {
  final Lending lending;
  final VoidCallback? onLendingUpdated;

  const LendingDetailScreen({
    super.key,
    required this.lending,
    this.onLendingUpdated,
  });

  @override
  State<LendingDetailScreen> createState() => _LendingDetailScreenState();
}

class _LendingDetailScreenState extends State<LendingDetailScreen> {
  late Lending _lending;
  List<LendingPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _lending = widget.lending;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        DatabaseService.getLendingById(_lending.id),
        DatabaseService.getLendingPayments(_lending.id),
      ]);

      final lending = results[0] as Lending?;
      final payments = results[1] as List<LendingPayment>;

      setState(() {
        if (lending != null) {
          _lending = lending;
        }
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lending details: $e'),
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
        title: Text(_lending.personName),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showEditDialog(),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'add_payment':
                  _showAddPaymentDialog();
                  break;
                case 'mark_completed':
                  _markAsCompleted();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_payment',
                child: Row(
                  children: [
                    Icon(Icons.payment),
                    SizedBox(width: 8),
                    Text('Add Payment'),
                  ],
                ),
              ),
              if (!_lending.isFullyPaid)
                const PopupMenuItem(
                  value: 'mark_completed',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text('Mark as Completed'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: 24),

                    // Details Card
                    _buildDetailsCard(),
                    const SizedBox(height: 24),

                    // Payment History
                    _buildPaymentHistory(),
                  ],
                ),
              ),
            ),
      floatingActionButton: _lending.isFullyPaid
          ? null
          : FloatingActionButton(
              onPressed: _showAddPaymentDialog,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.payment),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _lending.type == LendingType.lent
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            _lending.type == LendingType.lent
                ? Colors.green.withOpacity(0.05)
                : Colors.orange.withOpacity(0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lending.type == LendingType.lent
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _lending.type == LendingType.lent
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: _lending.type == LendingType.lent
                      ? Colors.green
                      : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lending.personName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _lending.type.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_lending.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 20),
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
                      CurrencyFormatter.formatNPR(_lending.amount),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
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
                      'Paid',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatNPR(_lending.amountPaid),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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
                      CurrencyFormatter.formatNPR(_lending.remainingAmount),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _lending.remainingAmount > 0
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_lending.amountPaid > 0) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _lending.amountPaid / _lending.amount,
              backgroundColor: colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _lending.type == LendingType.lent
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Status', _lending.status.displayName),
          _buildDetailRow('Lending Date', _formatDate(_lending.lendingDate)),
          if (_lending.dueDate != null)
            _buildDetailRow(
              'Due Date',
              _formatDate(_lending.dueDate!),
              isOverdue: _lending.isOverdue,
            ),
          if (_lending.interestRate != null && _lending.interestRate! > 0)
            _buildDetailRow(
              'Interest Rate',
              '${_lending.interestRate!.toStringAsFixed(2)}%',
            ),
          if (_lending.interestRate != null && _lending.interestRate! > 0)
            _buildDetailRow(
              'Total with Interest',
              CurrencyFormatter.formatNPR(_lending.totalWithInterest),
            ),
          if (_lending.personContact != null && _lending.personContact!.isNotEmpty)
            _buildDetailRow('Contact', _lending.personContact!),
          if (_lending.notes != null && _lending.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _lending.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isOverdue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isOverdue ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Payment History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!_lending.isFullyPaid)
                TextButton.icon(
                  onPressed: _showAddPaymentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_payments.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.payment,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payments yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add payments as they are received',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _payments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return _buildPaymentCard(payment);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(LendingPayment payment) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.formatNPR(payment.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(payment.paymentDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (payment.notes != null && payment.notes!.isNotEmpty)
            IconButton(
              onPressed: () => _showPaymentNotes(payment.notes!),
              icon: const Icon(Icons.info_outline),
              iconSize: 20,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPaymentScreen(
        lending: _lending,
        onPaymentAdded: () {
          Navigator.of(context).pop();
          _refreshData();
        },
      ),
    );
  }

  void _showEditDialog() {
    // TODO: Implement edit lending dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _markAsCompleted() async {
    try {
      final updatedLending = _lending.copyWith(
        status: LendingStatus.completed,
        updatedAt: DateTime.now(),
      );
      
      await DatabaseService.updateLending(updatedLending);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lending marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshData();
        widget.onLendingUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating lending: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lending'),
        content: const Text('Are you sure you want to delete this lending? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteLending();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLending() async {
    try {
      await DatabaseService.deleteLending(_lending.id);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onLendingUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lending deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting lending: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showPaymentNotes(String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Notes'),
        content: Text(notes),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
