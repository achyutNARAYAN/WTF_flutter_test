import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wtf_shared/services/services.dart';
import 'package:wtf_shared/utils/utils.dart';
import 'providers.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  AppLogger.log(LogTag.auth, 'Guru App started');
  runApp(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(authService)],
      child: GuruApp(authService: authService),
    ),
  );
}

class GuruApp extends StatelessWidget {
  final AuthService authService;
  const GuruApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Guru — Fitness Coach',
    theme: AppTheme.build(AppColors.memberPrimary),
    routerConfig: buildRouter(authService),
    debugShowCheckedModeBanner: false,
  );
}
