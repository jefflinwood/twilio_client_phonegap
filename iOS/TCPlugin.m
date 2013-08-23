//
//  TCPlugin.h
//  Twilio Client plugin for PhoneGap / Cordova
//
//  Copyright 2012 Stevie Graham.
//

#import "TCPlugin.h"

@interface TCPlugin() {
    TCDevice     *_device;
    TCConnection *_connection;
    NSString     *_callback;
}

@property(nonatomic, strong) TCDevice     *device;
@property(nonatomic, strong) NSString     *callback;
@property(atomic, strong)    TCConnection *connection;
@property(atomic, strong)    UILocalNotification *ringNotification;

-(void)javascriptCallback:(NSString *)event;
-(void)javascriptCallback:(NSString *)event withArguments:(NSDictionary *)arguments;
-(void)javascriptErrorback:(NSError *)error;

@end

@implementation TCPlugin

@synthesize device     = _device;
@synthesize callback   = _callback;
@synthesize connection = _connection;
@synthesize ringNotification = _ringNotification;

# pragma mark device delegate method

-(void)device:(TCDevice *)device didStopListeningForIncomingConnections:(NSError *)error {
    [self javascriptErrorback:error];
}

-(void)device:(TCDevice *)device didReceiveIncomingConnection:(TCConnection *)connection {
    self.connection = connection;    
    [self javascriptCallback:@"onincoming"];
}

-(void)device:(TCDevice *)device didReceivePresenceUpdate:(TCPresenceEvent *)presenceEvent {
    NSString *available = [NSString stringWithFormat:@"%d", presenceEvent.isAvailable];
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:presenceEvent.name, @"from", available, @"available", nil];
    [self javascriptCallback:@"onpresence" withArguments:object];
}

-(void)deviceDidStartListeningForIncomingConnections:(TCDevice *)device {
    // What to do here? The JS library doesn't have an event for this.
}

# pragma mark connection delegate methods

-(void)connection:(TCConnection*)connection didFailWithError:(NSError*)error {
    [self javascriptErrorback:error];
}

-(void)connectionDidStartConnecting:(TCConnection*)connection {
    self.connection = connection;
    // What to do here? The JS library doesn't have an event for connection negotiation.
}

-(void)connectionDidConnect:(TCConnection*)connection {
    self.connection = connection;
    [self javascriptCallback:@"onconnect"];
    if([connection isIncoming]) [self javascriptCallback:@"onaccept"];
}

-(void)connectionDidDisconnect:(TCConnection*)connection {
    self.connection = connection;
    [self javascriptCallback:@"ondevicedisconnect"];
    [self javascriptCallback:@"onconnectiondisconnect"];
}

# pragma mark javascript device mapper methods

-(void)deviceSetup:(NSMutableArray *)arguments withDict:(NSMutableDictionary*)options {
    self.callback = [arguments pop];
    self.device = [[TCDevice alloc] initWithCapabilityToken:[arguments pop] delegate:self];
    
    // Disable sounds. was getting EXC_BAD_ACCESS
    //self.device.incomingSoundEnabled   = NO;
    //self.device.outgoingSoundEnabled   = NO;
    //self.device.disconnectSoundEnabled = NO;
    
    [self javascriptCallback:@"onready"];
}

-(void)connect:(NSArray *)arguments withDict:(NSMutableDictionary *)options {
    [self.device connect:options delegate:self];
}

-(void)disconnectAll:(NSArray *)arguments withDict:(NSMutableDictionary *)options {
    [self.device disconnectAll];
}

-(void)deviceStatus:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {
    NSString *state;
    switch ([self.device state]) {
        case TCDeviceStateBusy:
            state = @"busy";
            break;
            
        case TCDeviceStateReady:
            state = @"ready";
            break;
            
        case TCDeviceStateOffline:
            state = @"offline";
            break;
            
        default:
            break;        
    }
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:state];    
    [self performSelectorOnMainThread:@selector(writeJavascript:) withObject:[result toSuccessCallbackString:[arguments pop]] waitUntilDone:NO];
}


