import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sph_plan/applets/definitions.dart';
import 'package:sph_plan/core/database/account_database/account_db.dart';
import 'package:sph_plan/core/database/account_database/kv_defaults.dart';
import 'package:sph_plan/utils/switch_tile.dart';
import 'package:sph_plan/view/settings/settings_page_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../core/sph/sph.dart';
import '../../../utils/callout.dart';
import '../../../utils/slider_tile.dart';

class NotificationSettings extends SettingsColours {
  final int accountCount;

  const NotificationSettings({super.key, required this.accountCount});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState
    extends SettingsColoursState<NotificationSettings> {
  final Map<String, AppletDefinition> supportedApplets = {};

  double androidNotificationInterval = kvDefaults['notifications-android-target-interval-minutes'].toDouble();
  List<bool> androidEnabledDays = kvDefaults['notifications-android-allowed-days'];
  TimeOfDay androidStartTime = TimeOfDay(hour: kvDefaults['notifications-android-start-time'][0], minute: kvDefaults['notifications-android-start-time'][1]);
  TimeOfDay androidEndTime = TimeOfDay(hour: kvDefaults['notifications-android-end-time'][0], minute: kvDefaults['notifications-android-end-time'][1]);
  
  PermissionStatus notificationPermissionStatus = PermissionStatus.provisional;
  Timer? checkTimer;

  List<String> getDatabaseKeys() {
    List<String> result = ["notifications-allow"];

    // Get supported applets
    for (final applet
        in AppDefinitions.applets.where((a) => a.notificationTask != null)) {
      if (sph!.session.doesSupportFeature(applet)) {
        result.add('notification-${applet.appletPhpUrl}');
        supportedApplets['notification-${applet.appletPhpUrl}'] = applet;
      }
    }

    return result;
  }

  void startPermissionCheck() {
    checkTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      final newStatus = await Permission.notification.status;
      if (newStatus != notificationPermissionStatus && mounted) {
        setState(() {
          notificationPermissionStatus = newStatus;
        });
      }
    });
  }

  void initVars() async {
    notificationPermissionStatus = await Permission.notification.status;

    final globalSettings =
      await accountDatabase.kv.getMultiple(
          ['notifications-android-target-interval-minutes',
            'notifications-android-allowed-days',
            'notifications-android-start-time',
            'notifications-android-end-time']);

    setState(() {
      notificationPermissionStatus = notificationPermissionStatus;
      androidNotificationInterval = globalSettings['notifications-android-target-interval-minutes'].toDouble();
      androidEnabledDays = globalSettings['notifications-android-allowed-days'].map<bool>((e) => e as bool).toList();
      androidStartTime = TimeOfDay(hour: globalSettings['notifications-android-start-time'][0], minute: globalSettings['notifications-android-start-time'][1]);
      androidEndTime = TimeOfDay(hour: globalSettings['notifications-android-end-time'][0], minute: globalSettings['notifications-android-end-time'][1]);
    });
  }

  @override
  void initState() {
    super.initState();
    initVars();
    startPermissionCheck();
  }

  @override
  void dispose() {
    checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageWithStreamBuilder(
        backgroundColor: backgroundColor,
        title: Text(
          AppLocalizations.of(context)!.notifications,
        ),
        subscription: sph!.prefs.kv.subscribeMultiple(getDatabaseKeys()),
        builder: (context, snapshot) {
          List<String> applets = snapshot.data!.keys.toList()..sort();
          applets.removeWhere((element) => !element.endsWith('.php'));

          final bool notificationsAllowed =
              notificationPermissionStatus == PermissionStatus.granted;
          final bool notificationsEnabled = (snapshot.data!['notifications-allow'] ?? true) == true;
          final bool notificationsActive = (snapshot.data!['notifications-allow'] ?? true) == true &&
                  notificationPermissionStatus == PermissionStatus.granted;

          return [
            if (!notificationsAllowed) ...[
              Callout(
                leading: Icon(Icons.error_rounded),
                title: Text(
                  AppLocalizations.of(context)!.deniedNotificationPermissions,
                ),
                buttonText: Text(AppLocalizations.of(context)!.openSystemSettings),
                onPressed: () {
                  AppSettings.openAppSettings(
                      type: AppSettingsType.notification);
                },
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                buttonTextColor: Theme.of(context).colorScheme.onError,
                foregroundColor: Theme.of(context).colorScheme.error,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              SizedBox(
                height: 24.0,
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: notificationsAllowed
                    ? () {
                        sph!.prefs.kv.set('notifications-allow', !notificationsEnabled);
                      }
                    : null,
                child: Card.filled(
                  color: notificationsAllowed
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    child: MinimalSwitchTile(
                      title: Text(
                        AppLocalizations.of(context)!.useNotifications,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: notificationsAllowed
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                      subtitle: widget.accountCount > 1
                          ? Text(
                          AppLocalizations.of(context)!.forThisAccount,
                            )
                          : null,
                      value: notificationsEnabled,
                      onChanged: notificationsAllowed
                          ? (value) {
                              sph!.prefs.kv
                                  .set('notifications-allow', value);
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 24.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Applets",
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: notificationsActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SizedBox(
              height: 8.0,
            ),
            ...applets.map((key) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: MinimalSwitchTile(
                    title: Text(
                      supportedApplets[key]?.label(context) ?? key,
                    ),
                    leading: Icon(
                      supportedApplets[key]?.selectedIcon.icon,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    value: (snapshot.data![key] ?? true) == true,
                    onChanged: notificationsActive
                        ? (value) {
                            sph!.prefs.kv.set(key, value);
                          }
                        : null,
                    useInkWell: true,
                  ),
                )),
            SizedBox(
              height: 12.0,
            ),
            if (Platform.isAndroid) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text(
                  AppLocalizations.of(context)!.backgroundService,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: notificationsActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 8.0,
                    children: [
                      for (int dayIndex = 1; dayIndex < 8; dayIndex++) FilterChip(
                        label: Text(
                          DateFormat.E(AppLocalizations.of(context)!.localeName).dateSymbols.SHORTWEEKDAYS[dayIndex % 7],
                        ),
                        selected: androidEnabledDays[dayIndex - 1],
                        onSelected: (val) {
                          setState(() {
                            androidEnabledDays[dayIndex - 1] = val;
                          });
                          accountDatabase.kv.set('notifications-android-allowed-days', androidEnabledDays);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: RangeSlider(
                  values: RangeValues(
                    minutesSinceZero(androidStartTime).toDouble(),
                    minutesSinceZero(androidEndTime).toDouble(),
                  ),
                  max: 24 * 60,
                  min: 0,
                  divisions: 48,
                  labels: RangeLabels(
                    androidStartTime.format(context),
                    androidEndTime.format(context),
                  ),
                  onChanged: (newValues) {
                    setState(() {
                      androidStartTime = timeFromMinutesSinceZero(newValues.start.round());
                      androidEndTime = timeFromMinutesSinceZero(newValues.end.round());
                    });
                  },
                  onChangeEnd: (newValues) {
                    accountDatabase.kv.setMultiple({
                      'notifications-android-start-time': [androidStartTime.hour, androidStartTime.minute],
                      'notifications-android-end-time': [androidEndTime.hour, androidEndTime.minute],
                    });
                  },
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: SliderTile(
                    title: Text(
                      AppLocalizations.of(context)!.updateInterval,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: notificationsAllowed
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                    subtitle: widget.accountCount > 1 ? Text(
                      AppLocalizations.of(context)!.forEveryAccount,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ) : null,
                    leading: Icon(Icons.schedule_rounded,
                        color: notificationsAllowed
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    value: androidNotificationInterval,
                    onChanged: notificationsAllowed
                        ? (val) {
                            setState(() {
                              androidNotificationInterval = val;
                            });
                          }
                        : null,
                    onChangedEnd: notificationsAllowed
                        ? (val) {
                            accountDatabase.kv.set(
                                'notifications-android-target-interval-minutes',
                                val.round());
                          }
                        : null,
                    label: "${androidNotificationInterval.round().toString()} min",
                    min: 15.0,
                    max: 180.0,
                    divisions: 11,
                    inactiveColor: sliderColor,
                  )),
              SizedBox(
                height: 16.0,
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20.0,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                ],
              ),
            ),
            SizedBox(
              height: 8.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                AppLocalizations.of(context)!.settingsInfoNotifications,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SizedBox(
              height: 4.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context)!.otherSettingsAvailablePart1,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    TextSpan(
                      text: AppLocalizations.of(context)!.systemSettings,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          AppSettings.openAppSettings(
                              type: AppSettingsType.notification);
                        },
                    ),
                    TextSpan(
                      text: AppLocalizations.of(context)!.otherSettingsAvailablePart2,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    )
                  ],
                ),
              ),
            )
          ];
        });
  }
}

int minutesSinceZero(TimeOfDay time) {
  return time.hour * 60 + time.minute;
}

TimeOfDay timeFromMinutesSinceZero(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return TimeOfDay(hour: hour, minute: minute);
}