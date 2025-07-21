import 'package:flutter/material.dart';
import '../models/verse.dart';

class VerseDetailsDialog extends StatelessWidget {
  final Verse verse;

  const VerseDetailsDialog({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Verse for ${verse.date}'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            _buildDetailRow('English Verse:', verse.englishVerse),
            _buildDetailRow('English Ref:', verse.englishRef),
            const Divider(),
            _buildDetailRow('Malayalam Verse:', verse.malayalamVerse),
            _buildDetailRow('Malayalam Ref:', verse.malayalamRef),
            const Divider(),
            _buildDetailRow('Message Title:', verse.messageTitle),
            _buildDetailRow('Paragraph 1:', verse.messageParagraph1),
            _buildDetailRow('Paragraph 2:', verse.messageParagraph2),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}