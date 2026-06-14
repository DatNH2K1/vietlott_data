import 'dart:convert';

/// Represents a single Vietlott draw record.
class LotteryDrawModel {
  LotteryDrawModel({
    required this.id,
    required this.date,
    required this.regular,
    required this.special,
  });
  final String id;
  final String date;
  final List<int> regular;
  final List<int> special;

  Map<String, dynamic> toJson() {
    return {'id': id, 'date': date, 'regular': regular, 'special': special};
  }

  /// Converts the draw record to a single JSON line.
  String toJsonLString() {
    return jsonEncode(toJson());
  }

  @override
  String toString() =>
      'LotteryDrawModel(id: $id, date: $date, regular: $regular, special: $special)';
}
