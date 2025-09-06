import 'package:appbanquanao/providers/cart_provider.dart';
import 'package:appbanquanao/screens/admin/admin_orders_screen.dart';
import 'package:appbanquanao/screens/home/home_screen.dart';
import 'package:appbanquanao/screens/theme.dart';
import 'package:appbanquanao/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'screens/auth/login_screen.dart';
import 'providers/product_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(service: ProductService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // 👈 Thêm dòng này
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Shop Quần Áo',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.currentTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      routes: {
        '/home': (context) => const HomeScreen(),
        '/admin/orders': (context) => const AdminOrdersScreen(),
        // Thêm các route khác nếu bạn cần
      },
    );
  }
}
