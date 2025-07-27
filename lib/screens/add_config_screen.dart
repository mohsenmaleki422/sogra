import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/v2ray_provider.dart';
import '../models/v2ray_config.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

class AddConfigScreen extends StatefulWidget {
  const AddConfigScreen({Key? key}) : super(key: key);

  @override
  State<AddConfigScreen> createState() => _AddConfigScreenState();
}

class _AddConfigScreenState extends State<AddConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _configController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _configController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _configController.text = data.text!;
      });
    }
  }

  void _addConfig() {
    if (_formKey.currentState!.validate()) {
      try {
        final configText = _configController.text.trim();
        
        // Check if it's a valid V2Ray URL
        if (!configText.startsWith('vmess://') && 
            !configText.startsWith('vless://') &&
            !configText.startsWith('trojan://') &&
            !configText.startsWith('ss://')) {
          setState(() {
            _errorMessage = 'Invalid configuration format';
          });
          return;
        }
        
        // Parse the configuration
        V2RayURL parser = FlutterV2ray.parseFromURL(configText);
        
        // Determine config type
        String configType = '';
        if (configText.startsWith('vmess://')) {
          configType = 'vmess';
        } else if (configText.startsWith('vless://')) {
          configType = 'vless';
        } else if (configText.startsWith('trojan://')) {
          configType = 'trojan';
        } else if (configText.startsWith('ss://')) {
          configType = 'shadowsocks';
        }
        
        // Create config object
        // Access server details from the V2Ray configuration
        // The parser doesn't directly expose serverAddress and serverPort as properties
        // Instead, we need to extract them from the configuration
        String address = '';
        int port = 0;
        
        // For simplicity, we'll extract address and port from the URL itself
        // This is a basic implementation and might need refinement based on URL format
        if (configText.contains('@')) {
          // Format is usually protocol://[user:pass@]address:port
          final parts = configText.split('@')[1].split(':');
          address = parts[0];
          // Extract port, removing any path or parameters
          if (parts.length > 1) {
            port = int.tryParse(parts[1].split('/')[0].split('?')[0]) ?? 0;
          }
        }
        
        final config = V2RayConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          remark: parser.remark,
          address: address,
          port: port,
          configType: configType,
          fullConfig: configText,
        );
        
        // Add to provider
        final provider = Provider.of<V2RayProvider>(context, listen: false);
        provider.addConfig(config);
        
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _errorMessage = 'Error parsing configuration: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Configuration'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your V2Ray configuration below:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _configController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'vmess://, vless://, etc.',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: _pasteFromClipboard,
                    tooltip: 'Paste from clipboard',
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a configuration';
                  }
                  return null;
                },
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add Configuration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}