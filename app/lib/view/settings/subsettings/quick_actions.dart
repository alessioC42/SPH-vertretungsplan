import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sph_plan/applets/definitions.dart';
import 'package:sph_plan/core/database/account_database/account_db.dart';
import 'package:sph_plan/core/sph/sph.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/utils/switch_tile.dart';
import 'package:sph_plan/view/settings/settings_page_builder.dart';

class QuickActions extends StatefulWidget {
  const QuickActions({super.key});

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  // Android supports 2 quick actions, iOS 4
  final int maxQuickActions = Platform.isAndroid ? 2 : 4;


  @override
  Widget build(BuildContext context) {

    List<AppletDefinition> applets = [];
    for (final applet in AppDefinitions.applets) {
      if (
      sph!.session.doesSupportFeature(applet) &&
          (!Platform.isAndroid || applet.appletType != AppletType.navigation)
      ) {
        applets.add(applet);
      }
    }


    return SettingsPage(
      title: Text(AppLocalizations.of(context).quickActions),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: StreamBuilder(
            stream: accountDatabase.kv.subscribe('quick-actions'),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.active) {
                return Container();
              }

              final List<String> quickActions = List<String>.from(snapshot.data ?? []);
              // Remove any empty or null strings
              quickActions.removeWhere((element) => element.isEmpty);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppLocalizations.of(context).applets,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  ...applets.map((applet) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: MinimalSwitchTile(
                      title: Text(
                        applet.label(context),
                      ),
                      leading: applet.icon,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      value: quickActions.contains(applet.appletPhpUrl),
                      onChanged: quickActions.length >= 2 && !quickActions.contains(applet.appletPhpUrl) ?
                          null : (bool value) {
                        if (value) {
                          quickActions.add(applet.appletPhpUrl);
                        } else {
                          quickActions.remove(applet.appletPhpUrl);
                        }
                        accountDatabase.kv.set('quick-actions', quickActions);
                      },
                      useInkWell: true,
                    ),
                  )),
                  SizedBox(
                    height: 8.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppLocalizations.of(context).external,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  ...AppDefinitions.external.map((external) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: MinimalSwitchTile(
                      title: Text(
                        external.label(context),
                      ),
                      leading: external.icon,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      value: quickActions.contains(external.id),
                      onChanged: quickActions.length >= 2 && !quickActions.contains(external.id) ?
                          null : (bool value) {
                        if (value) {
                          quickActions.add(external.id);
                        } else {
                          quickActions.remove(external.id);
                        }
                        accountDatabase.kv.set('quick-actions', quickActions);
                      },
                      useInkWell: true,
                    ),
                  )),
                  SizedBox(
                    height: 24.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    ],
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  Text(
                    AppLocalizations.of(context).restartRequired,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                    height: 4.0,
                  ),
                  Text(
                    AppLocalizations.of(context).quickActionsDisclaimer(maxQuickActions),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                    height: 4.0,
                  ),
                  if (Platform.isAndroid) Text(
                    AppLocalizations.of(context).quickActionsAndroid,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                ],
              );
            }
          ),
        )
      ],
    );
  }
}
