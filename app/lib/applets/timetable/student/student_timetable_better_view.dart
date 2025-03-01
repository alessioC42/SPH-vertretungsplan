import 'dart:async';
import 'dart:math';

import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sph_plan/applets/conversations/view/shared.dart';
import 'package:sph_plan/applets/timetable/definition.dart';
import 'package:sph_plan/applets/timetable/student/timetable_helper.dart';
import 'package:sph_plan/core/sph/sph.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/models/account_types.dart';
import 'package:sph_plan/models/timetable.dart';
import 'package:sph_plan/widgets/combined_applet_builder.dart';

final double itemHeight = 40;
double headerHeight = 40;
final double hourWidth = 70;

class StudentTimetableBetterView extends StatefulWidget {
  final Function? openDrawerCb;
  const StudentTimetableBetterView({super.key, this.openDrawerCb});

  @override
  State<StudentTimetableBetterView> createState() =>
      _StudentTimetableBetterViewState();
}

class _StudentTimetableBetterViewState
    extends State<StudentTimetableBetterView> {
  List<TimetableDay> getSelectedPlan(TimeTable data, TimeTableType selectedType,
      Map<String, dynamic> settings) {
    List<List<TimetableSubject>>? customLessons =
        TimeTableHelper.getCustomLessons(settings);
    if (selectedType == TimeTableType.own && data.planForOwn != null) {
      return TimeTableHelper.mergeByIndices(data.planForOwn!, customLessons);
    }
    return TimeTableHelper.mergeByIndices(data.planForAll!, customLessons);
  }

  int currentWeekIndex = -1;

  @override
  Widget build(BuildContext context) {
    return CombinedAppletBuilder<TimeTable>(
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
        builder: (BuildContext context,
            TimeTable timetable,
            _,
            Map<String, dynamic> settings,
            updateSettings,
            Future<void> Function()? refresh) {
          TimeTableType selectedType =
              settings['student-selected-type'] == 'TimeTableType.own'
                  ? TimeTableType.own
                  : TimeTableType.all;
          bool showByWeek = settings['student-selected-week'] == true;
          List<TimetableDay> selectedPlan =
              getSelectedPlan(timetable, selectedType, settings);
          final List<String> uniqueBadges = selectedPlan
              .expand((innerList) => innerList.map((e) => e.badge))
              .whereType<String>()
              .toSet()
              .toList();

          if (currentWeekIndex == -1) {
            currentWeekIndex = (showByWeek || timetable.weekBadge == null)
                ? 0
                : uniqueBadges.indexOf(timetable.weekBadge!) + 1;
          }

          TimeTableData data = TimeTableData(
              selectedPlan,
              timetable,
              settings,
              currentWeekIndex == 0
                  ? null
                  : uniqueBadges[currentWeekIndex - 1]);

          headerHeight =
              timetable.weekBadge != null && timetable.weekBadge!.isNotEmpty
                  ? 40
                  : 26;

          return Scaffold(
              appBar: AppBar(
                title: Text(timeTableDefinition.label(context)),
                leading: widget.openDrawerCb != null
                    ? IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => widget.openDrawerCb!(),
                      )
                    : null,
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        if (uniqueBadges.isNotEmpty &&
                            timetable.weekBadge != null)
                          TextButton(
                            onPressed: () {
                              updateSettings('student-selected-week',
                                  currentWeekIndex != 0);
                              currentWeekIndex = (currentWeekIndex + 1) %
                                  (uniqueBadges.length + 1);
                            },
                            child: Text(
                              (currentWeekIndex < 1)
                                  ? AppLocalizations.of(context)
                                      .timetableAllWeeks
                                  : AppLocalizations.of(context).timetableWeek(
                                      uniqueBadges[currentWeekIndex - 1]),
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TimeTableView(
                  data: data,
                  timetable: timetable,
                  settings: settings,
                  updateSettings: updateSettings,
                  refresh: refresh,
                ),
              ),
              floatingActionButton: timetable.planForOwn != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FloatingActionButton(
                          heroTag: "toggle",
                          tooltip: selectedType == TimeTableType.all
                              ? AppLocalizations.of(context)
                                  .timetableSwitchToPersonal
                              : AppLocalizations.of(context)
                                  .timetableSwitchToClass,
                          onPressed: () {
                            updateSettings(
                                'student-selected-type',
                                selectedType == TimeTableType.all
                                    ? 'TimeTableType.own'
                                    : 'TimeTableType.all');
                          },
                          child: Icon(selectedType == TimeTableType.all
                              ? Icons.person
                              : Icons.people),
                        ),
                      ],
                    )
                  : null);
        });
  }
}

