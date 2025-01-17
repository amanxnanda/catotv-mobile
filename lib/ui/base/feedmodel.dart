import 'package:feed/app/app.locator.dart';
import 'package:feed/core/constants/events.dart';
import 'package:feed/core/enums/user_events.dart';
import 'package:feed/core/models/app_models.dart';
import 'package:feed/core/services/message_queue_service.dart';
import 'package:feed/core/services/share_service.dart';
import 'package:feed/core/services/video_service.dart';
import 'package:feed/firebase/analytics.dart';
import 'package:feed/firebase/dynamic_links.dart';
import 'package:feed/core/mixins/snackbar_helper.dart';
import 'package:feed/core/mixins/auth.dart';
import 'package:stacked/stacked.dart';

abstract class BaseFeedModel extends BaseViewModel
    with AuthMixin, SnackbarHelper {
  final _videoService = locator<VideoService>();
  final _analytics = locator<AnalyticsService>();
  final _messageQueue = locator<MessageQueueService>();
  final _shareService = locator<ShareService>();
  final _dynamicLinksService = locator<DynamicLinksService>();

  List<Video> get videos;

  Future<String> getStreamUrl(String videoUrl) async {
    var beforeLoading = DateTime.now();

    String streamUrl = await _videoService.getStream(videoUrl);

    await _analytics.logEvent(VideoLoadingTime, params: {
      "duration": DateTime.now().difference(beforeLoading).inMilliseconds
    });

    return streamUrl;
  }

  Future shareVideo(int index) async {
    var video = videos[index];
    String url = await _dynamicLinksService.shareVideo(video);
    await _shareService.share("Checkout ${video.title} at $url");
    await _messageQueue.logUserEvent(UserEvent.share,
        videoId: videos[index].id);
  }

  Future getVideos();

  Future<void> refresh();

  String getThumbnail(String url) => VideoService.getThumbnail(url);

  logUserEvent(
    UserEvent event, {
    String videoId = "",
    String timestamp = '',
    String description = '',
    int videoDuration = 0,
    int sessionDuration = 0,
    int durationWatched = 0,
  }) =>
      _messageQueue.logUserEvent(
        event,
        videoId: videoId,
        description: description,
        videoDuration: videoDuration,
        sessionDuration: sessionDuration,
        durationWatched: durationWatched,
      );

  logPlayVideo(int index) {
    logUserEvent(UserEvent.play, videoId: videos[index].id);
  }

  logPauseVideo(int index) {
    logUserEvent(UserEvent.pause, videoId: videos[index].id);
  }

  getVideo(String videoId);
}
