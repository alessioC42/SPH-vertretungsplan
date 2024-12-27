import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sph_plan/utils/large_appbar.dart';

import '../../../core/sph/sph.dart';

class UserDataSettings extends StatefulWidget {
  const UserDataSettings({super.key});

  @override
  State<UserDataSettings> createState() => _UserDataSettingsState();
}

class _UserDataSettingsState extends State<UserDataSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      appBar: LargeAppBar(
          title: Text("User data")
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            for (var key in sph!.session.userData.keys)
              ListTile(
                title: Text(sph!.session.userData[key]!),
                subtitle: Text(toBeginningOfSentenceCase(key)!),
                contentPadding: EdgeInsets.zero,
              ),
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
              "All user data is stored on the Lanis servers.",
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
