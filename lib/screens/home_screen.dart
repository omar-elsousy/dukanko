import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/api_item.dart';
import '../widgets/app_error_banner.dart';
import 'category_products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (state.isAuthenticated && !state.isBootstrapped && !state.isLoading) {
      Future.microtask(state.loadHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pages = [
      const _CatalogTab(),
      const _CartTab(),
      const _OrdersTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dukanko'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : state.loadHome,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Badge.count(
              count: state.cartCount,
              isLabelVisible: state.cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatefulWidget {
  const _CatalogTab();

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final filteredCategories = state.categories
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return RefreshIndicator(
      onRefresh: state.loadHome,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search categories',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 18),
          if (state.error != null) ...[
            AppErrorBanner(message: state.error!),
            const SizedBox(height: 14),
          ],
          _SectionHeader(title: 'Sections', action: '${state.sections.length} found'),
          const SizedBox(height: 10),
          if (state.sections.isEmpty)
            const _EmptyState(message: 'No sections returned yet.')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: state.sections
                  .map((section) => Chip(label: Text(section.title), backgroundColor: Colors.white, side: BorderSide.none))
                  .toList(),
            ),
          const SizedBox(height: 22),
          _SectionHeader(title: 'Categories', action: '${filteredCategories.length} found'),
          const SizedBox(height: 10),
          if (filteredCategories.isEmpty)
            const _EmptyState(message: 'No categories match your search.')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (_, index) {
                final category = filteredCategories[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: category)),
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              category.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.cart.isEmpty) return const _EmptyState(message: 'Your cart is empty.');

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        ...state.cart.map(
          (line) => Card(
            child: ListTile(
              title: Text(line.product.title),
              subtitle: Text('${line.product.price?.toStringAsFixed(2) ?? '0.00'} EGP'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () => state.updateCartQuantity(line.product, line.quantity - 1), icon: const Icon(Icons.remove_circle_outline)),
                  Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => state.updateCartQuantity(line.product, line.quantity + 1), icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(message: 'Orders screen will be wired to API next.');
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: ListTile(
            title: Text(state.userMobile ?? 'Sales user'),
            subtitle: const Text('Connected to Dukanko API'),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: state.isLoading ? null : state.logout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        Text(action, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}
