import 'package:feed/app/app.locator.dart';
import 'package:feed/core/mixins/auth.dart';
import 'package:feed/core/services/share_service.dart';
import 'package:feed/core/services/url_service.dart';
import 'package:stacked/stacked.dart';

class DrawerViewModel extends BaseViewModel with AuthMixin {
  final _launcher = locator<OpenLinkService>();
  final _shareService = locator<ShareService>();

  launchUrl(String url) async => _launcher.openLink(url);

  inviteFriends() async {
    await _shareService.share(
        "Learn what matters. From the best. For Free\nCheck out cato - https://play.google.com/store/apps/details?id=cato.tv.app");
  }
}
