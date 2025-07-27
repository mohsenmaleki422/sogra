import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2ray_config.dart';
import '../providers/v2ray_provider.dart';

class ServerListItem extends StatelessWidget {
  final V2RayConfig config;

  const ServerListItem({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<V2RayProvider>(context);
    final isActive = provider.activeConfig?.id == config.id;
    final isSelected = provider.selectedConfig?.id == config.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          provider.selectConfig(config);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      config.remark,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Theme.of(context).colorScheme.primary : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.speed),
                        onPressed: () async {
                          final delay = await provider.testServerDelay(config);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  delay >= 0 
                                      ? 'Ping: $delay ms' 
                                      : 'Failed to test server',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        tooltip: 'Test Delay',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Configuration'),
                              content: Text(
                                'Are you sure you want to delete ${config.remark}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.removeConfig(config);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${config.address}:${config.port}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConfigTypeColor(config.configType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      config.configType.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  if (isSelected)
                    ElevatedButton(
                      onPressed: isActive
                          ? () => provider.disconnect()
                          : () => provider.connectToServer(config),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.red : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isActive ? 'Disconnect' : 'Connect'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfigTypeColor(String configType) {
    switch (configType.toLowerCase()) {
      case 'vmess':
        return Colors.blue;
      case 'vless':
        return Colors.green;
      case 'trojan':
        return Colors.purple;
      case 'shadowsocks':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}