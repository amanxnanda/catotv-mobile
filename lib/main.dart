import 'package:auto_route/auto_route.dart';
import 'package:cato_feed/application/auth/auth.dart';
import 'package:cato_feed/application/init/init.dart';
import 'package:cato_feed/injection.dart';
import 'package:cato_feed/presentation/routes/Router.gr.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'presentation/utils/assets/theme.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cato_feed/application/topic/topic.dart';
import 'package:cato_feed/application/post/post.dart';

/// Handler for firebase messaging background message
Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }

  // Or do other work.
}

/**
 *
 *
    _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) async {
    print("onMessage: $message");
    _showItemDialog(message);
    },
    onBackgroundMessage: myBackgroundMessageHandler,
    onLaunch: (Map<String, dynamic> message) async {
    print("onLaunch: $message");
    _navigateToItemDetail(message);
    },
    onResume: (Map<String, dynamic> message) async {
    print("onResume: $message");
    _navigateToItemDetail(message);
    },
    );
 */

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  FlutterError.onError = Crashlytics.instance.recordFlutterError;

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => getIt<InitBloc>()..add(InitEvent.requestAppVersionCheck())),
      BlocProvider(create: (_) => getIt<AuthBloc>()),
      BlocProvider(create: (_) => getIt<TopicBloc>()),
      BlocProvider(create: (_) => getIt<PostBloc>()),
    ],
    child: PlatformApp(
      title: 'Cato',
      debugShowCheckedModeBanner: false,
      material: (_, __) => MaterialAppData(theme: materialThemeData),
      cupertino: (_, __) => CupertinoAppData(theme: cupertinoTheme),
      builder: ExtendedNavigator.builder(
        router: CatoRouter(),
        observers: [
          FirebaseAnalyticsObserver(analytics: getIt.get<FirebaseAnalytics>()),
        ],
      ),
    ),
  ));
}