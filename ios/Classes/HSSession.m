//
//  Session.m
//  SIPSample
//
//  Created by Joe Lepple on 5/1/15.
//  Copyright (c) 2015 PortSIP Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSSession.h"

@implementation HSSession

- (instancetype)init {
  self = [super init];
  if (self) {
    [self reset];
  }
  return self;
}

- (id)initWithSessionIdAndUUID:(long)sessionId
                      callUUID:(NSUUID *)uuid
                   remoteParty:(NSString *)remoteParty
                   displayName:(NSString *)displayName
                    videoState:(BOOL)video
                       callOut:(BOOL)outState {

  if (self = [super init]) {
    [self reset];
    _sessionId = sessionId;
    if (uuid == nil) {
      uuid = [NSUUID UUID];
    }
    _uuid = uuid;

    _orignalId = -1;
    _videoCall = video;
    _outgoing = outState;
  }

  return self;
}

- (void)reset {
    self.uuid = nil;
    self.groupUUID = nil;
    self.sessionId = -1;
    self.holdState = NO;
    self.sessionState = NO;
    self.conferenceState = NO;
    self.recvCallState = NO;
    self.isReferCall = NO;
    self.orignalId = -1;
    self.existEarlyMedia = NO;
    self.videoCall = NO;
    self.outgoing = NO;
    self.callKitAnswered = NO;
    self.callKitCompletionCallback = nil;
    self.screenShare =false;
}

@end

