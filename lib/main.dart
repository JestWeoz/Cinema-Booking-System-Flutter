import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'app/router/app_router.dart';
import 'core/payment/payment_deep_link_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'vi';
  unawaited(initializeDateFormatting('vi'));

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const CinemaBookingApp());
}

class CinemaBookingApp extends StatefulWidget {
  const CinemaBookingApp({super.key});

  @override
  State<CinemaBookingApp> createState() => _CinemaBookingAppState();
}

class _CinemaBookingAppState extends State<CinemaBookingApp> {
  @override
  void initState() {
    super.initState();
    unawaited(PaymentDeepLinkService.instance.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cinema Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
