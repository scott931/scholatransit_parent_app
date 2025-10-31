import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/quick_action_card.dart';
import '../../../shared/widgets/status_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final driver = authState.driver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.go('/chats');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      driver?.fullName ?? 'Parent',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s what\'s happening with your child\'s transportation today.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Current Status
            Text(
              'Current Status',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const StatusCard(
              title: 'Trip Status',
              status: 'On Schedule',
              icon: Icons.directions_bus,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const StatusCard(
              title: 'Student Status',
              status: 'On Bus',
              icon: Icons.person,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                QuickActionCard(
                  title: 'View Trips',
                  icon: Icons.route,
                  color: Colors.blue,
                  onTap: () => context.go('/trips'),
                ),
                QuickActionCard(
                  title: 'Students',
                  icon: Icons.school,
                  color: Colors.green,
                  onTap: () => context.go('/students'),
                ),
                QuickActionCard(
                  title: 'Chats',
                  icon: Icons.chat,
                  color: Colors.orange,
                  onTap: () => context.go('/chats'),
                ),
                QuickActionCard(
                  title: 'Emergency',
                  icon: Icons.emergency,
                  color: Colors.red,
                  onTap: () => context.go('/emergency'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: const Text('Student picked up'),
                      subtitle: const Text('5 minutes ago'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.directions_bus,
                        color: Colors.blue,
                      ),
                      title: const Text('Trip started'),
                      subtitle: const Text('15 minutes ago'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.notifications,
                        color: Colors.orange,
                      ),
                      title: const Text('Route update'),
                      subtitle: const Text('1 hour ago'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
