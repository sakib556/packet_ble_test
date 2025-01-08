import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class BLEController extends GetxController {
  // Observables
  RxList<ScanResult> scannedDevices = <ScanResult>[].obs;
  RxBool isConnected = false.obs;

  // BLE objects
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? notifyCharacteristic;
  BluetoothCharacteristic? writeCharacteristic;

  // Device Data
  RxInt devId = 0x10.obs;
  RxInt sl1Current = 0.obs;
  RxInt sl1Voltage = 0.obs;
  RxInt sl1Power = 0.obs;

  RxInt sl2Current = 0.obs;
  RxInt sl2Voltage = 0.obs;
  RxInt sl2Power = 0.obs;

  RxInt sl3Current = 0.obs;
  RxInt sl3Voltage = 0.obs;
  RxInt sl3Power = 0.obs;

  RxInt alarmStatus = 0.obs;
  RxInt batteryStatus = 0.obs;
  RxInt batteryLevel = 0.obs;
  RxInt deviceTemperature = 0.obs;

  RxInt controlMode = 0.obs;

  void startScan() {
    scannedDevices.clear();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (result.device.name.startsWith("SAC")) {
          if (!scannedDevices
              .any((device) => device.device.id == result.device.id)) {
            scannedDevices.add(result);
          }
        }
      }
    });
  }

  // Connect to the BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == "4c51f3c6-aaaa-11ee-be56-0242ac120002") {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() ==
                "4c51f3c6-bbbb-11ee-be56-0242ac120002") {
              notifyCharacteristic = characteristic;

              // Enable notifications
              await notifyCharacteristic!.setNotifyValue(true);
              notifyCharacteristic!.value.listen((value) {
                processNotification(value);
              });
            } else if (characteristic.uuid.toString() ==
                "4c51f3c6-cccc-11ee-be56-0242ac120002") {
              writeCharacteristic = characteristic;
            }
          }
        }
      }

      isConnected.value = true;
    } catch (e) {
      isConnected.value = false;
      print("Error connecting to device: $e");
    }
  }

  // Process notification packet
  void processNotification(List<int> value) {
    if (value.isNotEmpty && value.length >= 32) {
      devId.value = value[0];

      // SL1
      sl1Current.value = value[1] | (value[2] << 8);
      sl1Voltage.value = value[3] | (value[4] << 8);
      sl1Power.value = value[5] | (value[6] << 8);

      // SL2
      sl2Current.value = value[7] | (value[8] << 8);
      sl2Voltage.value = value[9] | (value[10] << 8);
      sl2Power.value = value[11] | (value[12] << 8);

      // SL3
      sl3Current.value = value[13] | (value[14] << 8);
      sl3Voltage.value = value[15] | (value[16] << 8);
      sl3Power.value = value[17] | (value[18] << 8);

      // SYS
      alarmStatus.value = value[19];
      batteryStatus.value = value[20];
      batteryLevel.value = value[21];
      deviceTemperature.value = value[22] | (value[23] << 8);

      // Control Mode
      controlMode.value = value[24];

      print(
          "Notification Received -> DEV_ID: ${devId.value}, SL1: ${sl1Current.value} A, ${sl1Voltage.value} V");
    } else {
      print("Invalid notification packet received");
    }
  }

  Future<void> sendCommand(int devId, int cmd, int value) async {
    if (writeCharacteristic != null) {
      List<int> packet = [devId, cmd, ..._intToBytes(value)];
      await writeCharacteristic!.write(packet);
      print("Command Sent: $packet");
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

  // Disconnect the BLE device
  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      isConnected.value = false;
    }
  }
}
