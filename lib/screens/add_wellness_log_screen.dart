import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddWellnessLogScreen extends StatefulWidget {
  const AddWellnessLogScreen({super.key});

  @override
  State<AddWellnessLogScreen> createState() => _AddWellnessLogScreenState();
}

class _AddWellnessLogScreenState extends State<AddWellnessLogScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  String? _selectedLogType;

  final List<String> _logTypes = [
    'sleep', 'mood', 'water', 'exercise', 'weight',
    'bloodPressure', 'heartRate', 'medicationIntake', 'dietLog', 'mentalHealthCheck'
  ];

  // --- TextEditingControllers for various fields ---
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _sleepQualityController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _medicationNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // --- State variables for units or specific dropdowns ---
  String? _waterUnit = 'ml';
  final List<String> _waterUnits = ['ml', 'oz', 'glasses'];

  String? _sleepUnit = 'hours';
  final List<String> _sleepUnits = ['hours', 'minutes'];

  String? _bpUnit = 'mmHg';

  String? _exerciseDurationUnit = 'minutes';
  final List<String> _exerciseDurationUnits = ['minutes', 'hours'];

  String? _selectedCategory;
  final List<String> _categories = ['physical', 'emotional', 'medical', 'nutrition', 'activity', 'other'];

  String? _selectedDeviceSource = 'manual';
  final List<String> _deviceSources = ['manual', 'smartwatch', 'app', 'health_kit_ios', 'google_fit_android', 'other'];

  // Helper method to get log type icons
  IconData _getLogTypeIcon(String logType) {
    switch (logType) {
      case 'sleep': return Icons.bedtime;
      case 'mood': return Icons.mood;
      case 'water': return Icons.water_drop;
      case 'exercise': return Icons.fitness_center;
      case 'weight': return Icons.scale;
      case 'bloodPressure': return Icons.favorite;
      case 'heartRate': return Icons.monitor_heart;
      case 'medicationIntake': return Icons.medication;
      case 'dietLog': return Icons.restaurant;
      case 'mentalHealthCheck': return Icons.psychology;
      default: return Icons.health_and_safety;
    }
  }

  // Helper method to get log type colors
  Color _getLogTypeColor(String logType) {
    switch (logType) {
      case 'sleep': return Colors.indigo.shade300;
      case 'mood': return Colors.orange.shade300;
      case 'water': return Colors.blue.shade300;
      case 'exercise': return Colors.red.shade300;
      case 'weight': return Colors.purple.shade300;
      case 'bloodPressure': return Colors.pink.shade300;
      case 'heartRate': return Colors.green.shade400;
      case 'medicationIntake': return Colors.teal.shade300;
      case 'dietLog': return Colors.brown.shade300;
      case 'mentalHealthCheck': return Colors.deepPurple.shade300;
      default: return const Color(0xFF2DD4BF);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _valueController.dispose();
    _sleepQualityController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _medicationNameController.dispose();
    _dosageController.dispose();
    _activityNameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2DD4BF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Helper to clear specific controllers when log type changes
  void _clearSpecificFieldControllers() {
    _valueController.clear();
    _sleepQualityController.clear();
    _systolicController.clear();
    _diastolicController.clear();
    _medicationNameController.clear();
    _dosageController.clear();
    _activityNameController.clear();
    _durationController.clear();
    _waterUnit = 'ml';
    _sleepUnit = 'hours';
    _exerciseDurationUnit = 'minutes';
  }

  // Enhanced input field builder
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? suffix,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2DD4BF), size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // Enhanced dropdown builder
  Widget _buildEnhancedDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemBuilder,
    String? Function(T?)? validator,
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2DD4BF), size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        value: value,
        isExpanded: true,
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(itemBuilder(item), style: const TextStyle(fontSize: 16)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  // Widget builder for dynamic fields based on log type
  Widget _buildDynamicInputFields() {
    if (_selectedLogType == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Select a log type to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> fields = [];

    // Add a header for the selected log type
    fields.add(
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getLogTypeColor(_selectedLogType!),
              _getLogTypeColor(_selectedLogType!).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getLogTypeColor(_selectedLogType!).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getLogTypeIcon(_selectedLogType!),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLogType!.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your $_selectedLogType data',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    switch (_selectedLogType) {
      case 'water':
        fields.addAll([
          _buildEnhancedTextField(
            controller: _valueController,
            label: 'Amount Consumed',
            icon: Icons.water_drop,
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Please enter amount' : null,
          ),
          _buildEnhancedDropdown<String>(
            label: 'Unit',
            icon: Icons.straighten,
            value: _waterUnit,
            items: _waterUnits,
            itemBuilder: (unit) => unit,
            onChanged: (val) => setState(() => _waterUnit = val),
            validator: (val) => val == null ? 'Please select unit' : null,
          ),
        ]);
        break;

      case 'sleep':
        fields.addAll([
          _buildEnhancedTextField(
            controller: _valueController,
            label: 'Duration Slept',
            icon: Icons.bedtime,
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Please enter duration' : null,
          ),
          _buildEnhancedDropdown<String>(
            label: 'Unit',
            icon: Icons.schedule,
            value: _sleepUnit,
            items: _sleepUnits,
            itemBuilder: (unit) => unit,
            onChanged: (val) => setState(() => _sleepUnit = val),
            validator: (val) => val == null ? 'Please select unit' : null,
          ),
          _buildEnhancedTextField(
            controller: _sleepQualityController,
            label: 'Sleep Quality (Good, Fair, or 1-5)',
            icon: Icons.star_rate,
            validator: (val) => val == null || val.isEmpty ? 'Please enter sleep quality' : null,
          ),
        ]);
        break;

      case 'bloodPressure':
        fields.addAll([
          _buildEnhancedTextField(
            controller: _systolicController,
            label: 'Systolic (e.g., 120)',
            icon: Icons.favorite,
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Enter systolic value' : null,
          ),
          _buildEnhancedTextField(
            controller: _diastolicController,
            label: 'Diastolic (e.g., 80)',
            icon: Icons.monitor_heart,
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Enter diastolic value' : null,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text('Unit: $_bpUnit', style: TextStyle(fontSize: 16, color: Colors.blue.shade600)),
              ],
            ),
          ),
        ]);
        break;

      case 'medicationIntake':
        fields.addAll([
          _buildEnhancedTextField(
            controller: _medicationNameController,
            label: 'Medication Name',
            icon: Icons.medication,
            validator: (val) => val == null || val.isEmpty ? 'Enter medication name' : null,
          ),
          _buildEnhancedTextField(
            controller: _dosageController,
            label: 'Dosage (e.g., 500mg, 1 tablet)',
            icon: Icons.healing,
            validator: (val) => val == null || val.isEmpty ? 'Enter dosage' : null,
          ),
        ]);
        break;

      case 'exercise':
        fields.addAll([
          _buildEnhancedTextField(
            controller: _activityNameController,
            label: 'Activity Name (e.g., Running)',
            icon: Icons.fitness_center,
            validator: (val) => val == null || val.isEmpty ? 'Enter activity name' : null,
          ),
          _buildEnhancedTextField(
            controller: _durationController,
            label: 'Duration',
            icon: Icons.timer,
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Enter duration' : null,
          ),
          _buildEnhancedDropdown<String>(
            label: 'Unit for Duration',
            icon: Icons.schedule,
            value: _exerciseDurationUnit,
            items: _exerciseDurationUnits,
            itemBuilder: (unit) => unit,
            onChanged: (val) => setState(() => _exerciseDurationUnit = val),
            validator: (val) => val == null ? 'Please select unit' : null,
          ),
        ]);
        break;

      case 'mood':
      case 'weight':
      case 'heartRate':
      case 'mentalHealthCheck':
        fields.add(
          _buildEnhancedTextField(
            controller: _valueController,
            label: 'Value for $_selectedLogType',
            icon: _getLogTypeIcon(_selectedLogType!),
            keyboardType: (_selectedLogType == 'mood' || _selectedLogType == 'mentalHealthCheck') ? TextInputType.text : TextInputType.number,
            validator: (val) => val == null || val.isEmpty ? 'Please enter value' : null,
          )
        );
        break;

      default:
        fields.add(
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.construction, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fields for this log type are under development',
                    style: TextStyle(color: Colors.orange.shade600, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
    }

    return Column(children: fields);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Add Wellness Log',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 37, 49, 60),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Date Picker Card
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today, color: Color(0xFF2DD4BF)),
                    ),
                    title: const Text(
                      'Log Date',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    subtitle: Text(
                      DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF2DD4BF)),
                    onTap: () => _pickDate(context),
                  ),
                ),

                // Log Type Dropdown
                _buildEnhancedDropdown<String>(
                  label: 'Log Type',
                  icon: Icons.category_outlined,
                  value: _selectedLogType,
                  items: _logTypes,
                  itemBuilder: (type) => type.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase()),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLogType = newValue;
                      _clearSpecificFieldControllers();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a log type';
                    }
                    return null;
                  },
                  hint: 'Select type of log',
                ),

                // Dynamic Input Fields
                _buildDynamicInputFields(),
                const SizedBox(height: 20),

                // Category Dropdown
                _buildEnhancedDropdown<String>(
                  label: 'Category',
                  icon: Icons.class_outlined,
                  value: _selectedCategory,
                  items: _categories,
                  itemBuilder: (category) => category[0].toUpperCase() + category.substring(1),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  hint: 'Select category (optional)',
                ),

                // Device Source Dropdown
                _buildEnhancedDropdown<String>(
                  label: 'Data Source',
                  icon: Icons.device_hub_outlined,
                  value: _selectedDeviceSource,
                  items: _deviceSources,
                  itemBuilder: (source) => source.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase()),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDeviceSource = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a data source';
                    }
                    return null;
                  },
                  hint: 'Select data source',
                ),

                // Notes Field
                _buildEnhancedTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  icon: Icons.note_alt_outlined,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Save Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2DD4BF), Color(0xFF1DB8A8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DD4BF).withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        User? currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: No user logged in. Please log in again.')),
                          );
                          return;
                        }
                        String userId = currentUser.uid;

                        Map<String, dynamic> logData = {
                          'timestamp': _selectedDate,
                          'entryDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
                          'logType': _selectedLogType,
                          'notes': _notesController.text.trim(),
                          'category': _selectedCategory,
                          'deviceSource': _selectedDeviceSource,
                          'userId': userId,
                        };

                        switch (_selectedLogType) {
                          case 'water':
                            logData['value'] = num.tryParse(_valueController.text.trim());
                            logData['unit'] = _waterUnit;
                            break;
                          case 'sleep':
                            logData['value'] = num.tryParse(_valueController.text.trim());
                            logData['unit'] = _sleepUnit;
                            logData['quality'] = _sleepQualityController.text.trim();
                            break;
                          case 'bloodPressure':
                            logData['systolic'] = int.tryParse(_systolicController.text.trim());
                            logData['diastolic'] = int.tryParse(_diastolicController.text.trim());
                            logData['unit'] = _bpUnit;
                            break;
                          case 'medicationIntake':
                            logData['medicationName'] = _medicationNameController.text.trim();
                            logData['dosage'] = _dosageController.text.trim();
                            logData['timeTaken'] = _selectedDate;
                            break;
                          case 'exercise':
                            logData['activityName'] = _activityNameController.text.trim();
                            logData['duration'] = num.tryParse(_durationController.text.trim());
                            logData['unitDuration'] = _exerciseDurationUnit;
                            break;
                          case 'mood':
                            logData['value'] = _valueController.text.trim();
                            break;
                          case 'weight':
                            logData['value'] = num.tryParse(_valueController.text.trim());
                            break;
                          case 'heartRate':
                            logData['value'] = int.tryParse(_valueController.text.trim());
                            logData['unit'] = 'bpm';
                            break;
                          case 'mentalHealthCheck':
                            logData['checkInValue'] = _valueController.text.trim();
                            break;
                          case 'dietLog':
                            logData['mealDescription'] = _valueController.text.trim();
                            break;
                        }

                        Map<String, dynamic> finalLogData = {};
                        logData.forEach((key, value) {
                          if (value != null) {
                            finalLogData[key] = value;
                          } else if (key == 'category' || key == 'notes') {
                            finalLogData[key] = value;
                          }
                        });

                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('wellnessLogs')
                              .add(finalLogData);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Log saved successfully!'),
                                  ],
                                ),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(10),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text('Error saving log: ${e.toString()}')),
                                  ],
                                ),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(10),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      'Save Log',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}