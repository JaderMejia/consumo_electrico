import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


void main() {
  runApp(ElectricConsumptionCalculator());
    runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Consumo Eléctrico',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}
class ElectricConsumptionCalculator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Consumo Eléctrico',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}
final numberFormat = NumberFormat("#,##0.00", "en_US");

class _HomeScreenState extends State<HomeScreen> {
  final List<ElectronicDevice> devices = [];
  double costPerKWh = 0.0;
  String currency = 'USD';
  double exchangeRate = 1.0; // Tasa de cambio inicial es 1.0 para USD
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home - Consumo Eléctrico'),
        backgroundColor: Colors.teal,
        elevation: 0.0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _setCostDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(devices[index].name),
                    subtitle: Text('Consumo11: ${devices[index].consumption.toStringAsFixed(2)} kWh'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editDeviceDialog(context, index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => setState(() {
                            devices.removeAt(index);
                          }),
                        ),
                        IconButton(
                          icon: Icon(Icons.history),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConsumptionHistoryScreen(device: devices[index]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Consumo Total: ${numberFormat.format(_calculateTotalConsumption())} kWh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Costo Total: \$${numberFormat.format(_calculateTotalCostInSelectedCurrency())} $currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _addDeviceDialog(context),
              child: Text('Agregar Electrodoméstico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                textStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getRecommendations().map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.teal),
                    SizedBox(width: 5),
                    Expanded(child: Text(rec)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<double> getExchangeRate(String baseCurrency, String targetCurrency) async {
    final apiKey = 'b569cb1b71b431c220360352'; 
    final url = 'https://v6.exchangerate-api.com/v6/$apiKey/pair/$baseCurrency/$targetCurrency';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse["conversion_rate"];
    } else {
      throw Exception('Failed to load exchange rate');
    }
  }

  void _setCostDialog(BuildContext context) {
    final costController = TextEditingController();
    final currencyController = TextEditingController(text: currency);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Configurar Costo por kWh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: costController,
                decoration: InputDecoration(
                  labelText: 'Costo por kWh (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              TextField(
                controller: currencyController,
                decoration: InputDecoration(
                  labelText: 'Moneda (ej. COP)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final selectedCurrency = currencyController.text;
                final exchangeRate = await getExchangeRate('USD', selectedCurrency);
                setState(() {
                  costPerKWh = double.tryParse(costController.text) ?? 0.0;
                  currency = selectedCurrency;
                  this.exchangeRate = exchangeRate;
                });
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _addDeviceDialog(BuildContext context) {
    _deviceDialog(context);
  }

  void _editDeviceDialog(BuildContext context, int index) {
    _deviceDialog(context, device: devices[index], index: index);
  }

  void _deviceDialog(BuildContext context, {ElectronicDevice? device, int? index}) {
    final nameController = TextEditingController(text: device?.name ?? '');
    final consumptionController = TextEditingController(text: device != null ? (device.consumption / (device.days * device.hoursPerDay)).toString() : '');
    final daysController = TextEditingController(text: device?.days.toString() ?? '');
    final hoursController = TextEditingController(text: device?.hoursPerDay.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(device == null ? 'Agregar Electrodoméstico' : 'Editar Electrodoméstico'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: consumptionController,
                  decoration: InputDecoration(
                    labelText: 'Consumo por hora (kWh)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: daysController,
                  decoration: InputDecoration(
                    labelText: 'Días de uso',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: hoursController,
                  decoration: InputDecoration(
                    labelText: 'Horas de uso diario',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final name = nameController.text;
                final consumptionPerHour = double.tryParse(consumptionController.text) ?? 0.0;
                final days = int.tryParse(daysController.text) ?? 0;
                final hoursPerDay = double.tryParse(hoursController.text) ?? 0.0;

                final totalConsumption = consumptionPerHour * hoursPerDay * days;
                final dailyConsumptionHistory = List.generate(days, (index) => consumptionPerHour * hoursPerDay);

                setState(() {
                  if (device == null) {
                    devices.add(ElectronicDevice(
                      name: name, 
                      consumption: totalConsumption, 
                      days: days, 
                      hoursPerDay: hoursPerDay,
                      dailyConsumptionHistory: dailyConsumptionHistory,
                    ));
                  } else {
                    devices[index!] = ElectronicDevice(
                      name: name, 
                      consumption: totalConsumption, 
                      days: days, 
                      hoursPerDay: hoursPerDay,
                      dailyConsumptionHistory: dailyConsumptionHistory,
                    );
                  }
                });

                Navigator.of(context).pop();
              },
              child: Text(device == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  double _calculateTotalConsumption() {
    return devices.fold(0.0, (sum, item) => sum + item.consumption);
  }

  double _calculateTotalCost() {
    return _calculateTotalConsumption() * costPerKWh;
  }

  double _calculateTotalCostInSelectedCurrency() {
    return _calculateTotalCost() * exchangeRate;
  }

  List<String> _getRecommendations() {
    final totalConsumption = _calculateTotalConsumption();

    if (totalConsumption > 1000) {
      return ['Apaga los electrodomésticos cuando no los uses', 'Usa electrodomésticos de bajo consumo'];
    } else if (totalConsumption > 500) {
      return ['Revisa el aislamiento de tu hogar', 'Considera el uso de energía solar'];
    } else {
      return ['¡Buen trabajo manteniendo un consumo bajo!'];
    }
  }
}

class ElectronicDevice {
  final String name;
  final double consumption;
  final int days;
  final double hoursPerDay;
  final List<double> dailyConsumptionHistory;

  ElectronicDevice({
    required this.name, 
    required this.consumption, 
    required this.days, 
    required this.hoursPerDay,
    this.dailyConsumptionHistory = const [],
  });

  double get dailyConsumption => consumption / days;
  double get weeklyConsumption => dailyConsumption * 7;
  double get monthlyConsumption => dailyConsumption * 30;
}

class ConsumptionHistoryScreen extends StatelessWidget {
  final ElectronicDevice device;

  ConsumptionHistoryScreen({required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Consumo - ${device.name}'),
        backgroundColor: Colors.teal,
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: device.dailyConsumptionHistory.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('Día ${index + 1}'),
              trailing: Text('${device.dailyConsumptionHistory[index].toStringAsFixed(2)} kWh'),
            );
          },
        ),
      ),
    );
  }
}