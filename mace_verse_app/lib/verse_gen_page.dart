import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/verse.dart';
import '../services/auth_service.dart';
import '../services/verse_api_service.dart';
import '../widgets/verse_detail_widget.dart';

class VerseGeneratorPage extends StatefulWidget {
  const VerseGeneratorPage({super.key});

  @override
  State<VerseGeneratorPage> createState() => _VerseGeneratorPageState();
}

class _VerseGeneratorPageState extends State<VerseGeneratorPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _malayalamVerseController = TextEditingController();
  final TextEditingController _malayalamRefController = TextEditingController();
  final TextEditingController _englishVerseController = TextEditingController();
  final TextEditingController _englishRefController = TextEditingController();
  final TextEditingController _messageTitleController = TextEditingController();
  final TextEditingController _messageParagraph1Controller = TextEditingController();
  final TextEditingController _messageParagraph2Controller = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  List<String> _existingDates = [];
  String? _latestVerseDate; // NEW: To store the latest added verse date

  final VerseApiService _verseApiService = VerseApiService();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    _fetchInitialData(); // Call a new method to fetch all needed data
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch existing dates
      final dates = await _verseApiService.fetchExistingVerseDates();
      // Fetch latest verse date
      final latestDate = await _verseApiService.fetchLatestVerseDate();

      setState(() {
        _existingDates = dates;
        _latestVerseDate = latestDate;
      });
    } catch (e) {
      _showSnackBar('Error loading data: $e', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearVerseInputFields() {
    _malayalamVerseController.clear();
    _malayalamRefController.clear();
    _englishVerseController.clear();
    _englishRefController.clear();
    _messageTitleController.clear();
    _messageParagraph1Controller.clear();
    _messageParagraph2Controller.clear();
  }

  void _clearForm() {
    _dateController.clear();
    _selectedDate = null;
    _clearVerseInputFields();
    _formKey.currentState?.reset(); // Reset form validation state
  }

  Future<void> _submitVerse() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        _showSnackBar('Please select a date.', false);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final verse = Verse(
        date: _dateController.text,
        malayalamVerse: _malayalamVerseController.text,
        malayalamRef: _malayalamRefController.text,
        englishVerse: _englishVerseController.text,
        englishRef: _englishRefController.text,
        messageTitle: _messageTitleController.text,
        messageParagraph1: _messageParagraph1Controller.text,
        messageParagraph2: _messageParagraph2Controller.text,
      );

      try {
        await _verseApiService.uploadVerse(verse);
        _showSnackBar('Verse uploaded successfully!', true);
        _clearForm();
        await _fetchInitialData(); // Re-fetch all data to update latest date and existing dates
      } catch (e) {
        _showSnackBar('Failed to upload verse: $e', false);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _showSnackBar('Error signing out: $e', false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Parse _latestVerseDate into a DateTime object for comparison
    DateTime? latestVerseDateTime;
    if (_latestVerseDate != null) {
      try {
        latestVerseDateTime = DateFormat('MMMM dd, yyyy').parse(_latestVerseDate!);
      } catch (e) {
        debugPrint('Error parsing _latestVerseDate: $e');
        latestVerseDateTime = null; // Reset if parsing fails
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
              ),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
            ),
          ),
          child: child!,
        );
      },
      // NEW: Add selectableDayPredicate for blurring/disabling dates
      selectableDayPredicate: (DateTime day) {
        final String formattedDay = DateFormat('MMMM dd, yyyy').format(day);
        
        // Always selectable if it's an existing verse date
        if (_existingDates.contains(formattedDay)) {
          return true;
        }

        // If there's a latest verse date, disable dates before it that are NOT existing
        if (latestVerseDateTime != null) {
          // Check if 'day' is strictly before 'latestVerseDateTime'
          if (day.isBefore(latestVerseDateTime!)) {
            return false; // Disable if before latest and not existing
          }
        }
        
        // Allow selection for future dates or dates on/after the latest verse date
        // and also allow the current date to be selectable
        return true;
      },
    );

    if (picked != null) {
      final String formattedPickedDate = DateFormat('MMMM dd, yyyy').format(picked);

      if (_existingDates.contains(formattedPickedDate)) {
        await _fetchAndDisplayVerseDetails(formattedPickedDate);
        // Do not update form fields for existing dates when just viewing
      } else if (picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
          _dateController.text = formattedPickedDate;
          _clearVerseInputFields(); // Clear for new entry
        });
      }
    }
  }

  Future<void> _fetchAndDisplayVerseDetails(String date) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final Verse? verse = await _verseApiService.getVerseByDate(date);
      if (verse != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return VerseDetailsDialog(verse: verse);
            },
          );
        }
      } else {
        _showSnackBar('No verse found for $date.', false);
      }
    } catch (e) {
      _showSnackBar('Error fetching verse details: $e', false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MACE EU Verse Generator'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading && _existingDates.isEmpty && _latestVerseDate == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // NEW: Display latest verse date
                    if (_latestVerseDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Latest Verse Added: $_latestVerseDate',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _malayalamVerseController,
                      decoration: InputDecoration(
                        labelText: 'Malayalam Verse',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the Malayalam verse';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _malayalamRefController,
                      decoration: InputDecoration(
                        labelText: 'Malayalam Reference (e.g., മത്തായി 5:3)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the Malayalam reference';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _englishVerseController,
                      decoration: InputDecoration(
                        labelText: 'English Verse',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the English verse';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _englishRefController,
                      decoration: InputDecoration(
                        labelText: 'English Reference (e.g., Matthew 5:3)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the English reference';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _messageTitleController,
                      decoration: InputDecoration(
                        labelText: 'Message Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a message title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _messageParagraph1Controller,
                      decoration: InputDecoration(
                        labelText: 'Message Paragraph 1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the first message paragraph';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _messageParagraph2Controller,
                      decoration: InputDecoration(
                        labelText: 'Message Paragraph 2',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the second message paragraph';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitVerse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              'Generate & Upload Verse',
                              style: TextStyle(fontSize: 18.0),
                            ),
                    ),
                    const SizedBox(height: 12.0),
                    TextButton(
                      onPressed: _isLoading ? null : _clearForm,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                      child: const Text('Clear Form'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _malayalamVerseController.dispose();
    _malayalamRefController.dispose();
    _englishVerseController.dispose();
    _englishRefController.dispose();
    _messageTitleController.dispose();
    _messageParagraph1Controller.dispose();
    _messageParagraph2Controller.dispose();
    super.dispose();
  }
}