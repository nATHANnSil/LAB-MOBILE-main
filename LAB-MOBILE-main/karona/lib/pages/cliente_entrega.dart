import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClienteEntregaPage extends StatefulWidget {
  const ClienteEntregaPage({super.key});

  @override
  State<ClienteEntregaPage> createState() => _ClienteEntregaPageState();
}

class _ClienteEntregaPageState extends State<ClienteEntregaPage> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  List<Delivery> _deliveries = [];

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('deliveries') ?? '[]';
    final List list = jsonDecode(data);
    setState(() {
      _deliveries = list.map((e) => Delivery.fromJson(e)).toList();
    });
  }

  Future<void> _addDelivery() async {
    final origin = _originController.text;
    final destination = _destinationController.text;
    if (origin.isEmpty || destination.isEmpty) return;
    final newDelivery = Delivery(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originAddress: origin,
      destinationAddress: destination,
      status: 'requested',
    );
    setState(() {
      _deliveries.add(newDelivery);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deliveries', jsonEncode(_deliveries));
    _originController.clear();
    _destinationController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrega solicitada com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Entrega')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _originController,
              decoration: const InputDecoration(labelText: 'Endereço de Saída'),
            ),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Endereço de Destino',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addDelivery,
              child: const Text('Solicitar Entrega'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Minhas Entregas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _deliveries.length,
                itemBuilder: (context, index) {
                  final d = _deliveries[index];
                  return ListTile(
                    title: Text('${d.originAddress} → ${d.destinationAddress}'),
                    subtitle: Text('Status: ${d.status}'),
                    trailing:
                        d.status == 'accepted'
                            ? ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ClienteTrackingPage(delivery: d),
                                  ),
                                );
                              },
                              child: const Text('Rastrear'),
                            )
                            : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClienteTrackingPage extends StatefulWidget {
  final Delivery delivery;
  const ClienteTrackingPage({super.key, required this.delivery});

  @override
  State<ClienteTrackingPage> createState() => _ClienteTrackingPageState();
}

class _ClienteTrackingPageState extends State<ClienteTrackingPage> {
  GoogleMapController? _mapController;
  LatLng? _driverPos;

  @override
  void initState() {
    super.initState();
    _loadDriverPosition();
    // TODO: usar um Timer.periodic para atualizar a posição do motorista
  }

  Future<void> _loadDriverPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('deliveries') ?? '[]';
    final List list = jsonDecode(data);
    final d = list
        .map((e) => Delivery.fromJson(e))
        .firstWhere((e) => e.id == widget.delivery.id);
    if (d.driverLat != null && d.driverLng != null) {
      setState(() {
        _driverPos = LatLng(d.driverLat!, d.driverLng!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_driverPos == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rastreamento')),
        body: const Center(child: Text('Aguardando motorista aceitar...')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rastreamento')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _driverPos!, zoom: 14),
        markers: {
          Marker(markerId: const MarkerId('motorista'), position: _driverPos!),
        },
      ),
    );
  }
}

class Delivery {
  String id;
  String originAddress;
  String destinationAddress;
  String status;
  double? driverLat;
  double? driverLng;

  Delivery({
    required this.id,
    required this.originAddress,
    required this.destinationAddress,
    required this.status,
    this.driverLat,
    this.driverLng,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
    id: json['id'],
    originAddress: json['originAddress'],
    destinationAddress: json['destinationAddress'],
    status: json['status'],
    driverLat: (json['driverLat'] as num?)?.toDouble(),
    driverLng: (json['driverLng'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'originAddress': originAddress,
    'destinationAddress': destinationAddress,
    'status': status,
    'driverLat': driverLat,
    'driverLng': driverLng,
  };
}
