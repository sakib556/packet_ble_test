import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ble_controller.dart';

class BLEApp extends StatelessWidget {
  final BLEController bleController = Get.put(BLEController());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.red),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("SAC- CONTROL"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(
            () => bleController.isConnected.value
                ? Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            Text(
                                "Notification Received -> DEV_ID: ${bleController.devId.value}, "
                                "SL1: ${bleController.sl1Status.value}, ${bleController.sl1Current.value} A, ${bleController.sl1Voltage.value} V, ${bleController.sl1Power.value} W, "
                                "SL2: ${bleController.sl2Status.value}, ${bleController.sl2Current.value} A, ${bleController.sl2Voltage.value} V, ${bleController.sl2Power.value} W, "
                                "SL3: ${bleController.sl3Status.value}, ${bleController.sl3Current.value} A, ${bleController.sl3Voltage.value} V, ${bleController.sl3Power.value} W, "
                                "Alarm: ${bleController.alarmStatus.value}, Battery: ${bleController.batteryStatus.value}, "
                                "Level: ${bleController.batteryLevel.value}%, Temp: ${bleController.deviceTemperature.value}°C, "
                                "Mode: ${bleController.controlMode.value}"),
                            const SizedBox(height: 16),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                            //   children: [
                            //     _buildLineIndicator(
                            //         "L1", bleController.sl1Voltage.value > 0),
                            //     _buildLineIndicator(
                            //         "L2", bleController.sl2Voltage.value > 0),
                            //     _buildLineIndicator(
                            //         "L3", bleController.sl3Voltage.value > 0),
                            //     _buildLineIndicator("House", true),
                            //   ],
                            // ),
                            // const SizedBox(height: 16),
                            // _buildControlSwitch(
                            //   "Inverter",
                            //   bleController.controlMode.value == 1,
                            //   (value) => bleController.sendCommand(
                            //       0x10, 0x04, value ? 1 : 0),
                            // ),
                            // _buildControlSwitch(
                            //   "Generator",
                            //   bleController.controlMode.value == 1,
                            //   (value) => bleController.sendCommand(
                            //       0x10, 0x05, value ? 1 : 0),
                            // ),
                            // _buildControlSwitch(
                            //   "Output to House",
                            //   true,
                            //   (value) => bleController.sendCommand(
                            //       0x10, 0x06, value ? 1 : 0),
                            // ),
                            // _buildControlSwitch(
                            //   "Alarm",
                            //   bleController.alarmStatus.value == 1,
                            //   (value) => bleController.sendCommand(
                            //       0x10, 0x19, value ? 1 : 0),
                            // ),
                            // const SizedBox(height: 16),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                            //   children: [
                            //     _buildGauge(
                            //         "House output",
                            //         "${bleController.sl1Voltage.value}V",
                            //         Colors.green),
                            //     _buildGauge(
                            //         "Temperature output",
                            //         "${bleController.deviceTemperature.value}°C",
                            //         Colors.red),
                            //     _buildGauge(
                            //         "Battery level",
                            //         "${bleController.batteryLevel.value}%",
                            //         Colors.blue),
                            //   ],
                            // ),
                            // const SizedBox(height: 16),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                            //   children: [
                            //     _buildActionButton("Shutdown",
                            //         Icons.power_settings_new, Colors.red, () {
                            //       bleController.sendCommand(0x10, 0x0C, 1);
                            //     }),
                            //     _buildActionButton(
                            //         "Reset", Icons.refresh, Colors.green, () {
                            //       bleController.sendCommand(0x10, 0x0D, 1);
                            //     }),
                            //   ],
                            // ),
                            const SizedBox(height: 16),
                            const Text(
                              "App Flow Logs",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 400,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Obx(
                                () => ListView.builder(
                                  itemCount: bleController.appStatus.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 8),
                                      child: Text(
                                        bleController.appStatus[index],
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Not Connected"),
                      ElevatedButton(
                        onPressed: bleController.startScan,
                        child: const Text("Scan "),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: bleController.scannedDevices.length,
                          itemBuilder: (context, index) {
                            final device =
                                bleController.scannedDevices[index].device;
                            return ListTile(
                              title: Text(device.name),
                              subtitle: Text(device.id.toString()),
                              onTap: () =>
                                  bleController.connectToDevice(device),
                            );
                          },
                        ),
                      ),
                      const Text(
                        "App Flow Logs",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 400,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Obx(
                          () => ListView.builder(
                            itemCount: bleController.appStatus.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Text(
                                  bleController.appStatus[index],
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineIndicator(String label, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          radius: 20,
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildControlSwitch(
      String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildGauge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(value, style: TextStyle(fontSize: 14, color: color)),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          iconSize: 40,
          onPressed: onPressed,
        ),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
