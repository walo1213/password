import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/database_service.dart';

class AddEditScreen extends StatefulWidget {
  final PasswordEntry? entry;

  const AddEditScreen({Key? key, this.entry}) : super(key: key);

  @override
  _AddEditScreenState createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  
  late TextEditingController _intituleController;
  late TextEditingController _identifiantController;
  late TextEditingController _motDePasseController;
  late TextEditingController _noteController;
  
  String _selectedType = 'compte';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _intituleController = TextEditingController(text: widget.entry?.intitule ?? '');
    _identifiantController = TextEditingController(text: widget.entry?.identifiant ?? '');
    _motDePasseController = TextEditingController(text: widget.entry?.motDePasse ?? '');
    _noteController = TextEditingController(text: widget.entry?.note ?? '');
    _selectedType = widget.entry?.type ?? 'compte';
  }

  @override
  void dispose() {
    _intituleController.dispose();
    _identifiantController.dispose();
    _motDePasseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: widget.entry?.id,
        intitule: _intituleController.text.trim(),
        identifiant: _identifiantController.text.trim(),
        motDePasse: _motDePasseController.text,
        type: _selectedType,
        note: _noteController.text.trim(),
        dateCreation: widget.entry?.dateCreation ?? now,
        dateModification: now,
      );

      if (widget.entry == null) {
        await _databaseService.insertPassword(entry);
      } else {
        await _databaseService.updatePassword(entry);
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.entry == null ? 'Nouveau mot de passe' : 'Modifier',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[700]),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEntry,
            child: Text(
              'Sauvegarder',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.blue[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Carte principale
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intitulé
                    _buildTextField(
                      controller: _intituleController,
                      label: 'Intitulé',
                      icon: Icons.title,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'intitulé est requis';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    
                    // Type
                    Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeChip('compte', 'Compte', Icons.account_circle),
                        SizedBox(width: 8),
                        _buildTypeChip('banque', 'Banque', Icons.account_balance),
                        SizedBox(width: 8),
                        _buildTypeChip('autre', 'Autre', Icons.lock),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // Identifiant
                    _buildTextField(
                      controller: _identifiantController,
                      label: 'Identifiant',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'identifiant est requis';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    
                    // Mot de passe
                    _buildPasswordField(),
                    SizedBox(height: 20),
                    
                    // Note
                    _buildTextField(
                      controller: _noteController,
                      label: 'Note (optionnel)',
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.entry == null ? 'Créer' : 'Mettre à jour',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _motDePasseController,
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le mot de passe est requis';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    bool isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}