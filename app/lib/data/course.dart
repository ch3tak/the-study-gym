import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A course the student studies (spec "Decisions" 1–2). Only one is live;
/// the others are listed so the switcher is honest about what's coming.
class Course {
  const Course({required this.id, required this.shortLabel, required this.title, required this.available});

  /// The `subjects.id` the course is built from.
  final String id;

  /// Chip text, e.g. "Class 9".
  final String shortLabel;
  final String title;
  final bool available;
}

class Courses {
  Courses._();

  static const all = [
    Course(id: 'cbse_9_maths', shortLabel: 'Class 9', title: 'CBSE Class 9 Maths', available: true),
    Course(id: 'cbse_10_maths_standard', shortLabel: 'Class 10', title: 'CBSE Class 10 Maths', available: false),
  ];
}

/// The course Home and Learn show. One live course for now; switching
/// between several comes with onboarding (Slice 5).
final activeCourseProvider = Provider<Course>((ref) => Courses.all.firstWhere((c) => c.available));
