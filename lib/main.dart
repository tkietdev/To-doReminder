import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/group_provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService().initialize();
    await NotificationService().requestPermissions();

    debugPrint('Notification Service initialized');
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),

        ChangeNotifierProvider<TaskProvider>(create: (_) => TaskProvider()),

        ChangeNotifierProvider<GroupProvider>(create: (_) => GroupProvider()),
      ],

      child: MaterialApp(
        title: 'TaskMate',

        debugShowCheckedModeBanner: false,

        themeMode: ThemeMode.system,

        theme: ThemeData(
          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),

          scaffoldBackgroundColor: Colors.grey[50],

          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),

          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),

          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        darkTheme: ThemeData(
          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),

        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
        },

        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      _hasInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final authProvider = context.read<AuthProvider>();

        await authProvider.initAuth();

        if (!mounted) return;

        final userId = authProvider.currentUser?.id;

        if (userId != null) {
          await context.read<TaskProvider>().loadTasks(userId);

          if (!mounted) return;

          await context.read<GroupProvider>().loadGroups(userId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const CircularProgressIndicator(),

                  const SizedBox(height: 16),

                  Text(
                    'Đang tải...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return authProvider.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
