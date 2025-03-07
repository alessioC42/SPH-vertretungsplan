import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sph_plan/utils/file_operations.dart';
import 'package:sph_plan/utils/logger.dart';
import 'package:sph_plan/utils/random.dart';
import 'package:pdf/widgets.dart' as pw;

import '../generated/l10n.dart';

class PickedFile {
  String name;

  /// The size in bytes (is 0 if something went wrong)
  num? size;

  String? path;

  String get extension => name.split('.').last;

  /// May be null if no mimeType was found
  String? get mimeType => lookupMimeType(path!);

  MediaType? get mediaType => MediaType.parse(mimeType!);

  PickedFile({required this.name, this.size, this.path});
}

extension Actions on PickedFile {
  Future<MultipartFile> intoMultipart() async {
    return await MultipartFile.fromFile(
      path!,
      filename: name,
      contentType: mediaType,
    );
  }
}

const storageChannel = MethodChannel('io.github.lanis-mobile/storage');

/// Allows the user to pick any file using any supported method
Future<PickedFile?> pickSingleFile(
    BuildContext context, List<String>? allowedExtensions) async {
  List<bool> allowedMethods = [true, true, true, true];
  return showPickerUI(context, allowedMethods, allowedExtensions);
}

/// Allowed Methods (Position in [List<bool>]):
/// ```
/// 0 = File Manager
/// 1 = Scan Document (Requires API >= 26)
/// 2 = Camera
/// 3 = Gallery (iOS Only)
/// ```
Future<PickedFile?> showPickerUI(BuildContext context,
    List<bool> allowedMethods, List<String>? allowedExtensions) async {
  bool documentScannerSupported = true;

  if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt < 26) {
      documentScannerSupported = false;
    }
  }

  PickedFile? pickedFile;
  if (context.mounted) {
    await showModalBottomSheet(
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
                    if (allowedMethods[0])
                      (MenuItemButton(
                        onPressed: () async {
                          pickedFile = await pickFileUsingDocumentsUI(allowedExtensions);
                          if (context.mounted && pickedFile != null) {
                            Navigator.pop(context);
                          }
                        },
                        child: Row(
                          children: [
                            Padding(padding: EdgeInsets.only(left: 10.0)),
                            Icon(Icons.file_open_rounded),
                            Padding(padding: EdgeInsets.only(right: 8.0)),
                            Text(AppLocalizations.of(context).fileManager)
                          ],
                        ),
                      )),
                    if (allowedMethods[1] && documentScannerSupported)
                      (MenuItemButton(
                        onPressed: () async {
                          pickedFile = await pickFileUsingDocumentScanner(context);

                          if (context.mounted && pickedFile != null) {
                            Navigator.pop(context);
                          }
                        },
                        child: Row(
                          children: [
                            Padding(padding: EdgeInsets.only(left: 10.0)),
                            Icon(Icons.document_scanner_rounded),
                            Padding(padding: EdgeInsets.only(right: 8.0)),
                            Text(AppLocalizations.of(context).documentScanner)
                          ],
                        ),
                      )),
                    if (allowedMethods[2])
                      (MenuItemButton(
                        onPressed: () async {
                          pickedFile = await pickFileUsingCamera(context);
                          if (context.mounted && pickedFile != null) {
                            Navigator.pop(context);
                          }
                        },
                        child: Row(
                          children: [
                            Padding(padding: EdgeInsets.only(left: 10.0)),
                            Icon(Icons.camera_alt_rounded),
                            Padding(padding: EdgeInsets.only(right: 8.0)),
                            Text(AppLocalizations.of(context).camera)
                          ],
                        ),
                      )),
                    if (allowedMethods[3] && Platform.isIOS) // DocumentsUI supports galleries and the photo picker is horrible (from a user perspective)
                      (
                          MenuItemButton(
                        onPressed: () async {
                          pickedFile = await pickFileUsingGallery(context);
                          if (context.mounted && pickedFile != null) {
                            Navigator.pop(context);
                          }
                        },
                        child: Row(
                          children: [
                            Padding(padding: EdgeInsets.only(left: 10.0)),
                            Icon(Icons.photo_library_rounded),
                            Padding(padding: EdgeInsets.only(right: 8.0)),
                            Text(AppLocalizations.of(context).gallery)
                          ],
                        ),
                      ))
                  ],
                ),
              ),
            ),
          );
        });
  }
  return pickedFile;
}

Future<PickedFile?> pickFileUsingDocumentsUI(
    List<String>? allowedExtensions) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
  );

  if (result == null) {
    return null;
  } else {
    final PlatformFile firstFile = result.files.first;

    final PickedFile pickedFile = PickedFile(
        name: firstFile.name, path: firstFile.path, size: firstFile.size);
    return pickedFile;
  }
}

Future<PickedFile?> pickFileUsingCamera(BuildContext context) async {
  final ImagePicker imagePicker = ImagePicker();
  final image = await imagePicker.pickImage(source: ImageSource.camera);
  String? path = image?.path;

  if (path == null) {
    return null;
  }

  if (context.mounted) {
    String? name = await askFileName(context);

    if (name == null) {
      return null;
    }

    name = "$name.${path.split(".").last}";
    String newPath = "${(await getApplicationCacheDirectory()).path}/$name";
    await moveFile(path, newPath);

    PickedFile pickedFile = PickedFile(name: newPath.split("/").last, path: newPath, size: await File(newPath).length());
    return pickedFile;
  }

  return null;
}

