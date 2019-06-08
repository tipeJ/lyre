import '../Database/database.dart';

writeCredentials(String credentials, String username) async {
    final db = await DBProvider.db.database;

    var res = await db.insert("User", {
      "username" : username,
      "credentials": credentials
    });
    return res;
}
Future<String> readCredentials(String username) async {
    final db = await DBProvider.db.database;

    var res = await db.query("User", where: "username = ?", whereArgs: [username]);
    var x = res.first["credentials"];
    return res.isNotEmpty ? x : null;
}