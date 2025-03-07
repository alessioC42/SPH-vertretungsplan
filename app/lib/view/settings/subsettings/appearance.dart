import 'package:flutter/material.dart';
import 'package:sph_plan/core/database/account_database/account_db.dart';
import 'package:sph_plan/themes.dart';
import 'package:sph_plan/utils/radio_pills.dart';
import 'package:sph_plan/utils/switch_tile.dart';
import 'package:sph_plan/view/settings/settings_page_builder.dart';
import 'package:sph_plan/generated/l10n.dart';

class AppearanceSettings extends SettingsColours {
  final bool showBackButton;
  const AppearanceSettings({super.key, this.showBackButton = true});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState
    extends SettingsColoursState<AppearanceSettings> {
  ThemeData? dynamicTheme = Themes.dynamicTheme.lightTheme;

  @override
  void didChangeDependencies() {
    setState(() {
      dynamicTheme = Theme.of(context).brightness == Brightness.dark
          ? Themes.dynamicTheme.darkTheme
          : Themes.dynamicTheme.lightTheme;
    });

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageWithStreamBuilder(
        backgroundColor: backgroundColor,
        title: Text(AppLocalizations.of(context)!.appearance),
        showBackButton: widget.showBackButton,
        subscription: accountDatabase.kv
            .subscribeMultiple(['color', 'theme', 'is-amoled']),
        builder: (context, snapshot) {
          return [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                AppLocalizations.of(context).theme,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: RadioPillGroup<String>(
                  groupValue: snapshot.data!['theme'],
                  onChanged: (value) {
                    accountDatabase.kv.set('theme', value);
                  },
                  color: foregroundColor,
                  pills: [
                    RadioPillGroupItem.vertical(
                        title: Text(AppLocalizations.of(context).system),
                        leading: Icon(Icons.phone_android_rounded),
                        value: "system"),
                    RadioPillGroupItem.vertical(
                        title: Text(AppLocalizations.of(context).light),
                        leading: Icon(Icons.light_mode_rounded),
                        value: "light"),
                    RadioPillGroupItem.vertical(
                        title: Text(AppLocalizations.of(context).dark),
                        leading: Icon(Icons.dark_mode_rounded),
                        value: "dark"),
                  ],
                )),
            Visibility(
              visible: Theme.of(context).brightness == Brightness.dark,
              child: Column(
                children: [
                  SizedBox(
                    height: 16.0,
                  ),
                  MinimalSwitchTile(
                      title: Text(
                        AppLocalizations.of(context).amoledMode,
                      ),
                      leading: Icon(Icons.contrast_rounded),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                      useInkWell: true,
                      value: snapshot.data!['is-amoled'],
                      onChanged: (value) {
                        accountDatabase.kv.set('is-amoled', value);
                      }),
                ],
              ),
            ),
            SizedBox(
              height: 24.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                AppLocalizations.of(context).accentColor,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: RadioPillGroup<String>.large(
                  groupValue: snapshot.data!['color'],
                  onChanged: (value) {
                    accountDatabase.kv.set('color', value);
                  },
                  color: foregroundColor,
                  pills: [
                    RadioPillGroupItem.horizontal(
                        title: Text(AppLocalizations.of(context).standard),
                        value: "standard",
                        trailing: TrailingCircle(
                          color: Themes.standardTheme.lightTheme!.colorScheme
                              .primaryFixedDim,
                          selectedBackgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          selected: snapshot.data!['color'] == "standard",
                        )),
                    if (dynamicTheme != null)
                      RadioPillGroupItem.horizontal(
                          title:
                              Text(AppLocalizations.of(context).dynamicColor),
                          value: "dynamic",
                          trailing: TrailingCircle.custom(
                            selectedBackgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            selected: snapshot.data!['color'] == "dynamic",
                            customCircle: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(100)),
                                      color: dynamicTheme!.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(100)),
                                          color: dynamicTheme!
                                              .colorScheme.inversePrimary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                              bottomRight:
                                                  Radius.circular(100)),
                                          color: dynamicTheme!
                                              .colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ))
                              ],
                            ),
                          )),
                  ],
                  customPillBuilder:
                      (String? groupValue, void Function(String)? onChanged) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 2.0,
                        ),
                        RadioTrailingCircleGroup<String>(
                          groupValue: groupValue,
                          onChanged: onChanged,
                          border: RadioBorder.bottom,
                          color: foregroundColor,
                          colors: List<ColorPair<String>>.generate(
                              Themes.flutterColorThemes.keys.length, (index) {
                            final key =
                                Themes.flutterColorThemes.keys.elementAt(index);

                            return ColorPair<String>(
                              color: Themes.flutterColorThemes[key]!.lightTheme!
                                  .colorScheme.primaryFixedDim,
                              value: key,
                            );
                          }),
                        ),
                      ],
                    );
                  },
                )),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 28.0,
                    ),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20.0,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      dynamicTheme == null
                          ? AppLocalizations.of(context)
                          .settingsUnsupportedInfoAppearance
                      : AppLocalizations.of(context)
                          .settingsInfoDynamicColor,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color:
                          Theme.of(context).colorScheme.onSurfaceVariant),
                    )
                  ],
                )),
          ];
        });
  }
}