class TimeTableView extends StatelessWidget {
  final TimeTableData data;
  final TimeTable timetable;
  final Map<String, dynamic> settings;
  final Function updateSettings;
  final Future<void> Function()? refresh;

  double calculateColumnHeight(List<TimeTableRow> rows) {
    double totalHeight = 0;
    for (var row in rows) {
      totalHeight +=
          (row.type == TimeTableRowType.lesson ? itemHeight : itemHeight - 20) +
              8;
    }
    return totalHeight;
  }

  int getCurrentWeekNumber() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final days = now.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  const TimeTableView(
      {super.key,
      required this.data,
      required this.timetable,
      required this.settings,
      required this.updateSettings,
      this.refresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh!,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Stack(
          children: [
            Row(
              spacing: 4.0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  spacing: 8.0,
                  children: [
                    SizedBox(
                      height: headerHeight,
                      width: hourWidth,
                      child: Column(
                        children: [
                          Text("KW ${getCurrentWeekNumber()}"),
                          timetable.weekBadge != null &&
                                  timetable.weekBadge!.isNotEmpty
                              ? Text(
                                  AppLocalizations.of(context)
                                      .timetableWeek(timetable.weekBadge!),
                                  style: TextStyle(
                                      overflow: TextOverflow.ellipsis))
                              : SizedBox(),
                        ],
                      ),
                    ),
                    for (var (row) in data.hours)
                      Container(
                        decoration: BoxDecoration(
                          color: row.type == TimeTableRowType.lesson
                              ? Theme.of(context).colorScheme.surfaceContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        width: hourWidth,
                        height: itemHeight -
                            (row.type == TimeTableRowType.lesson ? 0 : 20),
                        child: Column(
                          children: [
                            Text(row.label.replaceAll('Stunde', '')),
                            ...(row.type == TimeTableRowType.lesson
                                ? [
                                    Text("${row.startTime.format(context)} -"),
                                    // Text(row.endTime.format(context))
                                  ]
                                : [
                                    // Text(
                                    //   '${row.startTime.differenceInMinutes(row.endTime)} Min.'),
                                  ]),
                          ],
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Row(
                    spacing: 4.0,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int i = 0; i < data.timetableDays.length; i++)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: headerHeight - 26,
                              ),
                              Container(
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateTime(2020, 8, 3)
                                          .add(Duration(days: i))
                                          .format('E'),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              SizedBox(
                                height: calculateColumnHeight(data.hours),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Stack(
                                      children: [
                                        for (var (index, row)
                                            in data.hours.indexed)
                                          ListItem(
                                            iteration: index,
                                            row: row,
                                            data: data,
                                            timetableDays: data.timetableDays,
                                            i: i,
                                            width: constraints.maxWidth,
                                            settings: settings,
                                            updateSettings: updateSettings,
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            TimeMarkerWidget(data: data, timetable: timetable),
          ],
        ),
      ),
    );
  }
}

class TimeMarkerWidget extends StatefulWidget {
  const TimeMarkerWidget({
    super.key,
    required this.data,
    required this.timetable,
  });

  final TimeTableData data;
  final TimeTable timetable;

  @override
  State<TimeMarkerWidget> createState() => _TimeMarkerWidgetState();
}

class _TimeMarkerWidgetState extends State<TimeMarkerWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final int msUntilNextMinute = (60 - now.second) * 1000 - now.millisecond;
    _timer = Timer(Duration(milliseconds: msUntilNextMinute), () {
      if (mounted) setState(() {});
      _timer = Timer.periodic(Duration(minutes: 1), (timer) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double offset = 8;
    final now = TimeOfDay.fromDateTime(DateTime.now());

    if (now < widget.data.hours.first.startTime) {
      return SizedBox();
    }

    if (now > widget.data.hours.last.endTime) {
      return SizedBox();
    }

    for (var (lesson) in widget.data.hours) {
      // Check if lesson is already over and add the height of the lesson (or height of break)
      // If in the lesson add percentage of the lesson that has already passed
      final height =
          lesson.type == TimeTableRowType.lesson ? itemHeight : itemHeight - 20;
      if (now >= lesson.startTime && now <= lesson.endTime) {
        final diff = height *
            ((-now.differenceInMinutes(lesson.startTime)) /
                lesson.startTime.differenceInMinutes(lesson.endTime));
        offset += diff;

        break;
      } else if (now > lesson.endTime) {
        offset += height + 8;
      }
    }

    // Padding for the sidebar
    final barWidth = hourWidth + 4;
    final dayWidth = (MediaQuery.of(context).size.width - barWidth - 10) /
        widget.data.timetableDays.length;

    // Current day 0 Monday, 6 Sunday
    var currentDay = (DateTime.now().weekday - 1) % 7;

    const double lineHeight = 2;
    return Positioned(
      top: headerHeight + offset - (lineHeight / 2),
      left: hourWidth +
          4 +
          (currentDay * (dayWidth)) +
          (currentDay > 0 ? (currentDay - 1) * 2 : 0),
      child: Container(
        color: Colors.red,
        width: dayWidth - 2,
        height: lineHeight,
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final int iteration;
  final TimeTableRow row;
  final TimeTableData data;
  final List<List<TimetableSubject>> timetableDays;
  final int i;
  final double width;
  final Map<String, dynamic> settings;
  final Function updateSettings;

  const ListItem({
    super.key,
    required this.iteration,
    required this.row,
    required this.data,
    required this.timetableDays,
    required this.i,
    required this.width,
    required this.settings,
    required this.updateSettings,
  });

  @override
  Widget build(BuildContext context) {
    double verticalOffset = 0;
    for (var j = 0; j < iteration; j++) {
      if (data.hours[j].type == TimeTableRowType.lesson) {
        verticalOffset += itemHeight;
      } else {
        verticalOffset += itemHeight - 20;
      }
      verticalOffset += 8;
    }

    double horizontalOffset = 2;

    final List<TimetableSubject> timetable = timetableDays[i];
    List<TimetableSubject> subjects = timetable.where((element) {
      return element.startTime == row.startTime;
    }).toList();

    List<TimetableSubject> subjectsInRow = timetable.where((element) {
      return row.startTime >= element.startTime &&
          row.endTime <= element.endTime;
    }).toList();

    // For pause rows, return a single Positioned widget
    if (row.type == TimeTableRowType.pause) {
      bool hidePause = false;
      for (var subject in subjectsInRow) {
        int numPauses = data.hours
            .where((element) =>
                element.type == TimeTableRowType.pause &&
                element.startTime >= subject.startTime &&
                element.endTime <= subject.endTime)
            .length;
        if (numPauses > 0) {
          hidePause = true;
          break;
        }
      }

      if (!hidePause) {
        return ItemBlock(
          height: itemHeight - 20,
          width: width,
          offset: verticalOffset,
          hOffset: horizontalOffset,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainer
              .withValues(alpha: 0.5),
          onlyColor: true,
          settings: settings,
          updateSettings: updateSettings,
        );
      }
    }

    // If no subject, return an empty Positioned widget with a pre-determined height (or 0 height)
    if (subjects.isEmpty || row.type == TimeTableRowType.pause) {
      return ItemBlock.empty(
        height: 0,
        offset: verticalOffset,
        width: width,
        hOffset: horizontalOffset,
        updateSettings: updateSettings,
        settings: settings,
      );
    }

    // Determine horizontal space: calculate max overlapping subjects
    int maxSubjectsInRow = 0;
    for (var subject in subjects) {
      int maxSubjects = timetable.where((element) {
        return element.startTime >= subject.startTime &&
            element.startTime < subject.endTime;
      }).length;
      if (maxSubjects > maxSubjectsInRow) {
        maxSubjectsInRow = maxSubjects;
      }
    }

    subjectsInRow.sort((a, b) {
      return a.startTime.compareTo(b.startTime);
    });

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          for (var subject in subjects)
            Builder(builder: (context) {
              int indexInRow = subjectsInRow.indexOf(subject);
              int maxNum = max(maxSubjectsInRow, subjectsInRow.length);

              double hOffset = (width / maxNum) * indexInRow;

              int numPauses = data.hours
                  .where((element) =>
                      element.type == TimeTableRowType.pause &&
                      element.startTime >= subject.startTime &&
                      element.endTime <= subject.endTime)
                  .length;

              return ItemBlock(
                subject: subject,
                height: itemHeight * subject.duration +
                    ((subject.duration - 1) * 8) +
                    (numPauses * (itemHeight - 20 + 8)),
                color: TimeTableHelper.getColorForLesson(settings, subject),
                offset: verticalOffset,
                // Calculate left offset based on subject index and max overlapping subjects
                hOffset: hOffset + (maxNum >= 2 ? 0 : 0),
                width: (width / maxNum) - (maxNum >= 2 ? 2 : 0),
                settings: settings,
                updateSettings: updateSettings,
              );
            }),
        ],
      ),
    );
  }
}

class ItemBlock extends StatelessWidget {
  final TimetableSubject? subject;
  final double height;
  final Color color;
  final bool empty;
  final double offset;
  final double width;
  final double? hOffset;
  final bool onlyColor;

  final Map<String, dynamic> settings;
  final Function updateSettings;

  const ItemBlock({
    super.key,
    this.subject,
    required this.height,
    this.color = Colors.white,
    this.empty = false,
    required this.offset,
    required this.width,
    this.hOffset,
    this.onlyColor = false,
    required this.settings,
    required this.updateSettings,
  });

  void showColorPicker(BuildContext context, Map<String, dynamic> settings,
      Function updateSettings, TimetableSubject lesson) {
    Color selectedColor = TimeTableHelper.getColorForLesson(settings, lesson);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (c) => {
                selectedColor = c,
              },
              enableAlpha: false,
              labelTypes: [],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(AppLocalizations.of(context).clear),
              onPressed: () {
                updateSettings('lesson-colors', {
                  ...settings['lesson-colors'],
                  lesson.id!.split('-')[0]: null
                });

                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context).select),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                if (settings['lesson-colors'] == null) {
                  settings['lesson-colors'] = {};
                }
                updateSettings('lesson-colors', {
                  ...settings['lesson-colors'],
                  lesson.id!.split('-')[0]:
                      selectedColor.toHexString(enableAlpha: false)
                });
              },
            ),
          ],
        );
      },
    );
  }

  void showSubject(BuildContext context) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SizedBox(
            width: double.infinity,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subject?.name ??
                              AppLocalizations.of(context).unknownLesson,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  showColorPicker(context, settings,
                                      updateSettings, subject!);
                                },
                                icon: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: color),
                                )),
                            if (subject != null &&
                                (subject?.id == null ||
                                    !subject!.id!.startsWith('custom')))
                              IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    updateSettings('hidden-lessons', [
                                      ...?settings['hidden-lessons'],
                                      subject!.id
                                    ]);
                                    showSnackbar(
                                        context,
                                        AppLocalizations.of(context)
                                            .lessonHidden(subject!.name!),
                                        seconds: 3);
                                  },
                                  icon: const Icon(
                                      Icons.visibility_off_outlined)),
                          ],
                        )
                      ],
                    ),
                  ),
                  if (subject?.raum != null)
                    modalSheetItem(subject!.raum!, Icons.place),
                  modalSheetItem(
                    "${subject!.startTime.format(context)} - ${subject!.endTime.format(context)} (${subject!.duration} ${subject!.duration == 1 ? "Stunde" : "Stunden"})",
                    Icons.access_time,
                  ),
                  if (subject?.lehrer != null)
                    modalSheetItem(subject!.lehrer!, Icons.person),
                  if (subject?.badge != null)
                    modalSheetItem(subject!.badge!, Icons.info),
                ],
              ),
            ),
          );
        });
  }

  Widget modalSheetItem(String content, IconData icon) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                icon,
                size: 24,
              ),
            ),
            Text(content, style: Theme.of(context).textTheme.labelLarge)
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      fontSize: 12,
      color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
    );

    double calcWidth =
        max(1, width - ((width > (hOffset ?? 0)) ? (hOffset ?? 0) : 0));

    return Positioned(
      top: offset,
      left: hOffset,
      child: InkWell(
        onTap: subject != null ? () => showSubject(context) : null,
        child: Container(
          width: calcWidth,
          height: height,
          clipBehavior:
              Clip.hardEdge, // Clips any overflow, useful for the y axis
          decoration: BoxDecoration(
            border: Border.all(color: color, width: min(1, calcWidth / 3)),
            color: color == Colors.white ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.all(4.0),
          child: (!onlyColor && subject != null)
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        subject!.name ?? '',
                        style: textStyle,
                        maxLines: 1,
                      ),
                      if (subject!.lehrer != null)
                        Text(
                          subject!.lehrer!,
                          style: textStyle,
                          maxLines: 1,
                        ),
                      if (subject!.raum != null)
                        Text(
                          subject!.raum!,
                          style: textStyle,
                          maxLines: 1,
                        ),
                    ],
                  ),
                )
              : SizedBox(),
        ),
      ),
    );
  }

  const ItemBlock.empty({
    super.key,
    required this.height,
    required this.offset,
    required this.width,
    required this.hOffset,
    required this.updateSettings,
    required this.settings,
  })  : subject = null,
        color = Colors.white,
        onlyColor = false,
        empty = true;
}

