enum SPHAppEnum {
  stundenplan,
  nachrichten,
  vertretungsplan,
  meinUnterricht,
  kalender,
  dateispeicher,
}

extension SPHApp on SPHAppEnum {
  String get str {
    return switch (this) {
      SPHAppEnum.stundenplan => "stundenplan",
      SPHAppEnum.nachrichten => "nachrichten",
      SPHAppEnum.vertretungsplan => "vertretungsplan",
      SPHAppEnum.meinUnterricht => "mein unterricht",
      SPHAppEnum.kalender => "kalender",
      SPHAppEnum.dateispeicher => "dateispeicher",
    };
  }
  String get php {
    return switch (this) {
      SPHAppEnum.stundenplan => "stundenplan.php",
      SPHAppEnum.nachrichten => "nachrichten.php",
      SPHAppEnum.vertretungsplan => "vertretungsplan.php",
      SPHAppEnum.meinUnterricht => "meinunterricht.php",
      SPHAppEnum.kalender => "kalender.php",
      SPHAppEnum.dateispeicher => "dateispeicher.php",
    };
  }
  bool get onlyStudents {
    return switch (this) {
      SPHAppEnum.meinUnterricht => true,
      _ => false,
    };
  }
}