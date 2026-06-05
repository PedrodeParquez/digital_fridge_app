import 'dart:io';

import 'package:dio/dio.dart';

import '../models/recipe.dart';
import 'api_client.dart';

class RecipeService {
  static final RecipeService instance = RecipeService._();
  RecipeService._();

  final _dio = ApiClient.instance.dio;

  Future<List<Recipe>> getRecipes() async {
    final response = await _dio.get('/recipes');
    final list = response.data as List<dynamic>;
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Recipe>> getPersonalRecipes() async {
    final response = await _dio.get('/recipes/personal');
    final list = response.data as List<dynamic>;
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Recipe> createRecipe(Recipe recipe) async {
    final response = await _dio.post('/recipes', data: recipe.toJson());
    return Recipe.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Recipe> updateRecipe(Recipe recipe) async {
    final response = await _dio.put(
      '/recipes/${recipe.id}',
      data: recipe.toJson(),
    );
    return Recipe.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecipe(String id) async {
    await _dio.delete('/recipes/$id');
  }

  Future<Recipe> uploadImage(String recipeId, File imageFile) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await _dio.post(
      '/recipes/$recipeId/images',
      data: formData,
    );
    return Recipe.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteImage(String recipeId, String imageId) async {
    await _dio.delete('/recipes/$recipeId/images/$imageId');
  }

  Future<List<String>> getFavoriteIds() async {
    final response = await _dio.get('/recipes/favorites');
    final list = response.data as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  Future<void> addFavorite(String recipeId) async {
    await _dio.post('/recipes/favorites/$recipeId');
  }

  Future<void> removeFavorite(String recipeId) async {
    await _dio.delete('/recipes/favorites/$recipeId');
  }

  Future<void> toggleFavorite(String recipeId, bool isFav) async {
    isFav ? await removeFavorite(recipeId) : await addFavorite(recipeId);
  }
}
