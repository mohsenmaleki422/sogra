import 'dart:convert';
import 'dart:async';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2ray_config.dart';
import '../models/subscription.dart';

class V2RayService {
  Function()? _onDisconnected;
  bool _isInitialized = false;
  V2RayConfig? _activeConfig;
  Timer? _statusCheckTimer;
  bool _statusCheckRunning = false;
  DateTime? _lastConnectionTime;
  
  late final FlutterV2ray _flutterV2ray;

  V2RayService() {
    _flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        print('V2Ray status changed: $status');
        _handleStatusChange(status);
      },
    );
  }

  void _handleStatusChange(V2RayStatus status) {
    // Handle disconnection from notification
    // Check for common disconnected status values using string matching
    String statusString = status.toString().toLowerCase();
    if ((statusString.contains('disconnect') || 
         statusString.contains('stop') ||
         statusString.contains('idle')) && _activeConfig != null) {
      print('Detected disconnection from notification');
      _activeConfig = null;
      _onDisconnected?.call();
    }
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _flutterV2ray.initializeV2Ray(
        notificationIconResourceType: "mipmap",
        notificationIconResourceName: "ic_launcher",
      );
      _isInitialized = true;
      
      // Try to restore active config if VPN is still running
      await _tryRestoreActiveConfig();
    }
  }

  Future<bool> connect(V2RayConfig config) async {
    try {
      await initialize();
      
      // Parse the configuration
      V2RayURL parser = FlutterV2ray.parseFromURL(config.fullConfig);
      
      // Request permission if needed (for VPN mode)
      bool hasPermission = await _flutterV2ray.requestPermission();
      if (!hasPermission) {
        return false;
      }
      
      // Start V2Ray
      await _flutterV2ray.startV2Ray(
        remark: parser.remark,
        config: parser.getFullConfiguration(),
        blockedApps: null,
        bypassSubnets: null,
        proxyOnly: false, // Use VPN mode for proper traffic routing
        notificationDisconnectButtonName: "DISCONNECT",
      );
      
      _activeConfig = config;
      _lastConnectionTime = DateTime.now();
      
      // Save active config to persistent storage
      await _saveActiveConfig(config);
      
      return true;
    } catch (e) {
      print('Error connecting to V2Ray: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _flutterV2ray.stopV2Ray();
      _activeConfig = null;
      
      // Clear active config from storage
      await _clearActiveConfig();
    } catch (e) {
      print('Error disconnecting from V2Ray: $e');
    }
  }

  Future<void> _saveActiveConfig(V2RayConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_config', jsonEncode(config.toJson()));
  }

  Future<void> _clearActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_config');
  }

  Future<V2RayConfig?> _loadActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configJson = prefs.getString('active_config');
    if (configJson == null) return null;
    return V2RayConfig.fromJson(jsonDecode(configJson));
  }

  Future<void> _tryRestoreActiveConfig() async {
    try {
      // Check if VPN is actually running
      final delay = await _flutterV2ray.getConnectedServerDelay();
      final isConnected = delay != null && delay >= 0;
      
      if (isConnected) {
        // Try to load the saved active config
        final savedConfig = await _loadActiveConfig();
        if (savedConfig != null) {
          _activeConfig = savedConfig;
          print('Restored active config: ${savedConfig.remark}');
        }
      } else {
        // VPN is not running, clear any saved config
        await _clearActiveConfig();
      }
    } catch (e) {
      print('Error restoring active config: $e');
      // Clear any saved config on error
      await _clearActiveConfig();
    }
  }

  Future<int> getServerDelay(V2RayConfig config) async {
    try {
      await initialize();
      V2RayURL parser = FlutterV2ray.parseFromURL(config.fullConfig);
      return await _flutterV2ray.getServerDelay(config: parser.getFullConfiguration());
    } catch (e) {
      print('Error getting server delay: $e');
      return -1;
    }
  }

  Future<List<V2RayConfig>> parseSubscriptionUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load subscription');
      }

      final List<V2RayConfig> configs = [];
      final String content = response.body;
      final List<String> lines = content.split('\n');

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        try {
          if (line.startsWith('vmess://') || 
              line.startsWith('vless://') ||
              line.startsWith('trojan://') ||
              line.startsWith('ss://')) {
            
            V2RayURL parser = FlutterV2ray.parseFromURL(line);
            String configType = '';
            
            if (line.startsWith('vmess://')) {
              configType = 'vmess';
            } else if (line.startsWith('vless://')) {
              configType = 'vless';
            } else if (line.startsWith('trojan://')) {
              configType = 'trojan';
            } else if (line.startsWith('ss://')) {
              configType = 'shadowsocks';
            }
            
            // Extract address and port from the URL string
            String address = '';
            int port = 0;
            
            // For simplicity, extract address and port from the URL itself
            if (line.contains('@')) {
              // Format is usually protocol://[user:pass@]address:port
              final parts = line.split('@')[1].split(':');
              address = parts[0];
              // Extract port, removing any path or parameters
              if (parts.length > 1) {
                port = int.tryParse(parts[1].split('/')[0].split('?')[0]) ?? 0;
              }
            }
            
            configs.add(V2RayConfig(
              id: DateTime.now().millisecondsSinceEpoch.toString() + configs.length.toString(),
              remark: parser.remark,
              address: address,
              port: port,
              configType: configType,
              fullConfig: line,
            ));
          }
        } catch (e) {
          print('Error parsing config: $e');
        }
      }

      return configs;
    } catch (e) {
      print('Error parsing subscription: $e');
      return [];
    }
  }

  // Save and load configurations
  Future<void> saveConfigs(List<V2RayConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> configsJson = configs.map((config) => jsonEncode(config.toJson())).toList();
    await prefs.setStringList('v2ray_configs', configsJson);
  }

  Future<List<V2RayConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? configsJson = prefs.getStringList('v2ray_configs');
    if (configsJson == null) return [];
    
    return configsJson
        .map((json) => V2RayConfig.fromJson(jsonDecode(json)))
        .toList();
  }

  // Save and load subscriptions
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> subscriptionsJson = 
        subscriptions.map((sub) => jsonEncode(sub.toJson())).toList();
    await prefs.setStringList('v2ray_subscriptions', subscriptionsJson);
  }

  Future<List<Subscription>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? subscriptionsJson = prefs.getStringList('v2ray_subscriptions');
    if (subscriptionsJson == null) return [];
    
    return subscriptionsJson
        .map((json) => Subscription.fromJson(jsonDecode(json)))
        .toList();
  }

  void setDisconnectedCallback(Function() callback) {
    _onDisconnected = callback;
    // Disable automatic monitoring to prevent false disconnects
    // _startStatusMonitoring();
  }

  void _startStatusMonitoring() {
    // Stop existing timer if any
    _statusCheckTimer?.cancel();
    
    // Start periodic status checking every 5 seconds (less aggressive)
    _statusCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkConnectionStatus();
    });
  }

  void _stopStatusMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  Future<void> _checkConnectionStatus() async {
    if (_activeConfig == null || _statusCheckRunning) return;
    
    // Skip monitoring for the first 10 seconds after connection to allow stabilization
    if (_lastConnectionTime != null && 
        DateTime.now().difference(_lastConnectionTime!).inSeconds < 10) {
      return;
    }
    
    _statusCheckRunning = true;
    try {
      // Check if V2Ray is actually running by getting the connection state
      final isConnected = await _flutterV2ray.getConnectedServerDelay();
      
      // Only consider it disconnected if we get multiple consecutive failures
      // or if the delay is clearly indicating disconnection
      if (isConnected == null || isConnected < -1) { // Changed from < 0 to < -1
        if (_activeConfig != null) {
          print('Detected VPN disconnection - no server response (delay: $isConnected)');
          _activeConfig = null;
          _lastConnectionTime = null;
          _onDisconnected?.call();
        }
      }
    } catch (e) {
      // Only disconnect on error if we've been connected for a while
      if (_activeConfig != null && _lastConnectionTime != null && 
          DateTime.now().difference(_lastConnectionTime!).inSeconds > 30) {
        print('Detected VPN disconnection - error checking status: $e');
        _activeConfig = null;
        _lastConnectionTime = null;
        _onDisconnected?.call();
      }
    } finally {
      _statusCheckRunning = false;
    }
  }

  // Public method to force check connection status
  Future<bool> isActuallyConnected() async {
    try {
      final delay = await _flutterV2ray.getConnectedServerDelay();
      final isConnected = delay != null && delay >= 0;
      
      if (!isConnected && _activeConfig != null) {
        print('Force check detected disconnection');
        _activeConfig = null;
        _onDisconnected?.call();
      }
      
      return isConnected;
    } catch (e) {
      print('Error in force connection check: $e');
      if (_activeConfig != null) {
        _activeConfig = null;
        _onDisconnected?.call();
      }
      return false;
    }
  }

  void dispose() {
    _stopStatusMonitoring();
  }

  V2RayConfig? get activeConfig => _activeConfig;
}
