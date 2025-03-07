import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sph_plan/generated/l10n.dart';

import '../core/sph/sph.dart';

int compareVersions(String version1, String version2) {
  List<int> v1 = version1
      .replaceFirst('v', '')
      .split(RegExp(r'[.+]'))
      .map(int.parse)
      .toList();
  List<int> v2 = version2
      .replaceFirst('v', '')
      .split(RegExp(r'[.+]'))
      .map(int.parse)
      .toList();

  for (int i = 0; i < v1.length; i++) {
    if (v1[i] > v2[i]) return 1;
    if (v1[i] < v2[i]) return -1;
  }
  return 0;
}

Future<ReleaseNotesScreen?> showLocalUpdateInfo(BuildContext context,
    {bool dialog = true}) async {
  if (dialog) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => SimpleDialog(
              title: Text(AppLocalizations.of(context)!.loading),
              children: [
                Center(
                  child: CircularProgressIndicator(),
                )
              ],
            ));
  }
  final deviceReleaseTag = await getDeviceReleaseTag();
  await sph!.prefs.kv.set('last-app-version', deviceReleaseTag);
  final deviceReleaseInfo = await getReleaseInfo(deviceReleaseTag);
  if (context.mounted && dialog) Navigator.of(context).pop();
  if (deviceReleaseInfo == null) return null;
  if (context.mounted) {
    if (dialog) {
      showDialog(
        context: context,
        builder: (context) => ReleaseNotesScreen(deviceReleaseInfo),
      );
    } else {
      return ReleaseNotesScreen(deviceReleaseInfo, showBack: dialog);
    }
  }
  return null;
}

void showUpdateInfoIfRequired(BuildContext context) async {
  final latestReleaseInfo = await getReleaseInfo(null);
  if (latestReleaseInfo == null) return;
  final String latestReleaseTag = latestReleaseInfo['tag_name'];
  final String deviceReleaseTag = await getDeviceReleaseTag();
  final String? storageReleaseTag = await sph!.prefs.kv.get('last-app-version');
  await sph!.prefs.kv.set('last-app-version', deviceReleaseTag);

  if (storageReleaseTag != deviceReleaseTag) {
    await sph!.prefs.kv.set('last-app-version', deviceReleaseTag);
    if (latestReleaseTag == deviceReleaseTag && context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => ReleaseNotesScreen(latestReleaseInfo),
      );
    } else {
      final deviceReleaseInfo = await getReleaseInfo(deviceReleaseTag);
      if (deviceReleaseInfo == null || !context.mounted) return;
      await showDialog(
        context: context,
        builder: (context) => ReleaseNotesScreen(deviceReleaseInfo),
      );
    }
  }

  if (compareVersions(latestReleaseTag, deviceReleaseTag) > 0 && context.mounted) {
    await showDialog(
      context: context,
      builder: (context) => NewUpdateAvailableDialog(
        deviceReleaseTag: deviceReleaseTag,
        latestReleaseTag: latestReleaseTag,
        releaseInfo: latestReleaseInfo,
      ),
    );
  }
}

Future<String> getDeviceReleaseTag() async {
  final packageInfo = await PackageInfo.fromPlatform();

  final String currentVersion = packageInfo.version;
  final String buildNumber = packageInfo.buildNumber;

  return ("v$currentVersion+$buildNumber");
}

Future<Map?> getReleaseInfo(String? releaseTag) async {
  try {
    String url =
        'https://api.github.com/repos/lanis-mobile/lanis-mobile/releases/latest';
    if (releaseTag != null) {
      url =
          'https://api.github.com/repos/lanis-mobile/lanis-mobile/releases/tags/$releaseTag';
    }
    final response = await sph!.session.dio.get(url);
    return response.data;
  } on Exception {
    return null;
  }
}

class ReleaseNotesScreen extends StatelessWidget {
  final Map releaseInfo;
  final bool showBack;
  const ReleaseNotesScreen(this.releaseInfo, {super.key, this.showBack = true});

  ///load contributors from markdown by searching for @username patterns
  List<String> getContributors(String markdownString) {
    final RegExp regExp = RegExp(r'@([a-zA-Z0-9_]+)');
    final Iterable<RegExpMatch> matches = regExp.allMatches(markdownString);
    final List<String> contributors = [];
    for (final match in matches) {
      final String contributor = match.group(1)!;
      if (!contributors.contains(contributor)) {
        contributors.add(contributor);
      }
    }
    return contributors;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update ${releaseInfo['tag_name']}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () {
              launchUrl(Uri.parse(releaseInfo['html_url']));
            },
          ),
        ],
        automaticallyImplyLeading: showBack,
      ),
      body: Column(
        children: [
          Expanded(
            child: Markdown(
              data: releaseInfo['body'] ?? AppLocalizations.of(context).error,
              padding: const EdgeInsets.all(16),
              onTapLink: (text, href, title) {
                launchUrl(Uri.parse(href!));
              },
            ),
          ),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(AppLocalizations.of(context).contributors, style: Theme.of(context).textTheme.labelLarge),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 8.0, top: 4.0, left: 8.0, right: 8.0),
                  child: Wrap(
                    children: getContributors(releaseInfo['body'] ?? '')
                        .map((contributor) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            launchUrl(
                                Uri.parse('https://github.com/$contributor'));
                          },
                          child: ClipOval(
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: Image.network(
                              'https://github.com/$contributor.png?size=60',
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Text(AppLocalizations.of(context).becomeContributor, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 32),
        ],
      ),
      floatingActionButton: showBack
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.done),
              label: Text(AppLocalizations.of(context)!.done),
            )
          : null,
    );
  }
}

class NewUpdateAvailableDialog extends StatelessWidget {
  const NewUpdateAvailableDialog(
      {super.key,
      required this.deviceReleaseTag,
      required this.latestReleaseTag,
      required this.releaseInfo});
  final String deviceReleaseTag;
  final String latestReleaseTag;
  final Map releaseInfo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.update, size: 56,),
      title: Text(AppLocalizations.of(context).updateAvailable),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            deviceReleaseTag,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Icon(Icons.arrow_forward),
          Text(
            latestReleaseTag,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context).info),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => ReleaseNotesScreen(releaseInfo),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            launchStore();
          },
          child: Text(AppLocalizations.of(context).install),
        ),
      ],
    );
  }
}

void launchStore() {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final url = Uri.parse(
        Platform.isAndroid
            ? "market://details?id=io.github.alessioc42.sph"
            : "https://apps.apple.com/app/id6511247743",
      );
      launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  } on PlatformException {
    launchUrl(Uri.parse(
      Platform.isAndroid
          ? "https://play.google.com/store/apps/details?id=io.github.alessioc42.sph"
          : "https://apps.apple.com/app/id6511247743",
    ));
  }
}
