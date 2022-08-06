package com.ujk.my_ujk_sip;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import easyphone.EasyLinphone;
import easyphone.callback.PhoneCallback;
import easyphone.callback.RegistrationCallback;
import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** MyUjkSipPlugin */
public class MyUjkSipPlugin implements FlutterPlugin, MethodCallHandler {//extends RegistrationCallback
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context applicationContext;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "my_ujk_sip");
    channel.setMethodCallHandler(this);
    applicationContext = flutterPluginBinding.getApplicationContext();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("registerUser")) {
//      Log.e("注册：",call.arguments.toString());
      String server = call.argument("sipServer").toString() +":"+ call.argument("port").toString();
      EasyLinphone.setAccount(call.argument("userName"), call.argument("pwd"), server);
//      Log.e("注册：","开始注册了哦。。");
      EasyLinphone.login();
//      Log.e("注册：","完成注册了哦。。");
//      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }
    else if (call.method.equals("hangUp")) {
      EasyLinphone.hangUp();
//      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }
    else if (call.method.equals("speaker"))
    {
      int speakerNum = Integer.parseInt(call.arguments.toString());
      EasyLinphone.toggleSpeaker(speakerNum==1);
    }

    else if (call.method.equals("initSource"))
    {
      EasyLinphone.startService(applicationContext);
      EasyLinphone.addCallback(
              new RegistrationCallback() {
                @Override
                public void registrationNone() {
                  super.registrationNone();
                  Log.e("注册log", "registrationNone>>>>");
                }

                @Override
                public void registrationProgress() {
                  super.registrationProgress();
                  Log.e("注册log", "registrationProgress>>>>");
                }

                @Override
                public void registrationOk() {
                  super.registrationOk();
                  Log.e("注册log", "registrationOk>>>>");
                  HashMap<Integer, String> Sites = new HashMap<Integer, String>();
                  // 添加键值对
                  Sites.put(1, "注册成功！");
                  channel.invokeMethod("registerUser", Sites);
                }

                @Override
                public void registrationCleared() {
                  super.registrationCleared();
                  Log.e("注册log", "registrationCleared>>>>");
                }

                @Override
                public void registrationFailed() {
                  super.registrationFailed();
                  Log.e("注册log", "registrationFailed>>>>");
                  HashMap<Integer, String> Sites = new HashMap<Integer, String>();
                  // 添加键值对
                  Sites.put(0, "注册失败！");
                  channel.invokeMethod("registerUser", Sites);
                }
              },
              new PhoneCallback() {
                @Override
                public void outgoingInit() {
                  super.outgoingInit();
                  Log.e("拨号log", "outgoingInit>>>>");
                }

                @Override
                public void callReleased() {
                  super.callReleased();
                  Log.e("拨号log", "callReleased>>>>");
                }

                @Override
                public void callConnected() {
                  super.callConnected();
                  Log.e("拨号log", "callConnected>>>>");
                  HashMap<Integer, String> Sites = new HashMap<Integer, String>();
                  // 添加键值对
                  Sites.put(1, "电话接通！");
                  channel.invokeMethod("callUser", Sites);
                }

                @Override
                public void callEnd() {
                  super.callEnd();
                  Log.e("拨号log", "callEnd>>>>");
                  HashMap<Integer, String> Sites = new HashMap<Integer, String>();
                  // 添加键值对
                  Sites.put(2, "电话接通！");
                  channel.invokeMethod("callUser", Sites);
                }

                @Override
                public void error() {
                  super.error();
                  Log.e("拨号log", "error>>>>");
                  HashMap<Integer, String> Sites = new HashMap<Integer, String>();
                  // 添加键值对
                  Sites.put(0, "电话失败！");
                  channel.invokeMethod("callUser", Sites);
                }
              }
      );
    }
    else if (call.method.equals("disposeSource")) {
      EasyLinphone.onDestroy();
    }
    else if (call.method.equals("callUser"))
    {
      Log.e("呼叫号码》》",call.arguments.toString());
      EasyLinphone.callTo(call.arguments.toString(), false);
//      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }

    else if (call.method.equals("toggleMicro"))
    {
      //是否静音
      int microNum = Integer.parseInt(call.arguments.toString());
      EasyLinphone.toggleMicro(microNum==1);
//      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }
    else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

//  @Override
//  public void registrationOk() {
//    super.registrationOk();
//    Log.e("注册log", "registrationOk>>>>");
//    HashMap<Integer, String> Sites = new HashMap<Integer, String>();
//    // 添加键值对
//    Sites.put(1, "注册成功！");
//    channel.invokeMethod("registerUser", Sites);
//  }
//
//  @Override
//  public void registrationFailed() {
//    super.registrationFailed();
//    Log.e("注册log", "registrationFailed>>>>");
//    HashMap<Integer, String> Sites = new HashMap<Integer, String>();
//    // 添加键值对
//    Sites.put(0, "注册失败！");
//    channel.invokeMethod("registerUser", Sites);
//  }
//
//  @Override
//  public void registrationNone() {
//    super.registrationNone();
//    Log.e("注册log", "registrationNone>>>>");
//  }
//
//  @Override
//  public void registrationCleared() {
//    super.registrationCleared();
//    Log.e("注册log", "registrationCleared>>>>");
//  }
//
//  @Override
//  public void registrationProgress() {
//    super.registrationProgress();
//    Log.e("注册log", "registrationProgress>>>>");
//  }
}
