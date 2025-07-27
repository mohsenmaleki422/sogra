# V2Ray Client

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-brightgreen.svg)](https://android.com/)

A powerful and user-friendly V2Ray client for Android, built with Flutter. This app provides seamless integration with the V2Ray protocol, allowing you to easily configure and manage your proxy connections with support for multiple server configurations and subscription management.

## 📱 Platform Support

### Android
- ✅ **Mobile**: Fully supported and optimized
- ✅ **Tablet**: Fully supported with responsive design
- ✅ **TV**: Supported with Android TV compatibility

## ✨ Features

### 🔧 Core Features
- **V2Ray Protocol Support**: Full support for V2Ray proxy protocol
- **Multiple Configuration Types**: Support for VMess, VLess, Trojan, and Shadowsocks
- **Subscription Management**: Easy import and management of subscription URLs
- **Auto-Update Subscriptions**: Automatic server list updates from subscription sources
- **Server Delay Testing**: Built-in ping test to check server response times
- **Connection Status Monitoring**: Real-time connection status with notification support

### 📱 User Interface
- **Modern Material Design**: Clean and intuitive user interface
- **Connection Status Widget**: Visual indication of connection state
- **Server List Management**: Easy-to-use server configuration list
- **Popup Menu Navigation**: Quick access to add configurations or subscriptions

### 🔄 Advanced Features
- **Notification Controls**: Connect/disconnect directly from notifications
- **Background Operation**: VPN continues running when app is minimized
- **State Persistence**: Connection state preserved across app restarts
- **Manual Configuration**: Support for manual server configuration input

## 📥 Installation

### Download
1. Download the latest APK from the [Releases](../../releases) page
2. Enable "Install from Unknown Sources" in Android settings
3. Install the APK file
4. Grant necessary permissions when prompted

## 🚀 Getting Started

### First Time Setup
1. **Launch the app** and grant VPN permissions when prompted
2. **Add a subscription** by tapping the + button → "Add Subscription"
3. **Enter subscription details**:
   - Name: Give your subscription a recognizable name
   - URL: Paste your subscription URL
4. **Tap "Add Subscription"** to import server configurations
5. **Select a server** from the list and tap "Connect"

### Manual Configuration
1. Tap the + button → "Add Configuration"
2. Choose your protocol type (VMess, VLess, Trojan, or Shadowsocks)
3. Fill in the server details
4. Save and connect

## 📖 Usage Guide

### Connecting to a Server
1. Select a server from the main list
2. Tap the "Connect" button
3. Grant VPN permission if requested
4. Monitor connection status in the notification bar

### Managing Subscriptions
1. Access subscription management from the + menu
2. Add new subscriptions with name and URL
3. Update existing subscriptions to refresh server lists
4. Remove unused subscriptions

### Testing Server Performance
1. Tap the speed test icon next to any server
2. View response time in milliseconds
3. Choose servers with lower latency for better performance

## 🔧 Configuration

### Supported Protocols
- **VMess**: V2Ray's native protocol with strong encryption
- **VLess**: Lightweight version of VMess
- **Trojan**: TLS-based proxy protocol
- **Shadowsocks**: Popular SOCKS5 proxy protocol

### Connection Modes
- **VPN Mode**: Routes all device traffic through the proxy

## 🛠️ Development

### Built With
- **Flutter 3.7.2+**: Cross-platform UI framework
- **Dart**: Programming language
- **flutter_v2ray**: V2Ray core integration
- **Provider**: State management
- **SharedPreferences**: Local data storage

### Architecture
```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic
└── widgets/         # Reusable UI components
```

## 📞 Support & Community

### Get Help
- 📱 **Telegram Channel**: [IRDevs Channel](https://t.me/irdevs_dns)
- 🆓 **Free Servers**: [Get Free Servers](https://t.me/tg_stars_free_servers)
- 🐛 **Bug Reports**: Create an issue in this repository
- 💡 **Feature Requests**: Submit enhancement requests

### Community Guidelines
- Be respectful and helpful to other users
- Search existing issues before creating new ones
- Provide detailed information when reporting bugs
- Follow the community guidelines in our Telegram channels

## 🔒 Privacy & Security

### Data Protection
- **No User Tracking**: We don't collect personal information
- **Local Storage**: All configurations stored locally on your device
- **Encrypted Connections**: All proxy connections use strong encryption
- **Open Source**: Code is available for security auditing

### Permissions Required
- **VPN Service**: Required for creating VPN connections
- **Internet Access**: Required for downloading configurations and connecting to servers
- **Network State**: Required for monitoring connection status

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📧 Contact

- **Developer**: Hossein Pira
- **Telegram**: [@h3dev](https://t.me/h3dev)
- **Email**: h3dev.pira@gmail.com

## 🙏 Acknowledgments

- V2Ray Project for the excellent proxy protocol
- Flutter team for the amazing framework
- Community contributors for their valuable feedback
- Beta testers for helping improve the app

---

**⭐ If you find this project useful, please give it a star on GitHub!**

**📱 Download now and enjoy secure, fast proxy connections on your Android device!**
