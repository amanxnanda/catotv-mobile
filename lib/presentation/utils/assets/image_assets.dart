final _basePath = 'assets/images/';
final _debugPath = _basePath + 'debug/';
final _releasePath = _basePath;

class ImageAssets {
  ImageAssets._();
  static final Debug = _Debug();
  static final Release = _Release();
}

class _Debug {
  final String google_logo = _debugPath + 'google.png';
}

class _Release {
  // Illustrations
  final String yoga_female = _releasePath + 'yoga_female.png';
  final String boy_block_game = _releasePath + 'boy_block_game.png';
  final String girl_read = _releasePath + 'girl_read.png';
  final String permission_lock = _releasePath + 'permission_lock.png';

  final String topicImageHealth = _releasePath + 'topic_health.png';
  final String topicImageIntellectual = _releasePath + 'topic_intellectual.png';
  final String topicImageCareer = _releasePath + 'topic_career.png';
  final String topicImageEmotional = _releasePath + 'topic_emotional.png';
  final String topicImageSocial = _releasePath + 'topic_social.png';
  final String topicImageProductivity = _releasePath + 'topic_productivity.png';


  // Logos
  final String google_logo = _releasePath + 'google-logo.png';
  final String cato_logo = _releasePath + 'cato_logo.png';

  // Backgrounds
  final String abstract_bg = _releasePath + 'abstract_bg.png';

  // Icons
  final String icon_timing = _releasePath + 'icon_timing.png';
  final String icon_select_apps = _releasePath + 'icon_select_apps.png';
  final String icon_logout = _releasePath + 'icon_logout.png';
  final String icon_settings = _releasePath + 'icon_settings.png';
  final String icon_no_distractions = _releasePath + 'icon_no_distractions.png';
  final String icon_deactivate = _releasePath + 'icon_deactivate.png';

}
