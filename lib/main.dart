import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:vaultsafe/core/storage/storage_service.dart';
import 'package:vaultsafe/features/auth/auth_service.dart';
import 'package:vaultsafe/features/auth/auth_screen.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';

/// 从安全存储获取数据目录
/// 如果没有设置，返回 null（将使用默认目录）
Future<String?> _getDataDirectory() async {
  const storage = FlutterSecureStorage();
  return await storage.read(key: 'data_directory');
}

void main() async {
  // 确保 Flutter 的 Widgets 绑定在使用任何依赖于它的功能之前已被正确初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 先读取数据目录设置
  String? dataDirectory = await _getDataDirectory();

  // 如果没有设置目录，使用默认目录
  if (dataDirectory == null || dataDirectory.isEmpty) {
    final appDocDir = await getApplicationDocumentsDirectory();
    dataDirectory = path.join(appDocDir.path, 'vault_safe_data');
    // 保存默认目录到安全存储
    const storage = FlutterSecureStorage();
    await storage.write(key: 'data_directory', value: dataDirectory);
  }

  // 使用正确的目录初始化本地存储服务
  final storageService = StorageService();
  await storageService.init(customDirectory: dataDirectory);

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
      // 亮色 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ).copyWith(
          // 覆盖之前的颜色
          surface: const Color(0xFFFAFBFC),
          surfaceContainer: const Color(0xFFF5F7FA),
          surfaceContainerHighest: const Color(0xFFEFF2F6),
        ),
        useMaterial3: true, // 启用 Material Design 3
        fontFamily: 'Roboto',
        // 全局卡片样式
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
