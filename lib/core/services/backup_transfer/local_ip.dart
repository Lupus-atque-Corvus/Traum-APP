import 'dart:io';

/// Every plausible LAN IPv4 address of this device, one per network
/// interface (excluding loopback). Deliberately lists all of them rather
/// than guessing "the" address — desktops commonly have extra virtual/VPN
/// adapters alongside the real WiFi/Ethernet one, and picking wrong would
/// silently produce an unreachable QR code.
Future<List<String>> listLocalIPv4Addresses() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
    includeLinkLocal: false,
  );
  final addresses = <String>[];
  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (!addresses.contains(addr.address)) {
        addresses.add(addr.address);
      }
    }
  }
  return addresses;
}
