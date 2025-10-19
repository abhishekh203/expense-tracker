import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import '../services/calendar_service.dart';
import '../utils/responsive_helper.dart';

class BilingualCalendarWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool showCalendarToggle;
  final String? title;

  const BilingualCalendarWidget({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.showCalendarToggle = true,
    this.title,
  });

  @override
  State<BilingualCalendarWidget> createState() => _BilingualCalendarWidgetState();
}

class _BilingualCalendarWidgetState extends State<BilingualCalendarWidget> {
  DateTime? _selectedDate;
  CalendarType _currentCalendar = CalendarService.currentCalendar;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
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
        children: [
          // Header with title and calendar toggle
          if (widget.title != null || widget.showCalendarToggle)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (widget.title != null) ...[
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                  if (widget.showCalendarToggle) ...[
                    const Spacer(),
                    _buildCalendarToggle(),
                  ],
                ],
              ),
            ),
          
          // Calendar content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCalendarContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarToggle() {
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
            'English',
            CalendarType.english,
            Icons.calendar_today,
          ),
          _buildToggleButton(
            'नेपाली',
            CalendarType.nepali,
            Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, CalendarType type, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentCalendar == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentCalendar = type;
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

  Widget _buildCalendarContent() {
    if (_currentCalendar == CalendarType.nepali) {
      return _buildNepaliCalendar();
    } else {
      return _buildEnglishCalendar();
    }
  }

  Widget _buildNepaliCalendar() {
    final colorScheme = Theme.of(context).colorScheme;
    final nepaliDate = _selectedDate!.toNepaliDateTime();
    
    return Column(
      children: [
        // Month/Year header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  final newDate = nepaliDate.subtract(Duration(days: 30));
                  _selectedDate = newDate.toDateTime();
                });
              },
              icon: Icon(Icons.chevron_left, color: colorScheme.primary),
            ),
            Text(
              '${nepaliDate.year} ${CalendarService.getMonthNames()[nepaliDate.month - 1]}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  final newDate = nepaliDate.add(Duration(days: 30));
                  _selectedDate = newDate.toDateTime();
                });
              },
              icon: Icon(Icons.chevron_right, color: colorScheme.primary),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Day headers
        Row(
          children: CalendarService.getShortDayNames().map((day) => 
            Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
        
        const SizedBox(height: 8),
        
        // Calendar grid
        _buildNepaliCalendarGrid(nepaliDate),
      ],
    );
  }

  Widget _buildNepaliCalendarGrid(NepaliDateTime nepaliDate) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstDayOfMonth = NepaliDateTime(nepaliDate.year, nepaliDate.month, 1);
    final lastDayOfMonth = NepaliDateTime(nepaliDate.year, nepaliDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    List<Widget> dayWidgets = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(height: 40));
    }
    
    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final dayDate = NepaliDateTime(nepaliDate.year, nepaliDate.month, day);
      final isSelected = day == nepaliDate.day;
      final isToday = dayDate.year == NepaliDateTime.now().year && 
                     dayDate.month == NepaliDateTime.now().month && 
                     dayDate.day == NepaliDateTime.now().day;
      
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = dayDate.toDateTime();
            });
            widget.onDateSelected(_selectedDate!);
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: colorScheme.primary, width: 2) : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? colorScheme.onPrimary 
                      : isToday 
                          ? colorScheme.primary 
                          : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Wrap(
      children: dayWidgets.map((widget) => 
        SizedBox(
          width: MediaQuery.of(context).size.width / 7 - 8,
          child: widget,
        ),
      ).toList(),
    );
  }

  Widget _buildEnglishCalendar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        // Month/Year header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(_selectedDate!.year, _selectedDate!.month - 1, _selectedDate!.day);
                });
              },
              icon: Icon(Icons.chevron_left, color: colorScheme.primary),
            ),
            Text(
              '${_selectedDate!.year} ${CalendarService.getMonthNames()[_selectedDate!.month - 1]}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(_selectedDate!.year, _selectedDate!.month + 1, _selectedDate!.day);
                });
              },
              icon: Icon(Icons.chevron_right, color: colorScheme.primary),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Day headers
        Row(
          children: CalendarService.getShortDayNames().map((day) => 
            Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
        
        const SizedBox(height: 8),
        
        // Calendar grid
        _buildEnglishCalendarGrid(),
      ],
    );
  }

  Widget _buildEnglishCalendarGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    final firstDayOfMonth = DateTime(_selectedDate!.year, _selectedDate!.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate!.year, _selectedDate!.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    List<Widget> dayWidgets = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(height: 40));
    }
    
    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final dayDate = DateTime(_selectedDate!.year, _selectedDate!.month, day);
      final isSelected = day == _selectedDate!.day;
      final isToday = dayDate.day == DateTime.now().day && 
                     dayDate.month == DateTime.now().month && 
                     dayDate.year == DateTime.now().year;
      
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = dayDate;
            });
            widget.onDateSelected(_selectedDate!);
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: colorScheme.primary, width: 2) : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? colorScheme.onPrimary 
                      : isToday 
                          ? colorScheme.primary 
                          : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Wrap(
      children: dayWidgets.map((widget) => 
        SizedBox(
          width: MediaQuery.of(context).size.width / 7 - 8,
          child: widget,
        ),
      ).toList(),
    );
  }
}
