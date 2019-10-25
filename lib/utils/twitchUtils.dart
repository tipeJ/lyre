import 'dart:convert';

import 'package:http/http.dart';

Future<String> getTwitchClipVideoLink(String url) async {
  final id = url.split('/').last;
  final client = Client();
  final response = await client.get("https://clips.twitch.tv/api/v2/clips/" + id + "/status");
  return json.decode(response.body)['quality_options'][0]['source'];
}