class TimeTableData {
  final List<TimeTableRow> hours = [];
  late final String? weekBadge;
  List<TimetableDay> timetableDays = [];

  bool isCurrentWeek(TimetableSubject lesson, bool sameWeek) {
    return (weekBadge == null ||
            weekBadge == "" ||
            lesson.badge == null ||
            lesson.badge == "")
        ? true
        : sameWeek
            ? (weekBadge == lesson.badge)
            : (weekBadge != lesson.badge);
  }

  TimeTableData(List<TimetableDay> data, TimeTable timetable,
      Map<String, dynamic> settings, this.weekBadge) {
    for (var (index, hour) in timetable.hours!.indexed) {
      if (index > 0 && timetable.hours![index - 1].endTime != hour.startTime) {
        if (timetable.hours![index - 1].endTime
                .differenceInMinutes(hour.startTime) >
            10) {
          hours.add(TimeTableRow(
              TimeTableRowType.pause,
              timetable.hours![index - 1].endTime,
              hour.startTime,
              'Pause',
              -1));
        }
      }
      hours.add(hour);
    }

    List<dynamic>? hiddenLessons = settings['hidden-lessons'];
    for (var day in data) {
      List<TimetableSubject> dayData = [];
      for (var subject in day) {
        if (isCurrentWeek(subject, true) &&
            (hiddenLessons == null || !hiddenLessons.contains(subject.id))) {
          dayData.add(subject);
        }
      }
      timetableDays.add(dayData);
    }

    timetableDays =
        timetableDays.where((TimetableDay day) => day.isNotEmpty).toList();
  }
}

