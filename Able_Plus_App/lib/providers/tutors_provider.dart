import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tutorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase.from('tutors').select();

    final tutors = List<Map<String, dynamic>>.from(response);

    final normalizedTutors = tutors.map((tutor) {
      final map = Map<String, dynamic>.from(tutor);

      map['id'] = map['id'] ?? map['auth_user_id'] ?? '';
      map['auth_user_id'] = map['auth_user_id'] ?? map['id'] ?? '';

      map['full_name'] = map['full_name'] ?? map['fullName'] ?? '';
      map['username'] = map['username'] ?? '';
      map['email'] = map['email'] ?? '';

      map['bio'] = map['bio'] ?? '';

      map['subject'] =
          map['subject'] ??
          map['subjects'] ??
          map['subject_text'] ??
          map['subjectText'] ??
          [];

      map['subjects'] = map['subjects'] ?? map['subject'];

      // لا نعتمد على location المخزنة في قاعدة البيانات
      // TutorScreen سيحسب المحافظة من latitude و longitude
      map['location'] = '';

      map['latitude'] = _toDouble(map['latitude']);
      map['longitude'] = _toDouble(map['longitude']);

      map['image_url'] =
          map['image_url'] ??
          map['avatar_url'] ??
          map['profile_image_url'] ??
          '';

      map['rating'] =
          map['rating'] ??
          map['avg_rating'] ??
          map['average_rating'] ??
          0;

      map['is_vip'] =
          map['is_vip'] ??
          map['isVip'] ??
          map['vip'] ??
          false;

      return map;
    }).toList();

    debugPrint('✅ tutorsProvider returned ${normalizedTutors.length} tutors');

    for (final tutor in normalizedTutors) {
      debugPrint(
        'Tutor: id=${tutor['id']}, username=${tutor['username']}, '
        'bio=${tutor['bio']}, subject=${tutor['subject']}, '
        'lat=${tutor['latitude']}, lng=${tutor['longitude']}',
      );
    }

    return normalizedTutors;
  } catch (e, stackTrace) {
    debugPrint('❌ tutorsProvider error: $e');
    debugPrint('❌ tutorsProvider stackTrace: $stackTrace');
    rethrow;
  }
});

double? _toDouble(dynamic value) {
  if (value == null) return null;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}