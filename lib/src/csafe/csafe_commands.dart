import '../models/data_conv_utils.dart';
import '../models/pm_data.dart';
import 'csafe_constants.dart';

extension IntExtensions on int {
  String toHex() {
    return toRadixString(16).padLeft(2, '0');
  }
}

class CsafeFrameProcessor {
  final Map<int, CsafeFrameContentBaseProcessor> _responseParser =
      _initResponseParsers();

  static _initResponseParsers() {
    Map<int, CsafeFrameContentBaseProcessor> v = {};

    for (CSAFE_PUBLIC_SHORT_CMDS e in CSAFE_PUBLIC_SHORT_CMDS.values) {
      v.putIfAbsent(e.id, () => CsafePublicShorCmdProcessor(e.id, e.fields));
    }

    for (CSAFE_PUBLIC_LONG_CMDS e in CSAFE_PUBLIC_LONG_CMDS.values) {
      if (e.id >= 0x76 && e.id <= 0x7F) {
        v.putIfAbsent(e.id, () => CsafeFrameWrapperProcessor(e.id));
      } else {
        v.putIfAbsent(e.id, () => CsafeFrameContentProcessor(e.id, e.fields));
      }
    }

    for (CSAFE_PROPRIETARY_SHORT_CMDS e
        in CSAFE_PROPRIETARY_SHORT_CMDS.values) {
      v.putIfAbsent(e.id, () => CsafeFrameContentProcessor(e.id, e.fields));
    }

    for (CSAFE_PROPRIETARY_LONG_CMDS e in CSAFE_PROPRIETARY_LONG_CMDS.values) {
      v.putIfAbsent(e.id, () => CsafeFrameContentProcessor(e.id, e.fields));
    }

    return v;
  }

  static IntList _unstuff(IntList inputList) {
    IntList data = [];
    for (int i = 0; i < inputList.length; i++) {
      if (inputList[i] == CSAFE_FRAME_STUFF_BYTE) {
        data.add(inputList[i + 1] + CSAFE_EXT_FRAME_START_BYTE);
        i++;
      } else {
        data.add(inputList[i]);
      }
    }
    return data;
  }

  Map<String, Object> deserializePropFrame(IntList inputList) {
    IntList data = _unstuff(inputList);
    Map<String, Object> response = {};
    int i = 0;
    switch (data[0]) {
      case CSAFE_EXT_FRAME_START_BYTE:
        response["checksum"] =
            DataConvUtils.csafe_checksum(data, 3, data.length - 1);
        response["source"] = ADDRESS_TEXT.fromInt(data[++i]).text;
        response["target"] = ADDRESS_TEXT.fromInt(data[++i]).text;
        response["state"] = STATE_MACHINE_STATE.fromInt(data[++i])!.text;
        response["previousFrameStatus"] =
            PREVIOUS_FRAME_STATUS.fromInt(data[i]).text;
        i = 4;
      case CSAFE_FRAME_START_BYTE:
        response["checksum"] =
            DataConvUtils.csafe_checksum(data, 1, data.length - 1);
        int id = data[++i];
        response["state"] = STATE_MACHINE_STATE.fromInt(id).text;
        i = 2;
      default:
        throw Exception("no start byte");
    }

    //parse frame contents
    CsafeFrameProcessorContext context = CsafeFrameProcessorContext();
    for (int j = i; j < data.length - 1; j++) {
      //print("#$j:value=${data[j].toRadixString(16).padLeft(2, '0')}");
      int v = data[j];
      if (_responseParser.containsKey(v)) {
        j = _responseParser[v]!.process(context, data, j);
      } else {
        throw Exception("Command $v at $j not found");
      }
    }
    response.putIfAbsent("data", () => context.result);

    //print(jsonEncode(response));
    return response;
  }

  Map<String, Object> deserializePublicFrame(
      int responseTo, IntList inputList) {
    IntList data = _unstuff(inputList);
    Map<String, Object> response = {};
    int i = 0;
    response["checksum"] =
        DataConvUtils.csafe_checksum(data, 1, data.length - 1);
    int id = data[++i];
    response["state"] = STATE_MACHINE_STATE.fromInt(id).text;
    return response;
  }
}

class CsafeFrameProcessorContext {
  Map<String, Object> result = {};
}

abstract class CsafeFrameContentBaseProcessor {
  int cmd;

  CsafeFrameContentBaseProcessor(this.cmd);

  int process(CsafeFrameProcessorContext context, IntList data, int start);
}

class CsafeFrameWrapperProcessor extends CsafeFrameContentBaseProcessor {
  final Map<int, CsafeFrameContentBaseProcessor> _responseParser =
      _initResponseParsers();

