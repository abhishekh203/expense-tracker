# Smart Receipt OCR Feature

## Overview
The Smart Receipt OCR feature uses Google's Gemini AI to automatically extract transaction details from receipt photos, significantly reducing manual data entry.

## Features
- **Automatic Data Extraction**: Amount, merchant, date, description, and category
- **Smart Category Detection**: AI suggests appropriate expense categories
- **Confidence Scoring**: Shows how reliable the OCR results are
- **Auto-fill Forms**: Automatically populates transaction fields
- **Error Handling**: Graceful fallback when OCR fails

## How It Works
1. User taps "Scan Receipt" button in Add Expense screen
2. Camera opens to capture receipt photo
3. Gemini AI analyzes the image and extracts structured data
4. Form fields are automatically filled with extracted information
5. User can review and modify before saving

## Technical Implementation

### Files Added/Modified:
- `lib/models/receipt_ocr_result.dart` - OCR data model
- `lib/services/ai_service.dart` - Gemini API integration
- `lib/screens/transactions/add_transaction_screen.dart` - Enhanced with OCR UI
- `lib/constants/app_constants.dart` - Added Gemini API key

### Dependencies Added:
- `google_generative_ai: ^0.2.1` - Gemini AI SDK
- `http: ^1.1.0` - HTTP requests for fallback method

### API Integration:
- Uses Gemini 1.5 Flash model for fast processing
- Implements both SDK and HTTP fallback methods
- Structured JSON prompts for consistent data extraction

## Usage Instructions

### For Users:
1. Open Add Expense screen
2. Tap "Scan Receipt" button
3. Take photo of receipt
4. Wait for AI processing (2-5 seconds)
5. Review auto-filled data
6. Make any necessary adjustments
7. Save transaction

### For Developers:
```dart
// Process receipt image
final result = await AIService.processReceiptImage(imageFile);

// Check if result is valid
if (result.isValidForTransaction) {
  // Use extracted data
  print('Amount: ${result.amount}');
  print('Merchant: ${result.merchant}');
  print('Category: ${result.suggestedCategory}');
}
```

## Error Handling
- Network failures: Shows error message, allows manual entry
- Invalid receipts: Low confidence scores prevent auto-fill
- API limits: Graceful degradation to manual entry
- Image quality: Optimized image processing for better results

## Future Enhancements
- Support for multiple currencies
- Batch receipt processing
- Receipt storage and history
- Integration with expense reports
- Voice-to-text for descriptions
- Bill due date extraction
