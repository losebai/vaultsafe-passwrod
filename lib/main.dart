import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/storage/storage_service.dart';
import 'package:vaultsafe/features/auth/auth_service.dart';
import 'package:vaultsafe/features/auth/auth_screen.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';

void main() async {
  // 确保 Flutter 的 Widgets 绑定在使用任何依赖于它的功能之前已被正确初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储服务（先初始化存储以获取设置）
  final storageService = StorageService();
  await storageService.init();

  // 初始化认证服务
  final authService = await AuthService.initialize();

  // 设置屏幕方向限制（在 runApp 之前！）win不生效，部分chrome不生效
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFFAFBFC),
          surfaceContainer: const Color(0xFFF5F7FA),
          surfaceContainerHighest: const Color(0xFFEFF2F6),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        // 全局圆角
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Color(0xFFFFFFFF),
        ),
        // 输入框圆角
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2196F3),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        // 按钮圆角
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        //OutlinedButton 圆角
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        // AppBar 样式
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        // Scaffold 背景色
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF64B5F6),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1A1D21),
          surfaceContainer: const Color(0xFF23272C),
          surfaceContainerHighest: const Color(0xFF2D3238),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        // 暗色模式圆角
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Color(0xFF23272C),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D3238),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF64B5F6),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1D21),
      ),
      themeMode: ThemeMode.system,
      home: const AuthScreen(),
    );
  }
}
