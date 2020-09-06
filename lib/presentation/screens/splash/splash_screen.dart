import 'dart:io';

import 'package:cato_feed/application/auth/auth.dart';
import 'package:cato_feed/application/init/init.dart';
import 'package:cato_feed/application/topic/topic.dart';
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
      backgroundColor: ColorAssets.black21,
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
                context.bloc<SplashBloc>().add(SplashEvent.updateRequired());
              },
              failure: (failure) {
                context.bloc<SplashBloc>().add(SplashEvent.failure(failure));
              },
              success: () {
                context.bloc<AuthBloc>().add(AuthEvent.authCheckRequested());
              },
            );
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (_, state) {
            state.when(
              initial: () {},
              unauthenticated: () {
                context.navigator.replace(CatoRoutes.onboardingScreen);
              },
              authenticated: (user) {
                context.bloc<TopicBloc>().add(TopicEvent.get(user));
              },
              failure: (message) {
                context
                    .bloc<SplashBloc>()
                    .add(SplashEvent.failure(Failure.message(message)));
              },
            );
          },
        ),
        BlocListener<TopicBloc, TopicState>(
          listener: (_, state) {
            // ignore: close_sinks
            var bloc = context.bloc<SplashBloc>();

            if (state.failure != null) {
              bloc.add(SplashEvent.failure(state.failure));
            } else if (state.allTopics != null) {
              // TODO: Add event to post bloc to get posts
              bloc.add(SplashEvent.success());
            }
          },
        ),
        BlocListener<SplashBloc, SplashState>(
          listener: (_, state) {
            state.maybeWhen(
              success: () {
                context.navigator.replace(CatoRoutes.homeScreen);
              },
              orElse: () {},
            );
          },
        ),
      ],
      child: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
              child: Image.asset(ImageAssets.Release.boy_block_game),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: BlocBuilder<SplashBloc, SplashState>(
                cubit: context.bloc<SplashBloc>(),
                builder: (_, state) {
                  return state.maybeWhen(
                    forceUpdateRequired: () => Column(
                      children: [
                        Text(
                          'You need to update app to continue.',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
                            var url = (Platform.isAndroid)
                                ? getIt.get(instanceName: 'PlayStoreUrl')
                                : getIt.get(instanceName: 'AppStoreUrl');
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          },
                        ),
                      ],
                    ),
                    failure: (failure) {
                      var message = failure.map(
                        error: (err) => err.error.toString(),
                        exception: (_) => 'Unknown error',
                        message: (e) => e.message,
                      );

                      return Text(
                        message,
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
