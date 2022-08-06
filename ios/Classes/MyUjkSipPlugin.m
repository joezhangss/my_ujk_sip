#import "MyUjkSipPlugin.h"
#import <PortSIPVoIPSDK/PortSIPVoIPSDK.h>
#import <AudioToolbox/AudioToolbox.h>
#import "HSSession.h"
#import <CallKit/CallKit.h>

@interface MyUjkSipPlugin() <PortSIPEventDelegate>
{
    PortSIPSDK* portSIPSDK;
//    BOOL sipInitialized;
    CXCallController *_callController;
    HSSession *session;
//    FlutterResult _globalResult;
}
@property (nonatomic, strong) FlutterMethodChannel *callbackChannel;

@end

@implementation MyUjkSipPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"my_ujk_sip"
            binaryMessenger:[registrar messenger]];
    
  MyUjkSipPlugin* instance = [[MyUjkSipPlugin alloc] initWithRegistrar:registrar methodChannel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
    
}

- (instancetype)initWithRegistrar: (NSObject<FlutterPluginRegistrar> *) registrar methodChannel:(FlutterMethodChannel *) flutterMethodChannel
{
    self = [super init];
    self.callbackChannel = flutterMethodChannel;
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

//  _globalResult = result;

  if ([@"initSource" isEqualToString:call.method]) {
        portSIPSDK = [[PortSIPSDK alloc] init];
        portSIPSDK.delegate = self;

        _callController = [[CXCallController alloc] init];
  //    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    else if ([@"disposeSource" isEqualToString:call.method])
    {
        [portSIPSDK unRegisterServer];
        [NSThread sleepForTimeInterval:1.0];
  //      sipInitialized = NO;
        [portSIPSDK unInitialize];//释放资源
        [portSIPSDK removeUser];//删除当前账号信息

  //    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    else if ([@"registerUser" isEqualToString:call.method])
    {
        //上线sip
        [self registerUser: call.arguments];
    }
    else if ([@"callUser" isEqualToString:call.method])
    {
        //拨号
        [self callUserAction:call.arguments];
    }
    else if ([@"speaker" isEqualToString:call.method])
    {
        int type = [call.arguments intValue];
        //开关扬声器
        [portSIPSDK setLoudspeakerStatus:type==1?YES:NO];//关闭扬声器
    }
    else if ([@"hangUp" isEqualToString:call.method])
    {
        //挂机
        [portSIPSDK hangUp:session.sessionId];
    }
    else {
      result(FlutterMethodNotImplemented);
    }
}

#pragma mark - 拨号
- (void)callUserAction:(NSString *)phone{
    long sessionId = [portSIPSDK call:phone sendSdp:TRUE videoCall:NO];
    BOOL sa = [portSIPSDK startAudio];
    NSLog(@"打开audio》》》%d", sa?1:0);
    
    if (sessionId <= 0) {

    }else{
        session = [[HSSession alloc] initWithSessionIdAndUUID:sessionId
                                                     callUUID:nil
                                                  remoteParty:phone
                                                  displayName:phone
                                                   videoState: NO
                                                      callOut:YES];
    }

//    if (@available(iOS 10.0, *)) {
        CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value: phone];

        CXStartCallAction *startCallAction =
        [[CXStartCallAction alloc] initWithCallUUID:session.uuid handle:handle];

        startCallAction.video = NO;

        CXTransaction *transcation = [[CXTransaction alloc] init];
        for (CXAction *action in @[ startCallAction ]) {
            [transcation addAction:action];
        }

        [_callController requestTransaction:transcation completion:^(NSError *_Nullable error) {
            if (error != nil) {
                NSLog(@"Error requesting transaction, code:%ld error:%@",
                      (long)error.code, error.domain);
            } else {
                NSLog(@"Requested transaction successfully");
            }
        }];
//    } else {
//        // Fallback on earlier versions
//    }

    // Fallback on earlier versions


}

#pragma mark - 上线sip
- (void)registerUser:(NSDictionary *)dataMap{


    TRANSPORT_TYPE transport = TRANSPORT_UDP; // TRANSPORT_TCP


    SRTP_POLICY srtp = SRTP_POLICY_NONE;

    NSString *kUserName = dataMap[@"userName"];
    NSString *kDisplayName = dataMap[@"userName"];
    NSString *kAuthName = @"";
    NSString *kPassword = dataMap[@"pwd"];
    NSString *kUserDomain = @"";
    NSString *kSIPServer = dataMap[@"sipServer"];
    int kSIPServerPort = [dataMap[@"port"] intValue];

    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:kUserName forKey:@"kUserName"];
    [settings setObject:kAuthName forKey:@"kAuthName"];
    [settings setObject:kPassword forKey:@"kPassword"];
    [settings setObject:kUserDomain forKey:@"kUserDomain"];
    [settings setObject:kSIPServer forKey:@"kSIPServer"];
    [settings setObject:dataMap[@"port"] forKey:@"kSIPServerPort"];
    [settings setInteger:transport forKey:@"kTRANSPORT"];

    int localSIPPort = 5000 + arc4random() % 2000; // local port range 5k-7k
    NSString *loaclIPaddress = @"0.0.0.0";         // Auto select IP address

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    int ret = [portSIPSDK initialize:transport
                             localIP:loaclIPaddress
                        localSIPPort:localSIPPort
                            loglevel:PORTSIP_LOG_DEBUG
                             logPath:documentsDirectory
                             maxLine:8
                               agent:@"PortSIP SDK for IOS"
                    audioDeviceLayer:0
                    videoDeviceLayer:0
             TLSCertificatesRootPath:@""
                       TLSCipherList:@""
                verifyTLSCertificate:NO
                          dnsServers:@""];
    if (ret != 0) {
      NSLog(@"initialize failure ErrorCode = %d", ret);
      return;
    }

    ret = [portSIPSDK setUser:kUserName
                  displayName:kDisplayName
                     authName:kAuthName
                     password:kPassword
                   userDomain:kUserDomain
                    SIPServer:kSIPServer
                SIPServerPort:kSIPServerPort
                   STUNServer:@""
               STUNServerPort:0
               outboundServer:@""
           outboundServerPort:0];

    if (ret != 0) {
      NSLog(@"setUser failure ErrorCode = %d", ret);
      return;
    }

    int rt = [portSIPSDK setLicenseKey:@"PORTSIP_TEST_LICENSE"];
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateBackground) {
      NSLog(@"setLicenseKey %d", rt);
    } else {
      if (rt == ECoreTrialVersionLicenseKey) {
//           [self showAlertView:@"This trial version SDK just allows short "
//           @"conversation, you can't heairng anyting after "
//           @"2-3 minutes, contact us: sales@portsip.com to "
//           @"buy official version."];
          NSLog(@"setLicenseKey failure ErrorCode = %d", rt);
      } else if (rt == ECoreWrongLicenseKey) {
//         [self showAlertView:@"The wrong license key was detected, please check "
//         @"with sales@portsip.com or support@portsip.com"];
        NSLog(@"setLicenseKey failure ErrorCode = %d", rt);
        return;
      } else if (rt == ECoreTrialVersionExpired) {
//          [self showAlertView:@"This trial version SDK has expired, please "
//          @"download new version at "
//          @"http://www.portsip.com/downloads.html."];
        NSLog(@"setLicenseKey failure ErrorCode = %d", rt);
        return;
      }
    }

    [portSIPSDK addAudioCodec:AUDIOCODEC_OPUS];
    [portSIPSDK addAudioCodec:AUDIOCODEC_G729];
    [portSIPSDK addAudioCodec:AUDIOCODEC_PCMA];
    [portSIPSDK addAudioCodec:AUDIOCODEC_PCMU];

    [portSIPSDK addVideoCodec:VIDEO_CODEC_H264];

    [portSIPSDK setVideoBitrate:-1
                    bitrateKbps:500]; // Default video send bitrate,500kbps
    [portSIPSDK setVideoFrameRate:-1 frameRate:10]; // Default video frame rate,10
    [portSIPSDK setVideoResolution:352 height:288];
    [portSIPSDK setAudioSamples:20 maxPtime:60]; // ptime 20

    [portSIPSDK setInstanceId:[[[UIDevice currentDevice] identifierForVendor]
                                  UUIDString]];

    // 1 - FrontCamra 0 - BackCamra
    [portSIPSDK setVideoDeviceId:1];

    // enable video RTCP nack
    [portSIPSDK setVideoNackStatus:YES];

    // enable srtp
    [portSIPSDK setSrtpPolicy:srtp];

    // Try to register the default identity.
    // Registration refreshment interval is 90 seconds
    ret = [portSIPSDK registerServer:90 retryTimes:0];
    if (ret != 0) {
      [portSIPSDK unInitialize];
      NSLog(@"registerServer failure ErrorCode = %d", ret);
      return;
    }

    if (transport == TRANSPORT_TCP || transport == TRANSPORT_TLS) {
      [portSIPSDK setKeepAliveTime:0];
    }

    NSString *sipURL = nil;
    if (kSIPServerPort == 5060)
      sipURL =
          [[NSString alloc] initWithFormat:@"sip:%@:%@", kUserName, kUserDomain];
    else
      sipURL = [[NSString alloc]
          initWithFormat:@"sip:%@:%@:%d", kUserName, kUserDomain, kSIPServerPort];
}

