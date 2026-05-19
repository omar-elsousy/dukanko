import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/api_item.dart';
import '../widgets/app_error_banner.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

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
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: state.cartCount,
              isLabelVisible: state.cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return RefreshIndicator(
      onRefresh: state.loadHome,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _HeroCard(productCount: state.products.length),
          if (state.error != null) ...[
            const SizedBox(height: 14),
            AppErrorBanner(message: state.error!),
          ],
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Categories',
            action: '${state.categories.length} found',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: state.categories.isEmpty
                ? const _EmptyState(message: 'No categories returned yet.')
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) => Chip(
                      label: Text(state.categories[index].title),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                    ),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: state.categories.length,
                  ),
          ),
          const SizedBox(height: 22),
          _SectionHeader(title: 'Products', action: '${state.products.length} items'),
          const SizedBox(height: 12),
          if (state.isLoading && state.products.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.products.isEmpty)
            const _EmptyState(
              message: 'Products will appear here once the API endpoint responds.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .68,
              ),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  onAdd: () => state.addToCart(product),
                  onOpen: () => _openProduct(context, product),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openProduct(BuildContext context, ApiItem product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.productCount});

  final int productCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_mall_outlined, color: Colors.white, size: 38),
          const SizedBox(height: 18),
          Text(
            'Sales made simple',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$productCount products synced from your Laravel API.',
            style: const TextStyle(color: Colors.white),
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
    if (state.cart.isEmpty) {
      return const _EmptyState(message: 'Your cart is empty.');
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        ...state.cart.map(
          (line) => Card(
            child: ListTile(
              title: Text(line.product.title),
              subtitle: Text(
                '${line.product.price?.toStringAsFixed(2) ?? '0.00'} EGP',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => state.updateCartQuantity(
                      line.product,
                      line.quantity - 1,
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${line.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => state.updateCartQuantity(
                      line.product,
                      line.quantity + 1,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Total: ${state.cartTotal.toStringAsFixed(2)} EGP',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: state.isLoading ? null : state.checkout,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Create order'),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.orders.isEmpty) {
      return const _EmptyState(message: 'No orders returned from API yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemBuilder: (_, index) {
        final order = state.orders[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
            title: Text(order.title),
            subtitle: Text(order.description ?? order.subtitle ?? 'Order #${order.id}'),
            trailing: order.price == null
                ? null
                : Text('${order.price!.toStringAsFixed(2)} EGP'),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: state.orders.length,
    );
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
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  state.userMobile ?? 'Sales user',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text('Connected to Dukanko API', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.api),
          title: const Text('API base URL'),
          subtitle: const Text('Configured in lib/core/network/api_config.dart'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: state.logout,
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
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
