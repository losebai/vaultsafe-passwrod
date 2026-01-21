import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/storage/storage_service.dart';
import 'package:vaultsafe/features/auth/auth_service.dart';
import 'package:vaultsafe/features/auth/auth_screen.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';

void main() async {
  // 保 Flutter 的 Widgets 绑定（binding）在使用任何依赖于它的功能之前已被正确初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化认证服务
  await AuthService.initialize();

  // 初始化本地存储服务
  final storageService = StorageService();
  await storageService.init();

  // 设置屏幕方向限制（在 runApp 之前！）win不生效，部分chrome不生效
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🔐 关键：在这里完成所有异步安全初始化
  final authService = await AuthService.initialize(); // 自定义静态初始化方法

  // 运行应用程序
  runApp(
    ProviderScope(
      overrides: [
        // 覆盖默认的 storageServiceProvider
        storageServiceProvider.overrideWithValue(storageService),
        authServiceProvider.overrideWithValue(authService), // 注入已初始化实例
      ],
      child: const VaultSafeApp(),
    ),
  );
}

class VaultSafeApp extends StatelessWidget {
  const VaultSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaultSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: const AuthScreen(),
    );
  }
}
