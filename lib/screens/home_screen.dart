import 'dart:async';

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
            _SectionsCarousel(sections: state.sections),
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
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: category.imageUrl == null
                                ? const Icon(Icons.image_outlined, size: 18)
                                : Image.network(
                                    category.imageUrl!,
                                    fit: BoxFit.cover,
                                    webHtmlElementStrategy: WebHtmlElementStrategy.always,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 18),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              category.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
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

class _SectionsCarousel extends StatefulWidget {
  const _SectionsCarousel({required this.sections});

  final List<ApiItem> sections;

  @override
  State<_SectionsCarousel> createState() => _SectionsCarouselState();
}

class _SectionsCarouselState extends State<_SectionsCarousel> {
  final PageController _controller = PageController(viewportFraction: 1);
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _SectionsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      _current = 0;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.sections.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_current + 1) % widget.sections.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (value) => setState(() => _current = value),
            itemCount: widget.sections.length,
            itemBuilder: (_, index) {
              final section = widget.sections[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: section.imageUrl == null
                    ? Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Center(child: Icon(Icons.image_outlined, size: 36)),
                      )
                    : Image.network(
                        section.imageUrl!,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.always,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Center(child: Icon(Icons.broken_image_outlined, size: 36)),
                        ),
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.sections.length,
            (index) => GestureDetector(
              onTap: () => _controller.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _current == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _current == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
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
