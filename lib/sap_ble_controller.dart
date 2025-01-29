import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class SapBleController extends GetxController {
  RxList<ScanResult> scannedDevices = <ScanResult>[].obs;
  RxBool isConnected = false.obs;

  BluetoothDevice? device;
  BluetoothCharacteristic? notifyCharacteristic;
  BluetoothCharacteristic? writeCharacteristic;

  final String serviceUUID = "000000bb-007d-4ae5-8fa9-9fafd205e455";
  final String notifyUUID = "00000003-bb7d-4ae5-8fa9-9fafd205e455";
  final String writeUUID = "00000002-bb7d-4ae5-8fa9-9fafd205e455";

  // Application Logs
  RxList<String> appStatus = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    requestPermissions();
    startScan();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
    logStatus("Permissions granted.");
  }

  void startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (r.device.name.contains("SAP-2HP")) {
          device = r.device;
          FlutterBluePlus.stopScan();
          connectToDevice();
          break;
        }
      }
    });
  }

  void connectToDevice() async {
    if (device == null) return;
    try {
      await device!.connect();
      isConnected.value = true;
      discoverServices();
    } catch (e) {
      logStatus("Connection failed: $e");
    }
  }

  void discoverServices() async {
    if (device == null) return;
    List<BluetoothService> services = await device!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == notifyUUID) {
            notifyCharacteristic = characteristic;
            enableNotifications();
          } else if (characteristic.uuid.toString() == writeUUID) {
            writeCharacteristic = characteristic;
          }
        }
      }
    }
  }

  void enableNotifications() async {
    if (notifyCharacteristic != null) {
      await notifyCharacteristic!.setNotifyValue(true);
      notifyCharacteristic!.lastValueStream.listen((value) {
        logStatus(
            "Received: ${value.map((e) => e.toRadixString(16)).join(' ')}");
        processNotification(value);
      });
    }
  }

  void sendCommand(int commandType, List<int> payload) async {
    if (writeCharacteristic != null) {
      List<int> packet = buildPacket(commandType, payload);
      await writeCharacteristic!.write(packet);
      logStatus("Sent: ${packet.map((e) => e.toRadixString(16)).join(' ')}");
    }
  }

  List<int> buildPacket(int commandType, List<int> payload) {
    List<int> packet = [0xAA, commandType, ...payload];
    packet.add(calculateChecksum(packet));
    packet.add(0x55);
    return packet;
  }

  int calculateChecksum(List<int> data) {
    return data.reduce((a, b) => a ^ b);
  }

  void processNotification(List<int> value) {
    logStatus("Packet length : ${value.length}");
    logStatus("Packet received. $value");
    if (value.length < 7) {
      logStatus("Invalid packet received.");
      return;
    }

    int commandType = value[1];

    if (commandType == 0x82) {
      int waterLevel = value[2];
      int ledBuzzerStatus = value[3];
      int pumpStatus = value[4];
      int errorCode = value[5];

      logStatus(
          "Status Report: Water Level: $waterLevel, LED/Buzzer: $ledBuzzerStatus, Pump: $pumpStatus, Error: $errorCode");
    } else if (commandType == 0x83) {
      logStatus("System Info Received.");
    }
  }

  // System Information
  void getSystemInformation() => sendCommand(0x00, []);

  // Pump Control
  void startPump() => sendCommand(0x01, []);
  void stopPump() => sendCommand(0x02, []);

  // Set Pump Timer
  void setPumpOnTime(int seconds) =>
      sendCommand(0x03, [seconds >> 8, seconds & 0xFF]);

  // Set Voltage Thresholds
  void setVoltageHighThreshold(int voltage) =>
      sendCommand(0x06, [voltage >> 8, voltage & 0xFF]);
  void setVoltageLowThreshold(int voltage) =>
      sendCommand(0x07, [voltage >> 8, voltage & 0xFF]);

  // Set Device Model
  void setDeviceModel(int model) => sendCommand(0x10, [model]);

  // Set Pump Control Mode
  void setPumpControlMode(int mode) => sendCommand(0x11, [mode]);

  void logStatus(String message) {
    appStatus.add("${DateTime.now()}: $message");
    print(message);
  }
}
