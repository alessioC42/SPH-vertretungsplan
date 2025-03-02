import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/applets/lessons/definition.dart';
import 'package:sph_plan/widgets/combined_applet_builder.dart';

import '../../../core/sph/sph.dart';
import '../../../models/lessons.dart';
import '../../../utils/file_picker.dart';
import '../../../utils/logger.dart';
import 'attendances.dart';
import 'lesson_list_tile.dart';

class LessonsStudentView extends StatefulWidget {
  final Function? openDrawerCb;
  const LessonsStudentView({super.key, this.openDrawerCb});

  @override
  State<StatefulWidget> createState() => _LessonsStudentViewState();
}

class _LessonsStudentViewState extends State<LessonsStudentView>
    with TickerProviderStateMixin {
  Widget noDataScreen(context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 60,
            ),
            Text(AppLocalizations.of(context).noCoursesFound)
          ],
        ),
      );

  Map<String, dynamic>? globalSettings;
  Future<void> Function(String, dynamic)? globalUpdateSetting;
  Lessons? homeworkLessons;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO: REMOVE THIS AFTER YOU'RE DONE BAKA!!!!!!!!!!!!
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            List<String> allowedExtensions = ["pdf", "ltx", "md", "docx", "txt"];
            PickedFile? pickedFile = await pickSingleFile(context, allowedExtensions);
            if (pickedFile == null) {
              logger.e("Picked file is NULL!");
            } else {
              OpenFile.open(pickedFile.path);
            }
          }
      ),
      appBar: widget.openDrawerCb != null
          ? AppBar(
              title: Text(lessonsDefinition.label(context)),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => widget.openDrawerCb!(),
              ),
              actions: globalSettings != null &&
                      globalUpdateSetting != null &&
                      homeworkLessons != null &&
                      homeworkLessons!.isNotEmpty
                  ? [
                      globalSettings!['showHomework'] == true
                          ? Tooltip(
                              message: AppLocalizations.of(context).lessons,
                              child: IconButton(
                                icon: const Icon(Icons.school_outlined),
                                onPressed: () {
                                  globalUpdateSetting!(
                                    'showHomework',
                                    false,
                                  );
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {});
                                  });
                                },
                              ),
                            )
                          : Tooltip(
                              message: AppLocalizations.of(context).homework,
                              child: IconButton(
                                icon: const Icon(Icons.task_outlined),
                                onPressed: () {
                                  globalUpdateSetting!(
                                    'showHomework',
                                    true,
                                  );
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {});
                                  });
                                },
                              ),
                            ),
                    ]
                  : null,
            )
          : null,
      body: CombinedAppletBuilder<Lessons>(
        parser: sph!.parser.lessonsStudentParser,
        phpUrl: lessonsDefinition.appletPhpUrl,
        settingsDefaults: lessonsDefinition.settingsDefaults,
        accountType: sph!.session.accountType,
        builder:
            (context, lessons, accountType, settings, updateSetting, refresh) {
          Lessons? attendanceLessons;
          homeworkLessons = lessons
              .where((element) => element.currentEntry?.homework != null)
              .toList();

          if (globalUpdateSetting == null || globalSettings == null) {
            globalUpdateSetting = updateSetting;
            globalSettings = settings;
            if (settings['showHomework'] == true &&
                homeworkLessons!.isEmpty) {
              updateSetting('showHomework', false);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {});
            });
          }

          if (settings['showHomework'] == true) {
            lessons = homeworkLessons!;

            lessons.sort((a, b) {
              if (a.currentEntry!.homework!.homeWorkDone ==
                  b.currentEntry?.homework?.homeWorkDone) {
                if (a.currentEntry?.topicDate != null &&
                    b.currentEntry?.topicDate != null) {
                  return a.currentEntry!.topicDate!
                      .compareTo(b.currentEntry!.topicDate!);
                } else {
                  return a.currentEntry?.topicDate == null ? 1 : -1;
                }
              }
              return (a.currentEntry?.homework?.homeWorkDone ?? false) ? 1 : -1;
            });
          } else {
            attendanceLessons = lessons
                .where((element) => element.attendances != null)
                .toList();
          }

          return Scaffold(
            body: RefreshIndicator(
              onRefresh: () => refresh!(),
              child: lessons.isNotEmpty
                  ? ListView.builder(
                      itemCount: lessons.length,
                      itemBuilder: (BuildContext context, int index) => Padding(
                        padding: EdgeInsets.only(
                          top: 4,
                          bottom: index == lessons.length - 1 ? 80 : 0,
                          left: 8,
                          right: 8,
                        ),
                        child: LessonListTile(lesson: lessons[index]),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        noDataScreen(context),
                      ],
                    ),
            ),
            floatingActionButton: Visibility(
              visible:
                  attendanceLessons != null && attendanceLessons.isNotEmpty,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AttendancesScreen(lessons: attendanceLessons!),
                    ),
                  );
                },
                label: Text(AppLocalizations.of(context).attendances),
                icon: const Icon(Icons.access_alarm),
              ),
            ),
          );
        },
      ),
    );
  }
}