class TimeTableRow {
  final TimeTableRowType type;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String label;
  final int lessonIndex;

  TimeTableRow(
      this.type, this.startTime, this.endTime, this.label, this.lessonIndex);

  @override
  String toString() {
    return 'TimeTableRow{type: \$type, subjects: \$subjects, startTime: \$startTime, endTime: \$endTime, label: \$label}';
  }

  @override
  bool operator ==(Object other) {
    if (other is TimeTableRow) {
      return type == other.type &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          lessonIndex == other.lessonIndex &&
          label == other.label;
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'label': label,
      'lessonIndex': lessonIndex,
    };
  }

  factory TimeTableRow.fromJson(Map<String, dynamic> json) {
    TimeTableRowType rowType = json['type'] == 'TimeTableRowType.lesson'
        ? TimeTableRowType.lesson
        : TimeTableRowType.pause;
    TimeOfDay start = TimeOfDay(
        hour: json['startTime']['hour'], minute: json['startTime']['minute']);
    TimeOfDay end = TimeOfDay(
        hour: json['endTime']['hour'], minute: json['endTime']['minute']);
    TimeTableRow row =
        TimeTableRow(rowType, start, end, json['label'], json['lessonIndex']);
    return row;
  }
}

extension TimeOfDayExtension on TimeOfDay {
  int differenceInMinutes(TimeOfDay other) {
    return (other.hour - hour) * 60 + other.minute - minute;
  }

  operator <=(TimeOfDay other) {
    return hour < other.hour || (hour == other.hour && minute <= other.minute);
  }

  operator >=(TimeOfDay other) {
    return hour > other.hour || (hour == other.hour && minute >= other.minute);
  }

  operator >(TimeOfDay other) {
    return hour > other.hour || (hour == other.hour && minute > other.minute);
  }

  operator <(TimeOfDay other) {
    return hour < other.hour || (hour == other.hour && minute < other.minute);
  }
}

enum TimeTableRowType { lesson, pause }
