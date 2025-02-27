import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sph_plan/applets/conversations/view/shared.dart';
import 'package:sph_plan/applets/timetable/definition.dart';
import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/models/account_types.dart';
import 'package:sph_plan/utils/extensions.dart';
import 'package:sph_plan/utils/random_color.dart';
import 'package:sph_plan/widgets/combined_applet_builder.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../core/sph/sph.dart';
import '../../../models/timetable.dart';

class StudentTimetableView extends StatefulWidget {
  final Function? openDrawerCb;
  const StudentTimetableView({super.key, this.openDrawerCb});

  @override
  State<StudentTimetableView> createState() => _StudentTimetableViewState();
}

class _StudentTimetableViewState extends State<StudentTimetableView> {
  Widget modalSheetItem(String content, IconData icon) {
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
  }

  List<TimetableDay> getSelectedPlan(TimeTable data, TimeTableType selectedType,
      Map<String, dynamic> settings) {
    List<List<TimetableSubject>>? customLessons =
        TimeTableHelper.getCustomLessons(settings);
    if (selectedType == TimeTableType.own && data.planForOwn != null) {
      return TimeTableHelper.mergeByIndices(data.planForOwn!, customLessons);
    }
    return TimeTableHelper.mergeByIndices(data.planForAll!, customLessons);
  }

