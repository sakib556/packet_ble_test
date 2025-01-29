import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sap_ble_controller.dart';

class SapBleApp extends StatelessWidget {
  final SapBleController bleController = Get.put(SapBleController());

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
                      Expanded(
                        child: ListView(
                          children: [
                            Text("Notification Received -> "
                                "Water Level: ${bleController.appStatus.length > 0 ? bleController.appStatus.last : 'No Data'}"),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => bleController.startPump(),
                              child: const Text("Start Pump"),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  bleController.setPumpOnTime(1000),
                              child: const Text("Set Pump Time (1000s)"),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "App Flow Logs",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 300,
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
                        child: const Text("Scan"),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
