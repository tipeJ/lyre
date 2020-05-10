import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' show Client;
import 'globals.dart';

class gfycatProvider {
  static final gfycatProvider _instance = new gfycatProvider._internal();
  gfycatProvider._internal();

  factory gfycatProvider(){
    return _instance;
  }

  Client client = Client();

  Future<String> getGfyWebmUrl(String gfyid) async {
    Map<String, String> headers = new Map<String, String>();

    headers["client_id"] = GFYCAT_CLIENT_ID;
    headers["client_secret"] = GFYCAT_CLIENT_SECRET;

    var response = await client.get("${GFYCAT_GET_URL}${gfyid}", headers: headers);
    if(response.statusCode == 200){
      return json.decode(response.body)["gfyItem"]["webmUrl"];
    } else {
      throw Exception('Failed to get gfycat info: ${gfyid}');
    }
  }
}