- (void)onACTVTransferFailure:(long)sessionId reason:(char *)reason code:(int)code {
    NSLog(@"c7777777777");
}

- (void)onACTVTransferSuccess:(long)sessionId {
    NSLog(@"c6666666666");
}

- (void)onAudioRawCallback:(long)sessionId audioCallbackMode:(int)audioCallbackMode data:(unsigned char *)data dataLength:(int)dataLength samplingFreqHz:(int)samplingFreqHz {
    NSLog(@"c555555555555");
}

- (void)onDialogStateUpdated:(char *)BLFMonitoredUri BLFDialogState:(char *)BLFDialogState BLFDialogId:(char *)BLFDialogId BLFDialogDirection:(char *)BLFDialogDirection {
    NSLog(@"c4444444444");
}

#pragma mark - 接通了
- (void)onInviteAnswered:(long)sessionId callerDisplayName:(char *)callerDisplayName caller:(char *)caller calleeDisplayName:(char *)calleeDisplayName callee:(char *)callee audioCodecs:(char *)audioCodecs videoCodecs:(char *)videoCodecs existsAudio:(BOOL)existsAudio existsVideo:(BOOL)existsVideo sipMessage:(char *)sipMessage {
    [self.callbackChannel invokeMethod:@"callUser" arguments:@{@1: [NSString stringWithFormat:@"%s", sipMessage]}];
    NSLog(@"接通了：callerDisplayName==%s,caller==%s,callee==%s",callerDisplayName,caller,callee);
}

