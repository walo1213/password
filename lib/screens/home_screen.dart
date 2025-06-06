import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/category_service.dart';
import '../services/export_service.dart';
import 'add_edit_screen.dart';
import 'category_management_screen.dart';
import '../widgets/password_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final CategoryService _categoryService = CategoryService();
  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  List<Category> _categories = [];
  String _selectedFilter = 'tous';
  int? _selectedCategoryFilter;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final passwords = await _databaseService.getAllPasswords();
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _passwords = passwords;
        _categories = categories;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des données');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPasswords = _passwords.where((password) {
        // Filtre par type
        bool typeMatch = _selectedFilter == 'tous' || password.type == _selectedFilter;
        
        // Filtre par catégorie
        bool categoryMatch = _selectedCategoryFilter == null || password.categoryId == _selectedCategoryFilter;
        
        // Filtre par recherche
        bool searchMatch = _searchQuery.isEmpty ||
            password.intitule.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            password.identifiant.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return typeMatch && categoryMatch && searchMatch;
      }).toList();
    });
  }

  Future<void> _loadPasswords() async {
    try {
      final passwords = await _databaseService.getAllPasswords();
      setState(() {
        _passwords = passwords;
        _applyFilters();
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionnaire de Mots de Passe', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.category, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
              );
              if (result == true) {
                _loadData();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'export') {
                _exportPasswords();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Text('Exporter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                SizedBox(height: 16),
                // Filtres
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'tous', child: Text('Tous les types')),
                          DropdownMenuItem(value: 'compte', child: Text('Compte')),
                          DropdownMenuItem(value: 'carte', child: Text('Carte')),
                          DropdownMenuItem(value: 'note', child: Text('Note sécurisée')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedCategoryFilter,
                        decoration: InputDecoration(
                          labelText: 'Catégorie',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Toutes les catégories'),
                          ),
                          ..._categories.map((category) => DropdownMenuItem<int?>(
                            value: category.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(category.couleur.replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(child: Text(category.nom)),
                              ],
                            ),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
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
                            category: _categories.firstWhere(
                              (cat) => cat.id == _filteredPasswords[index].categoryId,
                              orElse: () => Category(
                                id: 0, 
                                nom: '', 
                                couleur: '#666666',
                                dateCreation: DateTime.now(),
                              ),
                            ),
                            onTap: () => _navigateToAddEdit(_filteredPasswords[index]),
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

  Future<void> _exportPasswords() async {
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
      Navigator.pop(context);
      
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
      _loadData();
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
        _loadData();
        _showSuccessSnackBar('Mot de passe supprimé');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }
}