import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/v2ray_provider.dart';

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<V2RayProvider>(
      builder: (context, provider, child) {
        final activeConfig = provider.activeConfig;
        final isConnecting = provider.isConnecting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor(activeConfig != null, isConnecting),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isConnecting)
                    const SpinKitRing(
                      color: Colors.white,
                      size: 24,
                      lineWidth: 3,
                    )
                  else
                    Icon(
                      activeConfig != null ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(activeConfig, isConnecting),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (activeConfig != null && !isConnecting)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Connected to ${activeConfig.remark}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (provider.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    provider.errorMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return Colors.orange;
    }
    return isConnected ? Colors.green : Colors.red;
  }

  String _getStatusText(dynamic activeConfig, bool isConnecting) {
    if (isConnecting) {
      return 'Connecting...';
    }
    return activeConfig != null ? 'Connected' : 'Disconnected';
  }
}