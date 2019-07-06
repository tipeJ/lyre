import 'package:retrofit/dio.dart';
import 'package:retrofit/http.dart';
import 'dart:io';

abstract class ImgurAPI {
  String server = "https://api.imgur.com";
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
}