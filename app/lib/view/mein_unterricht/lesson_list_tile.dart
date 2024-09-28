import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/types/lesson.dart';
import 'course_overview.dart';
import 'homework_box.dart';

class LessonListTile extends StatefulWidget {
  final Lesson lesson;

  const LessonListTile({super.key, required this.lesson});

  @override
  State<LessonListTile> createState() => _LessonListTileState();
}

class _LessonListTileState extends State<LessonListTile> {
  final DateFormat dateFormat = DateFormat('dd.MM.yyyy');

  bool _showNotExcusedHours() {
    if (widget.lesson.attendances?.containsKey('fehlend') ?? false) {
      if (int.parse(widget.lesson.attendances?['fehlend'] ?? "0") > 0) {
        return true;
      }
    }
    return false;
  }
  
  @override
  Widget build(BuildContext context) {
    return Badge(
      label: Text('${widget.lesson.attendances?['fehlend'].toString() ?? ''} unentschuldigte Fehlstunden!', textAlign: TextAlign.left,),
      backgroundColor: Colors.red[300],
      isLabelVisible: _showNotExcusedHours(),
      alignment: Alignment.topLeft,
      child: Card(
        child: ListTile(
          title: Row(
            children: [
              Text(
                widget.lesson.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if ((widget.lesson.currentEntry?.files.length ?? 0) > 0) ...[
                Text(
                  widget.lesson.currentEntry!.files.length.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Icon(Icons.attach_file, size: 16),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.lesson.currentEntry?.topicTitle != null) Text(
                widget.lesson.currentEntry!.topicTitle ?? '-',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
              if (widget.lesson.currentEntry?.homework != null) ...[
                const SizedBox(height: 4),
                HomeworkBox(
                  currentEntry: widget.lesson.currentEntry!,
                  courseID: widget.lesson.courseID,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  Text(
                    " ${widget.lesson.teacher} (${widget.lesson.teacherKuerzel})",
                  ),
                  const Spacer(),
                  Text('${dateFormat.format(widget.lesson.currentEntry?.topicDate ?? DateTime(0))} '),
                  const Icon(Icons.calendar_today, size: 16)
                ],
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CourseOverviewAnsicht(
                    dataFetchURL: widget.lesson.courseURL.toString(),
                    title: widget.lesson.name,
                  )),
            );
          },
        ),
      ),
    );
  }
}
