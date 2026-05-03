import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/overtime_entry.dart';

class StorageService {
  static const String _key = 'overtime_entries';

  static Future<List<OvertimeEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((e) => OvertimeEntry.fromMap(json.decode(e)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveEntry(OvertimeEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    entries.add(entry);
    await prefs.setStringList(
      _key,
      entries.map((e) => json.encode(e.toMap())).toList(),
    );
  }

  static Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    entries.removeWhere((e) => e.id == id);
    await prefs.setStringList(
      _key,
      entries.map((e) => json.encode(e.toMap())).toList(),
    );
  }

  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
