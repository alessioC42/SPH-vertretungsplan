import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:sph_plan/applets/definitions.dart';
import 'package:sph_plan/core/database/account_database/account_db.dart';
import 'package:sph_plan/core/sph/sph.dart';
import 'package:sph_plan/home_page.dart';
import 'package:sph_plan/utils/logger.dart';

late final QuickActions quickActions;
bool _quickActionsSet = false;
bool _requestFailed = false;

class QuickActionsStartUp {

  static final Completer<void> _initializationCompleter = Completer<void>();
  bool _initialized = false;

  QuickActionsStartUp() {
    if(_initialized) return;
    quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      for (final applet in AppDefinitions.applets) {
        if (applet.appletPhpUrl == shortcutType) {

          if (!sph!.session.doesSupportFeature(applet)) {
            logger.e('Applet not supported: ${applet.appletPhpUrl}');
            return;
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            logger.i('Opening applet: ${applet.appletPhpUrl}');
            Destination destination = Destination.fromAppletDefinition(applet);
            if(homeKey.currentContext != null) Navigator.popUntil(homeKey.currentContext!, (route) => route.isFirst);
            if(destination.enableBottomNavigation) {
              int appletIndex = AppDefinitions.getIndexByPhpIdentifier(
                  applet.appletPhpUrl);

              if (homeKey.currentState != null) {
                homeKey.currentState?.updateDestination(appletIndex);
              } else {
                logger.e('Tried to open applet without homeKey');
              }

            } else {
              if(homeKey.currentContext != null) {
                destination.action?.call(homeKey.currentContext!);
                logger.i('Opened applet: ${applet.appletPhpUrl}');
              } else {
                logger.e('Tried to open applet without context');
              }
            }


          });
          break;
        }
      }
      for (final applet in AppDefinitions.external) {
        if (applet.id == shortcutType) {

          // Wait until the flutter app is fully initialized
          WidgetsBinding.instance.addPostFrameCallback((_) {
            applet.action?.call(homeKey.currentContext);
          });
        }
      }
    });
    logger.i('Initialized quick actions');
    _initializationCompleter.complete();
    _initialized = true;
  }

  static Future<bool> waitForInitialization() async {
    try {
      await _initializationCompleter.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('QuickActions initialization timed out.'),
      );
      return true;
    } on TimeoutException catch (_) {
      logger.e('QuickActions initialization timed out. Likely the user is not logged in.');
      return false;
    }
  }

  static void setNames(BuildContext context) async {
    if (_quickActionsSet) return;
    if (_requestFailed) return;
    var result = await waitForInitialization();
    if (!result) {
      _requestFailed = true;
      return;
    }
    if (_quickActionsSet) return;
    List<String> enabledShortcutsList = List<String>.from((await accountDatabase.kv.get('quick-actions')) ?? []);
    if (!context.mounted) return;

    List<ShortcutItem> shortcuts = [];
    for (final applet in AppDefinitions.applets) {
      if (enabledShortcutsList.contains(applet.appletPhpUrl)) {
        shortcuts.add(ShortcutItem(
          type: applet.appletPhpUrl,
          localizedTitle: applet.label(context),
          icon: '@mipmap/ic_launcher_monochrome',
        ));
      }
    }
    for (final applet in AppDefinitions.external) {
      if (enabledShortcutsList.contains(applet.id)) {
        shortcuts.add(ShortcutItem(
          type: applet.id,
          localizedTitle: applet.label(context),
          icon: '@mipmap/ic_launcher_monochrome',
        ));
      }
    }

    await quickActions.setShortcutItems(shortcuts);
    _quickActionsSet = true;
  }
}
