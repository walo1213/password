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
        if (entry.note != null && entry.note!.isNotEmpty) {
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

      return 'Export TXT réussi: $fileName';
    } catch (e) {
      return null;
    }
  }

  static Future<String?> exportToCsv(List<PasswordEntry> entries) async {
    try {
      StringBuffer content = StringBuffer();
      
      // En-tête CSV
      content.writeln('"Intitulé","Type","Identifiant","Mot de passe","Note","Date création","Date modification"');
      
      // Données
      for (PasswordEntry entry in entries) {
        String note = (entry.note ?? '').replaceAll('"', '""');
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

      return 'Export CSV réussi: $fileName';
    } catch (e) {
      return null;
    }
  }

  static Future<String?> exportToJson(List<PasswordEntry> entries) async {
    try {
      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0',
        'entries': entries.map((entry) => entry.toMap()).toList(),
      };

      String jsonString = jsonEncode(exportData);
      
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

      return 'Export JSON réussi: $fileName';
    } catch (e) {
      return null;
    }
  }
}