class ConnectionProfile {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool isSecure;

  ConnectionProfile({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.isSecure,
  });

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'isSecure': isSecure,
    };
  }

  factory ConnectionProfile.fromJson(Map<String, dynamic> json) {
    return ConnectionProfile(
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      isSecure: json['isSecure'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ConnectionProfile &&
      other.host == host &&
      other.port == port &&
      other.username == username &&
      other.password == password &&
      other.isSecure == isSecure;
  }

  @override
  int get hashCode {
    return host.hashCode ^
      port.hashCode ^
      username.hashCode ^
      password.hashCode ^
      isSecure.hashCode;
  }
}
