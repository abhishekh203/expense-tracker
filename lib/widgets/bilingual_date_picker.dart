import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import '../services/calendar_service.dart';
import '../utils/responsive_helper.dart';

class BilingualDatePicker {
  /// Show a bilingual date picker dialog
  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
    bool showCalendarToggle = true,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    DateTime selectedDate = initialDate ?? DateTime.now();
    CalendarType currentCalendar = CalendarService.currentCalendar;
    
    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: isDesktop ? 400 : double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title ?? 'Select Date',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (showCalendarToggle)
                            _buildCalendarToggle(
                              context, 
                              setState, 
                              currentCalendar, 
                              (type) => currentCalendar = type,
                            ),
                        ],
                      ),
                    ),
                    
                    // Calendar content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildCalendarContent(
                        context,
                        setState,
                        selectedDate,
                        currentCalendar,
                        (date) => selectedDate = date,
                        firstDate,
                        lastDate,
                      ),
                    ),
                    
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(selectedDate),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Select'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildCalendarToggle(
    BuildContext context,
    StateSetter setState,
    CalendarType currentCalendar,
    Function(CalendarType) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context,
            setState,
            'English',
            CalendarType.english,
            Icons.calendar_today,
            currentCalendar,
            onChanged,
          ),
          _buildToggleButton(
            context,
            setState,
            'नेपाली',
            CalendarType.nepali,
            Icons.calendar_month,
            currentCalendar,
            onChanged,
          ),
        ],
      ),
    );
  }

  static Widget _buildToggleButton(
    BuildContext context,
    StateSetter setState,
    String label,
    CalendarType type,
    IconData icon,
    CalendarType currentCalendar,
    Function(CalendarType) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = currentCalendar == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          onChanged(type);
          CalendarService.setCalendarType(type);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCalendarContent(
    BuildContext context,
    StateSetter setState,
    DateTime selectedDate,
    CalendarType currentCalendar,
    Function(DateTime) onDateChanged,
    DateTime? firstDate,
    DateTime? lastDate,
  ) {
    if (currentCalendar == CalendarType.nepali) {
      return _buildNepaliDatePicker(
        context,
        setState,
        selectedDate,
        onDateChanged,
        firstDate,
        lastDate,
      );
    } else {
      return _buildEnglishDatePicker(
        context,
        setState,
        selectedDate,
        onDateChanged,
        firstDate,
        lastDate,
      );
    }
  }

  static Widget _buildNepaliDatePicker(
    BuildContext context,
    StateSetter setState,
    DateTime selectedDate,
    Function(DateTime) onDateChanged,
    DateTime? firstDate,
    DateTime? lastDate,
  ) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          // Month/Year header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    final nepaliDate = selectedDate.toNepaliDateTime();
                    final newDate = nepaliDate.subtract(Duration(days: 30));
                    onDateChanged(newDate.toDateTime());
                  });
                },
                icon: Icon(Icons.chevron_left),
              ),
              Text(
                '${selectedDate.toNepaliDateTime().year} ${selectedDate.toNepaliDateTime().month}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    final nepaliDate = selectedDate.toNepaliDateTime();
                    final newDate = nepaliDate.add(Duration(days: 30));
                    onDateChanged(newDate.toDateTime());
                  });
                },
                icon: Icon(Icons.chevron_right),
              ),
            ],
          ),
          
          // Simple date selection for now
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nepali Calendar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Selected: ${selectedDate.toNepaliDateTime().year}/${selectedDate.toNepaliDateTime().month}/${selectedDate.toNepaliDateTime().day}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final nepaliDate = await showNepaliDatePicker(
                        context: context,
                        initialDate: selectedDate.toNepaliDateTime(),
                        firstDate: firstDate != null ? firstDate.toNepaliDateTime() : NepaliDateTime(2000),
                        lastDate: lastDate != null ? lastDate.toNepaliDateTime() : NepaliDateTime(2090),
                      );
                      if (nepaliDate != null) {
                        setState(() {
                          onDateChanged(nepaliDate.toDateTime());
                        });
                      }
                    },
                    child: Text('Select Nepali Date'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildEnglishDatePicker(
    BuildContext context,
    StateSetter setState,
    DateTime selectedDate,
    Function(DateTime) onDateChanged,
    DateTime? firstDate,
    DateTime? lastDate,
  ) {
    return SizedBox(
      height: 300,
      child: CalendarDatePicker(
        initialDate: selectedDate,
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime(2090),
        onDateChanged: (DateTime date) {
          setState(() {
            onDateChanged(date);
          });
        },
      ),
    );
  }
}
