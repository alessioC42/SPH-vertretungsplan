import 'package:flutter/material.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/applets/definitions.dart';
import 'package:sph_plan/applets/study_groups/background.dart';
import 'package:sph_plan/applets/study_groups/student/student_study_groups_view.dart';

import '../../models/account_types.dart';

final studyGroupsDefinition = AppletDefinition(
  appletPhpUrl: 'lerngruppen.php',
  addDivider: false,
  appletType: AppletType.navigation,
  icon: const Icon(Icons.groups),
  selectedIcon: const Icon(Icons.groups_outlined),
  label: (context) => AppLocalizations.of(context).studyGroups,
  supportedAccountTypes: [AccountType.student],
  allowOffline: true,
  settingsDefaults: {
    'showExams': 'true',
  },
  notificationTask: studyCheckExams,
  refreshInterval: const Duration(minutes: 15),
  bodyBuilder: (context, accountType, openDrawerCb) {
    return StudentStudyGroupsView();
  },
);
