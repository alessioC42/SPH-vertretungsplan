import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sph_plan/applets/conversations/view/shared.dart';
import 'package:sph_plan/applets/timetable/definition.dart';
import 'package:sph_plan/applets/timetable/student/student_timetable_view.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/models/account_types.dart';
import 'package:sph_plan/utils/large_appbar.dart';
import 'package:sph_plan/widgets/combined_applet_builder.dart';

import '../../../core/sph/sph.dart';
import '../../../models/timetable.dart';

class StudentTimetableSettings extends StatefulWidget {
  final Function? openDrawerCb;
  final bool showBack;
  const StudentTimetableSettings(
      {super.key, this.openDrawerCb, this.showBack = true});

  @override
  State<StudentTimetableSettings> createState() =>
      _StudentTimetableSettingsState();
}

class _StudentTimetableSettingsState extends State<StudentTimetableSettings> {
  List<TimetableDay> getSelectedPlan(
      TimeTable data, TimeTableType selectedType) {
    if (selectedType == TimeTableType.own) {
      return data.planForOwn!;
    }
    return data.planForAll!;
  }

  void showCustomLessonDialog(
      TimeTable currentTimetable,
      updateSettings,
      Map<String, dynamic> settings,
      List<List<TimetableSubject>>? customLessons,
      int currentDay,
      {TimetableSubject? lesson}) {
    TimeOfDay startTime =
        TimeOfDay(hour: (TimeOfDay.now().hour - 1).clamp(0, 24), minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: TimeOfDay.now().hour, minute: 0);
    int selectedWeek = 0;
    List<String?> allBadges = currentTimetable.planForAll!
        .expand((day) => day.map((lesson) => lesson.badge))
        .where((badge) => badge != null)
        .toSet()
        .toList();
    final String noBadge = '-';
    final TextEditingController nameController = TextEditingController();
    final TextEditingController teacherController = TextEditingController();
    final TextEditingController roomController = TextEditingController();

    if (lesson != null) {
      nameController.text = lesson.name ?? '';
      teacherController.text = lesson.lehrer ?? '';
      roomController.text = lesson.raum ?? '';
      startTime = lesson.startTime;
      endTime = lesson.endTime;
      selectedWeek =
          lesson.badge == null ? 0 : allBadges.indexOf(lesson.badge) + 1;
    }

    showModalBottomSheet(
        showDragHandle: true,
        useSafeArea: true,
        context: context,
        isScrollControlled: true,
        builder: (context1) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
                right: 16.0,
                left: 16.0,
                top: 16.0),
            child: StatefulBuilder(builder: (context1, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16.0,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                        labelText:
                            '${AppLocalizations.of(context).lessonName}*',
                        helperText:
                            '*${AppLocalizations.of(context).required}'),
                  ),
                  Row(
                    spacing: 8.0,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: teacherController,
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).teacher),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: roomController,
                          decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).room),
                        ),
                      )
                    ],
                  ),
                  Row(
                    spacing: 8.0,
                    children: [
                      Expanded(
                        child: Container(
                          height: 56.0,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            spacing: 8.0,
                            children: [
                              Icon(Icons.access_time),
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    TimeOfDay? selected = await showTimePicker(
                                        context: context,
                                        initialTime: startTime);
                                    if (selected != null) {
                                      if (selected.isAfter(endTime)) {
                                        return;
                                      }
                                      setState(() {
                                        startTime = selected;
                                      });
                                    }
                                  },
                                  child: Text(startTime.format(context)),
                                ),
                              ),
                              Text('-'),
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    TimeOfDay? selected = await showTimePicker(
                                        context: context, initialTime: endTime);
                                    if (selected != null) {
                                      if (selected.isBefore(startTime)) {
                                        return;
                                      }
                                      setState(() {
                                        endTime = selected;
                                      });
                                    }
                                  },
                                  child: Text(endTime.format(context)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (allBadges.isNotEmpty)
                        DropdownMenu(
                          width: 130.0,
                          label: Text(AppLocalizations.of(context).week),
                          initialSelection: [
                            noBadge,
                            ...allBadges
                          ][selectedWeek],
                          onSelected: (value) {
                            setState(() {
                              selectedWeek =
                                  [noBadge, ...allBadges].indexOf(value!);
                            });
                          },
                          dropdownMenuEntries: [noBadge, ...allBadges]
                              .map((badge) => DropdownMenuEntry(
                                    value: badge,
                                    label: badge != noBadge
                                        ? AppLocalizations.of(context)
                                            .timetableWeek(badge ?? '')
                                        : badge!,
                                  ))
                              .toList(),
                        )
                    ],
                  ),
                  ElevatedButton(
                      onPressed: nameController.text.isNotEmpty
                          ? () {
                              TimetableSubject newLesson = TimetableSubject(
                                  id:
                                      'custom${nameController.text.replaceAll('-', '_')}-$currentDay-${startTime.hour}-${startTime.minute}',
                                  name: nameController.text,
                                  raum: roomController.text.isEmpty
                                      ? null
                                      : roomController.text,
                                  lehrer: teacherController.text,
                                  badge: selectedWeek == 0
                                      ? null
                                      : allBadges[selectedWeek - 1],
                                  duration: 1,
                                  startTime: startTime,
                                  endTime: endTime);

                              if (settings['custom-lessons'] == null) {
                                settings['custom-lessons'] = ',,,,,,,'
                                    .split(',')
                                    .map((_) => [])
                                    .toList();
                              }

                              List<List<TimetableSubject>>? days =
                                  TimeTableHelper.getCustomLessons(settings);

                              if (days == null) {
                                throw Exception('days is null');
                              }

                              if (lesson != null) {
                                days[currentDay].remove(lesson);
                              }
                              days[currentDay].add(newLesson);

                              updateSettings('custom-lessons', days);
                              Navigator.of(context).pop();
                              showSnackbar(
                                  context,
                                  AppLocalizations.of(context)
                                      .lessonAdded(newLesson.name!));
                            }
                          : null,
                      child: Text(lesson == null
                          ? AppLocalizations.of(context).addLesson
                          : AppLocalizations.of(context).editLesson)),
                ],
              );
            }),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LargeAppBar(
        title: Text(timeTableDefinition.label(context)),
        back: () => Navigator.of(context).pop(),
        showBackButton: widget.showBack,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: CombinedAppletBuilder<TimeTable>(
        parser: sph!.parser.timetableStudentParser,
        phpUrl: timeTableDefinition.appletPhpUrl,
        settingsDefaults: timeTableDefinition.settingsDefaults,
        accountType: AccountType.student,
        loadingAppBar: AppBar(
          title: Text(timeTableDefinition.label(context)),
          leading: widget.openDrawerCb != null
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => widget.openDrawerCb!(),
                )
              : null,
        ),
        builder: (context, timetable, _, settings, updateSettings, refresh) {
          final ids = settings['hidden-lessons'];
          Map<int, List<TimetableSubject>> lessons = {};

          for (var (dayIndex, day) in timetable.planForAll!.indexed) {
            lessons[dayIndex] = [];
            if (ids == null) continue;
            for (var lesson in day) {
              if (!ids.contains(lesson.id)) continue;
              lessons[dayIndex]!.add(lesson);
            }
          }

          List<List<TimetableSubject>>? customLessons =
              TimeTableHelper.getCustomLessons(settings);

          List<String> weekDays =
              DateFormat.EEEE(Platform.localeName).dateSymbols.WEEKDAYS;
          weekDays = weekDays.sublist(1)..add(weekDays[0]);

          return DefaultTabController(
            length: weekDays.length,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: weekDays.map((dayName) => Tab(text: dayName)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: weekDays.map((dayName) {
                      final dayLessons =
                          lessons[weekDays.indexOf(dayName)] ?? [];
                      final List<TimetableSubject>? customDayLessons =
                          customLessons?[weekDays.indexOf(dayName)];
                      final currentDay = weekDays.indexOf(dayName);
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            spacing: 8,
                            children: [
                              Card(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .hiddenLessons,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                    ),
                                    if (dayLessons.isNotEmpty)
                                      ...dayLessons.map((lesson) {
                                        return ListTile(
                                          dense: true,
                                          title: Text(lesson.name ?? ''),
                                          subtitle: Text(
                                            "${lesson.startTime.format(context)} - ${lesson.endTime.format(context)}",
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () {
                                              setState(() {
                                                updateSettings(
                                                    'hidden-lessons',
                                                    settings['hidden-lessons']
                                                      ..remove(lesson.id));
                                              });
                                            },
                                          ),
                                        );
                                      }),
                                    if (dayLessons.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          AppLocalizations.of(context)
                                              .hiddenLessonsDescription,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                              Card(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .customLessons,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                    ),
                                    if (customDayLessons != null &&
                                        customDayLessons.isNotEmpty)
                                      ...customDayLessons.map((lesson) {
                                        return ListTile(
                                          dense: true,
                                          title: Text(lesson.name ?? ''),
                                          subtitle: Text(
                                            "${lesson.startTime.format(context)} - ${lesson.endTime.format(context)}",
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit),
                                                onPressed: () =>
                                                    showCustomLessonDialog(
                                                        timetable,
                                                        updateSettings,
                                                        settings,
                                                        customLessons,
                                                        currentDay,
                                                        lesson: lesson),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete),
                                                onPressed: () {
                                                  setState(() {
                                                    customLessons![currentDay]
                                                        .remove(lesson);
                                                    updateSettings(
                                                        'custom-lessons',
                                                        customLessons);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0, vertical: 2.0),
                                      child: ElevatedButton(
                                          onPressed: () =>
                                              showCustomLessonDialog(
                                                  timetable,
                                                  updateSettings,
                                                  settings,
                                                  customLessons,
                                                  currentDay),
                                          child: Text(
                                              AppLocalizations.of(context)
                                                  .addLesson)),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 32.0),
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
                          AppLocalizations.of(context)
                              .customizeTimetableDisclaimer,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        )
                      ],
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
