import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../models/category.dart';

class PasswordCard extends StatelessWidget {
  final PasswordEntry entry;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PasswordCard({
    Key? key,
    required this.entry,
    this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et type
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.intitule,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        entry.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTypeColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (category != null)
                        Text(
                          category!.nom,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(int.parse(category!.couleur.replaceFirst('#', '0xFF'))),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Informations du compte
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.identifiant,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.identifiant));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Identifiant copié')),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '••••••••',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.motDePasse));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mot de passe copié')),
                    );
                  },
                ),
              ],
            ),
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.note!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (entry.type) {
      case 'compte':
        return Colors.blue;
      case 'carte':
        return Colors.green;
      case 'wifi':
        return Colors.orange;
      case 'application':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (entry.type) {
      case 'compte':
        return Icons.account_circle;
      case 'carte':
        return Icons.credit_card;
      case 'wifi':
        return Icons.wifi;
      case 'application':
        return Icons.apps;
      default:
        return Icons.lock;
    }
  }
}