import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Required for date formatting

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MACE EU Verse Generator',
      theme: ThemeData(
        primarySwatch: Colors.green,
        // Define primary color directly for a more modern look
        primaryColor: const Color(0xFF4CAF50), // A standard green
        scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Light gray background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50), // Green app bar
          foregroundColor: Colors.white, // White text/icons on app bar
          elevation: 0, // No shadow for app bar
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none, // No border for a cleaner look
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)), // Light border when enabled
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF28A745), width: 2.0), // Darker green when focused
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50), // Green button
            foregroundColor: Colors.white, // White text
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 3,
            shadowColor: const Color(0xFF28A745).withOpacity(0.4), // Subtle shadow
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          margin: const EdgeInsets.all(12.0), // Consistent margin for cards
        ),
        // Use 'Open Sans' from Google Fonts if available, otherwise default
        fontFamily: 'Open Sans',
      ),
      debugShowCheckedModeBanner: false,
      home: const VerseGeneratorPage(),
    );
  }
}

class VerseGeneratorPage extends StatefulWidget {
  const VerseGeneratorPage({super.key});

  @override
  State<VerseGeneratorPage> createState() => _VerseGeneratorPageState();
}

class _VerseGeneratorPageState extends State<VerseGeneratorPage> {
  final _backendUrl =
      'https://mace-eu-verse-backend.onrender.com'; // Your Render backend URL
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _malayalamVerseController = TextEditingController();
  final TextEditingController _malayalamRefController = TextEditingController();
  final TextEditingController _englishVerseController = TextEditingController();
  final TextEditingController _englishRefController = TextEditingController();
  final TextEditingController _messageTitleController = TextEditingController();
  final TextEditingController _messagePara1Controller = TextEditingController();
  final TextEditingController _messagePara2Controller = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isFetchingDates = false; // New state for fetching dates
  List<String> _existingDates = []; // Stores dates in "MMMM dd, yyyy" format

  @override
  void initState() {
    super.initState();
    _fetchExistingDates(); // Fetch dates when the app starts
  }

  Future<void> _fetchExistingDates() async {
    setState(() {
      _isFetchingDates = true;
    });

    try {
      final response =
          await http.get(Uri.parse('$_backendUrl/get_existing_verse_dates'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _existingDates = List<String>.from(data['dates']);
          });
          //print('Fetched existing dates: $_existingDates'); // For debugging
        } else {
          _showSnackBar(
              'Failed to fetch existing dates: ${data['message']}', false);
        }
      } else {
        _showSnackBar(
            'Server error fetching existing dates: ${response.statusCode}',
            false);
      }
    } catch (e) {
      _showSnackBar('Error fetching existing dates: $e', false);
    } finally {
      setState(() {
        _isFetchingDates = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023), // Start from a reasonable past date
      lastDate: DateTime(2030), // End in the near future
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50), // Button text color
              ),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0), // Rounded corners
              ),
            ),
          ),
          child: child!,
        );
      },
      // Here's the key logic for hiding/disabling dates
      selectableDayPredicate: (DateTime day) {
        // 1. Disable dates before today
        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);
        if (day.isBefore(today)) {
          return false; // Cannot select past dates
        }

        // 2. Disable dates that are already existing
        final String formattedDay = DateFormat('MMMM dd, yyyy').format(day);
        return !_existingDates.contains(formattedDay); // Return false if date exists, true if not
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMMM dd, yyyy').format(_selectedDate!);
      });
    }
  }

  Future<void> _submitVerse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Please select a date for the verse.', false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String formattedDate =
        DateFormat('MMMM dd, yyyy').format(_selectedDate!);

    final Map<String, dynamic> data = {
      'date': formattedDate,
      'malayalam_verse': _malayalamVerseController.text,
      'malayalam_ref': _malayalamRefController.text,
      'english_verse': _englishVerseController.text,
      'english_ref': _englishRefController.text,
      'message_title': _messageTitleController.text,
      'message_paragraph1': _messagePara1Controller.text,
      'message_paragraph2': _messagePara2Controller.text,
    };

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/generate_and_upload_verse'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Verse uploaded successfully!', true);
        _clearForm();
        await _fetchExistingDates(); // Re-fetch dates after successful upload
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _showSnackBar(
            'Failed to upload verse: ${responseData['message'] ?? 'Unknown error'}',
            false);
      }
    } catch (e) {
      _showSnackBar('Error uploading verse: $e', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    _dateController.clear();
    _malayalamVerseController.clear();
    _malayalamRefController.clear();
    _englishVerseController.clear();
    _englishRefController.clear();
    _messageTitleController.clear();
    _messagePara1Controller.clear();
    _messagePara2Controller.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _malayalamVerseController.dispose();
    _malayalamRefController.dispose();
    _englishVerseController.dispose();
    _englishRefController.dispose();
    _messageTitleController.dispose();
    _messagePara1Controller.dispose();
    _messagePara2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MACE EU Verse Generator'),
      ),
      body: _isFetchingDates
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching existing verse dates...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Select Date',
                                hintText: 'Tap to choose a date',
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: _selectedDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _selectedDate = null;
                                            _dateController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a date.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _malayalamVerseController,
                              decoration: const InputDecoration(
                                labelText: 'Malayalam Verse',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 5,
                              minLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the Malayalam verse.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _malayalamRefController,
                              decoration: const InputDecoration(
                                labelText: 'Malayalam Reference (e.g., യോഹന്നാൻ 3:16)',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the Malayalam reference.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _englishVerseController,
                              decoration: const InputDecoration(
                                labelText: 'English Verse',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 5,
                              minLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the English verse.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _englishRefController,
                              decoration: const InputDecoration(
                                labelText: 'English Reference (e.g., John 3:16)',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the English reference.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _messageTitleController,
                              decoration: const InputDecoration(
                                labelText: 'Message Title',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the message title.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messagePara1Controller,
                              decoration: const InputDecoration(
                                labelText: 'Message Paragraph 1',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 7,
                              minLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter message paragraph 1.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messagePara2Controller,
                              decoration: const InputDecoration(
                                labelText: 'Message Paragraph 2',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 7,
                              minLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter message paragraph 2.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submitVerse,
                            child: const Text('Generate & Upload Verse'),
                          ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _clearForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey, // Grey button for clear
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear Form'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}