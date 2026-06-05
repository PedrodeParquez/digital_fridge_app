import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/api_client.dart';
import '../../store.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  static const _shadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  List<Recipe> get _recipes => AppStore.instance.myRecipes;

  Future<void> _openAddRecipe() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddRecipeScreen()));
    if (added == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recipes = _recipes;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Мои рецепты',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: cs.outline),
                  const SizedBox(height: 14),
                  Text(
                    'Пока здесь пусто',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Добавьте рецепт или отметьте\nлюбимые в разделе Рецепты',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: recipes.length,
              itemBuilder: (_, i) => _recipeRow(cs, recipes[i]),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openAddRecipe,
              icon: const Icon(Icons.add),
              label: const Text(
                'Добавить рецепт',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recipeRow(ColorScheme cs, Recipe recipe) {
    final isFav = AppStore.instance.favoriteRecipeIds.contains(recipe.id);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: recipe.mainImageUrl != null
                      ? Image.network(
                          '${ApiClient.baseUrl}${recipe.mainImageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _thumb(cs),
                        )
                      : _thumb(cs),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          recipe.cookTimeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.local_fire_department_outlined,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          recipe.caloriesLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: isFav ? Colors.red : cs.outline,
                  size: 22,
                ),
                onPressed: () =>
                    setState(() => AppStore.instance.toggleFavorite(recipe.id)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(ColorScheme cs) => Container(
        color: cs.outline.withValues(alpha: 0.2),
        child: Icon(Icons.restaurant, color: cs.onSurfaceVariant, size: 26),
      );
}
