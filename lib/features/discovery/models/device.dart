class Device {
  final String id;
  final String name;
  final String os;
  final String ip;
  final int port;
  final bool isMe;

  Device({
    required this.id,
    required this.name,
    required this.os,
    required this.ip,
    required this.port,
    this.isMe = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'os': os,
    'ip': ip,
    'port': port,
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'],
    name: json['name'],
    os: json['os'],
    ip: json['ip'],
    port: json['port'],
  );

  @override
  String toString() => 'Device(name: $name, ip: $ip, os: $os)';
}
