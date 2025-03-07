import 'dart:math';
import 'dart:ui';
import 'package:sph_plan/core/database/account_database/account_db.dart';
import 'package:sph_plan/core/sph/session.dart';
import 'package:sph_plan/models/account_types.dart';
import 'package:sph_plan/models/client_status_exceptions.dart';
import 'package:sph_plan/generated/l10n.dart';

import 'package:flutter/material.dart';
import 'package:sph_plan/utils/authentication_state.dart';
import 'package:sph_plan/utils/whats_new.dart';
import 'package:sph_plan/utils/cached_network_image.dart';
import 'package:sph_plan/view/account_switcher/account_switcher.dart';
import 'package:sph_plan/view/moodle.dart';
import 'package:sph_plan/view/settings/settings.dart';
import 'package:url_launcher/url_launcher.dart';

import 'applets/definitions.dart';
import 'core/sph/sph.dart';

const String surveyUrl = 'https://ruggmtk.edudocs.de/apps/forms/s/ScZp5xZMKYTksEcQMwgPHfFz';

typedef ActionFunction = void Function(BuildContext);

int selectedDestinationDrawer = -1;
final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();

class Destination {
  final Icon icon;
  final Icon selectedIcon;
  final bool enableBottomNavigation;
  final bool enableDrawer;
  final bool addDivider;
  final String Function(BuildContext) label;
  final ActionFunction? action;
  final Widget Function(BuildContext, AccountType, Function openDrawerCb)? body;
  late final bool isSupported;

  Destination(
      {this.body,
      this.action,
      this.addDivider = false,
      required this.isSupported,
      required this.enableBottomNavigation,
      required this.enableDrawer,
      required this.icon,
      required this.selectedIcon,
      required this.label});

