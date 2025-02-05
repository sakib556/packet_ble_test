import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class SapBleController extends GetxController {
  // Observables
  RxList<ScanResult> scannedDevices = <ScanResult>[].obs;

  // BLE objects
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? notifyCharacteristic;
  BluetoothCharacteristic? writeCharacteristic;

  // Device parameters
  var model = 0.obs;
  var mode = 0.obs;
  var pumpTimeSec = 0.obs;
  var downHighThresholdMv = 0.obs;
  var downLowThresholdMv = 0.obs;
  var upHighThresholdMv = 0.obs;
  var upLowThresholdMv = 0.obs;
  var pumpTotalHours = 0.obs;
  var checksum = 0.obs;

  // BLE & App Status
  var isConnected = false.obs;
  RxList<String> appStatus = <String>[].obs;

  void logStatus(String message) {
    appStatus.add("${DateTime.now()}: $message");
    print(message);
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      logStatus("All permissions granted.");
    } else {
      logStatus("Some permissions were denied.");
    }
  }

  void startScan() async {
    await requestPermissions();

    logStatus("Scanning for BLE devices...");
    scannedDevices.clear();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (!scannedDevices
            .any((device) => device.device.id == result.device.id)) {
          scannedDevices.add(result);
          logStatus(
              "Device found: ${result.device.name} (${result.device.id})");
        }
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      logStatus("Connecting to device: ${device.name} (${device.id})");

      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
      }

      await device.connect();
      connectedDevice = device;
      isConnected.value = true;

      // Request the device's maximum supported MTU
      int mtu = await device.mtu.first;
      await device.requestMtu(mtu);

      logStatus("Connected to device: ${device.name}, MTU: $mtu");

      await discoverServices(device);
    } catch (e) {
      isConnected.value = false;
      logStatus("Error connecting to device: $e");
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    logStatus("Discovering services...");
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      logStatus("service.uuid : ${service.uuid.toString()}");
      if (service.uuid.toString() == "000000bb-007d-4ae5-8fa9-9fafd205e455") {
        for (var characteristic in service.characteristics) {
          logStatus(
              "characteristic.uuid detect: : ${characteristic.uuid.toString()}");
          if (characteristic.uuid.toString() ==
              "00000003-bb7d-4ae5-8fa9-9fafd205e455") {
            notifyCharacteristic = characteristic;
            logStatus(
                "notifyCharacteristic characteristic found: ${characteristic.uuid.toString()}");
            await notifyCharacteristic?.setNotifyValue(true);
            notifyCharacteristic!.value.listen((value) {
              logStatus("Notification packet received: ${value.length} bytes");
              logStatus("Notification packet received data: ${value}");
              processNotification(value);
            });
          } else if (characteristic.uuid.toString() ==
              "00000002-bb7d-4ae5-8fa9-9fafd205e455") {
            writeCharacteristic = characteristic;
            logStatus(
                "Write characteristic found: ${characteristic.uuid.toString()}");
          }
        }
      }
    }
    logStatus("Service discovery completed.");
  }

  void processNotification(List<int> value) {
    if (value.isEmpty) {
      logStatus("Invalid notification packet received: $value");
      return;
    }

    // Validate Start and End Frame
    // if (value.first != 0xAA || value.last != 0x55) {
    //   logStatus("Invalid packet format: Missing start or end frame");
    //   return;
    // }

    // Extract values based on the structure
    // int commandType = value[1];
    // if (commandType != 0x83) {
    //   logStatus("Unexpected Command Type: $commandType");
    //   return;
    // }

    model.value = value[2]; // Model (0x00 for Single Sensor)
    mode.value = value[3]; // Pump Mode (0x00 for Auto + Manual)

    pumpTimeSec.value = (value[4] << 8) | value[5]; // 1000 seconds
    downHighThresholdMv.value = (value[6] << 8) | value[7]; // 1000mV
    downLowThresholdMv.value = (value[8] << 8) | value[9]; // 10mV
    upHighThresholdMv.value = (value[10] << 8) | value[11]; // 1000mV
    upLowThresholdMv.value = (value[12] << 8) | value[13]; // 10mV

    int calculatedChecksum = 0;
    for (int i = 1; i < value.length - 2; i++) {
      calculatedChecksum ^= value[i];
    }

    int receivedChecksum = value[value.length - 2];
    if (calculatedChecksum != receivedChecksum) {
      logStatus(
          "Checksum mismatch! Expected: $calculatedChecksum, Received: $receivedChecksum");
      return;
    }

    // Log parsed values
    logStatus("✅ System Information Report Received:");
    logStatus("Model: ${model.value == 0 ? 'Single Sensor' : 'Unknown'}");
    logStatus("Pump Mode: ${mode.value == 0 ? 'Auto + Manual' : 'Unknown'}");
    logStatus("Pump On Time: ${pumpTimeSec.value} sec");
    logStatus("Level Down High Threshold: ${downHighThresholdMv.value} mV");
    logStatus("Level Down Low Threshold: ${downLowThresholdMv.value} mV");
    logStatus("Level Up High Threshold: ${upHighThresholdMv.value} mV");
    logStatus("Level Up Low Threshold: ${upLowThresholdMv.value} mV");
  }

  void monitorDeviceConnection(BluetoothDevice device) {
    device.connectionState.listen((state) {
      switch (state) {
        case BluetoothConnectionState.connected:
          logStatus("Device ${device.name} connected");
          break;
        case BluetoothConnectionState.disconnected:
          logStatus("Device ${device.name} disconnected");
          isConnected.value = false;
          connectedDevice = null;
          break;
        default:
          logStatus("Device ${device.name} state: $state");
      }
    });
  }

  Future<void> sendCommand(int devId, int cmd, int value) async {
    if (writeCharacteristic != null) {
      List<int> packet = [devId, cmd, ..._intToBytes(value)];
      await writeCharacteristic!.write(packet);
      logStatus("Command Sent: $packet");
    } else {
      logStatus("Write characteristic not available");
    }
  }

  List<int> _intToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      logStatus("Disconnecting from device: ${connectedDevice!.name}");
      await connectedDevice!.disconnect();
      connectedDevice = null;
      isConnected.value = false;
      logStatus("Device disconnected");
    }
  }
}
