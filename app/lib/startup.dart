import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:sph_plan/home_page.dart';
import 'package:sph_plan/models/client_status_exceptions.dart';
import 'package:sph_plan/utils/authentication_state.dart';
import 'package:sph_plan/utils/quick_actions.dart';
import 'package:sph_plan/view/login/auth.dart';
import 'package:sph_plan/view/login/screen.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/widgets/offline_available_applets_section.dart';
import 'package:sph_plan/widgets/reset_account_page.dart';
import 'package:url_launcher/url_launcher.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with TickerProviderStateMixin{
  void openWelcomeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeLoginScreen()),
    );
  }

  void openLoginScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: LoginForm(showBackButton: false,),
        ),
      ),
    );
  }

  Future<void> statusListener() async {
    switch (authenticationState.status.value) {
      case LoginStatus.error:
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            builder: (context) => errorDialog(context),
          );
        }
        authenticationState.login();
        break;

      case LoginStatus.done:
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(
                key: homeKey,
              )),
        );
        break;

      case LoginStatus.setup:
        openWelcomeScreen();
        break;

      default:
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    authenticationState.status.addListener(statusListener);

    requestPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      statusListener();
    });
  }

  @override
  void dispose() {
    authenticationState.status.removeListener(statusListener);

    super.dispose();
  }

  void requestPermissions() async {
    var status = await Permission.notification.request();
    if (status.isGranted) return;
    status = await Permission.notification.request();
    if (status.isGranted) return;
    if (status == PermissionStatus.granted) return;
    if (status.isDenied && !status.isPermanentlyDenied) {
      if (mounted) {
        await showDialog(context: context, builder: (context) => AlertDialog(
          icon: Icon(Icons.notifications_off),
          title: Text(AppLocalizations.of(context).notifications),
          content: Text(AppLocalizations.of(context).notificationPermanentlyDenied),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).close),
            ),
            TextButton(
              onPressed: () {
                AppSettings.openAppSettings(asAnotherTask: false, type: AppSettingsType.notification);
              },
              child: Text(AppLocalizations.of(context).open),
            ),
          ],
        ));
      }
    }
  }

  Widget appVersion() {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, packageInfo) {
        return Text(
          "lanis-mobile ${packageInfo.data?.version}",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        );
      },
    );
  }

  Widget appLogo(double horizontal, double vertical) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: LayoutBuilder(builder: (context, constraints) {
        return SimpleShadow(
          color: Theme.of(context).colorScheme.surfaceTint,
          opacity: 0.25,
          sigma: 6,
          offset: const Offset(4, 8),
          child: SvgPicture.asset(
            "assets/startup.svg",
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary, BlendMode.srcIn),
            fit: BoxFit.contain,
            width: constraints.maxWidth.clamp(0, 300),
            height: constraints.maxHeight.clamp(0, 250),
          ),
        );
      }),
    );
  }

  WidgetSpan toolTipIcon(IconData icon) {
    return WidgetSpan(
        child: Icon(
      icon,
      size: 18,
      color: Theme.of(context).colorScheme.onPrimary,
    ));
  }

  Widget tipText(EdgeInsets padding, EdgeInsets margin, double? width) {
    List<Widget> toolTips = <Widget>[
      Text.rich(TextSpan(
          text: AppLocalizations.of(context).startUpMessage1,
          children: [toolTipIcon(Icons.code)])),
      Text.rich(TextSpan(
          text: AppLocalizations.of(context).startUpMessage2,
          children: [toolTipIcon(Icons.people)])),
      Text.rich(TextSpan(
          text: AppLocalizations.of(context).startUpMessage3,
          children: [toolTipIcon(Icons.filter_alt)])),
      Text.rich(TextSpan(
          text: AppLocalizations.of(context).startUpMessage4,
          children: [toolTipIcon(Icons.star)])),
      Text(AppLocalizations.of(context).startUpMessage5),
      Text(AppLocalizations.of(context).startUpMessage6),
      Text.rich(TextSpan(
          text: AppLocalizations.of(context).startUpMessage7,
          children: [toolTipIcon(Icons.favorite)])),
      Text.rich(TextSpan(
          text: AppLocalizations.of(context).startUpMessage8,
          children: [toolTipIcon(Icons.code)])),
      Text.rich(TextSpan(
          text: AppLocalizations.of(context).startUpMessage9,
          children: [toolTipIcon(Icons.settings)])),
    ];

    return Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(85),
                blurRadius: 18,
                spreadRadius: 1,
              )
            ],
            borderRadius: BorderRadius.circular(16.0)),
        padding: padding,
        margin: margin,
        width: width,
        child: DefaultTextStyle(
          style: Theme.of(context)
              .textTheme
              .labelLarge!
              .copyWith(color: Theme.of(context).colorScheme.onPrimary),
          textAlign: TextAlign.center,
          child: toolTips.elementAt(Random().nextInt(toolTips.length)),
        ));
  }

  BottomSheet errorDialog(BuildContext context) {
    var text = AppLocalizations.of(context).startupError;
    if (authenticationState.exception.value is LanisDownException) {
      text = AppLocalizations.of(context).lanisDownError;
    } else if (authenticationState.exception.value is NoConnectionException) {
      text = AppLocalizations.of(context).noInternetConnection2;
    }
    return BottomSheet(
      enableDrag: false,
      showDragHandle: false,
      onClosing: () {
        Navigator.of(context).pop();
      },
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.max,
            children: [
              IconButton(
                icon: const Icon(Icons.wifi_find_outlined),
                onPressed: (){
                  launchUrl(Uri.parse(
                      "https://info.schulportal.hessen.de/status-des-schulportal-hessen/"));
                },
                tooltip: AppLocalizations.of(context).checkStatus,
              ),
              Icon(
                authenticationState.exception.value is NoConnectionException ? Icons.wifi_off : Icons.error,
                size: 48,
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                tooltip: AppLocalizations.of(context).tryAgain,
              )
            ],
          ),
          SizedBox(height: 12),
          Center(
            child: Text(text),
          ),
          if (authenticationState.exception.value is! NoConnectionException && authenticationState.exception.value is! LanisDownException)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text.rich(
                TextSpan(
                  text: AppLocalizations.of(context).startupErrorMessage,
                  children: [
                    TextSpan(
                        text: "\n\n${authenticationState.exception.value.runtimeType}: ${authenticationState.exception.value?.cause}",
                        style: Theme.of(context).textTheme.labelLarge)
                  ],
                ),
              ),
            ),
          if (authenticationState.exception.value is WrongCredentialsException) Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.lock_reset),
              label: Text(AppLocalizations.of(context).resetAccount),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => ResetAccountPage()
                  ),
                );
              },
            ),
          ),
          if (authenticationState.exception.value is LanisDownException)
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: AppLocalizations.of(context).lanisDownErrorMessage,
                  style: Theme.of(context).textTheme.labelLarge)
            ], ), ),
            Flexible(child: SingleChildScrollView(
              child: OfflineAvailableAppletsSection(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sets the apps context as soon as possible
    AppLocalizations.of(context);
    QuickActionsStartUp.setNames(context);
    return MediaQuery.of(context).orientation == Orientation.portrait
        ? Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        appVersion(),
        Column(
          children: [
            appLogo(80.0, 20.0),
            tipText(
                const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 12.0),
                const EdgeInsets.symmetric(horizontal: 36.0),
                null)
          ],
        ),
        const LinearProgressIndicator()
      ],
    )
        : Stack(
      alignment: Alignment.topCenter,
      children: [
        appVersion(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                appLogo(0.0, 0.0),
                SizedBox.fromSize(
                  size: const Size(48.0, 0.0),
                ),
                tipText(
                    const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 12.0),
                    const EdgeInsets.only(),
                    250)
              ],
            ),
          ],
        ),
        const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [LinearProgressIndicator()],
        )
      ],
    );
  }
}