  CsafeFrameWrapperProcessor(super.cmd);

  static _initResponseParsers() {
    Map<int, CsafeFrameContentBaseProcessor> v = {};
    //1. C2 Proprietary Short Get Configuration Commands
    //2. C2 Proprietary Long Get Configuration Commands
    //3. C2 Proprietary Short Get Data Commands
    //4. C2 Proprietary Long Get Data Commands
    //5. C2 Proprietary Short Set Configuration Commands
    //6. C2 Proprietary Short Set Data Commands
    //7. C2 Proprietary Long Set Configuration Commands
    //8. C2 Proprietary Long Set Data Commands
    //1. C2 Proprietary Short Get Configuration Commands
    for (CSAFE_PROP_SHORT_GET_CONF_CMDS e
        in CSAFE_PROP_SHORT_GET_CONF_CMDS.values) {
      v.putIfAbsent(e.id, () => CsafeFrameContentProcessor(e.id, e.fields));
    }
    //2. C2 Proprietary Long Get Configuration Commands
    for (CSAFE_PROP_LONG_GET_CONF_CMDS e
        in CSAFE_PROP_LONG_GET_CONF_CMDS.values) {
      v.putIfAbsent(e.id, () => CsafeFrameContentProcessor(e.id, e.fields));
    }
    //3. C2 Proprietary Short Get Data Commands
    for (CSAFE_PROP_SHORT_GET_DATA_CMDS e
        in CSAFE_PROP_SHORT_GET_DATA_CMDS.values) {
      v.putIfAbsent(e.id, () => CsafeFrameContentProcessor(e.id, e.fields));
    }
    //4. C2 Proprietary Long Get Data Commands
    for (CSAFE_PROP_LONG_GET_DATA_CMDS e
        in CSAFE_PROP_LONG_GET_DATA_CMDS.values) {
      v.putIfAbsent(e.id, () => CsafeFrameContentProcessor(e.id, e.fields));
    }
    //5. C2 Proprietary Short Set Configuration Commands
    for (CSAFE_PROP_SHORT_SET_CONFIG_CMDS e
        in CSAFE_PROP_SHORT_SET_CONFIG_CMDS.values) {
      v.putIfAbsent(
          e.id, () => CsafePropShortSetConfigCmdProcessor(e.id, e.fields));
    }
    //6. C2 Proprietary Short Set Data Commands
    for (CSAFE_PROP_SHORT_SET_DATA_CMDS e
        in CSAFE_PROP_SHORT_SET_DATA_CMDS.values) {
      v.putIfAbsent(
          e.id, () => CsafePropShortSetDataCmdProcessor(e.id, e.fields));
    }
    //7. C2 Proprietary Long Set Configuration Commands
    for (CSAFE_PROP_LONG_SET_CONFIG_CMDS e
        in CSAFE_PROP_LONG_SET_CONFIG_CMDS.values) {
      v.putIfAbsent(
          e.id, () => CsafePropLongSetConfigCmdProcessor(e.id, e.fields));
    }
    //8. C2 Proprietary Long Set Data Commands
    for (CSAFE_PROP_LONG_SET_DATA_CMDS e
        in CSAFE_PROP_LONG_SET_DATA_CMDS.values) {
      v.putIfAbsent(e.id, () => CsafeFrameContentProcessor(e.id, e.fields));
    }
    return v;
  }

  @override
  int process(CsafeFrameProcessorContext context, IntList data, int start) {
    int cmd = data[start];
    assert(cmd == this.cmd);
    int length = data[start + 1];
    int idx = start + 2;
    int end = idx + length;
    for (; idx < end; idx++) {
      int v = data[idx];
      if (_responseParser.containsKey(v)) {
        idx = _responseParser[v]!.process(context, data, idx);
      }
    }
    return idx;
  }
}

class CsafeFrameContentProcessor extends CsafeFrameContentBaseProcessor {
  Map<String, FrameFieldType>? fields;

  CsafeFrameContentProcessor(super.cmd, this.fields);

