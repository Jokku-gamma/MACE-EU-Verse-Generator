class Verse {
  final String date;
  final String malayalamVerse;
  final String malayalamRef;
  final String englishVerse;
  final String englishRef;
  final String messageTitle;
  final String messageParagraph1;
  final String messageParagraph2;

  Verse({
    required this.date,
    required this.malayalamVerse,
    required this.malayalamRef,
    required this.englishVerse,
    required this.englishRef,
    required this.messageTitle,
    required this.messageParagraph1,
    required this.messageParagraph2,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      date: json['date'] as String,
      malayalamVerse: json['malayalam_verse'] as String,
      malayalamRef: json['malayalam_ref'] as String,
      englishVerse: json['english_verse'] as String,
      englishRef: json['english_ref'] as String,
      messageTitle: json['message_title'] as String,
      messageParagraph1: json['message_paragraph1'] as String,
      messageParagraph2: json['message_paragraph2'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'malayalam_verse': malayalamVerse,
      'malayalam_ref': malayalamRef,
      'english_verse': englishVerse,
      'english_ref': englishRef,
      'message_title': messageTitle,
      'message_paragraph1': messageParagraph1,
      'message_paragraph2': messageParagraph2,
    };
  }
}