# pragma mark javascript connection mapper methods

-(void)acceptConnection:(NSArray *)arguments withDict:(NSMutableDictionary *)options {
    [self.connection accept];
}

-(void)disconnectConnection:(NSArray *)arguments withDict:(NSMutableDictionary *)options {
    [self.connection disconnect];
}

-(void)rejectConnection:(NSArray *)arguments withDict:(NSMutableDictionary *)options {
    [self.connection reject];
}

-(void)muteConnection:(NSArray *)arguments withDict:(NSMutableDictionary *)options {
    if(self.connection.isMuted) {
        self.connection.muted = NO;
    } else {
        self.connection.muted = YES;
    }
}

-(void)sendDigits:(CDVInvokedUrlCommand*)command {
    [self.connection sendDigits:[command.arguments objectAtIndex:0]];
}

-(void)connectionStatus:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {
    NSString *state;
    switch ([self.connection state]) {
        case TCConnectionStateConnected:
            state = @"open";
            break;
            
        case TCConnectionStateConnecting:
            state = @"connecting";
            break;
            
        case TCConnectionStatePending:
            state = @"pending";
            break;
            
        case TCConnectionStateDisconnected:
            state = @"closed";
        
        default:
            break;        
    }
        
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:state];    
    [self performSelectorOnMainThread:@selector(writeJavascript:) withObject:[result toSuccessCallbackString:[arguments pop]] waitUntilDone:NO];
}


-(void)showNotification:(CDVInvokedUrlCommand*)command {
    @try {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
    @catch(NSException *exception) {
        NSLog(@"Couldn't Cancel Notification");
    }
    
    NSString *alertBody = [command.arguments objectAtIndex:0];
    
    NSString *ringSound = @"incoming.wav";
    if([command.arguments count] == 2) {
        ringSound = [command.arguments objectAtIndex:1];
    }

    _ringNotification = [[UILocalNotification alloc] init];
    _ringNotification.alertBody = alertBody;
    _ringNotification.alertAction = @"Answer";
    _ringNotification.soundName = ringSound;
    _ringNotification.fireDate = [NSDate date];
    [[UIApplication sharedApplication] scheduleLocalNotification:_ringNotification];

}

-(void)cancelNotification:(CDVInvokedUrlCommand*)command {
    [[UIApplication sharedApplication] cancelLocalNotification:_ringNotification];
}

-(void)setSpeaker:(CDVInvokedUrlCommand*)command {
    NSString *mode = [command.arguments objectAtIndex:0];
    if([mode isEqual: @"on"]) {
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (
            kAudioSessionProperty_OverrideAudioRoute,
            sizeof (audioRouteOverride),
            &audioRouteOverride
        );
    }
    else {
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
        AudioSessionSetProperty (
            kAudioSessionProperty_OverrideAudioRoute,
            sizeof (audioRouteOverride),
            &audioRouteOverride
        );
    }
}

# pragma mark private methods

-(void)javascriptCallback:(NSString *)event withArguments:(NSDictionary *)arguments {
    NSDictionary *options   = [NSDictionary dictionaryWithObjectsAndKeys:event, @"callback", arguments, @"arguments", nil];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:options];
    result.keepCallback     = [NSNumber numberWithBool:YES];
    
    [self performSelectorOnMainThread:@selector(writeJavascript:) withObject:[result toSuccessCallbackString:self.callback] waitUntilDone:NO];
}

-(void)javascriptCallback:(NSString *)event {
    [self javascriptCallback:event withArguments:nil];
}

-(void)javascriptErrorback:(NSError *)error {
    NSDictionary *object    = [NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], @"message", nil];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:object];
    result.keepCallback     = [NSNumber numberWithBool:YES];
    
    [self performSelectorOnMainThread:@selector(writeJavascript:) withObject:[result toErrorCallbackString:self.callback] waitUntilDone:NO];
}

@end