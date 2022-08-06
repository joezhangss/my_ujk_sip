
import 'dart:async';

import 'package:flutter/services.dart';

///type：返回的数据类型。1：注册，2：拨号，3：挂机，4：开关扬声器
///resultMap:返回的数据。key：是否成功（1：成功，0：失败），value：返回的消息
typedef OnResultCallback = void Function(int type, Map<int, String> resultMap);

class MyUjkSip {
  static const MethodChannel _channel = MethodChannel('my_ujk_sip');

  //初始化数据
  static void initSource() {
    _channel.invokeMethod('initSource');
  }

  //释放资源
  static void disposeSource() {
    _channel.invokeMethod('disposeSource');
  }

  //注册用户
  ///dataMap[@"userName"];
  //dataMap[@"pwd"];
  //dataMap[@"sipServer"];
  //dataMap[@"port"];
  static Future<void> registerUser(Map<String, String> dataMap) async {
    await _channel.invokeMethod('registerUser', dataMap);
  }

  //开关扬声器
  static void speaker(bool isOpen) {
    _channel.invokeMethod('speaker', isOpen?1:0);
  }

  //开关扬声器
  static void callUser(String phone) {
    _channel.invokeMethod('callUser', phone);
  }

  //是否静音（开关麦克风）
  static void toggleMicro(bool isMute) {
    _channel.invokeMethod('toggleMicro', isMute?1:0);
  }

  //挂机
  static void hangUp() {
    _channel.invokeMethod('hangUp');
  }

  static void onResult(OnResultCallback onResultCallback){
    _channel.setMethodCallHandler((call) async{
      Map map = call.arguments;
      Map<int, String> resultMap = {};
      map.forEach((key, value) {
        resultMap.putIfAbsent(key, () => value);
      });

      switch(call.method){
        case "registerUser":
        ///resultMap:返回的数据。key：是否成功（1：成功，0：失败），value：返回的消息
          onResultCallback(1, resultMap);
          break;
        case "callUser":
          //当前用户挂断电话没有回调
        ///resultMap:返回的数据。key：是否成功（1：成功，0：失败, 2:通话结束），value：返回的消息
          onResultCallback(2, resultMap);
          break;
      }

      // onResultCallback(call);
    });
  }
}
