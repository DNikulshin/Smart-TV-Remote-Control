import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote/constants/client_identity.dart';
import 'package:remote/l10n/app_localizations.dart';

/// Tells the user what the TV will show when this app connects.
///
/// A Samsung set asks "allow this device?" and lists the answer in its device
/// list under the name the client announces; a set that has already blocked it
/// keeps it there. Neither the name nor the address is visible anywhere else in
/// the app, so a tester had no way to match the entry on the TV to the phone in
/// their hand.
class ClientIdentityCard extends StatefulWidget {
  const ClientIdentityCard({
    this.name = kClientAppName,
    this.address,
    super.key,
  });

  /// The name announced during the handshake.
  final String name;

  /// Overrides the detected address; tests use it instead of depending on the
  /// interfaces of the machine running them.
  final Future<String?>? address;

  @override
  State<ClientIdentityCard> createState() => _ClientIdentityCardState();
}

class _ClientIdentityCardState extends State<ClientIdentityCard> {
  late final Future<String?> _address = widget.address ?? localIPv4();

  Future<void> _copy(String? ip) async {
    final l = AppLocalizations.of(context);
    final text = ip == null ? widget.name : '${widget.name} $ip';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.copied), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<String?>(
      future: _address,
      builder: (context, snapshot) {
        final ip = snapshot.data;
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            children: [
              Icon(Icons.settings_remote, color: Colors.grey[500], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ip == null
                      ? l.clientIdentityNoIp(widget.name)
                      : l.clientIdentity(widget.name, ip),
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: l.copyIdentity,
                onPressed: () => _copy(ip),
                icon: Icon(Icons.copy, color: Colors.grey[500], size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
}
