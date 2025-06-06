import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import 'add_edit_screen.dart';
import '../widgets/password_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  String _selectedFilter = 'tous';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    setState(() => _isLoading = true);
    try {
      final passwords = await _databaseService.getAllPasswords();
      setState(() {
        _passwords = passwords;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des données');
    }
  }

  void _applyFilters() {
    List<PasswordEntry> filtered = _passwords;

    // Filtrer par type
    if (_selectedFilter != 'tous') {
      filtered = filtered.where((p) => p.type == _selectedFilter).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.intitule.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.identifiant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.note.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    setState(() => _filteredPasswords = filtered);
  }

  Future<void> _exportPasswords() async {
    if (_passwords.isEmpty) {
      _showErrorSnackBar('Aucune donnée à exporter');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Export en cours...'),
          ],
        ),
      ),
    );

    try {
      String? filePath = await ExportService.exportToTxt(_passwords);
      Navigator.pop(context); // Fermer le dialog de chargement
      
      if (filePath != null) {
        _showSuccessSnackBar('Export réussi: $filePath');
      } else {
        _showErrorSnackBar('Erreur lors de l\'export');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Erreur lors de l\'export: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Gestionnaire de Mots de Passe',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download, color: Colors.grey[700]),
            onPressed: _exportPasswords,
            tooltip: 'Exporter en .txt',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
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
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
                SizedBox(height: 12),
                // Filtres par type
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('tous', 'Tous'),
                      SizedBox(width: 8),
                      _buildFilterChip('compte', 'Comptes'),
                      SizedBox(width: 8),
                      _buildFilterChip('banque', 'Banque'),
                      SizedBox(width: 8),
                      _buildFilterChip('autre', 'Autres'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Liste des mots de passe
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredPasswords.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredPasswords.length,
                        itemBuilder: (context, index) {
                          return PasswordCard(
                            entry: _filteredPasswords[index],
                            onEdit: () => _navigateToAddEdit(_filteredPasswords[index]),
                            onDelete: () => _deletePassword(_filteredPasswords[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(null),
        backgroundColor: Colors.blue[600],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    bool isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        _applyFilters();
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[600],
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'tous'
                ? 'Aucun résultat trouvé'
                : 'Aucun mot de passe enregistré',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'tous'
                ? 'Essayez de modifier vos critères de recherche'
                : 'Appuyez sur + pour ajouter votre premier mot de passe',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddEdit(PasswordEntry? entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScreen(entry: entry),
      ),
    );
    if (result == true) {
      _loadPasswords();
    }
  }

  Future<void> _deletePassword(PasswordEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${entry.intitule}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deletePassword(entry.id!);
        _loadPasswords();
        _showSuccessSnackBar('Mot de passe supprimé');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }
}