enum NatType { masquerade, source, destination }

class MasqueradeModel {
  final String sourceIp;
  final String interface;

  const MasqueradeModel({
    required this.sourceIp,
    required this.interface,
  });

  Map<String, dynamic> toJson() => {
        'nat_type': 'masquerade',
        'source_ip': sourceIp,
        'output_interface': interface,
        'comment': '',
      };

  String toCommand() =>
      'nft add rule ip nat postrouting ip saddr $sourceIp oif $interface masquerade';
}

class SourceNatModel {
  final String sourceIp;
  final String interface;
  final String newSourceIp;

  const SourceNatModel({
    required this.sourceIp,
    required this.interface,
    required this.newSourceIp,
  });

  Map<String, dynamic> toJson() => {
        'nat_type': 'snat',
        'source_ip': sourceIp,
        'new_source_ip': newSourceIp,
        'output_interface': interface,
        'comment': '',
      };

  String toCommand() =>
      'nft add rule ip nat postrouting ip saddr $sourceIp oif $interface snat to $newSourceIp';
}

class DestinationNatModel {
  final String protocol;
  final String interface;
  final String destIp;
  final String externalPort;
  final String internalPort;

  const DestinationNatModel({
    required this.protocol,
    required this.interface,
    required this.destIp,
    required this.externalPort,
    required this.internalPort,
  });

  Map<String, dynamic> toJson() => {
        'nat_type': 'dnat',
        'protocol': protocol,
        'input_interface': interface,
        'dest_ip': destIp,
        'ext_port': externalPort,
        'int_port': internalPort,
        'comment': '',
      };

  String toCommand() =>
      'nft add rule ip nat prerouting $protocol dport $externalPort dnat to $destIp:$internalPort';
}
