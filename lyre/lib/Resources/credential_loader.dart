import '../Database/database.dart';

writeCredentials(String usern, String creds) async {
  final db = await DBProvider.db.database;

  String lowercase = usern.toLowerCase();

  print("WTYFSAFASDF: $usern,$creds");
  var res = await db.rawInsert(
      "INSERT Into User (username,credentials) "
      " VALUES(?, ?)",[
        lowercase,
        creds,
      ]);
  return res;
}
updateCredentials(String user, String creds) async {
  final db = await DBProvider.db.database;

  var userLow = user.toLowerCase();
  var res = await db.update("User", toJson(userLow, creds),
  where: "username = ?", whereArgs: [userLow]);
  return res;
}
Map<String, dynamic> toJson(String username, String credentials) => {
  "username" : username,
  "credentials" : credentials
};
Future<String> readCredentials(String username) async {
  final db = await DBProvider.db.database;

  var res = await db.query("User", where: "username = ?", whereArgs: [username.toLowerCase()]);
  print(res.length.toString() + "EHEHEHEH");
  return res.isNotEmpty ? res.first["credentials"] : null;
}
Future<List<String>> readUsernames() async {
  final db = await DBProvider.db.database;

  var res = await db.query("User");
  List<String> list = new List();
  res.forEach((f)=>{
    list.add(f["username"])
  });
  return list;
}