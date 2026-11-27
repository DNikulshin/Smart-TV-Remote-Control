import 'package:remote/core/models/tv_app.dart';

/// Roku channel ids for `POST /launch/<id>`.
///
/// These are assigned by Roku once per channel and are the same on every
/// device, unlike the Tizen ones.
String? rokuAppIdFor(TvApp app) => switch (app) {
  TvApp.netflix => '12',
  TvApp.youtube => '837',
  TvApp.disneyPlus => '291097',
  TvApp.primeVideo => '13',
};
