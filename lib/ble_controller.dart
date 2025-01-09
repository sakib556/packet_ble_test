import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

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
  RxInt sl1Status = 0.obs;
  RxInt sl1Current = 0.obs;
  RxInt sl1Voltage = 0.obs;
  RxInt sl1Power = 0.obs;

  RxInt sl2Status = 0.obs;
  RxInt sl2Current = 0.obs;
  RxInt sl2Voltage = 0.obs;
  RxInt sl2Power = 0.obs;

  RxInt sl3Status = 0.obs;
  RxInt sl3Current = 0.obs;
  RxInt sl3Voltage = 0.obs;
  RxInt sl3Power = 0.obs;

  RxInt sysStatus = 0.obs;
  RxInt alarmStatus = 0.obs;
  RxInt batteryStatus = 0.obs;
  RxInt batteryLevel = 0.obs;
  RxInt deviceTemperature = 0.obs;

  RxInt controlMode = 0.obs;

  // Application Status
  RxList<String> appStatus = <String>[].obs;

  void logStatus(String message) {
    appStatus.add("${DateTime.now()}: $message");
    print(message);
  }

  Future<void> requestPermissions() async {
    // final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    // final bluetoothScanStatus = await Permission.bluetoothScan.status;
    // final locationStatus = await Permission.location.status;

    //  if (!bluetoothConnectStatus.isGranted) {
    await Permission.bluetoothConnect.request();
    //  }
    // if (!bluetoothScanStatus.isGranted) {
    await Permission.bluetoothScan.request();
    // }
    //  if (!locationStatus.isGranted) {
    await Permission.location.request();
    // }

    logStatus("Permissions granted for Bluetooth and Location");
  }

  void startScan() async {
    // Ensure permissions are granted before starting the scan
    await requestPermissions();
    logStatus("Scanning for BLE devices...");
    scannedDevices.clear();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        logStatus("Device : ${result.device.name} (${result.device.id})");
        // if (result.device.name.startsWith("SAC")) {
        if (!scannedDevices
            .any((device) => device.device.id == result.device.id)) {
          scannedDevices.add(result);
          logStatus(
              "Device found: ${result.device.name} (${result.device.id})");
        }
        // }
      }
    });
  }

  // Connect to the BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      logStatus("Connecting to device: ${device.name} (${device.id})");
      await device.connect();
      await device.requestMtu(512);
      await Future.delayed(const Duration(milliseconds: 500));
      connectedDevice = device;
      logStatus("Connected to device: ${device.name}");
      //  monitorDeviceConnection(device);
      await Future.delayed(const Duration(seconds: 1));

      // Discover services
      logStatus("discovering .. start11");
      List<BluetoothService> services = await device.discoverServices();
      logStatus("Service discovery completed");
      logStatus("Connected to device: ${device.name}");
      for (var service in services) {
        logStatus("service 1 ");
        if (service.uuid.toString() == "4c51f3c6-aaaa-11ee-be56-0242ac120002") {
          logStatus("service 2 ");
          for (var characteristic in service.characteristics) {
            logStatus("service 3 ");
            if (characteristic.uuid.toString() ==
                "4c51f3c6-bbbb-11ee-be56-0242ac120002") {
              logStatus("service 4 ");
              notifyCharacteristic = characteristic;
              logStatus(
                  "Notification $notifyCharacteristic enabled for characteristic notifing: ${characteristic.uuid}");
              // Enable notifications
              await notifyCharacteristic?.setNotifyValue(true, timeout: 30);
              logStatus(
                  "Notification enabled for characteristic: ${characteristic.uuid}");
              notifyCharacteristic!.value.listen((value) {
                print(" notification packet received : ${value}");
                logStatus(" notification packet received : ${value}");

                processNotification(value);
              });
            } else if (characteristic.uuid.toString() ==
                "4c51f3c6-cccc-11ee-be56-0242ac120002") {
              writeCharacteristic = characteristic;
              logStatus("Write characteristic found: ${characteristic.uuid}");
            }
          }
        }
      }

      isConnected.value = true;
    } catch (e) {
      isConnected.value = false;
      logStatus("Error connecting to device: $e");
    }
  }

  void processNotification(List<int> value) {
    if (value.isNotEmpty && value.length >= 32) {
      devId.value = value[0];

      // SL1
      sl1Status.value = value[1];
      sl1Current.value = value[2] | (value[3] << 8);
      sl1Voltage.value = value[4] | (value[5] << 8);
      sl1Power.value = value[6] | (value[7] << 8);

      // SL2
      sl2Status.value = value[8];
      sl2Current.value = value[9] | (value[10] << 8);
      sl2Voltage.value = value[11] | (value[12] << 8);
      sl2Power.value = value[13] | (value[14] << 8);

      // SL3
      sl3Status.value = value[15];
      sl3Current.value = value[16] | (value[17] << 8);
      sl3Voltage.value = value[18] | (value[19] << 8);
      sl3Power.value = value[20] | (value[21] << 8);

      // SYS
      sysStatus.value = value[22];
      alarmStatus.value = value[23];
      batteryStatus.value = value[24];
      batteryLevel.value = value[25] | (value[26] << 8);
      deviceTemperature.value = value[27] | (value[28] << 8);

      // Control Mode
      controlMode.value = value[29];

      logStatus("Notification Received: DEV_ID: ${devId.value}, "
          "SL1: ${sl1Status.value}, ${sl1Current.value} A, ${sl1Voltage.value} V, ${sl1Power.value} W, "
          "SL2: ${sl2Status.value}, ${sl2Current.value} A, ${sl2Voltage.value} V, ${sl2Power.value} W, "
          "SL3: ${sl3Status.value}, ${sl3Current.value} A, ${sl3Voltage.value} V, ${sl3Power.value} W, "
          "SYS: ${sysStatus.value}, Alarm: ${alarmStatus.value}, Battery: ${batteryStatus.value}, "
          "Battery Level: ${batteryLevel.value}%, Temp: ${deviceTemperature.value}°C, "
          "Control Mode: ${controlMode.value}");
    } else {
      logStatus("Invalid notification packet received");
    }
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

  // Disconnect the BLE device
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
