import 'package:flutter/material.dart';
import '../../controllers/app_scope.dart';
import '../../models/api_item.dart';
import '../order_details_screen.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    
    // فلترة الأوردرات النشطة لتظهر فقط الـ placed
    final activeOrders = state.orders.where((o) => 
      (o.subtitle ?? '').toLowerCase().contains('placed')
    ).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrderList(orders: activeOrders, onRefresh: state.loadOrders, canCancel: true),
                _OrderList(orders: state.ordersHistory, onRefresh: state.loadOrders, canCancel: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.onRefresh,
    required this.canCancel,
  });

  final List<ApiItem> orders;
  final Future<void> Function() onRefresh;
  final bool canCancel;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _EmptyState(message: 'No orders found.');
    }

    final state = AppScope.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                  title: Text('Order #${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.subtitle).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (order.subtitle ?? 'N/A').toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(order.subtitle),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.raw['created_at']?.toString().split(' ')[0] ?? '',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (order.price != null)
                        Text(
                          'Total: ${order.price!.toStringAsFixed(2)} EGP',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id)),
                  ),
                ),
                if (canCancel && order.raw['status']?.toString().toLowerCase() == 'placed')
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: state.isLoading ? null : () => _showCancelDialog(context, state, order.id),
                          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                          label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, dynamic state, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order #$orderId?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('NO')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await state.cancelOrder(orderId);
            },
            child: const Text('YES, CANCEL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('placed')) return Colors.blue;
    if (s.contains('cancel')) return Colors.red;
    if (s.contains('deliver') || s.contains('complete')) return Colors.green;
    return Colors.orange;
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
