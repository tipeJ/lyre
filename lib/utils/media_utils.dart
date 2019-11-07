import 'dart:convert';

import 'package:http/http.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:lyre/Resources/gfycat_provider.dart';

Future<String> getTwitchClipVideoLink(String url) async {
  final id = url.split('/').last;
  final client = Client();
  final response = await client.get("https://clips.twitch.tv/api/v2/clips/" + id + "/status");
  return json.decode(response.body)['quality_options'][0]['source'];
}

Future<String> getGfyVideoUrl(String url) {
  final id = getGfyid(url);
  return gfycatProvider().getGfyWebmUrl(id);
}