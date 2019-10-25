import 'dart:convert';

import 'package:lyre/Models/image.dart';
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
  final String client_id = "5d4483785a696ca";
  final String client_secret = "e2f8b7c938d7659dbde3623b22d59f2cbe98d767";

  final String imageUploadUrl = "https://api.imgur.com/3/upload";
  final String albumGetUrl = "https://api.imgur.com/3/album/";
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
  Future<String> uploadImage(File imageFile, String title) async {
    final response = await http.post(
      imageUploadUrl,
      headers: {
        "Authorization": 'Client-ID ${client_id}'
      },
      body: {
        'image': imageFile != null ? base64Encode(imageFile.readAsBytesSync()) : '',
        'name' : title,
      }
    );
    final responseJson = json.decode(response.body);
    return responseJson['data']['link'];
  }
  Future<List<LyreImage>> getAlbumPictures(String url) async {
    final String id = url.split("/").last;
    print('id:' + id);
    final response = await http.get(
      albumGetUrl + id,
      headers: {
        "Authorization": 'Client-ID ${client_id}'
      }
    );
    print('response: ' + response.body);
    final imagesJson = json.decode(response.body)['data']['images'];
    final List<LyreImage> images = [];
    imagesJson.forEach((image){
      final imageUrl = image['link'];
      print('image: ' + imageUrl);
      final thumbNailUrl = "https://i.imgur.com/" + imageUrl.split('/').last + "m." + imageUrl.split(",").last;
      print('thumb: ' + thumbNailUrl);

      images.add(LyreImage(description: image['description'], url: imageUrl, thumbnailUrl: thumbNailUrl));
    });
    return images;
  }
}