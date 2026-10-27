/// AdMob ad unit ids. Dev builds always use Google's test units, so a
/// developer can never tap or load a real ad. Prod units are filled in once
/// they exist in AdMob; until then prod shows no ads at all.
abstract final class AdUnits {
  static const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  // Real units, from the AdMob console. Empty = not created yet.
  static const _prodNativeAndroid = 'ca-app-pub-2470974563764561/1995021133';
  static const _prodNativeIos = 'ca-app-pub-2470974563764561/6672632749';
  static const _prodBannerAndroid = 'ca-app-pub-2470974563764561/3001688886';
  static const _prodBannerIos = 'ca-app-pub-2470974563764561/1611877750';

  /// The native (in-feed) unit for this build, or null when there is none.
  static String? native({required bool isIos, required bool prod}) {
    final id = prod
        ? (isIos ? _prodNativeIos : _prodNativeAndroid)
        : (isIos ? _testNativeIos : _testNativeAndroid);
    return id.isEmpty ? null : id;
  }

  /// The banner unit for this build (used in lists), or null when there is
  /// none.
  static String? banner({required bool isIos, required bool prod}) {
    final id = prod
        ? (isIos ? _prodBannerIos : _prodBannerAndroid)
        : (isIos ? _testBannerIos : _testBannerAndroid);
    return id.isEmpty ? null : id;
  }
}
