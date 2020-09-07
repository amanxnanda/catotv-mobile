import 'package:auto_route/auto_route.dart';
import 'package:cato_feed/application/auth/auth.dart';
import 'package:cato_feed/application/onboard/onboard_bloc.dart';
import 'package:cato_feed/application/topic/topic.dart';
import 'package:cato_feed/domain/core/failure.dart';
import 'package:cato_feed/injection.dart';
import 'package:cato_feed/presentation/routes/Router.gr.dart';
import 'package:cato_feed/presentation/utils/assets/color_assets.dart';
import 'package:cato_feed/presentation/utils/assets/font_assets.dart';
import 'package:cato_feed/presentation/utils/assets/string_assets.dart';
import 'package:cato_feed/presentation/utils/wave_path_clipper.dart';
import 'package:cato_feed/presentation/widgets/signinbutton/google_signin_button.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../utils/assets/image_assets.dart';
import 'package:flutter_tindercard/flutter_tindercard.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:cato_feed/application/post/post.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: BlocProvider(
        create: (context) => getIt<OnboardBloc>(),
        child: OnboardingPage(),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {

  final List _onboardingCards = [
    OnboardingCardOption(
        backgroundColor: ColorAssets.onboardPink,
        imageAssetPath: ImageAssets.Release.yoga_female,
        title: StringAssets.onboardTitle1,
        body: StringAssets.onboardBody1),
    OnboardingCardOption(
        backgroundColor: ColorAssets.onboardYellow,
        imageAssetPath: ImageAssets.Release.boy_block_game,
        title: StringAssets.onboardTitle2,
        body: StringAssets.onboardBody2),
    OnboardingCardOption(
        backgroundColor: ColorAssets.onboardOrange,
        imageAssetPath: ImageAssets.Release.girl_read,
        title: StringAssets.onboardTitle2,
        body: StringAssets.onboardBody3),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (_, state) {
            state.maybeWhen(
              authenticated: (user) =>
                  context.bloc<TopicBloc>().add(TopicEvent.get(user)),
              failure: (message) => context
                  .bloc<OnboardBloc>()
                  .add(OnboardEvent.failure(Failure.message(message))),
              orElse: () {},
            );
          },
        ),
        BlocListener<TopicBloc, TopicState>(
          listener: (_, state) {
            // ignore: close_sinks
            var bloc = context.bloc<OnboardBloc>();

            if (state.failure != null) {
              bloc.add(OnboardEvent.failure(state.failure));
            } else {
              if (state.allTopics != null) {
                context.bloc<PostBloc>().add(PostEvent.loadFeed(0, 10));
              }

              if (state.selectedTopicIds == null ||
                  state.selectedTopicIds.isEmpty) {
                // Send to topic Selected
                context.navigator.replace(CatoRoutes.topicSelectionScreen);
              } else {
                context.navigator.replace(CatoRoutes.homeScreen);
              }
            }
          },
        ),
        BlocListener<OnboardBloc, OnboardState>(
          listener: (_, state) {
            if (state.failure != null) {
              var message = state.failure.map(
                  error: (err) => err.toString(),
                  exception: (err) => err.toString(),
                  message: (msg) => msg
              );
              Flushbar(
                message: message,
                duration: Duration(seconds: 3),
              )..show(context);
            }
          },
        ),
      ],
      child: BlocBuilder<OnboardBloc, OnboardState>(
        cubit: context.bloc<OnboardBloc>(),
        builder: (_, state) {
          return Column(children: [
            SizedBox(
              height: 60,
            ),
            Container(
              height: 450,
              child: TinderSwapCard(
                allowVerticalMovement: false,
                orientation: AmassOrientation.TOP,
                totalNum: 1000,
                stackNum: _onboardingCards.length,
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: 400,
                minWidth: MediaQuery.of(context).size.width * 0.7,
                minHeight: 375,
                cardBuilder: (_, index) {
                  return OnboardingCardWidget(
                    cardOption:
                        _onboardingCards[index % _onboardingCards.length],
                  );
                },
                swipeCompleteCallback: (_, index) {
                  context
                      .bloc<OnboardBloc>()
                      .add(OnboardEvent.cardSwiped(_onboardingCards.length));
                },
              ),
            ),
            SizedBox(
              height: 4,
            ),
            DotsIndicator(
              dotsCount: _onboardingCards.length,
              position: state.currentCardIndex.toDouble(),
              decorator: DotsDecorator(
                  color: Color(0xFF323232), activeColor: Color(0xFF2CB9B0)),
            ),
            // PageIndicator
            SizedBox(
              height: 15,
            ),
            Expanded(
              flex: 1,
              child: ClipPath(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: ColorAssets.black21,
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    margin: EdgeInsets.only(bottom: 20),
                    child: GoogleSignInButton(
                      onPressed: () {
                        context.bloc<AuthBloc>().add(AuthEvent.login());
                      },
                      darkMode: true,
                    ),
                  ),
                ),
                clipper: WavePathClipper(clipFromTop: true),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class OnboardingCardWidget extends StatelessWidget {
  final OnboardingCardOption cardOption;

  OnboardingCardWidget({@required this.cardOption});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      height: 375,
      decoration: BoxDecoration(
        color: cardOption.backgroundColor,
        borderRadius: BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Container(
            child: Image.asset(cardOption.imageAssetPath),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            cardOption.title,
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontFamily: FontAssets.Roboto,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            child: Text(
              cardOption.body,
              maxLines: 2,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: FontAssets.Roboto,
              ),
              softWrap: true,
              textAlign: TextAlign.center,
            ),
            padding: EdgeInsets.symmetric(horizontal: 24),
          ),
        ],
      ),
    );
  }
}

class OnboardingCardOption {
  final Color backgroundColor;
  final String imageAssetPath;
  final String title;
  final String body;

  OnboardingCardOption({
    @required this.backgroundColor,
    @required this.imageAssetPath,
    @required this.title,
    @required this.body,
  });
}