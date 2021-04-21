import 'dart:io';

import 'package:cato_feed/application/auth/auth.dart';
import 'package:cato_feed/application/init/init.dart';
import 'package:cato_feed/application/init/init_bloc.dart';
import 'package:cato_feed/application/post/post.dart';
import 'package:cato_feed/application/topic/topic.dart';
import 'package:cato_feed/application/user_profile/user_profile.dart';
import 'package:cato_feed/domain/core/i_logger.dart';
import 'package:cato_feed/infrastructure/core/logger/log_events.dart';
import 'package:cato_feed/main.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:cato_feed/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cato_feed/application/splash/splash_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cato_feed/domain/core/failure.dart';
import 'package:cato_feed/presentation/routes/Router.gr.dart';
import 'package:cato_feed/presentation/utils/assets/color_assets.dart';
import 'package:cato_feed/presentation/utils/assets/image_assets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: Colors.white,
      body: BlocProvider(
        create: (_) => getIt<SplashBloc>(),
        child: SplashPage(),
      ),
    );
  }
}

class SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<InitBloc, InitState>(
          listener: (_, state) {
            state.when(
              initial: () {},
              updateRequired: () {
                context.read<SplashBloc>().add(SplashEvent.updateRequired());
              },
              failure: (failure) {
                context.read<SplashBloc>().add(SplashEvent.failure(failure));
              },
              success: () {
                context.read<AuthBloc>().add(AuthEvent.authCheckRequested());
              },
            );
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (_, state) {
            state.when(
              initial: () {},
              unauthenticated: () async {
                // Extract the invitation code
                var inviteCode = await getInviteCodeFromDynamicLink();
                if (inviteCode == null || inviteCode.isEmpty) {
                  // context.navigator.replace(CatoRoutes.onboardInviteScreen);
                  context.navigator.replace(CatoRoutes.onboardLoginScreen);
                } else {
                  context.read<AuthBloc>().add(
                      AuthEvent.sessionLogin(name: '', inviteCode: inviteCode));
                }
              },
              authenticated: (user) {
                context.read<TopicBloc>().add(TopicEvent.get());
              },
              sessionLoggedIn: (user) {
                context.read<TopicBloc>().add(TopicEvent.get());
              },
              failure: (message) {
                context
                    .read<SplashBloc>()
                    .add(SplashEvent.failure(Failure.message(message)));
              },
            );
          },
        ),
        BlocListener<TopicBloc, TopicState>(
          listener: (_, state) async {
            // ignore: close_sinks
            var bloc = context.read<SplashBloc>();

            if (state.failure != null) {
              bloc.add(SplashEvent.failure(state.failure));
            } else if (state.allTopics != null) {
              context.read<AuthBloc>().state.maybeMap(
                  authenticated: (e) {
                    // Get the user profile
                    context.read<UserProfileBloc>().add(UserProfileEvent.get(e.user.id));
                  },
                  sessionLoggedIn: (e) {
                    // Jump to onboard login
                    context.navigator.replace(CatoRoutes.onboardLoginScreen);
                  },
                  orElse: () {});
            }
          },
        ),
        BlocListener<UserProfileBloc, UserProfileState>(listener: (context, state) async {
          if (state.profile == null ||
              state.profile.selectedTopics == null ||
              state.profile.selectedTopics.isEmpty) {
            // Navigate to the onboard selection
            context.navigator.replace(CatoRoutes.onboardScreen);
          } else {
            context.read<UserProfileBloc>().add(UserProfileEvent.refresh());
            // Request for posts
            context.read<PostBloc>().add(PostEvent.loadRecommendedVideos(context.read<AuthBloc>().state.getUserId() ?? ''));
            // Navigate to home screen
            await openDynamicLinkOr(context,
                otherScreen: CatoRoutes.homeScreen);
          }
        })
      ],
      child: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              child: Image.asset(ImageAssets.Release.cato_logo),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: BlocBuilder<SplashBloc, SplashState>(
                builder: (_, state) {
                  return state.maybeWhen(
                    forceUpdateRequired: () => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'You need to update the app to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: ColorAssets.black21, fontSize: 16),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        RaisedButton(
                          color: ColorAssets.teal,
                          child: Text(
                            (Platform.isAndroid)
                                ? 'Open PlayStore'
                                : 'Open AppStore',
                            style: TextStyle(fontSize: 15),
                          ),
                          textColor: Colors.white,
                          onPressed: () async {
                            getIt<ILogger>()
                                .logEvent(LogEvents.EVENT_UPDATE_APP_CLICKED);
                            var url = (Platform.isAndroid)
                                ? getIt.get(instanceName: 'PlayStoreUrl') as String
                                : getIt.get(instanceName: 'AppStoreUrl') as String;
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          },
                        ),
                      ],
                    ),
                    failure: (failure) {
                      var message = failure.toString();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: ColorAssets.black21, fontSize: 16),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          RaisedButton(
                            color: ColorAssets.teal,
                            child: Text(
                              'Retry',
                              style: TextStyle(fontSize: 15),
                            ),
                            textColor: Colors.white,
                            onPressed: () async {
                              getIt<ILogger>().logEvent(
                                  LogEvents.EVENT_SPLASH_ERROR_RETRY_CLICK);
                              context
                                  .read<InitBloc>()
                                  .add(InitEvent.requestAppVersionCheck());
                              context
                                  .read<SplashBloc>()
                                  .add(SplashEvent.loading());
                            },
                          ),
                        ],
                      );
                    },
                    orElse: () => CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
