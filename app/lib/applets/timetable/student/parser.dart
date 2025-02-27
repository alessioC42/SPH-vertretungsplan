import 'dart:convert';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:sph_plan/core/applet_parser.dart';
import 'package:sph_plan/models/client_status_exceptions.dart';
import 'package:uuid/uuid.dart';

import '../../../models/timetable.dart';

class TimetableStudentParser extends AppletParser<TimeTable> {
  TimetableStudentParser(super.sph, super.appletDefinition);

  @override
  Future<TimeTable> getHome() async {
    final Document? document = await getTimetableDocument();
    if (document == null) throw NetworkException();

    final tbodyAll =
        await getTableBody(document, timeTableType: TimeTableType.all);
    final tbodyOwn =
        await getTableBody(document, timeTableType: TimeTableType.own);
    final String? weekBadge =
        document.querySelector("#aktuelleWoche")?.text.trim();
    final List<TimetableDay> parsedAll = parseRoomPlan(tbodyAll!);
    final List<TimetableDay>? parsedOwn = tbodyOwn == null ? null : parseRoomPlan(tbodyOwn);

    return TimeTable(
      planForAll: parsedAll,
      planForOwn: parsedOwn,
      weekBadge: weekBadge,
    );
  }

  @override
  TimeTable typeFromJson(String json) {
    return TimeTable.fromJson(jsonDecode(json));
  }

  Future<Document?> getTimetableDocument() async {
    final redirectedRequest = await sph.session.dio
        .get("https://start.schulportal.hessen.de/stundenplan.php");

    if (redirectedRequest.headers["location"] == null) {
      return null;
    }

    final response = await sph.session.dio.get(
        "https://start.schulportal.hessen.de/${redirectedRequest.headers["location"]?[0]}");
    return parse(response.data);
  }

  Future<Element?> getTableBody(Document document,
      {TimeTableType timeTableType = TimeTableType.all}) async {
    switch (timeTableType) {
      case TimeTableType.all:
        return document.querySelector("#all tbody");
      case TimeTableType.own:
        return document.querySelector("#own tbody");
    }
  }

  List<TimetableDay> parseRoomPlan(Element tbody) {
    int dayCount = tbody.children[0].children.length - 1;
    List<TimetableDay> result = List.generate(dayCount, (_) => []);

    List<(TimeOfDay, TimeOfDay)> timeSlots =
        tbody.querySelectorAll(".VonBis").map((e) {
      var timeString = e.text.trim();
      var s = timeString.split(" - ");
      var splitA = s[0].split(":");
      var splitB = s[1].split(":");
      return (
        TimeOfDay(hour: int.parse(splitA[0]), minute: int.parse(splitA[1])),
        TimeOfDay(hour: int.parse(splitB[0]), minute: int.parse(splitB[1]))
      );
    }).toList();

    List<List<bool>> alreadyParsed = List.generate(
        timeSlots.length + 1, (_) => List.generate(dayCount, (_) => false));

    bool timeslotOffsetFirstRow =
        tbody.children[0].children[0].text.trim() != "";

    for (var (rowIndex, rowElement) in tbody.children.indexed) {
      if (rowIndex == 0) continue; // skip first empty row
      for (var (colIndex, colElement) in rowElement.children.indexed) {
        if (colIndex == 0) continue; // skip first column
        final int rowSpan = int.parse(colElement.attributes["rowspan"] ?? "1");

        var actualDay = colIndex - 1;
        //actualDay should be the first where alreadyParsed is false
        while (alreadyParsed[rowIndex][actualDay]) {
          actualDay++;
        }
        //set all the affected rowspans to true
        for (var i = 0; i < rowSpan; i++) {
          alreadyParsed[rowIndex + i][actualDay] = true;
        }

        result[actualDay].addAll(parseSingeHour(colElement, rowIndex, timeSlots,
            timeslotOffsetFirstRow, actualDay));
      }
    }
    return result;
  }

  List<TimetableSubject> parseSingeHour(
      Element cell,
      int y,
      List<(TimeOfDay, TimeOfDay)> timeSlots,
      bool timeslotOffsetFirstRow,
      int day) {
    List<TimetableSubject> result = [];
    for (var row in cell.querySelectorAll(".stunde")) {
      var name = row.querySelector("b")?.text.trim();
      var raum = row.nodes
          .map((node) => node.nodeType == 3 ? node.text!.trim() : "")
          .join();
      var lehrer = row.querySelector("small")?.text.trim();
      var badge = row.querySelector(".badge")?.text.trim();
      var duration = int.parse(row.parent!.attributes["rowspan"]!);
      var startTime =
          timeslotOffsetFirstRow ? timeSlots[y].$1 : timeSlots[y - 1].$1;
      var endTime = timeslotOffsetFirstRow
          ? timeSlots[y + duration - 1].$2
          : timeSlots[y - 1 + duration - 1].$2;
      // Id unique for every subject. Added with startTime to make it unique
      // even if lessons are removed.
      var id = row.attributes['data-mix'];
      if (id == null || id.isEmpty) {
        // Convert name to a reproducible unique id
        id = Uuid().v5(Uuid.NAMESPACE_URL, name ?? raum).replaceAll('-', '');
      }

      result.add(TimetableSubject(
          id: '$id-$day-${startTime.hour}-${startTime.minute}',
          name: name,
          raum: raum,
          lehrer: lehrer,
          badge: badge,
          duration: duration,
          startTime: startTime,
          endTime: endTime));
    }
    return result;
  }
}