- (void)onInviteBeginingForward:(char *)forwardTo {
    NSLog(@"c2222222222");
}

#pragma mark - 对方挂断
- (void)onInviteClosed:(long)sessionId sipMessage:(char *)sipMessage {
    NSLog(@"c111111");
    [self.callbackChannel invokeMethod:@"callUser" arguments:@{@2: [NSString stringWithFormat:@"%s", sipMessage]}];
}

#pragma mark - 连接成功
- (void)onInviteConnected:(long)sessionId {
    NSLog(@"连接成功：b99999999999");
}

#pragma mark - 拨号失败
- (void)onInviteFailure:(long)sessionId reason:(char *)reason code:(int)code sipMessage:(char *)sipMessage {
    [self.callbackChannel invokeMethod:@"callUser" arguments:@{@0: [NSString stringWithFormat:@"%s", sipMessage]}];
    NSLog(@"拨号失败：b88888888==%s, %s", reason, sipMessage);
}

- (void)onInviteIncoming:(long)sessionId callerDisplayName:(char *)callerDisplayName caller:(char *)caller calleeDisplayName:(char *)calleeDisplayName callee:(char *)callee audioCodecs:(char *)audioCodecs videoCodecs:(char *)videoCodecs existsAudio:(BOOL)existsAudio existsVideo:(BOOL)existsVideo sipMessage:(char *)sipMessage {
    NSLog(@"b777777777777");
}

