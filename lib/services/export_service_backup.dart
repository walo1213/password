import 'dart:io';
import 'dart:convert';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/password_entry.dart';
import 'database_service.dart';

class ExportService {
  static Future<String?> exportToTxt(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      content.writeln('=== EXPORT DES MOTS DE PASSE ===');
      content.writeln('Date d\'export: ${DateTime.now().toString().split('.')[0]}');
      content.writeln('Nombre d\'entrées: ${entries.length}');
      content.writeln('');
      content.writeln('=' * 50);
      content.writeln('');

      for (int i = 0; i < entries.length; i++) {
        PasswordEntry entry = entries[i];
        content.writeln('ENTRÉE ${i + 1}:');
        content.writeln('Intitulé: ${entry.intitule}');
        content.writeln('Type: ${entry.type}');
        content.writeln('Identifiant: ${entry.identifiant}');
        content.writeln('Mot de passe: ${entry.motDePasse}');
        if (entry.note.isNotEmpty) {
          content.writeln('Note: ${entry.note}');
        }
        content.writeln('Date de création: ${entry.dateCreation.toString().split('.')[0]}');
        content.writeln('Date de modification: ${entry.dateModification.toString().split('.')[0]}');
        content.writeln('');
        content.writeln('-' * 30);
        content.writeln('');
      }

      content.writeln('');
      content.writeln('=== FIN DE L\'EXPORT ===');

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.txt';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToCsv(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      // En-têtes CSV
      content.writeln('Intitulé,Type,Identifiant,Mot de passe,Note,Date de création,Date de modification');
      
      // Données
      for (PasswordEntry entry in entries) {
        String note = entry.note.replaceAll(',', ';').replaceAll('\n', ' ');
        String dateCreation = entry.dateCreation.toString().split('.')[0];
        String dateModification = entry.dateModification.toString().split('.')[0];
        
        content.writeln('"${entry.intitule}","${entry.type}","${entry.identifiant}","${entry.motDePasse}","$note","$dateCreation","$dateModification"');
      }

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.csv';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToJson(List<PasswordEntry> entries) async {
    try {
      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_entries': entries.length,
        'passwords': entries.map((entry) => entry.toMap()).toList(),
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.json';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<List<PasswordEntry>?> importFromJson(String jsonContent) async {
    try {
      Map<String, dynamic> data = json.decode(jsonContent);
      List<dynamic> passwordsData = data['passwords'] ?? [];
      
      return passwordsData.map((item) => PasswordEntry.fromMap(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> importFromFile() async {
    try {
      final input = html.FileUploadInputElement();
      input.accept = '.json';
      input.click();
      
      await input.onChange.first;
      
      if (input.files?.isNotEmpty == true) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        
        await reader.onLoad.first;
        
        final content = reader.result as String;
        final entries = await importFromJson(content);
        
        if (entries != null) {
          return 'Import réussi: ${entries.length} entrées importées';
        } else {
          return 'Erreur: Format de fichier invalide';
        }
      }
      
      return 'Aucun fichier sélectionné';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static Future<void> downloadBackup(List<PasswordEntry> entries) async {
    await exportToJson(entries);
  }

  static Future<void> saveBackup(List<PasswordEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> backupData = entries.map((entry) => jsonEncode(entry.toMap())).toList();
      await prefs.setStringList('password_backup', backupData);
      await prefs.setString('backup_date', DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  static Future<List<PasswordEntry>?> loadBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? backupData = prefs.getStringList('password_backup');
      
      if (backupData != null) {
        return backupData.map((data) {
          Map<String, dynamic> map = jsonDecode(data);
          return PasswordEntry.fromMap(map);
        }).toList();
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement de la sauvegarde: $e');
      return null;
    }
  }

  static Future<String?> importFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.length < 2) {
        return 'Fichier CSV vide ou invalide';
      }

      final dbService = DatabaseService();
      int importedCount = 0;

      // Ignorer la première ligne (en-têtes)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parser la ligne CSV
        final values = _parseCsvLine(line);
        if (values.length >= 4) {
          final entry = PasswordEntry(
            intitule: values[0],
            type: values[1],
            identifiant: values[2],
            motDePasse: values[3],
            note: values.length > 4 ? values[4] : '',
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
          );
          
          await dbService.insertPassword(entry);
          importedCount++;
        }
      }

      return 'Import réussi: $importedCount entrées importées';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current.trim());
    return result;
  }
}
class ExportService {
  static Future<String?> exportToTxt(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      content.writeln('=== EXPORT DES MOTS DE PASSE ===');
      content.writeln('Date d\'export: ${DateTime.now().toString().split('.')[0]}');
      content.writeln('Nombre d\'entrées: ${entries.length}');
      content.writeln('');
      content.writeln('=' * 50);
      content.writeln('');
  
      for (int i = 0; i < entries.length; i++) {
        PasswordEntry entry = entries[i];
        content.writeln('ENTRÉE ${i + 1}:');
        content.writeln('Intitulé: ${entry.intitule}');
        content.writeln('Type: ${entry.type}');
        content.writeln('Identifiant: ${entry.identifiant}');
        content.writeln('Mot de passe: ${entry.motDePasse}');
        if (entry.note.isNotEmpty) {
          content.writeln('Note: ${entry.note}');
        }
        content.writeln('Date de création: ${entry.dateCreation.toString().split('.')[0]}');
        content.writeln('Date de modification: ${entry.dateModification.toString().split('.')[0]}');
        content.writeln('');
        content.writeln('-' * 30);
        content.writeln('');
      }
  
      content.writeln('');
      content.writeln('=== FIN DE L\'EXPORT ===');
  
      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.txt';
  
      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
  
      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToCsv(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      // En-têtes CSV
      content.writeln('Intitulé,Type,Identifiant,Mot de passe,Note,Date de création,Date de modification');
      
      // Données
      for (PasswordEntry entry in entries) {
        String note = entry.note.replaceAll(',', ';').replaceAll('\n', ' ');
        String dateCreation = entry.dateCreation.toString().split('.')[0];
        String dateModification = entry.dateModification.toString().split('.')[0];
        
        content.writeln('"${entry.intitule}","${entry.type}","${entry.identifiant}","${entry.motDePasse}","$note","$dateCreation","$dateModification"');
      }

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.csv';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToJson(List<PasswordEntry> entries) async {
    try {
      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_entries': entries.length,
        'passwords': entries.map((entry) => entry.toMap()).toList(),
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.json';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<List<PasswordEntry>?> importFromJson(String jsonContent) async {
    try {
      Map<String, dynamic> data = json.decode(jsonContent);
      List<dynamic> passwordsData = data['passwords'] ?? [];
      
      return passwordsData.map((item) => PasswordEntry.fromMap(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> importFromFile() async {
    try {
      final input = html.FileUploadInputElement();
      input.accept = '.json';
      input.click();
      
      await input.onChange.first;
      
      if (input.files?.isNotEmpty == true) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        
        await reader.onLoad.first;
        
        final content = reader.result as String;
        final entries = await importFromJson(content);
        
        if (entries != null) {
          return 'Import réussi: ${entries.length} entrées importées';
        } else {
          return 'Erreur: Format de fichier invalide';
        }
      }
      
      return 'Aucun fichier sélectionné';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static Future<void> downloadBackup(List<PasswordEntry> entries) async {
    await exportToJson(entries);
  }

  static Future<void> saveBackup(List<PasswordEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> backupData = entries.map((entry) => jsonEncode(entry.toMap())).toList();
      await prefs.setStringList('password_backup', backupData);
      await prefs.setString('backup_date', DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  static Future<List<PasswordEntry>?> loadBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? backupData = prefs.getStringList('password_backup');
      
      if (backupData != null) {
        return backupData.map((data) {
          Map<String, dynamic> map = jsonDecode(data);
          return PasswordEntry.fromMap(map);
        }).toList();
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement de la sauvegarde: $e');
      return null;
    }
  }

  static Future<String?> importFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.length < 2) {
        return 'Fichier CSV vide ou invalide';
      }

      final dbService = DatabaseService();
      int importedCount = 0;

      // Ignorer la première ligne (en-têtes)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parser la ligne CSV
        final values = _parseCsvLine(line);
        if (values.length >= 4) {
          final entry = PasswordEntry(
            intitule: values[0],
            type: values[1],
            identifiant: values[2],
            motDePasse: values[3],
            note: values.length > 4 ? values[4] : '',
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
          );
          
          await dbService.insertPassword(entry);
          importedCount++;
        }
      }

      return 'Import réussi: $importedCount entrées importées';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current.trim());
    return result;
  }
}
class ExportService {
  static Future<String?> exportToTxt(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      content.writeln('=== EXPORT DES MOTS DE PASSE ===');
      content.writeln('Date d\'export: ${DateTime.now().toString().split('.')[0]}');
      content.writeln('Nombre d\'entrées: ${entries.length}');
      content.writeln('');
      content.writeln('=' * 50);
      content.writeln('');
  
      for (int i = 0; i < entries.length; i++) {
        PasswordEntry entry = entries[i];
        content.writeln('ENTRÉE ${i + 1}:');
        content.writeln('Intitulé: ${entry.intitule}');
        content.writeln('Type: ${entry.type}');
        content.writeln('Identifiant: ${entry.identifiant}');
        content.writeln('Mot de passe: ${entry.motDePasse}');
        if (entry.note.isNotEmpty) {
          content.writeln('Note: ${entry.note}');
        }
        content.writeln('Date de création: ${entry.dateCreation.toString().split('.')[0]}');
        content.writeln('Date de modification: ${entry.dateModification.toString().split('.')[0]}');
        content.writeln('');
        content.writeln('-' * 30);
        content.writeln('');
      }
  
      content.writeln('');
      content.writeln('=== FIN DE L\'EXPORT ===');
  
      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.txt';
  
      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
  
      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToCsv(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      // En-têtes CSV
      content.writeln('Intitulé,Type,Identifiant,Mot de passe,Note,Date de création,Date de modification');
      
      // Données
      for (PasswordEntry entry in entries) {
        String note = entry.note.replaceAll(',', ';').replaceAll('\n', ' ');
        String dateCreation = entry.dateCreation.toString().split('.')[0];
        String dateModification = entry.dateModification.toString().split('.')[0];
        
        content.writeln('"${entry.intitule}","${entry.type}","${entry.identifiant}","${entry.motDePasse}","$note","$dateCreation","$dateModification"');
      }

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.csv';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToJson(List<PasswordEntry> entries) async {
    try {
      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_entries': entries.length,
        'passwords': entries.map((entry) => entry.toMap()).toList(),
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.json';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<List<PasswordEntry>?> importFromJson(String jsonContent) async {
    try {
      Map<String, dynamic> data = json.decode(jsonContent);
      List<dynamic> passwordsData = data['passwords'] ?? [];
      
      return passwordsData.map((item) => PasswordEntry.fromMap(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> importFromFile() async {
    try {
      final input = html.FileUploadInputElement();
      input.accept = '.json';
      input.click();
      
      await input.onChange.first;
      
      if (input.files?.isNotEmpty == true) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        
        await reader.onLoad.first;
        
        final content = reader.result as String;
        final entries = await importFromJson(content);
        
        if (entries != null) {
          return 'Import réussi: ${entries.length} entrées importées';
        } else {
          return 'Erreur: Format de fichier invalide';
        }
      }
      
      return 'Aucun fichier sélectionné';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static Future<void> downloadBackup(List<PasswordEntry> entries) async {
    await exportToJson(entries);
  }

  static Future<void> saveBackup(List<PasswordEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> backupData = entries.map((entry) => jsonEncode(entry.toMap())).toList();
      await prefs.setStringList('password_backup', backupData);
      await prefs.setString('backup_date', DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  static Future<List<PasswordEntry>?> loadBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? backupData = prefs.getStringList('password_backup');
      
      if (backupData != null) {
        return backupData.map((data) {
          Map<String, dynamic> map = jsonDecode(data);
          return PasswordEntry.fromMap(map);
        }).toList();
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement de la sauvegarde: $e');
      return null;
    }
  }

  static Future<String?> importFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.length < 2) {
        return 'Fichier CSV vide ou invalide';
      }

      final dbService = DatabaseService();
      int importedCount = 0;

      // Ignorer la première ligne (en-têtes)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parser la ligne CSV
        final values = _parseCsvLine(line);
        if (values.length >= 4) {
          final entry = PasswordEntry(
            intitule: values[0],
            type: values[1],
            identifiant: values[2],
            motDePasse: values[3],
            note: values.length > 4 ? values[4] : '',
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
          );
          
          await dbService.insertPassword(entry);
          importedCount++;
        }
      }

      return 'Import réussi: $importedCount entrées importées';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current.trim());
    return result;
  }
}
class ExportService {
  static Future<String?> exportToTxt(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      content.writeln('=== EXPORT DES MOTS DE PASSE ===');
      content.writeln('Date d\'export: ${DateTime.now().toString().split('.')[0]}');
      content.writeln('Nombre d\'entrées: ${entries.length}');
      content.writeln('');
      content.writeln('=' * 50);
      content.writeln('');
  
      for (int i = 0; i < entries.length; i++) {
        PasswordEntry entry = entries[i];
        content.writeln('ENTRÉE ${i + 1}:');
        content.writeln('Intitulé: ${entry.intitule}');
        content.writeln('Type: ${entry.type}');
        content.writeln('Identifiant: ${entry.identifiant}');
        content.writeln('Mot de passe: ${entry.motDePasse}');
        if (entry.note.isNotEmpty) {
          content.writeln('Note: ${entry.note}');
        }
        content.writeln('Date de création: ${entry.dateCreation.toString().split('.')[0]}');
        content.writeln('Date de modification: ${entry.dateModification.toString().split('.')[0]}');
        content.writeln('');
        content.writeln('-' * 30);
        content.writeln('');
      }
  
      content.writeln('');
      content.writeln('=== FIN DE L\'EXPORT ===');
  
      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.txt';
  
      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
  
      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToCsv(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      // En-têtes CSV
      content.writeln('Intitulé,Type,Identifiant,Mot de passe,Note,Date de création,Date de modification');
      
      // Données
      for (PasswordEntry entry in entries) {
        String note = entry.note.replaceAll(',', ';').replaceAll('\n', ' ');
        String dateCreation = entry.dateCreation.toString().split('.')[0];
        String dateModification = entry.dateModification.toString().split('.')[0];
        
        content.writeln('"${entry.intitule}","${entry.type}","${entry.identifiant}","${entry.motDePasse}","$note","$dateCreation","$dateModification"');
      }

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.csv';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToJson(List<PasswordEntry> entries) async {
    try {
      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_entries': entries.length,
        'passwords': entries.map((entry) => entry.toMap()).toList(),
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.json';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<List<PasswordEntry>?> importFromJson(String jsonContent) async {
    try {
      Map<String, dynamic> data = json.decode(jsonContent);
      List<dynamic> passwordsData = data['passwords'] ?? [];
      
      return passwordsData.map((item) => PasswordEntry.fromMap(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> importFromFile() async {
    try {
      final input = html.FileUploadInputElement();
      input.accept = '.json';
      input.click();
      
      await input.onChange.first;
      
      if (input.files?.isNotEmpty == true) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        
        await reader.onLoad.first;
        
        final content = reader.result as String;
        final entries = await importFromJson(content);
        
        if (entries != null) {
          return 'Import réussi: ${entries.length} entrées importées';
        } else {
          return 'Erreur: Format de fichier invalide';
        }
      }
      
      return 'Aucun fichier sélectionné';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static Future<void> downloadBackup(List<PasswordEntry> entries) async {
    await exportToJson(entries);
  }

  static Future<void> saveBackup(List<PasswordEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> backupData = entries.map((entry) => jsonEncode(entry.toMap())).toList();
      await prefs.setStringList('password_backup', backupData);
      await prefs.setString('backup_date', DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  static Future<List<PasswordEntry>?> loadBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? backupData = prefs.getStringList('password_backup');
      
      if (backupData != null) {
        return backupData.map((data) {
          Map<String, dynamic> map = jsonDecode(data);
          return PasswordEntry.fromMap(map);
        }).toList();
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement de la sauvegarde: $e');
      return null;
    }
  }

  static Future<String?> importFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.length < 2) {
        return 'Fichier CSV vide ou invalide';
      }

      final dbService = DatabaseService();
      int importedCount = 0;

      // Ignorer la première ligne (en-têtes)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parser la ligne CSV
        final values = _parseCsvLine(line);
        if (values.length >= 4) {
          final entry = PasswordEntry(
            intitule: values[0],
            type: values[1],
            identifiant: values[2],
            motDePasse: values[3],
            note: values.length > 4 ? values[4] : '',
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
          );
          
          await dbService.insertPassword(entry);
          importedCount++;
        }
      }

      return 'Import réussi: $importedCount entrées importées';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current.trim());
    return result;
  }
}
class ExportService {
  static Future<String?> exportToTxt(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      content.writeln('=== EXPORT DES MOTS DE PASSE ===');
      content.writeln('Date d\'export: ${DateTime.now().toString().split('.')[0]}');
      content.writeln('Nombre d\'entrées: ${entries.length}');
      content.writeln('');
      content.writeln('=' * 50);
      content.writeln('');
  
      for (int i = 0; i < entries.length; i++) {
        PasswordEntry entry = entries[i];
        content.writeln('ENTRÉE ${i + 1}:');
        content.writeln('Intitulé: ${entry.intitule}');
        content.writeln('Type: ${entry.type}');
        content.writeln('Identifiant: ${entry.identifiant}');
        content.writeln('Mot de passe: ${entry.motDePasse}');
        if (entry.note.isNotEmpty) {
          content.writeln('Note: ${entry.note}');
        }
        content.writeln('Date de création: ${entry.dateCreation.toString().split('.')[0]}');
        content.writeln('Date de modification: ${entry.dateModification.toString().split('.')[0]}');
        content.writeln('');
        content.writeln('-' * 30);
        content.writeln('');
      }
  
      content.writeln('');
      content.writeln('=== FIN DE L\'EXPORT ===');
  
      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.txt';
  
      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
  
      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToCsv(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      // En-têtes CSV
      content.writeln('Intitulé,Type,Identifiant,Mot de passe,Note,Date de création,Date de modification');
      
      // Données
      for (PasswordEntry entry in entries) {
        String note = entry.note.replaceAll(',', ';').replaceAll('\n', ' ');
        String dateCreation = entry.dateCreation.toString().split('.')[0];
        String dateModification = entry.dateModification.toString().split('.')[0];
        
        content.writeln('"${entry.intitule}","${entry.type}","${entry.identifiant}","${entry.motDePasse}","$note","$dateCreation","$dateModification"');
      }

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.csv';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToJson(List<PasswordEntry> entries) async {
    try {
      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_entries': entries.length,
        'passwords': entries.map((entry) => entry.toMap()).toList(),
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.json';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<List<PasswordEntry>?> importFromJson(String jsonContent) async {
    try {
      Map<String, dynamic> data = json.decode(jsonContent);
      List<dynamic> passwordsData = data['passwords'] ?? [];
      
      return passwordsData.map((item) => PasswordEntry.fromMap(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> importFromFile() async {
    try {
      final input = html.FileUploadInputElement();
      input.accept = '.json';
      input.click();
      
      await input.onChange.first;
      
      if (input.files?.isNotEmpty == true) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        
        await reader.onLoad.first;
        
        final content = reader.result as String;
        final entries = await importFromJson(content);
        
        if (entries != null) {
          return 'Import réussi: ${entries.length} entrées importées';
        } else {
          return 'Erreur: Format de fichier invalide';
        }
      }
      
      return 'Aucun fichier sélectionné';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static Future<void> downloadBackup(List<PasswordEntry> entries) async {
    await exportToJson(entries);
  }

  static Future<void> saveBackup(List<PasswordEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> backupData = entries.map((entry) => jsonEncode(entry.toMap())).toList();
      await prefs.setStringList('password_backup', backupData);
      await prefs.setString('backup_date', DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  static Future<List<PasswordEntry>?> loadBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? backupData = prefs.getStringList('password_backup');
      
      if (backupData != null) {
        return backupData.map((data) {
          Map<String, dynamic> map = jsonDecode(data);
          return PasswordEntry.fromMap(map);
        }).toList();
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement de la sauvegarde: $e');
      return null;
    }
  }

  static Future<String?> importFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.length < 2) {
        return 'Fichier CSV vide ou invalide';
      }

      final dbService = DatabaseService();
      int importedCount = 0;

      // Ignorer la première ligne (en-têtes)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parser la ligne CSV
        final values = _parseCsvLine(line);
        if (values.length >= 4) {
          final entry = PasswordEntry(
            intitule: values[0],
            type: values[1],
            identifiant: values[2],
            motDePasse: values[3],
            note: values.length > 4 ? values[4] : '',
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
          );
          
          await dbService.insertPassword(entry);
          importedCount++;
        }
      }

      return 'Import réussi: $importedCount entrées importées';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current.trim());
    return result;
  }
}
class ExportService {
  static Future<String?> exportToTxt(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      content.writeln('=== EXPORT DES MOTS DE PASSE ===');
      content.writeln('Date d\'export: ${DateTime.now().toString().split('.')[0]}');
      content.writeln('Nombre d\'entrées: ${entries.length}');
      content.writeln('');
      content.writeln('=' * 50);
      content.writeln('');
  
      for (int i = 0; i < entries.length; i++) {
        PasswordEntry entry = entries[i];
        content.writeln('ENTRÉE ${i + 1}:');
        content.writeln('Intitulé: ${entry.intitule}');
        content.writeln('Type: ${entry.type}');
        content.writeln('Identifiant: ${entry.identifiant}');
        content.writeln('Mot de passe: ${entry.motDePasse}');
        if (entry.note.isNotEmpty) {
          content.writeln('Note: ${entry.note}');
        }
        content.writeln('Date de création: ${entry.dateCreation.toString().split('.')[0]}');
        content.writeln('Date de modification: ${entry.dateModification.toString().split('.')[0]}');
        content.writeln('');
        content.writeln('-' * 30);
        content.writeln('');
      }
  
      content.writeln('');
      content.writeln('=== FIN DE L\'EXPORT ===');
  
      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.txt';
  
      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
  
      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToCsv(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      // En-têtes CSV
      content.writeln('Intitulé,Type,Identifiant,Mot de passe,Note,Date de création,Date de modification');
      
      // Données
      for (PasswordEntry entry in entries) {
        String note = entry.note.replaceAll(',', ';').replaceAll('\n', ' ');
        String dateCreation = entry.dateCreation.toString().split('.')[0];
        String dateModification = entry.dateModification.toString().split('.')[0];
        
        content.writeln('"${entry.intitule}","${entry.type}","${entry.identifiant}","${entry.motDePasse}","$note","$dateCreation","$dateModification"');
      }

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.csv';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToJson(List<PasswordEntry> entries) async {
    try {
      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_entries': entries.length,
        'passwords': entries.map((entry) => entry.toMap()).toList(),
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.json';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<List<PasswordEntry>?> importFromJson(String jsonContent) async {
    try {
      Map<String, dynamic> data = json.decode(jsonContent);
      List<dynamic> passwordsData = data['passwords'] ?? [];
      
      return passwordsData.map((item) => PasswordEntry.fromMap(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> importFromFile() async {
    try {
      final input = html.FileUploadInputElement();
      input.accept = '.json';
      input.click();
      
      await input.onChange.first;
      
      if (input.files?.isNotEmpty == true) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        
        await reader.onLoad.first;
        
        final content = reader.result as String;
        final entries = await importFromJson(content);
        
        if (entries != null) {
          return 'Import réussi: ${entries.length} entrées importées';
        } else {
          return 'Erreur: Format de fichier invalide';
        }
      }
      
      return 'Aucun fichier sélectionné';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static Future<void> downloadBackup(List<PasswordEntry> entries) async {
    await exportToJson(entries);
  }

  static Future<void> saveBackup(List<PasswordEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> backupData = entries.map((entry) => jsonEncode(entry.toMap())).toList();
      await prefs.setStringList('password_backup', backupData);
      await prefs.setString('backup_date', DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  static Future<List<PasswordEntry>?> loadBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? backupData = prefs.getStringList('password_backup');
      
      if (backupData != null) {
        return backupData.map((data) {
          Map<String, dynamic> map = jsonDecode(data);
          return PasswordEntry.fromMap(map);
        }).toList();
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement de la sauvegarde: $e');
      return null;
    }
  }

  static Future<String?> importFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.length < 2) {
        return 'Fichier CSV vide ou invalide';
      }

      final dbService = DatabaseService();
      int importedCount = 0;

      // Ignorer la première ligne (en-têtes)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parser la ligne CSV
        final values = _parseCsvLine(line);
        if (values.length >= 4) {
          final entry = PasswordEntry(
            intitule: values[0],
            type: values[1],
            identifiant: values[2],
            motDePasse: values[3],
            note: values.length > 4 ? values[4] : '',
            dateCreation: DateTime.now(),
            dateModification: DateTime.now(),
          );
          
          await dbService.insertPassword(entry);
          importedCount++;
        }
      }

      return 'Import réussi: $importedCount entrées importées';
    } catch (e) {
      return 'Erreur lors de l\'import: $e';
    }
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current.trim());
    return result;
  }
}
class ExportService {
  static Future<String?> exportToTxt(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      content.writeln('=== EXPORT DES MOTS DE PASSE ===');
      content.writeln('Date d\'export: ${DateTime.now().toString().split('.')[0]}');
      content.writeln('Nombre d\'entrées: ${entries.length}');
      content.writeln('');
      content.writeln('=' * 50);
      content.writeln('');
  
      for (int i = 0; i < entries.length; i++) {
        PasswordEntry entry = entries[i];
        content.writeln('ENTRÉE ${i + 1}:');
        content.writeln('Intitulé: ${entry.intitule}');
        content.writeln('Type: ${entry.type}');
        content.writeln('Identifiant: ${entry.identifiant}');
        content.writeln('Mot de passe: ${entry.motDePasse}');
        if (entry.note.isNotEmpty) {
          content.writeln('Note: ${entry.note}');
        }
        content.writeln('Date de création: ${entry.dateCreation.toString().split('.')[0]}');
        content.writeln('Date de modification: ${entry.dateModification.toString().split('.')[0]}');
        content.writeln('');
        content.writeln('-' * 30);
        content.writeln('');
      }
  
      content.writeln('');
      content.writeln('=== FIN DE L\'EXPORT ===');
  
      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.txt';
  
      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
  
      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToCsv(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      // En-têtes CSV
      content.writeln('Intitulé,Type,Identifiant,Mot de passe,Note,Date de création,Date de modification');
      
      // Données
      for (PasswordEntry entry in entries) {
        String note = entry.note.replaceAll(',', ';').replaceAll('\n', ' ');
        String dateCreation = entry.dateCreation.toString().split('.')[0];
        String dateModification = entry.dateModification.toString().split('.')[0];
        
        content.writeln('"${entry.intitule}","${entry.type}","${entry.identifiant}","${entry.motDePasse}","$note","$dateCreation","$dateModification"');
      }

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.csv';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(content.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<String?> exportToJson(List<PasswordEntry> entries) async {
    try {
      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_entries': entries.length,
        'passwords': entries.map((entry) => entry.toMap()).toList(),
      };

      String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Créer le nom du fichier avec timestamp
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      String fileName = 'mots_de_passe_$timestamp.json';

      // Télécharger le fichier via le navigateur
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      return 'Export réussi: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'export: $e';
    }
  }

  static Future<List<PasswordEntry>?> importFromJson(String jsonContent) async {
    try {
      Map<String, dynamic> data = json.decode(jsonContent);
      List<dynamic> passwordsData = data['passwords'] ?? [];
      
      return passwordsData.map((item) => PasswordEntry.fromMap(item)).toList();
    } catch (e) {
      return null;
    }