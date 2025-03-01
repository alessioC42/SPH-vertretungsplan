import 'package:flutter/material.dart';
import 'package:sph_plan/applets/timetable/student/student_timetable_better_view.dart';

class TimetableSubject {
  // The ID is not nullable, to support legacy data where the ID was not present
  String? id;
  String? name;
  String? raum;
  String? lehrer;
  String? badge;
  int duration;
  TimeOfDay startTime;
  TimeOfDay endTime;
  // Row index in the timetable
  int? stunde;

  TimetableSubject(
      {required this.id,
      required this.name,
      required this.raum,
      required this.lehrer,
      required this.badge,
      required this.duration,
      required this.startTime,
      required this.endTime,
      required this.stunde});

  @override
  String toString() {
    return "(Id: $id, Fach: $name, Raum: $raum, Lehrer: $lehrer, Badge: $badge, Dauer: $duration (${startTime.hour}:${startTime.minute}-${endTime.hour}:${endTime.minute}))";
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "raum": raum,
      "lehrer": lehrer,
      "badge": badge,
      "duration": duration,
      "startTime": [startTime.hour, startTime.minute],
      "endTime": [endTime.hour, endTime.minute],
      "stunde": stunde
    };
  }

  factory TimetableSubject.fromJson(Map<String, dynamic> json) {
    return TimetableSubject(
        id: json["id"],
        name: json["name"],
        raum: json["raum"],
        lehrer: json["lehrer"],
        badge: json["badge"],
        duration: json["duration"],
        stunde: json["stunde"],
        startTime:
            TimeOfDay(hour: json["startTime"][0], minute: json["startTime"][1]),
        endTime:
            TimeOfDay(hour: json["endTime"][0], minute: json["endTime"][1]));
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (other is TimetableSubject) {
      return id == other.id &&
          name == other.name &&
          raum == other.raum &&
          lehrer == other.lehrer &&
          badge == other.badge &&
          duration == other.duration &&
          stunde == other.stunde &&
          startTime == other.startTime &&
          endTime == other.endTime;
    }
    return false;
  }
}

typedef TimetableDay = List<TimetableSubject>;

enum TimeTableType { all, own }

class TimeTable {
  List<TimetableDay>? planForAll;
  List<TimetableDay>? planForOwn;
  List<TimeTableRow>? hours;
  String? weekBadge;

  TimeTable({this.planForAll, this.planForOwn, this.weekBadge, this.hours});

  // JSON operations
  TimeTable.fromJson(Map<String, dynamic> json) {
    planForAll = (json['planForAll'] as List?)
        ?.map((day) => (day as List)
            .map((fach) =>
                TimetableSubject.fromJson(fach as Map<String, dynamic>))
            .toList())
        .toList();
    planForOwn = (json['planForOwn'] as List?)
        ?.map((day) => (day as List)
            .map((fach) =>
                TimetableSubject.fromJson(fach as Map<String, dynamic>))
            .toList())
        .toList();
    hours = (json['hours'] as List?)
        ?.map((hour) => TimeTableRow.fromJson(hour as Map<String, dynamic>))
        .toList();
    weekBadge = json['weekBadge'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['planForAll'] = planForAll
        ?.map((day) => day.map((fach) => fach.toJson()).toList())
        .toList();
    data['planForOwn'] = planForOwn
        ?.map((day) => day.map((fach) => fach.toJson()).toList())
        .toList();
    data['hours'] = hours?.map((hour) => hour.toJson()).toList();
    data['weekBadge'] = weekBadge;
    return data;
  }
}