- (void)onInviteRinging:(long)sessionId statusText:(char *)statusText statusCode:(int)statusCode sipMessage:(char *)sipMessage {
    NSLog(@"b66666666666");
}

#pragma mark - 呼叫中
- (void)onInviteSessionProgress:(long)sessionId audioCodecs:(char *)audioCodecs videoCodecs:(char *)videoCodecs existsEarlyMedia:(BOOL)existsEarlyMedia existsAudio:(BOOL)existsAudio existsVideo:(BOOL)existsVideo sipMessage:(char *)sipMessage {
    NSLog(@"呼叫中：b5555555555==%s,%s",sipMessage, audioCodecs);
}

#pragma mark - 发起呼叫
- (void)onInviteTrying:(long)sessionId {
    NSLog(@"发起呼叫：b444444444==%ld",sessionId);
}

- (void)onInviteUpdated:(long)sessionId audioCodecs:(char *)audioCodecs videoCodecs:(char *)videoCodecs screenCodecs:(char *)screenCodecs existsAudio:(BOOL)existsAudio existsVideo:(BOOL)existsVideo existsScreen:(BOOL)existsScreen sipMessage:(char *)sipMessage {
    NSLog(@"b3333333333");
}

- (void)onPlayAudioFileFinished:(long)sessionId fileName:(char *)fileName {
    NSLog(@"b222222222");
}

- (void)onPlayVideoFileFinished:(long)sessionId {
    NSLog(@"b111111111");
}

- (void)onPresenceOffline:(char *)fromDisplayName from:(char *)from {
    NSLog(@"a99999999999");
}

- (void)onPresenceOnline:(char *)fromDisplayName from:(char *)from stateText:(char *)stateText {
    NSLog(@"a888888888888");
}

- (void)onPresenceRecvSubscribe:(long)subscribeId fromDisplayName:(char *)fromDisplayName from:(char *)from subject:(char *)subject {
    NSLog(@"a77777777777");
}

- (void)onRTPPacketCallback:(long)sessionId mediaType:(int)mediaType direction:(DIRECTION_MODE)direction RTPPacket:(unsigned char *)RTPPacket packetSize:(int)packetSize {
    NSLog(@"a666666666");
}

- (void)onReceivedRefer:(long)sessionId referId:(long)referId to:(char *)to from:(char *)from referSipMessage:(char *)referSipMessage {
    NSLog(@"a555555555");
}

- (void)onReceivedSignaling:(long)sessionId message:(char *)message {
    NSLog(@"a4444444444");
}

- (void)onRecvDtmfTone:(long)sessionId tone:(int)tone {
    NSLog(@"a3333333");
}

- (void)onRecvInfo:(char *)infoMessage {
    NSLog(@"a22222222");
}

- (void)onRecvMessage:(long)sessionId mimeType:(char *)mimeType subMimeType:(char *)subMimeType messageData:(unsigned char *)messageData messageDataLength:(int)messageDataLength {
    NSLog(@"a1111111");
}

- (void)onRecvNotifyOfSubscription:(long)subscribeId notifyMessage:(char *)notifyMessage messageData:(unsigned char *)messageData messageDataLength:(int)messageDataLength {
    NSLog(@"011011011011011");
}

- (void)onRecvOptions:(char *)optionsMessage {
    NSLog(@"0909090909090909");
}

