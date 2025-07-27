import 'package:flutter/widgets.dart';
import '../models/v2ray_config.dart';
import '../models/subscription.dart';
import '../services/v2ray_service.dart';

class V2RayProvider with ChangeNotifier, WidgetsBindingObserver {
  final V2RayService _v2rayService = V2RayService();
  
  List<V2RayConfig> _configs = [];
  List<Subscription> _subscriptions = [];
  V2RayConfig? _selectedConfig;
  bool _isConnecting = false;
  bool _isLoading = false;
  String _errorMessage = '';

  List<V2RayConfig> get configs => _configs;
  List<Subscription> get subscriptions => _subscriptions;
  V2RayConfig? get selectedConfig => _selectedConfig;
  V2RayConfig? get activeConfig => _v2rayService.activeConfig;
  bool get isConnecting => _isConnecting;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  V2RayProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    _setLoading(true);
    try {
      await _v2rayService.initialize();
      
      // Set up callback for notification disconnects
      _v2rayService.setDisconnectedCallback(() {
        _handleNotificationDisconnect();
      });
      
      await loadConfigs();
      await loadSubscriptions();
      
      // Fetch the current notification status to sync with the app
      await fetchNotificationStatus();

      // If we have an active config and it's in the saved list, ensure its status is correct
      final activeConfig = _v2rayService.activeConfig;
      if (activeConfig != null) {
        for (var config in _configs) {
          if (config.fullConfig == activeConfig.fullConfig) {
            config.isConnected = true;
            _selectedConfig = config;
            break;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConfigs() async {
    _setLoading(true);
    try {
      _configs = await _v2rayService.loadConfigs();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load configurations: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSubscriptions() async {
    _setLoading(true);
    try {
      _subscriptions = await _v2rayService.loadSubscriptions();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load subscriptions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addConfig(V2RayConfig config) async {
    _configs.add(config);
    await _v2rayService.saveConfigs(_configs);
    notifyListeners();
  }

  Future<void> removeConfig(V2RayConfig config) async {
    _configs.removeWhere((c) => c.id == config.id);
    
    // Also remove from subscriptions
    for (int i = 0; i < _subscriptions.length; i++) {
      final subscription = _subscriptions[i];
      if (subscription.configIds.contains(config.id)) {
        final updatedConfigIds = List<String>.from(subscription.configIds)
          ..remove(config.id);
        _subscriptions[i] = subscription.copyWith(configIds: updatedConfigIds);
      }
    }
    
    await _v2rayService.saveConfigs(_configs);
    await _v2rayService.saveSubscriptions(_subscriptions);
    notifyListeners();
  }

  Future<void> addSubscription(String name, String url) async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final configs = await _v2rayService.parseSubscriptionUrl(url);
      if (configs.isEmpty) {
        _setError('No valid configurations found in subscription');
        return;
      }
      
      // Add configs
      _configs.addAll(configs);
      await _v2rayService.saveConfigs(_configs);
      
      // Create subscription
      final subscription = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: url,
        lastUpdated: DateTime.now(),
        configIds: configs.map((c) => c.id).toList(),
      );
      
      _subscriptions.add(subscription);
      await _v2rayService.saveSubscriptions(_subscriptions);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final configs = await _v2rayService.parseSubscriptionUrl(subscription.url);
      if (configs.isEmpty) {
        _setError('No valid configurations found in subscription');
        return;
      }
      
      // Remove old configs
      _configs.removeWhere((c) => subscription.configIds.contains(c.id));
      
      // Add new configs
      _configs.addAll(configs);
      await _v2rayService.saveConfigs(_configs);
      
      // Update subscription
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = subscription.copyWith(
          lastUpdated: DateTime.now(),
          configIds: configs.map((c) => c.id).toList(),
        );
        await _v2rayService.saveSubscriptions(_subscriptions);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeSubscription(Subscription subscription) async {
    // Remove configs associated with this subscription
    _configs.removeWhere((c) => subscription.configIds.contains(c.id));
    
    // Remove subscription
    _subscriptions.removeWhere((s) => s.id == subscription.id);
    
    await _v2rayService.saveConfigs(_configs);
    await _v2rayService.saveSubscriptions(_subscriptions);
    notifyListeners();
  }

  Future<void> connectToServer(V2RayConfig config) async {
    _isConnecting = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Disconnect from current server if connected
      if (_v2rayService.activeConfig != null) {
        await _v2rayService.disconnect();
      }
      
      // Connect to new server
      final success = await _v2rayService.connect(config);
      if (success) {
        // Update config status
        for (int i = 0; i < _configs.length; i++) {
          if (_configs[i].id == config.id) {
            _configs[i].isConnected = true;
          } else {
            _configs[i].isConnected = false;
          }
        }
        _selectedConfig = config;

        // Persist the changes
        await _v2rayService.saveConfigs(_configs);
      } else {
        _setError('Failed to connect to server');
      }
    } catch (e) {
      _setError('Error connecting to server: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _isConnecting = true;
    notifyListeners();
    
    try {
      await _v2rayService.disconnect();
      
      // Update config status
      for (int i = 0; i < _configs.length; i++) {
        _configs[i].isConnected = false;
      }
      
      _selectedConfig = null;

      // Persist the changes
      await _v2rayService.saveConfigs(_configs);
    } catch (e) {
      _setError('Error disconnecting: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<int> testServerDelay(V2RayConfig config) async {
    try {
      return await _v2rayService.getServerDelay(config);
    } catch (e) {
      _setError('Error testing server delay: $e');
      return -1;
    }
  }

  void selectConfig(V2RayConfig config) {
    _selectedConfig = config;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void _handleNotificationDisconnect() {
    // Update config status when disconnected from notification
    for (int i = 0; i < _configs.length; i++) {
      _configs[i].isConnected = false;
    }
    
    _selectedConfig = null;
    
    // Persist the changes
    _v2rayService.saveConfigs(_configs).then((_) {
      notifyListeners();
    }).catchError((e) {
      print('Error saving configs after notification disconnect: $e');
      notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // Fetch the actual connection status from the notification
      fetchNotificationStatus();
    }
  }

  // Method to fetch connection status from the notification
  Future<void> fetchNotificationStatus() async {
    try {
      // Get the actual connection status from the service
      final isActuallyConnected = await _v2rayService.isActuallyConnected();
      final activeConfig = _v2rayService.activeConfig;
      
      print('Fetching notification status - Connected: $isActuallyConnected, Active config: ${activeConfig?.remark}');
      
      // Update all configs based on the actual status
      bool statusChanged = false;
      for (int i = 0; i < _configs.length; i++) {
        bool shouldBeConnected = false;
        
        if (isActuallyConnected && activeConfig != null) {
          // Find the matching config by comparing the server details
          shouldBeConnected = _configs[i].fullConfig == activeConfig.fullConfig ||
                            (_configs[i].address == activeConfig.address && _configs[i].port == activeConfig.port);
        }
        
        if (_configs[i].isConnected != shouldBeConnected) {
          _configs[i].isConnected = shouldBeConnected;
          statusChanged = true;
          
          if (shouldBeConnected) {
            _selectedConfig = _configs[i];
          }
        }
      }
      
      if (!isActuallyConnected) {
        _selectedConfig = null;
      }
      
      if (statusChanged) {
        await _v2rayService.saveConfigs(_configs);
        notifyListeners();
        print('Connection status updated from notification');
      }
    } catch (e) {
      print('Error fetching notification status: $e');
    }
  }

  // Method to manually check connection status
  Future<void> checkConnectionStatus() async {
    // Force check the actual connection status
    final isActuallyConnected = await _v2rayService.isActuallyConnected();
    
    // Update our configs based on the actual status
    bool hadConnectedConfig = false;
    for (int i = 0; i < _configs.length; i++) {
      if (_configs[i].isConnected && !isActuallyConnected) {
        _configs[i].isConnected = false;
        hadConnectedConfig = true;
      }
    }
    
    if (hadConnectedConfig) {
      _selectedConfig = null;
      await _v2rayService.saveConfigs(_configs);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose the service to stop monitoring
    _v2rayService.dispose();
    // Disconnect if connected when disposing
    if (_v2rayService.activeConfig != null) {
      _v2rayService.disconnect();
    }
    super.dispose();
  }
}
