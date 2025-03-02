import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '../core/sph/sph.dart';
import 'file_icons.dart';

class FileInfo {
  String? name;

  /// The size + the unit. Often enclosed with parentheses.
  String? size;

  Uri? url;

  String get extension => name!.split('.').last;

  FileInfo({this.name, this.size, this.url});
}

void showFileModal(BuildContext context, FileInfo file) {
  showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 22.0),
                      Icon(getIconByFileExtension(file.extension)),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(file.name ?? AppLocalizations.of(context).unknownFile, overflow: TextOverflow.ellipsis,),),
                      Text(file.size ?? "", style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(width: 22.0),
                    ],
                  ),
                  SizedBox(height: 8,),
                  Divider(),
                  MenuItemButton(
                    onPressed: () => {
                      launchFile(context, file.url.toString(), file.name ?? AppLocalizations.of(context).unknownFile, file.size, () {})
                    },
                    child: Row(
                      children: [
                        Padding(padding: EdgeInsets.only(left: 10.0)),
                        Icon(Icons.open_in_new),
                        Padding(padding: EdgeInsets.only(right: 8.0)),
                        Text(AppLocalizations.of(context).openFile)
                      ],
                    ),
                  ),
                  if (!Platform.isIOS) (
                    MenuItemButton(
                      onPressed: () => {
                        saveFile(context, file.url.toString(), file.name ?? AppLocalizations.of(context).unknownFile, file.size, () {})
                      },
                      child: Row(
                        children: [
                          Padding(padding: EdgeInsets.only(left: 10.0)),
                          Icon(Icons.save_alt_rounded),
                          Padding(padding: EdgeInsets.only(right: 8.0)),
                          Text(AppLocalizations.of(context).saveFile)
                        ],
                      ),
                    )
                  ),
                  if (!Platform.isLinux) (
                    MenuItemButton(
                      onPressed: () => {
                        shareFile(context, file.url.toString(), file.name ?? AppLocalizations.of(context).unknownFile, file.size, () {})
                      },
                      child: Row(
                        children: [
                          Padding(padding: EdgeInsets.only(left: 10.0)),
                          Icon(Icons.share_rounded),
                          Padding(padding: EdgeInsets.only(right: 8.0)),
                          Text(AppLocalizations.of(context).shareFile)
                        ],
                      ),
                    )
                  )
                ],
              ),
            ),
          ),
        );
      }
  );
}

void launchFile(BuildContext context, String url, String filename,
    String? fileSize, Function callback) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => downloadDialog(context, fileSize));

  sph!.storage.downloadFile(url, filename).then((filepath) async {
    if(context.mounted) Navigator.of(context).pop();

    if (filepath == "" && context.mounted) {
      showDialog(
          context: context,
          builder: (context) => errorDialog(context));
    } else {
      final result = await OpenFile.open(filepath);
      //sketchy, but "open_file" left us no other choice
      if (result.message.contains("No APP found to open this file") && context.mounted) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("${AppLocalizations.of(context).error}!"),
              icon: const Icon(Icons.error),
              content: Text(
                  AppLocalizations.of(context).noAppToOpen),
              actions: [
                FilledButton(
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
      }
      callback(); // Call the callback function after the file is opened
    }
  });
}


void saveFile(BuildContext context, String url, String filename, String? fileSize, Function callback) {
  const platform = MethodChannel('io.github.lanis-mobile/storage');

  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => downloadDialog(context, fileSize));

  sph!.storage.downloadFile(url, filename).then((filepath) async {
    if(context.mounted) Navigator.of(context).pop();

    if (filepath == "" && context.mounted) {
      showDialog(
          context: context,
          builder: (context) => errorDialog(context));
    } else {
      await platform.invokeMethod('saveFile', {
        'fileName': filename,
        'mimeType': lookupMimeType(filepath) ?? "*/*",
        'filePath': filepath,
      });
      callback(); // Call the callback function after the file is opened
    }
  });
}

void shareFile(BuildContext context, String url, String filename, String? fileSize, Function callback) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => downloadDialog(context, fileSize));

  sph!.storage.downloadFile(url, filename).then((filepath) async {
    if(context.mounted) Navigator.of(context).pop();

    if (filepath == "" && context.mounted) {
      showDialog(
          context: context,
          builder: (context) => errorDialog(context));
    } else {
      await Share.shareXFiles([XFile(filepath)]);
      callback(); // Call the callback function after the file is opened
    }
  });
}

AlertDialog errorDialog(BuildContext context) => AlertDialog(
  title: Text("${AppLocalizations.of(context).error}!"),
  icon: const Icon(Icons.error),
  content: Text(
      AppLocalizations.of(context).reportError),
  actions: [
    TextButton(
        onPressed: () {
          launchUrl(Uri.parse("https://github.com/alessioC42/lanis-mobile/issues"));
        },
        child: const Text("GitHub")
    ),
    FilledButton(
      child: const Text('Ok'),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
  ],
);

AlertDialog downloadDialog(BuildContext context, String? fileSize) => AlertDialog(
  title: Text("Download... ${fileSize ?? ""}"),
  content: const Center(
    heightFactor: 1.1,
    child: CircularProgressIndicator(),
  ),
);

Future<File> moveFile(String originPath, String targetPath) async {
  final originFile = File.fromUri(Uri.file(originPath));
  try {
    return await originFile.rename(targetPath);
  } on FileSystemException catch (_) {
    final newFile = await originFile.copy(targetPath);
    await originFile.delete();
    return newFile;
  }
}