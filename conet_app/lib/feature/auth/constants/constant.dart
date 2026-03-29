class AuthConstants {
  static const int generatedPasswordLength = 16;

  static const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String numberChars = '0123456789';
  static const String specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static const List<String> collegeOptions = [
    'Harvard University',
    'Stanford University',
    'MIT',
    'University of California, Berkeley',
    'Yale University',
  ];

  static const List<String> degreeOptions = [
    'B.A (Bachelor of Arts)',
    'B.S (Bachelor of Science)',
    'B.B.A (Bachelor of Business Administration)',
    'M.A (Master of Arts)',
    'M.S (Master of Science)',
  ];

  static const List<String> courseOptions = [
    'Economics',
    'Psychology',
    'English Literature',
    'History',
    'Political Science',
    'Computer Science',
    'Mathematics',
    'Business Administration',
  ];
}
