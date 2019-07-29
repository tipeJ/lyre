import 'dart:convert';

import 'package:retrofit/dio.dart';
import 'package:retrofit/http.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;

class ImgurAPI {
  static final ImgurAPI _instance = new ImgurAPI._internal();
  ImgurAPI._internal();

  factory ImgurAPI(){
    return _instance;
  }
  String client_id = "5d4483785a696ca";
  String client_secret = "e2f8b7c938d7659dbde3623b22d59f2cbe98d767";

  String imageUploadUrl = "https://api.imgur.com/3/upload";
  /*
  void postImage(
    @Header("Authorization") String auth,
            @Query("title") String title,
            @Query("description") String description,
            @Query("album") String albumId,
            @Query("account_url") String username,
            @Body File file,
            Callback<ImageResponse> cb
  );
  */
  Future<void> uploadImage(File imageFile, String title) async {
    final response = await http.post(
      imageUploadUrl,
      headers: {
        "Authorization": 'Client-ID {{${client_id}}}'
      },
      body: {
        'image': imageFile != null ? base64Encode(imageFile.readAsBytesSync()) : '',
        'name' : title,
      }
    );
    final responseJson = json.decode(response.body);

    print("IMAGE_TEST_RESPONSE: " + responseJson.toString());
  }
  
}