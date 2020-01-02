import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:lyre/Models/image.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:lyre/Resources/PreferenceValues.dart';

const Map<String, String> imgurThumbnailsQuality = {
  "Small Square (90x90)" : "s",
  "Big Square (160x160)" : "b",
  "Small Thumbnail (160x160)" : "t",
  "Medium Thumbnail (320x320)" : "m",
  "Large Thumbnail (640x640)" : "l",
  "Huge Thumbnail (1024x1024)" : "h",
};

///Singleton to be used for retreiving data from Imgur
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

  ///Upload image to imgur. I love the new lineup of Tangerine Dream <3
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

  ///Function for retreiving imgur album pictures, and mapping them to a LyreImage object.
  Future<List<LyreImage>> getAlbumPictures(String url) async {
    final String id = url.split("/").last;
    final response = await http.get(
      albumGetUrl + id,
      headers: {
        "Authorization": 'Client-ID ${client_id}'
      }
    );
    final imagesJson = json.decode(response.body)['data']['images'];
    final List<LyreImage> images = [];
    final String qualityKey = await Hive.box('settings').get(IMGUR_THUMBNAIL_QUALITY, defaultValue: imgurThumbnailsQuality.keys.first); //Default thumbnail quality is the lowest
    final qualityValue = imgurThumbnailsQuality[qualityKey];
    imagesJson.forEach((image){
      final imageUrl = image['link'];
      final thumbNailUrl = "https://i.imgur.com/" + imageUrl.split('/').last.split('.').first + qualityValue + "." + imageUrl.split(".").last;

      images.add(LyreImage(description: image['description'], url: imageUrl, thumbnailUrl: thumbNailUrl));
    });
    return images;
  }
}