  int getCurrentWeekNumber() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final days = now.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  void showColorPicker(dynamic settings,
      Future<void> Function(String, dynamic) updateSettings, lesson) {
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
                  lesson.id.split('-')[0]: null
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
                  lesson.id.split('-')[0]:
                      selectedColor.toHexString(enableAlpha: false)
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var controller = CalendarController();
    int currentWeekIndex = -1;

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
      builder: (context, timetable, _, settings, updateSettings, refresh) {
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

        final CalendarView view =
            switch (settings['current-timetable-view']! as String) {
          "CalendarView.day" => CalendarView.day,
          "CalendarView.week" => CalendarView.week,
          "CalendarView.workWeek" => CalendarView.workWeek,
          String() => throw UnimplementedError(),
        };

        TimeTableDataSource source = TimeTableDataSource(
            context,
            selectedPlan,
            currentWeekIndex == 0 ? null : uniqueBadges[currentWeekIndex - 1],
            settings);

        return Scaffold(
            appBar: AppBar(
              title: Text(timeTableDefinition.label(context)),
              leading: widget.openDrawerCb != null
                  ? IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => widget.openDrawerCb!(),
                    )
                  : null,
            ),
            body: Stack(
              children: [
                SfCalendar(
                  headerStyle: CalendarHeaderStyle(
                      textAlign: TextAlign.left,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor),
                  headerDateFormat: " ", // This needs to be a space
                  view: view,
                  allowedViews: [
                    CalendarView.day,
                    CalendarView.week,
                    CalendarView.workWeek,
                  ],
                  timeSlotViewSettings: TimeSlotViewSettings(
                      timeFormat: "HH:mm",
                      startHour: source.earliestHour.floor().toTimeDouble(),
                      endHour: source.latestHour.ceil().toTimeDouble(),
                      timeInterval: Duration(minutes: 30),
                      timeIntervalHeight: 30),
                  firstDayOfWeek: DateTime.monday,
                  dataSource: source,
                  minDate: DateTime.now(),
                  maxDate: DateTime.now().add(const Duration(days: 7)),
                  controller: controller,
                  onViewChanged: (_) => updateSettings(
                      'current-timetable-view', controller.view.toString()),
                  onTap: (details) {
                    if (details.appointments != null) {
                      final appointment = details.appointments!.first;

                      final helperIDs =
                          appointment.id.split("-").map(int.parse).toList();
                      final TimetableSubject selected =
                          selectedPlan[helperIDs[0]][helperIDs[1]];

                      showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          builder: (context) {
                            return SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 20.0, right: 20.0, bottom: 20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            selected.name ??
                                                AppLocalizations.of(context)
                                                    .unknownLesson,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                  onPressed: () {
                                                    showColorPicker(
                                                        settings,
                                                        updateSettings,
                                                        selected);
                                                  },
                                                  icon: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: TimeTableHelper
                                                            .getColorForLesson(
                                                                settings,
                                                                selected)),
                                                  )),
                                              if (selected.id == null ||
                                                  !selected.id!
                                                      .startsWith('custom'))
                                                IconButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      updateSettings(
                                                          'hidden-lessons', [
                                                        ...?settings[
                                                            'hidden-lessons'],
                                                        selected.id
                                                      ]);

                                                      showSnackbar(
                                                          context,
                                                          AppLocalizations.of(
                                                                  context)
                                                              .lessonHidden(
                                                                  selected
                                                                      .name!),
                                                          seconds: 5,
                                                          action:
                                                              SnackBarAction(
                                                                  label: AppLocalizations.of(
                                                                          context)
                                                                      .undo,
                                                                  onPressed:
                                                                      () {
                                                                    updateSettings(
                                                                        'hidden-lessons',
                                                                        settings['hidden-lessons']
                                                                            .where((element) =>
                                                                                element !=
                                                                                selected.id)
                                                                            .toList());
                                                                  }));
                                                    },
                                                    icon: const Icon(Icons
                                                        .visibility_off_outlined)),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    if (selected.raum != null)
                                      modalSheetItem(
                                          selected.raum!, Icons.place),
                                    modalSheetItem(
                                      "${selected.startTime.format(context)} - ${selected.endTime.format(context)} (${selected.duration} ${selected.duration == 1 ? "Stunde" : "Stunden"})",
                                      Icons.access_time,
                                    ),
                                    if (selected.lehrer != null)
                                      modalSheetItem(
                                          selected.lehrer!, Icons.person),
                                    if (selected.badge != null)
                                      modalSheetItem(
                                          selected.badge!, Icons.info),
                                  ],
                                ),
                              ),
                            );
                          });
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 7, top: 6),
                      child: Text(
                        '${AppLocalizations.of(context).calendarWeek} ${getCurrentWeekNumber()}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color
                                      ?.withValues(alpha: 0.85),
                                ),
                      ),
                    ),
                    if (uniqueBadges.isNotEmpty && timetable.weekBadge != null)
                      GestureDetector(
                        onTap: () {
                          updateSettings(
                              'student-selected-week', currentWeekIndex != 0);
                          currentWeekIndex = (currentWeekIndex + 1) %
                              (uniqueBadges.length + 1);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 40, top: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .buttonTheme
                                  .colorScheme
                                  ?.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: Text(
                              (currentWeekIndex < 1)
                                  ? AppLocalizations.of(context)
                                      .timetableAllWeeks
                                  : AppLocalizations.of(context).timetableWeek(
                                      uniqueBadges[currentWeekIndex - 1]),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .buttonTheme
                                    .colorScheme
                                    ?.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              ],
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (refresh != null)
                  FloatingActionButton(
                    heroTag: "refresh",
                    tooltip: AppLocalizations.of(context).refresh,
                    onPressed: refresh,
                    child: const Icon(Icons.refresh),
                  ),
                if(timetable.planForOwn != null) ...[
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "toggle",
                    tooltip: selectedType == TimeTableType.all
                        ? AppLocalizations.of(context).timetableSwitchToPersonal
                        : AppLocalizations.of(context).timetableSwitchToClass,
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
                ]
              ],
            ));
      },
    );
  }
}

class TimeTableHelper {
  static Color getColorForLesson(dynamic settings, lesson) {
    if (settings['lesson-colors'] == null) {
      return RandomColor.bySeed(lesson.name!).primary;
    }
    if (settings['lesson-colors'][lesson.id.split('-')[0]] != null) {
      return Color(int.parse(settings['lesson-colors'][lesson.id.split('-')[0]],
          radix: 16));
    }
    return RandomColor.bySeed(lesson.name!).primary;
  }

