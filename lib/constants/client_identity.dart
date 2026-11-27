import 'dart:io';

/// The name this app announces to a TV when it connects.
///
/// Samsung prints it verbatim in the set's "allow this device?" prompt and in
/// its device list, so it has to be something a person recognises on the TV
/// screen. The previous value, `DartSamsungSmartTVDriver`, came from the
/// driver this client was modelled on and reads like a debug build there.
const String kClientAppName = 'Smart TV Remote';

/// The phone's address on the local network.
///
/// Some sets list a connecting device by address rather than by name, and the
/// address is the one thing that tells two phones with the same app name
/// apart. Returns null when there is no usable address — no LAN, Wi-Fi off, or
/// mobile data only — in which case the caller shows the name alone.
Future<String?> localIPv4() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    final addresses = <String>[
      for (final interface in interfaces)
        for (final address in interface.addresses) address.address,
    ];
    if (addresses.isEmpty) return null;
    // A phone with a VPN up also has a tunnel address; the TV is reachable
    // only over a private one, so those come first.
    return addresses.firstWhere(_isPrivate, orElse: () => addresses.first);
  } on SocketException {
    // No interfaces at all is a normal state, not an error worth throwing.
    return null;
  }
}

bool _isPrivate(String address) {
  if (address.startsWith('192.168.') || address.startsWith('10.')) return true;
  final parts = address.split('.');
  if (parts.length != 4) return false;
  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  if (first == null || second == null) return false;
  return first == 172 && second >= 16 && second <= 31;
}
