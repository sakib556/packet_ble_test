import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sap_ble_controller.dart';

class SapBleApp extends StatelessWidget {
  final SapBleController bleController = Get.put(SapBleController());

  SapBleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.red),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("SAP- CONTROL"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(
                () => bleController.isConnected.value
                ? Column(
              children: [
                const Text(
                  "Connected Device Data",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // /// Device Information
                // buildInfoTile("Model",
                //     bleController.model.value == 0 ? "Single Sensor" : "Unknown"),
                // buildInfoTile("Pump Mode",
                //     bleController.mode.value == 0 ? "Auto + Manual" : "Unknown"),
                // buildInfoTile(
                //     "Pump On Time", "${bleController.pumpTimeSec.value} sec"),
                // buildInfoTile("Level Down High Threshold",
                //     "${bleController.downHighThresholdMv.value} mV"),
                // buildInfoTile("Level Down Low Threshold",
                //     "${bleController.downLowThresholdMv.value} mV"),
                // buildInfoTile("Level Up High Threshold",
                //     "${bleController.upHighThresholdMv.value} mV"),
                // buildInfoTile("Level Up Low Threshold",
                //     "${bleController.upLowThresholdMv.value} mV"),

                const SizedBox(height: 16),

                /// App Logs Section
                const Text(
                  "App Flow Logs",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
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
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: bleController.disconnectDevice,
                  child: const Text("Disconnect"),
                ),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Not Connected"),
                ElevatedButton(
                  onPressed: bleController.startScan,
                  child: const Text("Scan"),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    return ListView.builder(
                      itemCount: bleController.scannedDevices.length,
                      itemBuilder: (context, index) {
                        final device =
                            bleController.scannedDevices[index].device;
                        return ListTile(
                          title: Text(device.name.isNotEmpty
                              ? device.name
                              : "Unknown Device"),
                          subtitle: Text(device.id.toString()),
                          trailing: ElevatedButton(
                            onPressed: () =>
                                bleController.connectToDevice(device),
                            child: const Text("Connect"),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper function to create labeled data rows
  Widget buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
