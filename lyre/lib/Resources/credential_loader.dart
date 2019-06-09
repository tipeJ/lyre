import '../Database/database.dart';

Future<void> writeCredentials(String credentials, String username) async {
  final db = await DBProvider.db.database;

  print("WTYFSAFASDF: $username,$credentials");
  var res = await db.rawInsert(
      "INSERT Into Client (username,credentials)"
      " VALUES ($username,$credentials)");
  return res;
}
Future<String> readCredentials(String username) async {
  final db = await DBProvider.db.database;

  var res = await db.query("User", where: "username = ?", whereArgs: [username]);
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