import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/v2ray_provider.dart';
import '../widgets/server_list_item.dart';
import '../widgets/connection_status.dart';
import 'subscription_screen.dart';
import 'add_config_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('V2Ray Client'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<V2RayProvider>(context, listen: false);
              provider.loadConfigs();
              provider.loadSubscriptions();
              provider.fetchNotificationStatus(); // Fetch status from notification
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
            tooltip: 'About',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onSelected: (String value) {
              switch (value) {
                case 'config':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddConfigScreen(),
                    ),
                  );
                  break;
                case 'subscription':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'config',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Add Configuration', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'subscription',
                child: Row(
                  children: [
                    Icon(Icons.rss_feed, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Add Subscription', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectionStatus(),
          Expanded(
            child: Consumer<V2RayProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.configs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No configurations found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionScreen(),
                              ),
                            );
                          },
                          child: const Text('Add Subscription'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: provider.configs.length,
                  itemBuilder: (context, index) {
                    final config = provider.configs[index];
                    return ServerListItem(config: config);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}