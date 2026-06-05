import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'recipes/recipes_screen.dart';
import 'products/products_screen.dart';
import 'profile/profile_screen.dart';
import 'recipes/add_recipe_screen.dart';
import 'products/add_product_screen.dart';
import 'products/add_purchase_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  bool _showProductMenu = false;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _recipesKey = GlobalKey<RecipesScreenState>();
  final _productsKey = GlobalKey<ProductsScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      RecipesScreen(key: _recipesKey),
      ProductsScreen(key: _productsKey),
      const ProfileScreen(),
    ];
  }

  void _onTabTap(int i) {
    if (_showProductMenu) setState(() => _showProductMenu = false);
    if (i == 0) _homeKey.currentState?.reload();
    setState(() => _currentIndex = i);
  }

  Future<void> _openAddProduct() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddProductScreen()));
    if (added == true) await _productsKey.currentState?.reload();
  }

  void _onFabPressed() async {
    if (_currentIndex == 1) {
      final added = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const AddRecipeScreen()));
      if (added == true) _recipesKey.currentState?.setState(() {});
    } else if (_currentIndex == 2) {
      setState(() => _showProductMenu = !_showProductMenu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showFab = _currentIndex == 2;

    return GestureDetector(
      onTap: () {
        if (_showProductMenu) setState(() => _showProductMenu = false);
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        floatingActionButton: showFab ? _buildFab(cs) : null,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTap,
              elevation: 0,
              backgroundColor: Colors.transparent,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Главная',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  activeIcon: Icon(Icons.menu_book),
                  label: 'Рецепты',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_basket_outlined),
                  activeIcon: Icon(Icons.shopping_basket),
                  label: 'Продукты',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Профиль',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab(ColorScheme cs) {
    if (_currentIndex != 2) {
      return FloatingActionButton(
        onPressed: _onFabPressed,
        child: const Icon(Icons.add, size: 28),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedOpacity(
          opacity: _showProductMenu ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedSlide(
            offset: _showProductMenu ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: !_showProductMenu,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IntrinsicWidth(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _menuTile(
                            label: 'Добавить покупку',
                            icon: Icons.shopping_cart_outlined,
                            onTap: () async {
                              setState(() => _showProductMenu = false);
                              final added = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => const AddPurchaseScreen(),
                                    ),
                                  );
                              if (added == true)
                                await _productsKey.currentState?.reload();
                            },
                            isFirst: true,
                          ),
                          Divider(height: 0, color: Colors.grey.shade200),
                          _menuTile(
                            label: 'Добавить продукт',
                            icon: Icons.kitchen_outlined,
                            onTap: () {
                              setState(() => _showProductMenu = false);
                              _openAddProduct();
                            },
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'fab_main',
          onPressed: _onFabPressed,
          child: AnimatedRotation(
            turns: _showProductMenu ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _menuTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: const Color(0xFF2E9B45)),
          ],
        ),
      ),
    );
  }
}
