class RedditUser{
  String username;
  String credentials;
  int date;

  RedditUser({
        this.username,
        this.credentials,
        this.date
    });

  factory RedditUser.fromJson(Map<String, dynamic> json) => new RedditUser(
    username: json["username"],
    credentials: json["credentials"],
    date: json["date"],
  );
}