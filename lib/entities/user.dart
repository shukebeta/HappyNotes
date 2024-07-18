class User {
  String username;
  String email;
  String gravatar;
  int createdAt;

  User({
    required this.username,
    required this.email,
    required this.gravatar,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      email: json['email'],
      gravatar: json['gravatar'],
      createdAt: json['createAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.username;
    data['email'] = this.email;
    data['gravatar'] = this.gravatar;
    data['createAt'] = this.createdAt;
    return data;
  }
}
