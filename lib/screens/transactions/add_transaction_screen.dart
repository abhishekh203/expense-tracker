import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// import 'package:image_picker/image_picker.dart';  // Temporarily disabled
import 'dart:io';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import '../../services/calendar_service.dart';
import '../../services/ai_service.dart';
import '../../constants/app_constants.dart';
import '../../utils/currency_formatter.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../models/receipt_ocr_result.dart';
import '../../models/category_suggestion.dart';
import '../../widgets/bilingual_date_picker.dart';

class AddTransactionScreen extends StatefulWidget {
  final String transactionType; // 'expense', 'income', or 'transfer'
  
  const AddTransactionScreen({
    super.key,
    required this.transactionType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  Account? _selectedAccount;
  List<Category> _categories = [];
  List<Account> _accounts = [];
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  // OCR related variables
  // final ImagePicker _imagePicker = ImagePicker();  // Temporarily disabled
  OCRStatus _ocrStatus = OCRStatus.idle;
  ReceiptOCRResult? _ocrResult;
  File? _selectedImage;
  
  // Smart categorization variables
  SmartCategorizationStatus _categorizationStatus = SmartCategorizationStatus.idle;
  CategorySuggestion? _categorySuggestion;
  bool _isAnalyzingDescription = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final categories = await DatabaseService.getCategories();
      final accounts = await DatabaseService.getAccounts();
      
      setState(() {
        _categories = categories.where((c) => 
          c.type == widget.transactionType || widget.transactionType == 'transfer'
        ).toList();
        _accounts = accounts;
        _isLoadingData = false;
        
        // Auto-select first category and account if available
        if (_categories.isNotEmpty) _selectedCategory = _categories.first;
        if (_accounts.isNotEmpty) _selectedAccount = _accounts.first;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and account')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      
      await DatabaseService.createTransaction(
        accountId: _selectedAccount!.id,
        categoryId: _selectedCategory!.id,
        amount: amount,
        type: widget.transactionType,
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim(),
        transactionDate: _selectedDate,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.transactionType.toUpperCase()} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await BilingualDatePicker.showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      title: 'Select Transaction Date',
      showCalendarToggle: true,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickReceiptImage() async {
    // Temporarily disabled - image picker functionality
    /*
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _ocrStatus = OCRStatus.processing;
        });
        
        await _processReceiptOCR();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
    */
    // Show message that feature is temporarily disabled
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt scanning temporarily disabled')),
      );
    }
  }

  Future<void> _processReceiptOCR() async {
    if (_selectedImage == null) return;
    
    try {
      final result = await AIService.processReceiptImage(_selectedImage!);
      
      setState(() {
        _ocrResult = result;
        _ocrStatus = OCRStatus.success;
      });
      
      // Auto-fill form with OCR results
      _fillFormWithOCRResult(result);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt processed successfully! Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _ocrStatus = OCRStatus.error;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fillFormWithOCRResult(ReceiptOCRResult result) {
    if (result.amount != null) {
      _amountController.text = result.amount!.toStringAsFixed(2);
    }
    
    if (result.description != null && result.description!.isNotEmpty) {
      _descriptionController.text = result.description!;
    }
    
    if (result.date != null) {
      setState(() {
        _selectedDate = result.date!;
      });
    }
    
    // Auto-select category based on OCR suggestion
    if (result.category != null) {
      final suggestedCategory = _categories.firstWhere(
        (cat) => cat.name.toLowerCase() == result.category!.toLowerCase(),
        orElse: () => _categories.first,
      );
      setState(() {
        _selectedCategory = suggestedCategory;
      });
    }
    
    // Add OCR details to notes
    if (result.rawText.isNotEmpty) {
      _notesController.text = 'OCR Details: ${result.rawText}';
    }
  }

  void _clearOCRData() {
    setState(() {
      _ocrStatus = OCRStatus.idle;
      _ocrResult = null;
      _selectedImage = null;
    });
  }

  // Smart categorization methods
  Future<void> _analyzeDescription() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty || description.length < 3) {
      return;
    }

    setState(() {
      _isAnalyzingDescription = true;
      _categorizationStatus = SmartCategorizationStatus.analyzing;
    });

    try {
      final suggestion = await AIService.suggestCategory(description);
      
      setState(() {
        _categorySuggestion = suggestion;
        _categorizationStatus = SmartCategorizationStatus.success;
        _isAnalyzingDescription = false;
      });

      // Auto-select category if confidence is high
      if (suggestion.isHighConfidence) {
        _applyCategorySuggestion(suggestion);
      }
    } catch (e) {
      setState(() {
        _categorizationStatus = SmartCategorizationStatus.error;
        _isAnalyzingDescription = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing description: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyCategorySuggestion(CategorySuggestion suggestion) {
    final matchingCategory = _categories.firstWhere(
      (cat) => cat.name.toLowerCase() == suggestion.category.toLowerCase(),
      orElse: () => _categories.first,
    );
    
    setState(() {
      _selectedCategory = matchingCategory;
    });

    // Learn from the suggestion
    AIService.learnFromCorrection(_descriptionController.text, suggestion.category);
  }

  void _clearCategorySuggestion() {
    setState(() {
      _categorySuggestion = null;
      _categorizationStatus = SmartCategorizationStatus.idle;
    });
  }

  void _onDescriptionChanged(String value) {
    // Debounce the analysis to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _descriptionController.text.trim() == value.trim()) {
        _analyzeDescription();
      }
    });
  }

  String get _title {
    switch (widget.transactionType) {
      case 'expense':
        return 'Add Expense';
      case 'income':
        return 'Add Income';
      case 'transfer':
        return 'Add Transfer';
      default:
        return 'Add Transaction';
    }
  }

  Color get _primaryColor {
    switch (widget.transactionType) {
      case 'expense':
        return Colors.red;
      case 'income':
        return Colors.green;
      case 'transfer':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData get _icon {
    switch (widget.transactionType) {
      case 'expense':
        return Icons.remove_circle_outline;
      case 'income':
        return Icons.add_circle_outline;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.close,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor,
                  _primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header with icon and amount
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withOpacity(0.1),
                    _primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryColor.withOpacity(0.2),
                          _primaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _icon,
                      size: 40,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // OCR Camera Button
                  if (widget.transactionType == 'expense') ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _ocrStatus == OCRStatus.processing ? null : _pickReceiptImage,
                            icon: _ocrStatus == OCRStatus.processing 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.camera_alt),
                            label: Text(_ocrStatus == OCRStatus.processing 
                                ? 'Processing...' 
                                : 'Scan Receipt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_ocrResult != null) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _clearOCRData,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear OCR Data',
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // OCR Status Display
                    if (_ocrStatus != OCRStatus.idle) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _ocrStatus == OCRStatus.success 
                              ? Colors.green.withOpacity(0.1)
                              : _ocrStatus == OCRStatus.error
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _ocrStatus == OCRStatus.success 
                                ? Colors.green.withOpacity(0.3)
                                : _ocrStatus == OCRStatus.error
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _ocrStatus == OCRStatus.success 
                                  ? Icons.check_circle
                                  : _ocrStatus == OCRStatus.error
                                      ? Icons.error
                                      : Icons.hourglass_empty,
                              color: _ocrStatus == OCRStatus.success 
                                  ? Colors.green
                                  : _ocrStatus == OCRStatus.error
                                      ? Colors.red
                                      : Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _ocrStatus == OCRStatus.success 
                                    ? 'Receipt scanned successfully!'
                                    : _ocrStatus == OCRStatus.error
                                        ? 'Failed to scan receipt'
                                        : 'Scanning receipt...',
                                style: TextStyle(
                                  color: _ocrStatus == OCRStatus.success 
                                      ? Colors.green[700]
                                      : _ocrStatus == OCRStatus.error
                                          ? Colors.red[700]
                                          : Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  
                  // Amount Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        prefixText: '${AppConstants.currencySymbol} ',
                        prefixStyle: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
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
                    ),
                  ),
                ],
              ),
            ),

            // Form fields
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Description with Smart Categorization
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: _onDescriptionChanged,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'What was this ${widget.transactionType} for?',
                              prefixIcon: Icon(Icons.description_outlined, color: colorScheme.primary),
                              suffixIcon: _isAnalyzingDescription 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : _categorySuggestion != null
                                      ? IconButton(
                                          icon: Icon(Icons.close, color: colorScheme.primary),
                                          onPressed: _clearCategorySuggestion,
                                        )
                                      : null,
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          
                          // Smart Category Suggestion
                          if (_categorySuggestion != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _categorySuggestion!.isHighConfidence 
                                    ? Colors.green.withOpacity(0.1)
                                    : _categorySuggestion!.isMediumConfidence
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _categorySuggestion!.isHighConfidence 
                                      ? Colors.green
                                      : _categorySuggestion!.isMediumConfidence
                                          ? Colors.orange
                                          : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _categorySuggestion!.confidenceIcon,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI Suggestion: ${_categorySuggestion!.category}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _categorySuggestion!.confidenceDisplayText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _categorySuggestion!.reasoning,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  if (_categorySuggestion!.alternatives.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: _categorySuggestion!.alternatives.map((alt) {
                                        return InkWell(
                                          onTap: () {
                                            final altSuggestion = CategorySuggestion(
                                              category: alt,
                                              confidence: _categorySuggestion!.confidence * 0.8,
                                              reasoning: 'Alternative suggestion',
                                              alternatives: [],
                                            );
                                            _applyCategorySuggestion(altSuggestion);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colorScheme.primary.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              alt,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _applyCategorySuggestion(_categorySuggestion!),
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('Apply'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor: colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: Size.zero,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: _clearCategorySuggestion,
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Dismiss'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: colorScheme.onSurface.withOpacity(0.7),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: Size.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Category Selection
                      DropdownButtonFormField<Category>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined, color: colorScheme.primary),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Text(
                                  category.icon ?? '📝',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Account Selection
                      DropdownButtonFormField<Account>(
                        value: _selectedAccount,
                        decoration: InputDecoration(
                          labelText: 'Account',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: colorScheme.primary),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _accounts.map((account) {
                          return DropdownMenuItem(
                            value: account,
                            child: Row(
                              children: [
                                Icon(_getAccountIcon(account.type), size: 20),
                                const SizedBox(width: 12),
                                Text(account.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (account) {
                          setState(() {
                            _selectedAccount = account;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an account';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date Selection
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    CalendarService.formatDateWithMonth(_selectedDate),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CalendarService.currentCalendar == CalendarType.nepali 
                                        ? 'English: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'
                                        : 'नेपाली: ${CalendarService.formatDateWithMonth(CalendarService.toNepaliDate(_selectedDate).toDateTime())}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notes (Optional)
                      TextFormField(
                        controller: _notesController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Add any additional notes...',
                          prefixIcon: Icon(Icons.note_outlined, color: colorScheme.primary),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Save Button
            Container(
              padding: const EdgeInsets.all(24),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor,
                      _primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save ${widget.transactionType.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.digitalWallet:
        return Icons.phone_android;
    }
  }
}
