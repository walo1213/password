import 'dart:convert';
import 'dart:html' as html;
import '../models/category.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  static const String _storageKey = 'categories_data';

  Future<List<Category>> getAllCategories() async {
    try {
      final storage = html.window.localStorage;
      final data = storage[_storageKey];
      if (data == null) {
        // Créer des catégories par défaut
        final defaultCategories = await _createDefaultCategories();
        return defaultCategories;
      }
      
      final List<dynamic> jsonList = json.decode(data);
      return jsonList.map((json) => Category.fromMap(json)).toList();
    } catch (e) {
      return await _createDefaultCategories();
    }
  }

  Future<List<Category>> _createDefaultCategories() async {
    final defaultCategories = [
      Category(
        id: 1,
        nom: 'Personnel',
        couleur: '#4CAF50',
        description: 'Comptes personnels',
        dateCreation: DateTime.now(),
      ),
      Category(
        id: 2,
        nom: 'Travail',
        couleur: '#2196F3',
        description: 'Comptes professionnels',
        dateCreation: DateTime.now(),
      ),
      Category(
        id: 3,
        nom: 'Finance',
        couleur: '#FF9800',
        description: 'Banques et finances',
        dateCreation: DateTime.now(),
      ),
    ];
    await _saveCategories(defaultCategories);
    return defaultCategories;
  }

  Future<void> insertCategory(Category category) async {
    final categories = await getAllCategories();
    final newCategory = Category(
      id: categories.isEmpty ? 1 : categories.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) + 1,
      nom: category.nom,
      couleur: category.couleur,
      description: category.description,
      dateCreation: category.dateCreation,
    );
    categories.add(newCategory);
    await _saveCategories(categories);
  }

  Future<void> updateCategory(Category category) async {
    final categories = await getAllCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await _saveCategories(categories);
    }
  }

  Future<void> deleteCategory(int id) async {
    final categories = await getAllCategories();
    categories.removeWhere((c) => c.id == id);
    await _saveCategories(categories);
  }

  Future<Category?> getCategoryById(int id) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveCategories(List<Category> categories) async {
    final storage = html.window.localStorage;
    final jsonList = categories.map((c) => c.toMap()).toList();
    storage[_storageKey] = json.encode(jsonList);
  }
}