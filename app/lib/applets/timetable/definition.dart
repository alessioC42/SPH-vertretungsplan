import 'package:flutter/material.dart';
import 'package:sph_plan/applets/definitions.dart';
import 'package:sph_plan/applets/timetable/student/student_timetable_better_view.dart';
import 'package:sph_plan/generated/l10n.dart';

import '../../models/account_types.dart';

final timeTableDefinition = AppletDefinition(
  appletPhpUrl: 'stundenplan.php',
  icon: Icon(Icons.timelapse),
  selectedIcon: Icon(Icons.timelapse_outlined),
  appletType: AppletType.nested,
  addDivider: false,
  label: (context) => AppLocalizations.of(context).timeTable,
  supportedAccountTypes: [AccountType.student],
  refreshInterval: Duration(hours: 1),
  allowOffline: true,
  settingsDefaults: {
    'student-selected-type': 'TimeTableType.own',
    'current-timetable-view': 'CalendarView.workWeek',
  },
  bodyBuilder: (context, accountType, openDrawerCb) {
    if (accountType == AccountType.student) {
      return StudentTimetableBetterView(openDrawerCb: openDrawerCb);
    } else {
      return Placeholder();
    }
  },
);