  @override
  int process(CsafeFrameProcessorContext context, IntList data, int start) {
    int cmd = data[start];
    assert(cmd == this.cmd);
    int length = data[start + 1];
    int pos = start + 2;
    fields!.forEach((key, value) {
      // @formatter:off
      switch(value){
        case FrameFieldType.CHAR:
          context.result.putIfAbsent(key, () => data[pos].toString());
          pos = pos + 1;
        case FrameFieldType.INT:
          context.result.putIfAbsent(key, () => data[pos]);
          pos = pos + 1;
        case FrameFieldType.INT2:
          context.result.putIfAbsent(key, () => (data[pos] << 8) + data[pos+1]);
          pos = pos + 2;
        case FrameFieldType.INT3:
          context.result.putIfAbsent(key, () => (data[pos] << 16) + (data[pos+1] << 8) + data[pos+2]);
          pos = pos + 3;
        case FrameFieldType.INT4:
          context.result.putIfAbsent(key, () => (data[pos] << 24) + (data[pos+1] << 16) + (data[pos+2] << 8) + data[pos+3]);
          pos = pos + 4;
        case FrameFieldType.VAR_BUFF:
          context.result.putIfAbsent(key, () => DataConvUtils.intSubArrayToHex(data, pos, length));
          pos = pos + length;
        default:
      }
      // @formatter:on
    });
    return pos;
  }
}

//CSAFE_PROP_SHORT_SET_CONFIG_CMDS
class CsafePublicShorCmdProcessor extends CsafeFrameContentBaseProcessor {
  Map<String, FrameFieldType> fields;

  CsafePublicShorCmdProcessor(super.cmd, this.fields);

  @override
  int process(CsafeFrameProcessorContext context, IntList data, int start) {
    int cmd = data[start];
    assert(cmd == this.cmd);
    int length = data[start + 1];
    int pos = start + 2;
    fields.forEach((key, value) {
      // @formatter:off
        switch(value){
          case FrameFieldType.CHAR:
            context.result.putIfAbsent(key, () => data[pos].toString());
            pos = pos + 1;
          case FrameFieldType.INT:
            context.result.putIfAbsent(key, () => data[pos]);
            pos = pos + 1;
          case FrameFieldType.INT2:
            context.result.putIfAbsent(key, () => (data[pos] << 8) + data[pos+1]);
            pos = pos + 2;
          case FrameFieldType.INT3:
            context.result.putIfAbsent(key, () => (data[pos] << 16) + (data[pos+1] << 8) + data[pos+2]);
            pos = pos + 3;
          case FrameFieldType.INT4:
            context.result.putIfAbsent(key, () => (data[pos] << 24) + (data[pos+1] << 16) + (data[pos+2] << 8) + data[pos+3]);
            pos = pos + 4;
          default:
        }
      // @formatter:on
    });

    return pos;
  }
}

//CSAFE_PROP_SHORT_SET_CONFIG_CMDS
class CsafePropShortSetConfigCmdProcessor
    extends CsafeFrameContentBaseProcessor {
  Map<String, FrameFieldType>? fields;

  CsafePropShortSetConfigCmdProcessor(super.cmd, this.fields);

  @override
  int process(CsafeFrameProcessorContext context, IntList data, int start) {
    int cmd = data[start];
    assert(cmd == this.cmd);
    int pos = start;
    context.result.putIfAbsent(
        '0x${data[pos].toRadixString(16).padLeft(2, '0')}#$start',
        () => CSAFE_PROP_SHORT_SET_CONFIG_CMDS.values
            .firstWhere((en) => en.id == cmd)
            .toString());
    return pos;
  }
}

//CSAFE_PROP_SHORT_SET_DATA_CMDS
class CsafePropShortSetDataCmdProcessor extends CsafeFrameContentBaseProcessor {
  Map<String, FrameFieldType>? fields;

  CsafePropShortSetDataCmdProcessor(super.cmd, this.fields);

  @override
  int process(CsafeFrameProcessorContext context, IntList data, int start) {
    int cmd = data[start];
    assert(cmd == this.cmd);
    int pos = start;
    context.result.putIfAbsent(
        '0x${data[pos].toRadixString(16).padLeft(2, '0')}#$start',
        () => CSAFE_PROP_SHORT_SET_DATA_CMDS.values
            .firstWhere((en) => en.id == cmd)
            .toString());
    return pos;
  }
}

//CSAFE_PROP_LONG_SET_CONFIG_CMDS
class CsafePropLongSetConfigCmdProcessor
    extends CsafeFrameContentBaseProcessor {
  Map<String, FrameFieldType>? fields;

  CsafePropLongSetConfigCmdProcessor(super.cmd, this.fields);

  @override
  int process(CsafeFrameProcessorContext context, IntList data, int start) {
    int cmd = data[start];
    assert(cmd == this.cmd);
    int pos = start;
    context.result.putIfAbsent(
        '0x${data[pos].toRadixString(16).padLeft(2, '0')}#$start',
        () => CSAFE_PROP_LONG_SET_CONFIG_CMDS.values
            .firstWhere((en) => en.id == cmd)
            .toString());
    return pos;
  }
}