  factory Destination.fromAppletDefinition(AppletDefinition appletDefinition) {
    return Destination(
      body: appletDefinition.appletType == AppletType.nested
          ? appletDefinition.bodyBuilder
          : null,
      action: appletDefinition.appletType != AppletType.nested
          ? (context) =>
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return appletDefinition.bodyBuilder!(
                    context, sph!.session.accountType, () {});
              }))
          : null,
      addDivider: appletDefinition.addDivider,
      isSupported: sph!.session.doesSupportFeature(appletDefinition),
      enableBottomNavigation:
          appletDefinition.appletType == AppletType.nested,
      enableDrawer: true,
      icon: appletDefinition.icon,
      selectedIcon: appletDefinition.selectedIcon,
      label: appletDefinition.label,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey();

  late bool doesSupportAnyApplet = false;
  List<Destination> destinations = [];

  @override
  void initState() {
    for (var destination in AppDefinitions.applets) {
      destinations.add(Destination.fromAppletDefinition(destination));
    }
    destinations.addAll(endDestinations);
    super.initState();
    setDefaultDestination();
    showUpdateInfoIfRequired(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void updateDestination(int newIndex) {
    setState(() {
      selectedDestinationDrawer = newIndex;
    });
  }

  final List<Destination> endDestinations = [
    Destination(
        label: (context) => AppLocalizations.of(context).openMoodle,
        icon: const Icon(Icons.open_in_new),
        selectedIcon: const Icon(Icons.open_in_new),
        isSupported: true,
        enableBottomNavigation: false,
        addDivider: true,
        enableDrawer: true,
        action: (context) => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const MoodleWebView()))),
    Destination(
        label: (context) => AppLocalizations.of(context).openLanisInBrowser,
        icon: const Icon(Icons.open_in_new),
        selectedIcon: const Icon(Icons.open_in_new),
        isSupported: true,
        enableBottomNavigation: false,
        enableDrawer: true,
        action: (context) {
          SessionHandler.getLoginURL(sph!.account).then((response) {
            launchUrl(Uri.parse(response));
          });
        }),
    Destination(
      label: (context) => AppLocalizations.of(context).settings,
      icon: const Icon(Icons.settings),
      selectedIcon: const Icon(Icons.settings),
      isSupported: true,
      enableBottomNavigation: false,
      enableDrawer: true,
      addDivider: true,
      action: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ),
    ),
    Destination(
      isSupported: true,
      enableBottomNavigation: false,
      enableDrawer: true,
      icon: Icon(Icons.logout),
      selectedIcon: Icon(Icons.logout_outlined),
      label: (context) => AppLocalizations.of(context).logout,
      action: (context) async {
        await sph!.session.deAuthenticate();
        await accountDatabase.deleteAccount(sph!.account.localId);
        if(context.mounted) authenticationState.reset(context);
      }
    ),
  ];

  void setDefaultDestination() {
    if (selectedDestinationDrawer != -1) return;
    for (var destination in destinations) {
      if (destination.isSupported && destination.enableBottomNavigation) {
        selectedDestinationDrawer = destinations.indexOf(destination);
        doesSupportAnyApplet = true;
        return;
      }
    }
    selectedDestinationDrawer = -1;
  }

  void openLanisInBrowser(BuildContext? context) {
    SessionHandler.getLoginURL(sph!.account).then((response) {
      launchUrl(Uri.parse(response));
    }).catchError((ex) {
      if (context == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ex.cause),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'ACTION',
          onPressed: () {},
        ),
      ));
    }, test: (e) => e is LanisException);
  }

  Widget noAppsSupported() {
    return Center(
      // In case no feature is supported at all just show an open in browser button.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.disabled_by_default_outlined,
            size: 150,
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(AppLocalizations.of(context).noSupportOpenInBrowser),
          ),
          ElevatedButton(
              onPressed: () => openLanisInBrowser(context),
              child: Text(AppLocalizations.of(context).openLanisInBrowser))
        ],
      ),
    );
  }

  void openDestination(int index, bool fromDrawer) {
    if (destinations[index].action != null) {
      destinations[index].action!(context);
    } else {
      setState(() {
        selectedDestinationDrawer = index;
        if (fromDrawer) Navigator.pop(context);
      });
    }
  }

  NavigationDrawer navDrawer(context) {
    List<Widget> drawerDestinations = [];

    for (var destination in destinations) {
      if (destination.enableDrawer) {
        if (destination.addDivider) {
          drawerDestinations.add(const Divider());
        }
        drawerDestinations.add(NavigationDrawerDestination(
          label: Text(destination.label(context)),
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
          enabled: destination.isSupported,
        ));
      }
    }

    final Color imageColor =
        Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.5);
    final Color textColor =
        imageColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;

    return NavigationDrawer(
        selectedIndex: selectedDestinationDrawer,
        onDestinationSelected: (int index) => openDestination(index, true),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Stack(
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: ColorFiltered(
                          colorFilter:
                              ColorFilter.mode(imageColor, BlendMode.srcOver),
                          child: AspectRatio(
                            aspectRatio: 16 / 8,
                            child: CachedNetworkImage(
                              imageUrl: Uri.parse(
                                  "https://startcache.schulportal.hessen.de/exporteur.php?a=schoolbg&i=${sph!.account.schoolID}&s=xs"),
                              placeholder: const Image(
                                image: AssetImage("assets/icon.png"),
                                fit: BoxFit.cover,
                              ),
                              builder: (BuildContext context,
                                  ImageProvider<Object> imageProvider) {
                                return Image(
                                  fit: BoxFit.cover,
                                  image: imageProvider,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${sph?.session.userData["nachname"]}, ${sph?.session.userData["vorname"]}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor),
                            ),
                            Text(
                              sph!.account.schoolName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: textColor),
                            ),
                          ],
                        ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 2, right: 2),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AccountSwitcher()));
                      },
                      icon: Icon(Icons.switch_account),
                      color: textColor,
                      iconSize: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...drawerDestinations,
        ]);
  }

  NavigationBar navBar(context) {
    List<NavigationDestination> barDestinations = [];

    for (var destination in destinations) {
      if (destination.enableBottomNavigation && destination.isSupported) {
        barDestinations.add(NavigationDestination(
          label: destination.label(context),
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
          enabled: destination.isSupported,
        ));
      }
    }

    List<int?> indexNavbarTranslationLayer = [];

    int helpIndex = 0;
    for (var destination in destinations) {
      if (destination.enableBottomNavigation && destination.isSupported) {
        indexNavbarTranslationLayer.add(helpIndex);
        helpIndex += 1;
      } else {
        indexNavbarTranslationLayer.add(null);
      }
    }
    return NavigationBar(
      destinations: barDestinations,
      selectedIndex: indexNavbarTranslationLayer[selectedDestinationDrawer]!,
      onDestinationSelected: (int index) =>
          openDestination(indexNavbarTranslationLayer.indexOf(index), false),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _drawerKey,
      body: doesSupportAnyApplet
          ? destinations[selectedDestinationDrawer].body!(
              context, sph!.session.accountType, () {
              _drawerKey.currentState!.openDrawer();
            })
          : noAppsSupported(),
      bottomNavigationBar: doesSupportAnyApplet ? navBar(context) : null,
      drawer: navDrawer(context),
      floatingActionButton: StreamBuilder(
        stream: sph!.prefs.kv.subscribe('poll_survey_1_12_25_clicked'),
        builder: (context, snapshot) {
          return Visibility(
            visible: !snapshot.hasData || !snapshot.data,
            child: Padding(
              padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 24),
              child: ElevatedButton(
                  onPressed: () async {
                    await launchUrl(Uri.parse(surveyUrl));
                    await sph!.prefs.kv.set('poll_survey_1_12_25_clicked', true);
                  },
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.feedback),
                    Text(AppLocalizations.of(context).feedback)
                  ],
                ),
              ),
            ),
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
    );
  }
}

bool randomBool(double chance) {
  return Random().nextDouble() < chance;
}