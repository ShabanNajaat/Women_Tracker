import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/api_service.dart';
import 'sqflite_platform_stub.dart'
    if (dart.library.io) 'sqflite_platform.dart' as sqflite_plat;
import 'services/challenge_service.dart';
import 'services/partner_service.dart';
import 'services/phase_notification_service.dart';
import 'services/buddy_challenge_service.dart';
import 'services/cycle_service.dart';
import 'services/glow_effects_service.dart';
import 'services/glow_notification_service.dart';
import 'services/medication_reminder_service.dart';
import 'services/wellness_schedule_service.dart';
import 'services/health_log_service.dart';
import 'services/wearable_health_service.dart';
import 'services/theme_service.dart';
import 'services/wellness_score_service.dart';
import 'screens/splash_screen.dart';
import 'theme/glow_app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await sqflite_plat.initSqfliteForPlatform();
  }
  await ThemeService.load();
  await GlowEffectsService.instance.load();
  await ApiService().init();
  await CycleService.instance.ensureLoaded();
  await HealthLogService.instance.ensureLoaded();
  await WearableHealthService.instance.ensureLoaded();
  await WellnessScoreService.instance.ensureLoaded();
  await ChallengeService.instance.ensureLoaded();
  if (ApiService().isAuthenticated) {
    await PartnerService.instance.refresh();
  }
  await GlowNotificationService.instance.init();
  await MedicationReminderService.instance.ensureLoaded();
  await MedicationReminderService.instance.rescheduleAll();
  await WellnessScheduleService.instance.ensureLoaded();
  await WellnessScheduleService.instance.rescheduleAll();
  await BuddyChallengeService.instance.ensureLoaded();
  await PhaseNotificationService.instance.reschedule();
  runApp(const GlowApp());
}

class GlowApp extends StatelessWidget {
  const GlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Glow Wellness',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final overlay = isDark
                ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
                : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlay,
              child: MediaQuery(
                data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.25,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          theme: GlowAppTheme.light(),
          darkTheme: GlowAppTheme.dark(),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