- (void)onRecvOutOfDialogMessage:(char *)fromDisplayName from:(char *)from toDisplayName:(char *)toDisplayName to:(char *)to mimeType:(char *)mimeType subMimeType:(char *)subMimeType messageData:(unsigned char *)messageData messageDataLength:(int)messageDataLength sipMessage:(char *)sipMessage {
    NSLog(@"080808080808");
}

- (void)onReferAccepted:(long)sessionId {
    NSLog(@"07070707070707");
}

- (void)onReferRejected:(long)sessionId reason:(char *)reason code:(int)code {
    NSLog(@"06060606060606");
}

- (void)onRegisterFailure:(char *)statusText statusCode:(int)statusCode sipMessage:(char *)sipMessage {
    NSLog(@"05050505050505==%s",sipMessage);
}

#pragma mark - 注册成功
- (void)onRegisterSuccess:(char *)statusText statusCode:(int)statusCode sipMessage:(char *)sipMessage {
    [self.callbackChannel invokeMethod:@"registerUser" arguments:@{@1: [NSString stringWithFormat:@"%s", sipMessage]}];
    NSLog(@"注册成功：e1111111111111==%s",sipMessage);
}

- (void)onRemoteHold:(long)sessionId {
    NSLog(@"040404040404");
}

- (void)onRemoteUnHold:(long)sessionId audioCodecs:(char *)audioCodecs videoCodecs:(char *)videoCodecs existsAudio:(BOOL)existsAudio existsVideo:(BOOL)existsVideo {
    NSLog(@"030303030303");
}

- (void)onSendMessageFailure:(long)sessionId messageId:(long)messageId reason:(char *)reason code:(int)code sipMessage:(char *)sipMessage {
    NSLog(@"0202020202");
}

- (void)onSendMessageSuccess:(long)sessionId messageId:(long)messageId sipMessage:(char *)sipMessage {
    NSLog(@"0101010101");
}

- (void)onSendOutOfDialogMessageFailure:(long)messageId fromDisplayName:(char *)fromDisplayName from:(char *)from toDisplayName:(char *)toDisplayName to:(char *)to reason:(char *)reason code:(int)code sipMessage:(char *)sipMessage {
    NSLog(@"0000000");
}

- (void)onSendOutOfDialogMessageSuccess:(long)messageId fromDisplayName:(char *)fromDisplayName from:(char *)from toDisplayName:(char *)toDisplayName to:(char *)to sipMessage:(char *)sipMessage {
    NSLog(@"99999999");
}

- (void)onSendingSignaling:(long)sessionId message:(char *)message {
    NSLog(@"8888888");
}

- (void)onSubscriptionFailure:(long)subscribeId statusCode:(int)statusCode {
    NSLog(@"7777777");
}

- (void)onSubscriptionTerminated:(long)subscribeId {
    NSLog(@"666666");
}

- (void)onTransferRinging:(long)sessionId {
    NSLog(@"5555");
}

- (void)onTransferTrying:(long)sessionId {
    NSLog(@"4444");
}

- (int)onVideoRawCallback:(long)sessionId videoCallbackMode:(int)videoCallbackMode width:(int)width height:(int)height data:(unsigned char *)data dataLength:(int)dataLength {
    NSLog(@"3333");
    return 0;
}

- (void)onWaitingFaxMessage:(char *)messageAccount urgentNewMessageCount:(int)urgentNewMessageCount urgentOldMessageCount:(int)urgentOldMessageCount newMessageCount:(int)newMessageCount oldMessageCount:(int)oldMessageCount {
    NSLog(@"2222");
}

- (void)onWaitingVoiceMessage:(char *)messageAccount urgentNewMessageCount:(int)urgentNewMessageCount urgentOldMessageCount:(int)urgentOldMessageCount newMessageCount:(int)newMessageCount oldMessageCount:(int)oldMessageCount {
    NSLog(@"111111");
}

@end
