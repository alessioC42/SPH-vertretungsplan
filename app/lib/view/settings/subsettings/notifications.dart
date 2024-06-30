import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sph_plan/client/storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sph_plan/view/settings/info_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
        actions: [
          InfoButton(
              infoText: AppLocalizations.of(context)!.settingsInfoNotifications,
              context: context)
        ],
      ),
      body: ListView(
        children: const [NotificationElements()],
      ),
    );
  }
}

class NotificationElements extends StatefulWidget {
  const NotificationElements({super.key});

  @override
  State<NotificationElements> createState() => _NotificationElementsState();
}

class _NotificationElementsState extends State<NotificationElements> {
  bool _enableNotifications = true;
  int _androidNotificationInterval = 15;
  bool _androidNotificationsOngoing = false;
  bool _androidNotificationPermissionGranted = false;
  TimeOfDay _iOSUpdateTime = const TimeOfDay(hour: 7, minute: 40);

  Future<void> loadSettingsVars() async {
    _enableNotifications =
        (await globalStorage.read(key: StorageKey.settingsPushService)) ==
            "true";
    _androidNotificationInterval = int.parse(
        await globalStorage.read(key: StorageKey.settingsPushServiceIntervall));
    _androidNotificationsOngoing = (await globalStorage.read(
            key: StorageKey.settingsPushServiceOngoing)) ==
        "true";

    _androidNotificationPermissionGranted = await Permission.notification.isGranted;
    final String timeString = await globalStorage.read(key: StorageKey.settingsPushServiceIOSTime);
    final List<String> timeList = timeString.split(":");
    _iOSUpdateTime = TimeOfDay(hour: int.parse(timeList[0]), minute: int.parse(timeList[1]));
  }

  @override
  void initState() {
    super.initState();
    // Use await to ensure that loadSettingsVariables completes before continuing
    loadSettingsVars().then((_) {
      setState(() {
        // Set the state after loading the variables
        _enableNotifications = _enableNotifications;
        _androidNotificationInterval = _androidNotificationInterval;
        _androidNotificationsOngoing = _androidNotificationsOngoing;
        _iOSUpdateTime = _iOSUpdateTime;

        _androidNotificationPermissionGranted = _androidNotificationPermissionGranted;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (Platform.isAndroid) ListTile(
          title: Text(
              AppLocalizations.of(context)!.systemPermissionForNotifications),
          trailing: Text(_androidNotificationPermissionGranted
              ? AppLocalizations.of(context)!.granted
              : AppLocalizations.of(context)!.denied),
          subtitle: !_androidNotificationPermissionGranted
              ? Text(AppLocalizations.of(context)!
                  .systemPermissionForNotificationsExplained)
              : null,
        ),
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.pushNotifications),
          value: _enableNotifications,
          onChanged: _androidNotificationPermissionGranted
              ? (bool? value) async {
                  setState(() {
                    _enableNotifications = value!;
                  });
                  await globalStorage.write(
                      key: StorageKey.settingsPushService,
                      value: _enableNotifications.toString());
                }
              : null,
          subtitle:
              Text(AppLocalizations.of(context)!.activateToGetNotification),
        ),
        if (Platform.isAndroid) SwitchListTile(
          title: Text(AppLocalizations.of(context)!.persistentNotification),
          value: _androidNotificationsOngoing,
          onChanged: _enableNotifications && _androidNotificationPermissionGranted
              ? (bool? value) async {
                  setState(() {
                    _androidNotificationsOngoing = value!;
                  });
                  await globalStorage.write(
                      key: StorageKey.settingsPushServiceOngoing,
                      value: _androidNotificationsOngoing.toString());
                }
              : null,
        ),
        if (Platform.isAndroid) ListTile(
          title: Text(AppLocalizations.of(context)!.updateInterval),
          trailing: Text('$_androidNotificationInterval min',
              style: const TextStyle(fontSize: 14)),
          enabled: _enableNotifications && _androidNotificationPermissionGranted,
        ),
        if (Platform.isAndroid) Slider(
          value: _androidNotificationInterval.toDouble(),
          min: 15,
          max: 180,
          onChanged: _enableNotifications && _androidNotificationPermissionGranted
              ? (double value) {
                  setState(() {
                    _androidNotificationInterval = value.toInt(); // Umwandlung zu int
                  });
                }
              : null,
          onChangeEnd: (double value) async {
            await globalStorage.write(
                key: StorageKey.settingsPushServiceIntervall,
                value: _androidNotificationInterval.toString());
          },
        ),
        if (Platform.isIOS) ListTile(
          title: const Text("Time of day"),
          subtitle: const Text("The time of day when the notifications are sent. Does only apply when the app is opened fairly often. "),
          trailing: Text(_iOSUpdateTime.format(context), style: const TextStyle(fontSize: 20)),
          onTap: () async {
            final TimeOfDay? newTime = await showTimePicker(
              context: context,
              initialTime: _iOSUpdateTime,
            );
            if (newTime != null) {
              setState(() {
                _iOSUpdateTime = newTime;
              });
            }
            globalStorage.write(key: StorageKey.settingsPushServiceIOSTime, value: "${_iOSUpdateTime.hour}:${_iOSUpdateTime.minute}");
          },
        )
      ],
    );
  }
}
