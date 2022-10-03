class Server {
  final String name, abbreviation, type, config, ip;
  final num load;
  final bool premium;
  final int id;

  Server({
    required this.id,
    required this.name,
    required this.load,
    required this.abbreviation,
    required this.premium,
    required this.type,
    required this.config,
    required this.ip,
  });

  Server copyWith({
    int? id,
    String? name,
    String? abbreviation,
    num? load,
    bool? premium,
    String? type,
    String? config,
    String? ip,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      load: load ?? this.load,
      premium: premium ?? this.premium,
      type: type ?? this.type,
      config: config ?? this.config,
      ip: ip ?? this.ip,
    );
  }

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'],
      abbreviation: json['abbreviation'],
      name: json['name'],
      load: json['load'],
      premium: json['premium'],
      type: json['type'],
      config: json['config'],
      ip: json['ip'],
    );
  }
}