  static List<List<T>> mergeByIndices<T>(
      List<List<T>> list1, List<List<T>>? list2) {
    final int maxLength = list1.length > (list2?.length ?? 0)
        ? list1.length
        : (list2?.length ?? 0);

    final List<List<T>> result = List.generate(maxLength, (index) {
      List<T> combined = [];
      if (index < list1.length) combined.addAll(list1[index]);

      if (list2 != null && index < list2.length) {
        combined.addAll(list2[index]);
      }
      return combined;
    });

    return result;
  }

  static List<List<TimetableSubject>>? getCustomLessons(
      Map<String, dynamic> settings) {
    return settings['custom-lessons'] == null
        ? null
        : (settings['custom-lessons'] as List)
            .map((e) => (e as List).map((item) {
                  if (item.runtimeType == TimetableSubject) {
                    return item as TimetableSubject;
                  }
                  return TimetableSubject.fromJson(item);
                }).toList())
            .toList();
  }
}

class TimeTableDataSource extends CalendarDataSource {
  BuildContext context;
  TimeOfDay earliestHour = const TimeOfDay(hour: 23, minute: 59);
  TimeOfDay latestHour = const TimeOfDay(hour: 0, minute: 0);

  TimeTableDataSource(
      this.context, List<TimetableDay>? data, String? weekBadge, settings) {
    final now = DateTime.now();
    final lastMonday = now.subtract(Duration(days: now.weekday - 1));
    var events = <Appointment>[];

    // Same week should be true when it's the current week.
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

    for (var (dayIndex, day) in data!.indexed) {
      final date = lastMonday.add(Duration(days: dayIndex));

      for (var (lessonIndex, lesson) in day.indexed) {
        List<dynamic>? hiddenLessons = settings['hidden-lessons'];
        if (hiddenLessons != null && hiddenLessons.contains(lesson.id)) {
          continue;
        }
        // Use the calculated date for the startTime and endTime
        final startTime = DateTime(date.year, date.month, date.day,
            lesson.startTime.hour, lesson.startTime.minute);
        final endTime = DateTime(date.year, date.month, date.day,
            lesson.endTime.hour, lesson.endTime.minute);

        final Color entryColor =
            TimeTableHelper.getColorForLesson(settings, lesson);

        if (lesson.startTime < earliestHour) {
          earliestHour = lesson.startTime;
        }
        if (lesson.endTime > latestHour) {
          latestHour = lesson.endTime;
        }

        //1 week before
        events.add(Appointment(
            startTime: startTime.subtract(const Duration(days: 7)),
            endTime: endTime.subtract(const Duration(days: 7)),
            subject: "${lesson.name!} ${lesson.lehrer} ${lesson.raum ?? ""}",
            location: lesson.raum,
            notes: lesson.badge,
            color: entryColor,
            id: "$dayIndex-$lessonIndex-1"));

        if (isCurrentWeek(lesson, true)) {
          events.add(Appointment(
              startTime: startTime,
              endTime: endTime,
              subject: "${lesson.name!} ${lesson.lehrer} ${lesson.raum ?? ""}",
              location: lesson.raum,
              notes: lesson.badge,
              color: entryColor,
              id: "$dayIndex-$lessonIndex-2"));
        }

        //1 week later
        events.add(Appointment(
            startTime: startTime.add(const Duration(days: 7)),
            endTime: endTime.add(const Duration(days: 7)),
            subject: "${lesson.name!} ${lesson.lehrer} ${lesson.raum ?? ""}",
            location: lesson.raum,
            notes: lesson.lehrer,
            color: entryColor,
            id: "$dayIndex-$lessonIndex-3"));
      }
    }

    appointments = events;
  }
}
