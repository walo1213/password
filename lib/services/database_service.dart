import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import '../models/password_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _storageKey = 'passwords_data';

  Future<List<PasswordEntry>> getAllPasswords() async {
    try {
      final storage = html.window.localStorage;
      final data = storage[_storageKey];
      if (data == null) return [];
      
      final List<dynamic> jsonList = json.decode(data);
      return jsonList.map((json) => PasswordEntry.fromMap(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> insertPassword(PasswordEntry entry) async {
    final passwords = await getAllPasswords();
    final newEntry = PasswordEntry(
      id: passwords.isEmpty ? 1 : passwords.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1,
      intitule: entry.intitule,
      identifiant: entry.identifiant,
      motDePasse: entry.motDePasse,
      type: entry.type,
      note: entry.note,
      dateCreation: entry.dateCreation,
      dateModification: entry.dateModification,
    );
    passwords.add(newEntry);
    await _savePasswords(passwords);
  }

  Future<void> updatePassword(PasswordEntry entry) async {
    final passwords = await getAllPasswords();
    final index = passwords.indexWhere((p) => p.id == entry.id);
    if (index != -1) {
      passwords[index] = entry;
      await _savePasswords(passwords);
    }
  }

  Future<void> deletePassword(int id) async {
    final passwords = await getAllPasswords();
    passwords.removeWhere((p) => p.id == id);
    await _savePasswords(passwords);
  }

  Future<List<PasswordEntry>> searchPasswords(String query) async {
    final passwords = await getAllPasswords();
    return passwords.where((p) => 
      p.intitule.toLowerCase().contains(query.toLowerCase()) ||
      p.identifiant.toLowerCase().contains(query.toLowerCase()) ||
      p.type.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<void> _savePasswords(List<PasswordEntry> passwords) async {
    final storage = html.window.localStorage;
    final jsonList = passwords.map((p) => p.toMap()).toList();
    storage[_storageKey] = json.encode(jsonList);
  }

  Future<void> clearAllData() async {
    final storage = html.window.localStorage;
    storage.remove(_storageKey);
  }
}