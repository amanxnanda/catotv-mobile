import 'package:cato_feed/domain/auth/i_user_repository.dart';
import 'package:cato_feed/domain/core/errors.dart';
import 'package:cato_feed/domain/core/i_logger.dart';
import 'package:cato_feed/domain/topic/topic.dart';
import 'package:cato_feed/infrastructure/core/db/moor/moor_database.dart';
import 'package:cato_feed/infrastructure/core/db/moor/extensions.dart';
import 'package:cato_feed/infrastructure/core/remote/network.dart';
import 'package:cato_feed/domain/core/result.dart';
import 'package:cato_feed/domain/core/failure.dart';
import 'package:cato_feed/domain/auth/user.dart';
import 'package:injectable/injectable.dart';
import 'package:kt_dart/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton(as: IUserRepository)
class UserRepository implements IUserRepository {
  final MyDatabase db;
  final Network network;
  final ILogger logger;
  final SharedPreferences pref;

  static const String _USER_SELECTED_TOPIC_IDS = "user_topic_ids";

  UserRepository(this.db, this.network, this.logger, this.pref);

  void _initializeClientsOnUserData(User user) {
    // Update the network client with the auth token
    network.updateJwt(user.jwtToken);
    logger.setUserIdentifier(name: user.name, email: user.email, identifier: user.id);
  }

  @override
  Future<Result<Failure, User>> getUser(KtMap<String, dynamic> details) async {
    var googleId = details.getOrElse(IUserRepository.KEY_GOOGLE_ID, () => null);

    if (googleId == null) {
      return Result.fail(Failure.error(NotAuthenticatedError()));
    }

    var user = (await db.usersDao.getUserByGoogleId(googleId)).toUser();

    if (user == null || user.isJWTExpired()) {
      return await _fetchAndCacheUser(details, user?.interestSelected ?? false);
    }

    _initializeClientsOnUserData(user);

    return Result.data(user);
  }

  Future<Result<Failure, User>> _fetchAndCacheUser(
      KtMap<String, dynamic> details, bool doesProfileExists) async {
    var result = await network.authenticate(
        name: details.get(IUserRepository.KEY_NAME),
        email: details.get(IUserRepository.KEY_EMAIL),
        googleId: details.get(IUserRepository.KEY_GOOGLE_ID),
        accessToken: details.get(IUserRepository.KEY_ACCESS_TOKEN),
        avatar: details.get(IUserRepository.KEY_PHOTO_URL));

    if (result.hasFailed()) return result;

    var user = result.data;
    _initializeClientsOnUserData(user);

    var profileResult = await network.getUserProfile();
    var isUserProfileCreated = _isProfileCreated(profileResult);

    user = user.copyWith(interestSelected: isUserProfileCreated);

    if(profileResult.isSuccess()) {
      // Save topics
      _saveUserTopics(user, profileResult.data.map((e) => e.id).asList());
    }

    await db.usersDao.insertOrUpdate(user.toMUser());

    return result;
  }

  // Helper function to check if user's profile is created
  // or not based on result failure status.
  bool _isProfileCreated(Result<Failure, dynamic> result) {
    if(result.hasFailed()) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Future<Result<Failure, bool>> signOut(String googleId) async {
    // Remove local user from the database
    await db.usersDao.removeByGoogleId(googleId);
    // Remove JWT
    network.updateJwt(null);
    logger.resetUserIdentifier();
    // Clear entire user preferences
    await pref.clear();

    return Result.data(true);
  }

  @override
  Future<Result<Failure, User>> updateTopics(User user, KtList<String> topicIds) async {

    // First try to update the user profile
    Result<Failure, KtList<Topic>> result = await network.updateUserProfile(topicIds.asList());

    // If error, try to create user profile
    if(result.hasFailed()) {
      result = await network.createUserProfile(topicIds.asList());
    }

    // If Still error return failure
    if (result.hasFailed()) return Result.fail(result.failure);

    var updatedUser = user.copyWith.call(interestSelected: true, updatedAt: DateTime.now());

    await db.usersDao.insertOrUpdate(updatedUser.toMUser());

    // Save user topics
    _saveUserTopics(user, topicIds.asList());

    return Result.data(updatedUser);
  }

  void _saveUserTopics(User user, List<String> selectedTopicIds) {
    // TODO: Later might need to save on the database
    pref.setStringList(_USER_SELECTED_TOPIC_IDS, selectedTopicIds);
  }

  /// Returns Selected Topic Ids Can be null
  Future<List<String>> getSelectedTopics(User user) async {
    return pref.getStringList(_USER_SELECTED_TOPIC_IDS);
  }
}
