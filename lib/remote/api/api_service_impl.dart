import 'dart:io';

import 'package:feed/app/app.locator.dart';
import 'package:feed/app/app.logger.dart';
import 'package:feed/core/models/result/failure.dart';
import 'package:feed/core/models/result/result.dart';
import 'package:feed/core/models/app_models.dart';
import 'package:feed/remote/api/api_service.dart';
import 'package:feed/remote/client.dart';
import 'package:feed/remote/queries.dart';
import 'package:package_info/package_info.dart';

class APIServiceImpl implements APIService {
  final RemoteClient _client = locator<RemoteClient>();
  final PackageInfo _packageInfo = locator<PackageInfo>();
  final _log = getLogger("API Service");

  @override
  Future checkUpdateRequired() async {
    _log.v("Checking If there's update required");

    Result result = Platform.isAndroid
        ? await _client.processQuery(query: GQLQueries.queryAndroidVersionCode)
        : await _client.processQuery(query: GQLQueries.mutationIosVersionCode);

    if (result.isFailed) return result.failure;

    int version = result.success["androidVersionCode"]["data"];

    var currentVersion = _convertVersionCode(_packageInfo.version);

    return version > currentVersion;
  }

  int _convertVersionCode(String version) {
    return int.parse(version.split(".")[0]);
  }

  @override
  Future performLogin({
    required String name,
    required String email,
    required String googleId,
    required String avatar,
    required String accessToken,
  }) async {
    _log.v("Performing Google Login with $name $googleId $avatar $accessToken");

    Result<Failure, dynamic> result = await _client.mutation(
        GQLQueries.mutationGoogleLogin,
        variables: GQLQueries.createMapForGoogleLogin(
            name, email, googleId, avatar, accessToken));

    if (result.isFailed) return result.failure;

    Map<String, dynamic> json = result.success["googleLogin"]["user"];
    json["token"] = result.success["googleLogin"]["token"];

    return User.fromJson(json);
  }

  @override
  Future fetchTopics() async {
    _log.v("Fetching Topics from GraphQL");

    Result result = await _client.processQuery(query: GQLQueries.queryAllTopic);

    if (result.isFailed) return result.failure;

    return result.success["allTopic"];
  }

  @override
  Future requestInvite({required String email}) async {
    _log.v("Adding $email to the waitlist");

    Result<Failure, dynamic> result = await _client.mutation(
        GQLQueries.mutationAddToWaitlist,
        variables: GQLQueries.createMapForRequestInvite(email));

    if (result.isFailed) return result.failure;

    _log.v(result.success);

    return true;
  }

  @override
  Future getProfile({required String userID}) async {
    _log.v("Fetching profile for User(id: $userID)");

    Result<Failure, dynamic> result = await _client.processQuery(
        query: GQLQueries.queryUserProfile,
        variables: GQLQueries.createMapForGetUserProfile(userID));

    if (result.isFailed) return result.failure;

    return result.success['userProfile']['selectedTopics'];
  }

  Future createUserProfile(
      {required String userId,
      required String name,
      required List<String> topicIds}) async {
    Result<Failure, dynamic> result = await _client.mutation(
        GQLQueries.mutationCreateUserProfile,
        variables:
            GQLQueries.createUserProfileVariables(userId, name, topicIds));

    if (result.isFailed) return result.failure;

    _log.v(result.success);

    return true;
  }

  @override
  Future fetchVideos(int skip, int limit, List<String> selectedTopics) async {
    _log.i("Getting videos for topics: $selectedTopics");

    Result<Failure, dynamic> result = await _client.processQuery(
        query: GQLQueries.queryVideosByTopics,
        variables: GQLQueries.createVideosByTopicsVariables(
            skip, limit, selectedTopics));

    if (result.isFailed) return result.failure;

    return result.success["videoByTopics"];
  }
}
