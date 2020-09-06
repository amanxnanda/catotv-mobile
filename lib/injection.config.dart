// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/get_it_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/auth/auth_bloc.dart';
import 'application/home/feed/feed_bloc.dart';
import 'application/onboard/onboard_bloc.dart';
import 'application/splash/splash_bloc.dart';
import 'application/topic_selection/topicselection_bloc.dart';
import 'domain/auth/i_auth_facade.dart';
import 'domain/auth/i_user_repository.dart';
import 'domain/core/i_logger.dart';
import 'domain/core/i_repository.dart';
import 'domain/posts/i_post_repository.dart';
import 'domain/topic/i_topic_repository.dart';
import 'infrastructure/auth/auth_facade.dart';
import 'infrastructure/auth/user_repository.dart';
import 'infrastructure/core/db/moor/moor_database.dart';
import 'infrastructure/core/logger/logger.dart';
import 'infrastructure/core/remote/network.dart';
import 'infrastructure/core/repository.dart';
import 'infrastructure/di/di.dart';
import 'infrastructure/posts/post_repository.dart';
import 'infrastructure/topic/topic_repository.dart';

/// adds generated dependencies
/// to the provided [GetIt] instance

Future<void> $initGetIt(GetIt g, {String environment}) async {
  final gh = GetItHelper(g, environment);
  final registerModule = _$RegisterModule();
  gh.factory<Connectivity>(() => registerModule.connectivity);
  gh.lazySingleton<FirebaseAnalytics>(() => registerModule.firebaseAnalytics);
  gh.factory<FirebaseDynamicLinks>(() => registerModule.dynamicLinks);
  gh.factory<FirebaseMessaging>(() => registerModule.firebaseMessaging);
  gh.lazySingleton<GoogleSignIn>(() => registerModule.getGoogleSignIn);
  gh.lazySingleton<MyDatabase>(() => MyDatabase());
  final sharedPreferences = await registerModule.prefs;
  gh.factory<SharedPreferences>(() => sharedPreferences);
  gh.factory<String>(() => registerModule.apiEndpoint,
      instanceName: 'ApiEndpoint');
  gh.lazySingleton<Network>(() => Network(
        g<ILogger>(),
        g<Connectivity>(),
        g<String>(instanceName: 'ApiEndpoint'),
      ));
  gh.lazySingleton<IPostRepository>(() => PostRepository(
        g<Network>(),
        g<ILogger>(),
        g<MyDatabase>(),
      ));
  gh.lazySingleton<IRepository>(() => Repository(g<Network>()));
  gh.lazySingleton<ITopicRepository>(() => TopicRepository(
        g<MyDatabase>(),
        g<Network>(),
        g<ILogger>(),
      ));
  gh.lazySingleton<IUserRepository>(() => UserRepository(
        g<MyDatabase>(),
        g<Network>(),
        g<ILogger>(),
        g<SharedPreferences>(),
      ));
  gh.factory<TopicselectionBloc>(
      () => TopicselectionBloc(g<IUserRepository>(), g<ITopicRepository>()));
  gh.factory<FeedBloc>(() => FeedBloc(g<IPostRepository>()));
  gh.lazySingleton<IAuthFacade>(() => AuthFacade(
        g<GoogleSignIn>(),
        g<IUserRepository>(),
        g<ILogger>(),
      ));
  gh.factory<OnboardBloc>(() => OnboardBloc(g<IAuthFacade>()));
  gh.factory<SplashBloc>(() => SplashBloc(
        g<IAuthFacade>(),
        g<IRepository>(),
        g<ITopicRepository>(),
        g<FirebaseDynamicLinks>(),
      ));
  gh.factory<AuthBloc>(() => AuthBloc(g<IAuthFacade>()));

  // Eager singletons must be registered in the right order
  gh.singleton<ILogger>(Logger(g<FirebaseAnalytics>()));
}

class _$RegisterModule extends RegisterModule {}
