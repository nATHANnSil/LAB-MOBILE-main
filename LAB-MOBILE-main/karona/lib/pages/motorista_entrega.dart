import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'cliente_entrega.dart';

class MotoristaEntregaPage extends StatefulWidget {
  const MotoristaEntregaPage({super.key});

  @override
  State<MotoristaEntregaPage> createState() => _MotoristaEntregaPageState();
}

class _MotoristaEntregaPageState extends State<MotoristaEntregaPage> {
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

  Future<void> _acceptDelivery(Delivery d) async {
    // atualiza status e geocodifica endereços
    d.status = 'accepted';
    final orig = (await locationFromAddress(d.originAddress)).first;
    final dest = (await locationFromAddress(d.destinationAddress)).first;
    d.driverLat = orig.latitude;
    d.driverLng = orig.longitude;

    await _saveDeliveries();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MotoristaMapaPage(delivery: d)),
    );
  }

  Future<void> _saveDeliveries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deliveries', jsonEncode(_deliveries));
  }

  @override
  Widget build(BuildContext context) {
    final pending = _deliveries.where((d) => d.status == 'requested').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Entregas Disponíveis')),
      body: ListView.builder(
        itemCount: pending.length,
        itemBuilder: (context, index) {
          final d = pending[index];
          return ListTile(
            title: Text('${d.originAddress} → ${d.destinationAddress}'),
            trailing: ElevatedButton(
              onPressed: () => _acceptDelivery(d),
              child: const Text('Aceitar'),
            ),
          );
        },
      ),
    );
  }
}

class MotoristaMapaPage extends StatefulWidget {
  final Delivery delivery;
  const MotoristaMapaPage({super.key, required this.delivery});

  @override
  State<MotoristaMapaPage> createState() => _MotoristaMapaPageState();
}

class _MotoristaMapaPageState extends State<MotoristaMapaPage> {
  GoogleMapController? _mapController;
  List<LatLng> _route = [];
  LatLng? _current;

  @override
  void initState() {
    super.initState();
    _prepareRoute();
  }

  Future<void> _prepareRoute() async {
    final orig = LatLng(widget.delivery.driverLat!, widget.delivery.driverLng!);
    final destCoords =
        (await locationFromAddress(widget.delivery.destinationAddress)).first;
    final dest = LatLng(destCoords.latitude, destCoords.longitude);
    setState(() {
      _route = [orig, dest];
      _current = orig;
    });
    await _updateDriverPosition(orig);
  }

  Future<void> _updateDriverPosition(LatLng pos) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('deliveries') ?? '[]';
    final List list = jsonDecode(data);
    final updated =
        list.map((e) {
          final d = Delivery.fromJson(e);
          if (d.id == widget.delivery.id) {
            d.driverLat = pos.latitude;
            d.driverLng = pos.longitude;
          }
          return d;
        }).toList();
    await prefs.setString('deliveries', jsonEncode(updated));
  }

  @override
  Widget build(BuildContext context) {
    if (_route.isEmpty || _current == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Rota da Entrega')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _current!, zoom: 14),
        markers: {
          Marker(markerId: const MarkerId('origin'), position: _route.first),
          Marker(markerId: const MarkerId('dest'), position: _route.last),
          Marker(markerId: const MarkerId('driver'), position: _current!),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: _route,
            width: 4,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // exemplo: simula movimento para metade do caminho
          final mid = LatLng(
            (_route.first.latitude + _route.last.latitude) / 2,
            (_route.first.longitude + _route.last.longitude) / 2,
          );
          setState(() => _current = mid);
          await _updateDriverPosition(mid);
        },
        child: const Icon(Icons.directions_car),
      ),
    );
  }
}
