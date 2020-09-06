import 'dart:async';
import 'package:graphql/client.dart' show FetchResult, Operation, Link, NextLink;
import 'package:meta/meta.dart';

typedef GetToken = FutureOr<String> Function();

/// CustomAuthLink is similar to library's AuthLink with headerKey fix.
class CustomAuthLink extends Link {
  CustomAuthLink({@required this.getToken, this.headerKey = 'Authorization'})
      : super(
          request: (Operation operation, [NextLink forward]) {
            StreamController<FetchResult> controller;

            Future<void> onListen() async {
              try {
                final String token = await getToken();
                if (token != null) {
                  operation.setContext(<String, Map<String, String>>{
                    'headers': <String, String>{headerKey: token}
                  });
                }
              } catch (error) {
                controller.addError(error);
              }

              await controller.addStream(forward(operation));
              await controller.close();
            }

            controller = StreamController<FetchResult>(onListen: onListen);

            return controller.stream;
          },
        );

  GetToken getToken;
  String headerKey;
}
