import 'package:flutter/material.dart';

extension ComparableTimeOfDay on TimeOfDay {
  bool operator <(TimeOfDay other) =>
      (hour * 60 + minute) < (other.hour * 60 + other.minute);

  bool operator >(TimeOfDay other) =>
      (hour * 60 + minute) > (other.hour * 60 + other.minute);
}

extension ParsableTimeOfDay on TimeOfDay {
  double toTimeDouble() => hour + minute / 60.0;

  TimeOfDay ceil() {
    if (minute > 0) {
      return TimeOfDay(hour: hour + 1, minute: 0);
    }
    return this;
  }

  TimeOfDay floor() {
    return TimeOfDay(hour: hour, minute: 0);
  }
}
