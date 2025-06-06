import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../models/category.dart'; // Import manquant

class PasswordCard extends StatelessWidget {
  final PasswordEntry entry;
  final Category? category; // Nouveau paramètre
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PasswordCard({
    Key? key,
    required this.entry,
    this.category, // Nouveau paramètre
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category != null 
              ? Color(int.parse(category!.couleur.replaceFirst('#', '0xFF')))
              : _getTypeColor(entry.type),
          child: Icon(
            _getTypeIcon(entry.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          entry.intitule,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.identifiant),
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
                          widget.entry.intitule,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          widget.entry.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTypeColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit();
                      } else if (value == 'delete') {
                        widget.onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.grey[600]),
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
              SizedBox(height: 16),
              // Identifiant
              _buildInfoRow(
                'Identifiant',
                widget.entry.identifiant,
                Icons.person,
                () => _copyToClipboard(widget.entry.identifiant, 'Identifiant'),
              ),
              SizedBox(height: 12),
              // Mot de passe
              _buildPasswordRow(),
              // Note (si présente)
             if (widget.entry.note.isNotEmpty) ...[
                SizedBox(height: 12),
                _buildInfoRow(
                  'Note',
                  widget.entry.note,
                  Icons.note,
                  null,
                  maxLines: 2,
                ),
              ],
              SizedBox(height: 8),
              // Date de modification
              Text(
                'Modifié le ${_formatDate(widget.entry.dateModification)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    VoidCallback? onTap, {
    int maxLines = 1,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onTap != null)
          IconButton(
            icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
            onPressed: onTap,
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildPasswordRow() {
    return Row(
      children: [
        Icon(Icons.lock, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          'Mot de passe: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            _isPasswordVisible ? widget.entry.motDePasse : '••••••••',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontFamily: _isPasswordVisible ? 'monospace' : null,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            size: 16,
            color: Colors.grey[600],
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(),
        ),
        IconButton(
          icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
          onPressed: () => _copyToClipboard(widget.entry.motDePasse, 'Mot de passe'),
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}