import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/verse.dart';

class VerseApiService {
  final String _backendUrl = 'https://mace-eu-verse-backend.onrender.com';

  Future<List<String>> fetchExistingVerseDates() async {
    try {
      final response =
          await http.get(Uri.parse('$_backendUrl/get_existing_verse_dates'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['dates']);
        } else {
          throw data['message'] ?? 'Failed to fetch existing dates: Unknown backend error.';
        }
      } else {
        throw 'Server error fetching existing dates: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Verse?> getVerseByDate(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/get_verse_content_by_date?date=${Uri.encodeComponent(date)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['verse'] != null) {
          return Verse.fromJson(data['verse']);
        } else if (data['success'] == false) {
          throw data['message'] ?? 'Failed to fetch verse: Unknown backend error.';
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw 'Server error fetching verse: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadVerse(Verse verse) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/generate_and_upload_verse'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(verse.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] != true) {
          throw responseData['message'] ?? 'Failed to upload verse: Unknown backend error.';
        }
      } else if (response.statusCode == 409) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw responseData['message'] ?? 'A verse for this date already exists.';
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw 'Failed to upload verse: ${responseData['message'] ?? 'Server error ${response.statusCode}'}';
      }
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Fetch the latest date a verse was added
  Future<String?> fetchLatestVerseDate() async {
    try {
      final response =
          await http.get(Uri.parse('$_backendUrl/get_latest_verse_date'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['latest_date'] as String?; // Will be null if no verses
        } else {
          throw data['message'] ?? 'Failed to fetch latest verse date: Unknown backend error.';
        }
      } else {
        throw 'Server error fetching latest verse date: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }
}