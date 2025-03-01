import 'package:flutter/material.dart';
import 'package:sph_plan/models/timetable.dart';
import 'package:sph_plan/utils/random_color.dart';

class TimeTableHelper {
  static Color getColorForLesson(dynamic settings, lesson) {
    if (settings['lesson-colors'] == null) {
      return RandomColor.bySeed(lesson.name!).primary;
    }
    if (settings['lesson-colors'][lesson.id.split('-')[0]] != null) {
      return Color(int.parse(settings['lesson-colors'][lesson.id.split('-')[0]],
          radix: 16));
    }
    return RandomColor.bySeed(lesson.name!).primary;
  }

  static List<List<T>> mergeByIndices<T>(
      List<List<T>> list1, List<List<T>>? list2) {
    final int maxLength = list1.length > (list2?.length ?? 0)
        ? list1.length
        : (list2?.length ?? 0);

    final List<List<T>> result = List.generate(maxLength, (index) {
      List<T> combined = [];
      if (index < list1.length) combined.addAll(list1[index]);

      if (list2 != null && index < list2.length) {
        combined.addAll(list2[index]);
      }
      return combined;
    });

    return result;
  }

  static List<List<TimetableSubject>>? getCustomLessons(
      Map<String, dynamic> settings) {
    return settings['custom-lessons'] == null
        ? null
        : (settings['custom-lessons'] as List)
            .map((e) => (e as List).map((item) {
                  if (item.runtimeType == TimetableSubject) {
                    return item as TimetableSubject;
                  }
                  return TimetableSubject.fromJson(item);
                }).toList())
            .toList();
  }
}
