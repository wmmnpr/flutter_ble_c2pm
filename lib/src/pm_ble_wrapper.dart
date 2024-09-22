import 'dart:async';

import 'package:flutter_ble_c2pm/flutter_ble_c2pm.dart';
import 'package:flutter_ble_c2pm/src/pm_ble_characteristic.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart';

class PmBleWrapper {
  final log = Logger('PmBleWrapper');
  Map<int, DeviceCharacteristic> characteristics = {};

  BluetoothDevice bluetoothDevice;
  PmBLEDevice? pmBLEDevice;

  PmBleWrapper(this.bluetoothDevice);

  Future<PmBleWrapper> enumerate() async {
    ///////
    // listen for disconnection

    Completer<PmBleWrapper> completer = Completer();
    bluetoothDevice.connectionState.listen((BluetoothConnectionState state) {
      if (state == BluetoothConnectionState.connected) {
        Guid guid21 = Guid("ce060021-43e5-11e4-916c-0800200c9a66");
        Guid guid22 = Guid("ce060022-43e5-11e4-916c-0800200c9a66");
        Guid guid32 = Guid("ce060032-43e5-11e4-916c-0800200c9a66");
        Guid guid35 = Guid("ce060035-43e5-11e4-916c-0800200c9a66");

        List<String> uuidList = [];
        bluetoothDevice
            .discoverServices()
            .then((List<BluetoothService> bluetoothServiceList) {
          for (BluetoothService service in bluetoothServiceList) {
            log.info("------>service: ${service.uuid}");
            for (BluetoothCharacteristic characteristic
                in service.characteristics) {
              log.info("service: ${service.uuid} <==> ${characteristic.uuid}");
              uuidList.add(characteristic.uuid.str);
              if (characteristic.characteristicUuid == guid21) {
                characteristics[characteristic.uuid.hashCode] =
                    CsafeBufferCharacteristic(characteristic);
              } else if (characteristic.characteristicUuid == guid32) {
                characteristics[characteristic.uuid.hashCode] =
                    CsafeBufferCharacteristic(characteristic);
              } else if (characteristic.characteristicUuid == guid35) {
                characteristics[characteristic.uuid.hashCode] =
                    StrokeDataCharacteristic(characteristic);
              } else if (characteristic.characteristicUuid == guid22) {
                characteristics[characteristic.uuid.hashCode] =
                    CsafeBufferCharacteristic(characteristic);
              } else {
                characteristics[characteristic.uuid.hashCode] =
                    CsafeBufferCharacteristic(characteristic);
              }
            }
          }
          pmBLEDevice = PmBLEDevice(characteristics);
          completer.complete(this);
        });
      }
    });
    return completer.future;
  }
}
