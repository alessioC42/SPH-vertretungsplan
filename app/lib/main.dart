import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sph_plan/core/sph/sph.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/startup.dart';
import 'package:sph_plan/themes.dart';
import 'package:sph_plan/utils/authentication_state.dart';
import 'package:sph_plan/utils/quick_actions.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import 'applets/conversations/view/shared.dart';
import 'background_service.dart';
import 'core/database/account_database/account_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return errorWidget(details);
    };
  }

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  accountDatabase = AccountDatabase();

  enableTransparentNavigationBar();

  authenticationState.login().then((v) {
    if(sph?.session != null) QuickActionsStartUp();
  });

  await setupBackgroundService(accountDatabase);
  await initializeNotifications();
  await initializeDateFormatting();

  runApp(
    Phoenix(
      child: const App(),
    ),
  );
}

// Or translucent when 3-Way.
Future<void> enableTransparentNavigationBar() async {
  if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    int androidVersion = androidInfo.version.sdkInt;

    // Android 10 and above
    if (androidVersion >= 29) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: accountDatabase.kv.subscribeMultiple(['color', 'theme', 'is-amoled']),
      builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        late ThemeMode mode;
        late Themes theme;
        if (snapshot.hasData) {
          mode = snapshot.data!['theme'] == 'system' ? ThemeMode.system : snapshot.data!['theme'] == 'dark' ? ThemeMode.dark : ThemeMode.light;

          if (snapshot.data!['color'] == 'standard') {
            theme = Themes.standardTheme;
          } else if (snapshot.data!['color'] != 'standard' && snapshot.data!['color'] != 'dynamic') {
            if (Themes.flutterColorThemes.containsKey(snapshot.data!['color'])) {
              theme = Themes.flutterColorThemes[snapshot.data!['color']!]!;
            } else {
              theme = Themes.standardTheme;
            }
          } else {
            theme = Themes.standardTheme;
          }
          if (snapshot.data!['is-amoled'] == true) {
            theme = Themes.getAmoledThemes(theme);
          }
        } else {
          mode = ThemeMode.system;
          theme = Themes.standardTheme;
        }
        return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
          if (lightDynamic != null && darkDynamic != null) {
            Themes.dynamicTheme = Themes.getNewTheme(lightDynamic.primary);
          }
          if (snapshot.data?['color'] == 'dynamic') {
            var dynamicTheme = Themes.dynamicTheme;
            var darkTheme = dynamicTheme.darkTheme;
            if (snapshot.data!['is-amoled'] == true) {
              darkTheme = Themes.getAmoledThemes(dynamicTheme).darkTheme;
            }

            theme = Themes(
              dynamicTheme.lightTheme,
              darkTheme
            );
          }

          if (mode == ThemeMode.light ||
              mode == ThemeMode.system &&
                  MediaQuery.of(context).platformBrightness ==
                      Brightness.light) {
            BubbleStyles.init(theme.lightTheme!);
          } else if (mode == ThemeMode.dark ||
              mode == ThemeMode.system &&
                  MediaQuery.of(context).platformBrightness ==
                      Brightness.dark) {
            BubbleStyles.init(theme.darkTheme ?? Themes.standardTheme.darkTheme!);
          }

          return MaterialApp(
            title: 'Lanis Mobile',
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: mode,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              SfGlobalLocalizations.delegate
            ],
            supportedLocales: AppLocalizations.delegate.supportedLocales,
            home: const Scaffold(
              body: StartupScreen(),
            ),
          );
        });
      },
    );
  }
}

Widget errorWidget(FlutterErrorDetails details, {BuildContext? context}) {
  if(context != null) AppLocalizations.of(context);

  String error = details.exception.toString();

  return Container(
    color: Color.fromARGB(255, 249, 222, 220),
    child: Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20.0, vertical: 32.0,),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_rounded,
            size: 60,
            color: Color.fromARGB(255, 179, 38, 30),
          ),
          SizedBox(height: 24,),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 179, 38, 30),
            ),
            child: Text(AppLocalizations.current.errorOccurred,
                textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8,),
          DefaultTextStyle(
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 179, 38, 30),
            ),
            child: Text(
              AppLocalizations.current.errorOccurredDetails(error),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24,),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                  text: Trace.from(details.stack!).terse.toString()));
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Color.fromARGB(255, 198, 40, 32);
                }
                return Color.fromARGB(255, 179, 38, 30);
              }),
            ),
            child: Text(
              AppLocalizations.current.copyErrorToClipboard,
            ),
          ),
        ],
      ),
    ),
  );
}
