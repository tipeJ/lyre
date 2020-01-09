import '../Database/database.dart';
import '../Models/User.dart';
import 'dart:core';

const USER_TABLE = "User";

Future<int> writeCredentials(String usern, String creds) async {
  final db = await DBProvider.db.database;

  String lowercase = usern.toLowerCase();

  final res = await db.rawInsert(
      "INSERT Into User (username,credentials,date) "
      " VALUES(?, ?, ?)",[
        lowercase,
        creds,
        DateTime.now().millisecondsSinceEpoch
      ]);
  return res;
}
Future<bool> deleteCredentials(String usern) async {
  final db = await DBProvider.db.database;

  String lowercase = usern.toLowerCase();

  var res = await db.delete(USER_TABLE, where: "username = ?", whereArgs: [lowercase]);
  return res == 1;
}
updateCredentials(String user, String creds) async {
  final db = await DBProvider.db.database;

  var userLow = user.toLowerCase();
  var res = await db.update(USER_TABLE, toJson(userLow, creds),
  where: "username = ?", whereArgs: [userLow]);
  return res;
}
updateLogInDate(String user) async {
  final db = await DBProvider.db.database;

  String creds = await readCredentials(user);

  var res = await db.update(USER_TABLE, toJson2(user, creds), where: "username = ?", whereArgs: [user.toLowerCase()]);
  return res;
}
Map<String, dynamic> toJson2(String username, String creds) => {
  "username" : username,
  "credentials" : creds,
  "date" : DateTime.now().millisecondsSinceEpoch
};
Map<String, dynamic> toJson(String username, String credentials) => {
  "username" : username,
  "credentials" : credentials
};
Future<DateTime> readLatestLogInDate(String username) async {
  final db = await DBProvider.db.database;

  var res = await db.query(USER_TABLE, where: "username = ?", whereArgs: [username.toLowerCase()]);
  var x = res.isNotEmpty ? res.first["date"] : null;
  return DateTime.fromMillisecondsSinceEpoch(x);
}
Future<String> readCredentials(String username) async {
  final db = await DBProvider.db.database;

  var res = await db.query(USER_TABLE, where: "username = ?", whereArgs: [username.toLowerCase()]);
  return res.isNotEmpty ? res.first["credentials"] : null;
}
Future<List<String>> readUsernames() async {
  final db = await DBProvider.db.database;

  var res = await db.query(USER_TABLE);
  List<String> list = [];
  res.forEach((f)=>{
    list.add(f["username"])
  });
  return list;
}
Future<List<RedditUser>> getAllUsers() async {
  final db = await DBProvider.db.database;

  final res = await db.query(USER_TABLE);
  List<RedditUser> list = res.isNotEmpty ? res.map((u) => RedditUser.fromJson(u)).toList() : const [];
  return list;
}