/// This will return null if called on anything other than iOS
Future<PickedFile?> pickFileUsingGallery(BuildContext context) async {
  if (Platform.isIOS) {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      return null;
    }

    if (context.mounted) {
      final name = await askFileName(context);

      if (name == null) {
        return null;
      }

      final String extension = image.path.split(".").last;
      final path = "${(await getApplicationCacheDirectory()).path}/$name.$extension";
      await moveFile(image.path, path);
      final file = File(path);
      final size = await file.length();

      final PickedFile pickedFile = PickedFile(name: file.path.split("/").last, size: size, path: file.path);
      return pickedFile;
    }
  }
  return null;
}

Future<PickedFile?> pickFileUsingDocumentScanner(BuildContext context) async {
  List<String> paths = List.empty(growable: true);
  bool breakLoop = false;

  if (Platform.isAndroid) {
    while (true) {
      String? path = await storageChannel.invokeMethod("scanDocument");
      if (path == null) {
        return null;
      }

      final newPath = "$path-${getRandomString(32)}";
      await moveFile(path, newPath);
      paths.add(newPath);

      if (context.mounted) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context).morePages),
                content:
                    Text(AppLocalizations.of(context).scanAnotherPageQuestion),
                actions: <Widget>[
                  ElevatedButton(
                      onPressed: () {
                        breakLoop = true;
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context).no)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context).yes))
                ],
              );
            });
        if (breakLoop) {
          break;
        }
      }
    }
  } else if (Platform.isIOS) {

    dynamic scannedDocuments;
    try {
      scannedDocuments = await FlutterDocScanner().getScannedDocumentAsImages(page: 4);
    } on PlatformException {
      return null;
    }

    logger.d("scannedDocuments: $scannedDocuments");

    final List<Object?> list = scannedDocuments;

    for (final s in list) {
      final uri = Uri.parse(s.toString());
      paths.add(uri.path);
    }
  } else {
    return null;
  }
  List<String>? newPaths;

  if (context.mounted) {
    newPaths = await imageCycler(context, paths);
  }

  if (newPaths == null) {
    return null;
  }

  String? filePath;
  if (context.mounted) {
    filePath = await mergeImagesIntoPDF(newPaths, context);
  }

  if (filePath == null) {
    return null;
  }

  File file = File(filePath);

  PickedFile pickedFile = PickedFile(name: filePath.split("/").last, path: filePath, size: await file.length());
  return pickedFile;
}

Future<String?> askFileName(BuildContext context) async {
  String? result;
  final TextEditingController controller = TextEditingController();

  await showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).filename),
      content: TextField(
        controller: controller,
      ),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
          child: Text(AppLocalizations.of(context).confirm),
          onPressed: () {
            Navigator.of(context).pop();
            result = controller.text;
          },
        ),
      ],
    );
  },
  );

  return result;
}

Future<String?> mergeImagesIntoPDF(List<String> paths, BuildContext context) async {
  String? pathName = await askFileName(context);
  if (pathName == null) {
    return null;
  }

  if (!pathName.endsWith(".pdf")) {
    pathName = "$pathName.pdf";
  }

  pw.Document pdf = pw.Document();
  for (String path in paths) {
    File file = File(path);
    final bytes = await file.readAsBytes();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(
              pw.MemoryImage(bytes)
            ),
            widthFactor: double.infinity,
          );
        },
        margin: pw.EdgeInsets.zero,
      )
    );
  }

  final cache = (await getApplicationCacheDirectory()).path;
  final path = "$cache/$pathName";
  final file = File(path);
  file.create();
  file.writeAsBytes(await pdf.save());
  return path;
}

Future<List<String>?> imageCycler(BuildContext context, List<String> paths) async {
  return await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ImageCyclerScreen(initialPaths: paths),
    ),
  );
}

class ImageCyclerScreen extends StatefulWidget {
  final List<String> initialPaths;

  const ImageCyclerScreen({super.key, required this.initialPaths});

  @override
  ImageCyclerScreenState createState() => ImageCyclerScreenState();
}

class ImageCyclerScreenState extends State<ImageCyclerScreen> {
  late List<String> paths;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    paths = List.from(widget.initialPaths);
  }

  void removeImage(int index) {
    setState(() {
      paths.removeAt(index);
      if (currentIndex >= paths.length) {
        currentIndex = paths.length - 1;
      }
      if (paths.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.check_rounded),
            onPressed: () {
              Navigator.pop(context, paths);
            },
            tooltip: AppLocalizations.of(context).confirm,
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              if (paths.isNotEmpty)
                (Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: InteractiveViewer(
                      maxScale: 10,
                      minScale: 1,
                      child: Image.file(File(paths[currentIndex])),
                    ),
                  )
                )),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                          child: currentIndex > 0 ? IconButton(
                            padding: EdgeInsets.all(0.0),
                            icon: Icon(Icons.arrow_left_rounded, size: 48.0),
                            tooltip: AppLocalizations.of(context).previousImage,
                            onPressed: () {
                              setState(() {
                                currentIndex = currentIndex - 1;
                              });
                            },
                          ) : SizedBox(width: 48.0)
                      ),
                      Flexible(
                          child: IconButton(
                            padding: EdgeInsets.all(0.0),
                            icon: Icon(Icons.delete_forever_rounded, size: 32.0,),
                            tooltip: AppLocalizations.of(context).deleteImage,
                            onPressed: () => removeImage(currentIndex),
                          ),
                      ),
                      Flexible(
                        child: currentIndex < paths.length - 1 ? IconButton(
                          padding: EdgeInsets.all(0.0),
                          icon: Icon(Icons.arrow_right_rounded, size: 48.0),
                          tooltip: AppLocalizations.of(context).nextImage,
                          onPressed: () {
                            setState(() {
                              currentIndex = currentIndex + 1;
                            });
                          },
                        ) : SizedBox(width: 48.0),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
