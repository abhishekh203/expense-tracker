import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  
  // Controllers for editing
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  DateTime? _selectedDateOfBirth;
  String _selectedCurrency = 'NPR';
  String _selectedLanguage = 'en';

  final List<String> _currencies = ['NPR', 'USD', 'EUR', 'GBP', 'INR'];
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ne', 'name': 'नेपाली'},
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = AuthService.getCurrentUser()?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final profile = await DatabaseService.getUserProfile(userId);
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _firstNameController.text = profile.firstName ?? '';
          _lastNameController.text = profile.lastName ?? '';
          _phoneController.text = profile.phoneNumber ?? '';
          _occupationController.text = profile.occupation ?? '';
          _bioController.text = profile.bio ?? '';
          _websiteController.text = profile.website ?? '';
          _locationController.text = profile.location ?? '';
          _selectedDateOfBirth = profile.dateOfBirth;
          _selectedCurrency = profile.currency;
          _selectedLanguage = profile.language;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_userProfile == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedProfile = _userProfile!.copyWith(
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        currency: _selectedCurrency,
        language: _selectedLanguage,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.updateUserProfile(updatedProfile);
      
      if (mounted) {
        setState(() {
          _userProfile = updatedProfile;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildModernProfileHeader(),
                const SizedBox(height: 32),
                _buildProfileSections(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AppBar(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'Profile',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: _isEditing
              ? _buildSaveButton()
              : _buildEditButton(),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _toggleEditMode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: colorScheme.onPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Edit',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green,
            Colors.green.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isSaving ? null : _saveProfile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                else
                  Icon(
                    Icons.save_rounded,
                    size: 18,
                    color: colorScheme.onPrimary,
                  ),
                const SizedBox(width: 6),
                Text(
                  _isSaving ? 'Saving...' : 'Save',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
            colorScheme.tertiary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar with modern design
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // User Info
            Text(
              _userProfile?.fullName ?? 'User',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              _userProfile?.email ?? 'No email',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Member since badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Member since ${DateFormat('MMM yyyy').format(_userProfile?.createdAt ?? DateTime.now())}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSections() {
    return Column(
      children: [
        _buildProvidedInfoSection(),
        const SizedBox(height: 20),
        _buildMissingInfoSection(),
        const SizedBox(height: 20),
        _buildPreferencesSection(),
      ],
    );
  }

  Widget _buildProvidedInfoSection() {
    final providedFields = <Widget>[];
    
    // Check each field and add to provided list if it has data
    if (_firstNameController.text.isNotEmpty) {
      providedFields.add(_buildInfoItem(
        label: 'First Name',
        value: _firstNameController.text,
        icon: Icons.badge_rounded,
        controller: _firstNameController,
      ));
    }
    
    if (_lastNameController.text.isNotEmpty) {
      providedFields.add(_buildInfoItem(
        label: 'Last Name',
        value: _lastNameController.text,
        icon: Icons.badge_rounded,
        controller: _lastNameController,
      ));
    }
    
    if (_selectedDateOfBirth != null) {
      providedFields.add(_buildDateInfoItem());
    }
    
    if (_phoneController.text.isNotEmpty) {
      providedFields.add(_buildInfoItem(
        label: 'Phone Number',
        value: _phoneController.text,
        icon: Icons.phone_rounded,
        controller: _phoneController,
      ));
    }
    
    if (_locationController.text.isNotEmpty) {
      providedFields.add(_buildInfoItem(
        label: 'Location',
        value: _locationController.text,
        icon: Icons.location_on_rounded,
        controller: _locationController,
      ));
    }
    
    if (_occupationController.text.isNotEmpty) {
      providedFields.add(_buildInfoItem(
        label: 'Occupation',
        value: _occupationController.text,
        icon: Icons.work_rounded,
        controller: _occupationController,
      ));
    }
    
    if (_websiteController.text.isNotEmpty) {
      providedFields.add(_buildInfoItem(
        label: 'Website',
        value: _websiteController.text,
        icon: Icons.web_rounded,
        controller: _websiteController,
      ));
    }
    
    if (_bioController.text.isNotEmpty) {
      providedFields.add(_buildInfoItem(
        label: 'Bio',
        value: _bioController.text,
        icon: Icons.description_rounded,
        controller: _bioController,
        isMultiline: true,
      ));
    }
    
    if (providedFields.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildModernSection(
      icon: Icons.check_circle_rounded,
      title: 'Provided Information',
      children: providedFields,
    );
  }

  Widget _buildMissingInfoSection() {
    final missingFields = <Widget>[];
    
    // Check each field and add to missing list if it's empty
    if (_firstNameController.text.isEmpty) {
      missingFields.add(_buildMissingInfoItem(
        label: 'First Name',
        icon: Icons.badge_rounded,
        controller: _firstNameController,
      ));
    }
    
    if (_lastNameController.text.isEmpty) {
      missingFields.add(_buildMissingInfoItem(
        label: 'Last Name',
        icon: Icons.badge_rounded,
        controller: _lastNameController,
      ));
    }
    
    if (_selectedDateOfBirth == null) {
      missingFields.add(_buildMissingDateItem());
    }
    
    if (_phoneController.text.isEmpty) {
      missingFields.add(_buildMissingInfoItem(
        label: 'Phone Number',
        icon: Icons.phone_rounded,
        controller: _phoneController,
        keyboardType: TextInputType.phone,
      ));
    }
    
    if (_locationController.text.isEmpty) {
      missingFields.add(_buildMissingInfoItem(
        label: 'Location',
        icon: Icons.location_on_rounded,
        controller: _locationController,
      ));
    }
    
    if (_occupationController.text.isEmpty) {
      missingFields.add(_buildMissingInfoItem(
        label: 'Occupation',
        icon: Icons.work_rounded,
        controller: _occupationController,
      ));
    }
    
    if (_websiteController.text.isEmpty) {
      missingFields.add(_buildMissingInfoItem(
        label: 'Website',
        icon: Icons.web_rounded,
        controller: _websiteController,
        keyboardType: TextInputType.url,
      ));
    }
    
    if (_bioController.text.isEmpty) {
      missingFields.add(_buildMissingInfoItem(
        label: 'Bio',
        icon: Icons.description_rounded,
        controller: _bioController,
        isMultiline: true,
      ));
    }
    
    if (missingFields.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildModernSection(
      icon: Icons.add_circle_rounded,
      title: 'Missing Information',
      children: missingFields,
    );
  }

  Widget _buildPreferencesSection() {
    return _buildModernSection(
      icon: Icons.settings_rounded,
      title: 'Preferences',
      children: [
        _buildModernDropdownField(
          label: 'Currency',
          value: _selectedCurrency,
          items: _currencies,
          icon: Icons.currency_exchange_rounded,
          onChanged: (value) => setState(() => _selectedCurrency = value!),
        ),
        _buildModernDropdownField(
          label: 'Language',
          value: _selectedLanguage,
          items: _languages.map((lang) => lang['code']!).toList(),
          icon: Icons.language_rounded,
          onChanged: (value) => setState(() => _selectedLanguage = value!),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    required TextEditingController controller,
    bool isMultiline = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Container(
              width: 200,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter $label',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateInfoItem() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDateOfBirth!),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Container(
              width: 200,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDateOfBirth = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedDateOfBirth != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedDateOfBirth!)
                        : 'Select Date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _selectedDateOfBirth != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMissingInfoItem({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isMultiline = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Not provided',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Container(
              width: 200,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter $label',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMissingDateItem() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Not provided',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Container(
              width: 200,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDateOfBirth = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Select Date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.05),
                  colorScheme.secondary.withOpacity(0.02),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '(Optional)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing)
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                prefixIcon: Icon(
                  icon,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                controller.text.isEmpty ? 'Not provided' : controller.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: controller.text.isEmpty
                      ? colorScheme.onSurfaceVariant.withOpacity(0.6)
                      : colorScheme.onSurface,
                  fontWeight: controller.text.isEmpty ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Date of Birth',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(Optional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing)
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: colorScheme.copyWith(
                          primary: colorScheme.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() {
                    _selectedDateOfBirth = date;
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDateOfBirth != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedDateOfBirth!)
                          : 'Select Date of Birth',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _selectedDateOfBirth != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _selectedDateOfBirth != null
                    ? DateFormat('MMM dd, yyyy').format(_selectedDateOfBirth!)
                    : 'Not provided',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _selectedDateOfBirth != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontWeight: _selectedDateOfBirth != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing)
            DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  icon,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: colorScheme.primary.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}