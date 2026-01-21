import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/applicant.dart';
import '../controllers/applicant_controller.dart';
import '../views/login_page.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _businessGoalController = TextEditingController();
  final _fundingGoalController = TextEditingController();
  final _familyMembersController = TextEditingController();
  final _divisionController = TextEditingController();
  final _districtController = TextEditingController();
  final _upazillaController = TextEditingController();
  final _thanaController = TextEditingController();
  final _currentOccupationController = TextEditingController();

  final _applicantController = ApplicantController();
  final _picker = ImagePicker();

  MaritalStatus _selectedMaritalStatus = MaritalStatus.single;
  XFile? _photoFile;
  XFile? _fingerprintFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _businessGoalController.dispose();
    _fundingGoalController.dispose();
    _familyMembersController.dispose();
    _divisionController.dispose();
    _districtController.dispose();
    _upazillaController.dispose();
    _thanaController.dispose();
    _currentOccupationController.dispose();
    super.dispose();
  }

  Future<void> _submitApplicant() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Capture values *before* async operations to prevent race conditions
      final name = _nameController.text.trim();
      final age = int.parse(_ageController.text.trim());
      final location = _locationController.text.trim();
      final businessGoal = _businessGoalController.text.trim();
      final fundingGoal = double.parse(_fundingGoalController.text.trim());
      final familyMembers = int.parse(_familyMembersController.text.trim());
      final division = _divisionController.text.trim();
      final district = _districtController.text.trim();
      final upazilla = _upazillaController.text.trim();
      final thana = _thanaController.text.trim();
      final currentOccupation = _currentOccupationController.text.trim();
      final maritalStatus = _selectedMaritalStatus;

      print('DEBUG: Submitting applicant...');

      String? photoUrl;
      String? fingerprintUrl;

      try {
        // Upload images if selected
        if (_photoFile != null) {
          print('DEBUG: Uploading photo...');
          final bytes = await _photoFile!.readAsBytes();
          final ext = _photoFile!.name.split('.').last.toLowerCase();
          final mime = _getMimeType(ext);

          photoUrl = await _applicantController.uploadImage(
            bytes,
            'photo.$ext', // pass extension
            mime,
          );
          print('DEBUG: Photo uploaded: $photoUrl');
        }

        if (_fingerprintFile != null) {
          print('DEBUG: Uploading fingerprint...');
          final bytes = await _fingerprintFile!.readAsBytes();
          final ext = _fingerprintFile!.name.split('.').last.toLowerCase();
          final mime = _getMimeType(ext);

          fingerprintUrl = await _applicantController.uploadImage(
            bytes,
            'fingerprint.$ext',
            mime,
          );
          print('DEBUG: Fingerprint uploaded: $fingerprintUrl');
        }

        final applicant = Applicant(
          id: '', // DB will generate ID
          name: name,
          age: age,
          location: location,
          businessGoal: businessGoal,
          fundingGoal: fundingGoal,
          maritalStatus: maritalStatus,
          familyMembers: familyMembers,
          division: division,
          district: district,
          upazilla: upazilla,
          thana: thana,
          currentOccupation: currentOccupation,
          photo: photoUrl,
          fingerprintPhoto: fingerprintUrl,
        );

        await _applicantController.addApplicant(applicant);

        // Success handling
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Applicant information submitted successfully!'),
              backgroundColor: Color(0xFF388e3c),
            ),
          );

          try {
            // Clear form
            _formKey.currentState?.reset();
            _nameController.clear();
            _ageController.clear();
            _locationController.clear();
            _businessGoalController.clear();
            _fundingGoalController.clear();
            _familyMembersController.clear();
            _divisionController.clear();
            _districtController.clear();
            _upazillaController.clear();
            _thanaController.clear();
            _currentOccupationController.clear();
            setState(() {
              _photoFile = null;
              _fingerprintFile = null;
              _selectedMaritalStatus = MaritalStatus.single;
              _isLoading = false;
            });
          } catch (cleanupError) {
            print('Cleanup error: $cleanupError');
            setState(() => _isLoading = false);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting applicant: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickPhoto() async {
    if (_isLoading) return;
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        setState(() {
          _photoFile = photo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
    }
  }

  Future<void> _pickFingerprint() async {
    if (_isLoading) return;
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        setState(() {
          _fingerprintFile = photo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking fingerprint: $e')));
    }
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and logout
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/Haat_Baran_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.favorite,
                          color: Color(0xFF388e3c),
                          size: 24,
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFF388e3c)),
                    onPressed: _handleLogout,
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
            // Centered title
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Volunteer Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388e3c),
                ),
              ),
            ),
            // Form content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF388e3c,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.person_add,
                                    size: 40,
                                    color: Color(0xFF388e3c),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Register New Applicant',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF388e3c),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Photo field
                            _buildPhotoField('Photo', _photoFile, _pickPhoto),
                            const SizedBox(height: 16),
                            // Fingerprint field
                            _buildPhotoField(
                              'Fingerprint Photo',
                              _fingerprintFile,
                              _pickFingerprint,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nameController,
                              label: 'Name',
                              icon: Icons.person,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _ageController,
                              label: 'Age',
                              icon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (int.tryParse(value!) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<MaritalStatus>(
                              initialValue: _selectedMaritalStatus,
                              decoration: _inputDecoration(
                                'Marital Status',
                                Icons.favorite,
                              ),
                              items: MaritalStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status == MaritalStatus.single
                                        ? 'Single'
                                        : status == MaritalStatus.married
                                        ? 'Married'
                                        : status == MaritalStatus.divorced
                                        ? 'Divorced'
                                        : 'Widowed',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(
                                    () => _selectedMaritalStatus = value,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _familyMembersController,
                              label: 'Family Members',
                              icon: Icons.people,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (int.tryParse(value!) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _divisionController,
                              label: 'Division',
                              icon: Icons.location_city,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _districtController,
                              label: 'District',
                              icon: Icons.location_city,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _upazillaController,
                              label: 'Upazilla',
                              icon: Icons.location_on,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _thanaController,
                              label: 'Thana',
                              icon: Icons.location_on,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _currentOccupationController,
                              label: 'Current Occupation',
                              icon: Icons.work,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _locationController,
                              label: 'Full Address',
                              icon: Icons.home,
                              maxLines: 2,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _businessGoalController,
                              label: 'Business Goal',
                              icon: Icons.business,
                              maxLines: 2,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _fundingGoalController,
                              label: 'Funding Goal (BDT)',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (double.tryParse(value!) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitApplicant,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF388e3c),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Submit Applicant Information',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF388e3c), width: 2),
      ),
    );
  }

  Widget _buildPhotoField(String label, XFile? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              label.contains('Fingerprint')
                  ? Icons.fingerprint
                  : Icons.camera_alt,
              color: const Color(0xFF388e3c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null
                    ? 'Image Selected: ${file.name}'
                    : 'Tap to select $label',
                style: TextStyle(
                  color: file != null ? Colors.black87 : Colors.grey,
                  fontWeight: file != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (file != null)
              const Icon(Icons.check_circle, color: Color(0xFF388e3c)),
          ],
        ),
      ),
    );
  }
}
