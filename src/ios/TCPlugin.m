//
//  TCPlugin.h
//  Twilio Client plugin for PhoneGap / Cordova
//
//  Copyright 2012 Stevie Graham.
//


#import "TCPlugin.h"
#import  <AVFoundation/AVFoundation.h>


@interface TCPlugin() {
    TCDevice     *_device;
    TCConnection *_connection;
    NSString     *_callback;
}

@property(nonatomic, strong)    TCDevice     *device;
@property(nonatomic, strong)    NSString     *callback;
@property(atomic, strong)       TCConnection *connection;
@property(atomic, strong)       UILocalNotification *ringNotification;
@property(atomic, strong)       NSTimer      *timer;
@property (nonatomic, assign)   NSInteger    *nbRepeats;

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

-(void)deviceSetup:(CDVInvokedUrlCommand*)command {
    self.callback = command.callbackId;
    _nbRepeats = 0;

    //if device hasn't been created, create with token. If it does, then update the capability token    
    if(!self.device) self.device = [[TCDevice alloc] initWithCapabilityToken:command.arguments[0] delegate:self];
    else [self.device updateCapabilityToken:command.arguments[0]];

    // Disable sounds. was getting EXC_BAD_ACCESS
    //self.device.incomingSoundEnabled   = NO;
    //self.device.outgoingSoundEnabled   = NO;
    //self.device.disconnectSoundEnabled = NO;

    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(deviceStatusEvent) userInfo:nil repeats:YES];
}

-(void)deviceStatusEvent {
    
    NSLog(@"Device state: %ld",(long) self.device.state);
    
    switch ([self.device state]) {
            
        case TCDeviceStateReady:
            [self javascriptCallback:@"onready"];
            NSLog(@"State: Ready");
            
            [_timer invalidate];
            _timer = nil;
            
            break;
            
        case TCDeviceStateOffline:
            [self javascriptCallback:@"onoffline"];
            NSLog(@"State: Offline");
            
            if ((long)_nbRepeats>20){
                
                [_timer invalidate];
                _timer = nil;
                _nbRepeats = 0;
            }
            else _nbRepeats++;
            
            break;
            
        default:
            
            [_timer invalidate];
            _timer = nil;
            
            break;
    }
}

-(void)connect:(CDVInvokedUrlCommand*)command {
    [self.device connect:[command.arguments objectAtIndex:0] delegate:self];
}

-(void)disconnectAll:(CDVInvokedUrlCommand*)command {
    [self.device disconnectAll];
}

-(void)deviceStatus:(CDVInvokedUrlCommand*)command {
    NSString *state;
    
    NSLog(@"Device state: %ld",(long) self.device.state);
    
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
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


# pragma mark javascript connection mapper methods

-(void)acceptConnection:(CDVInvokedUrlCommand*)command {
    [self.connection accept];
}

-(void)disconnectConnection:(CDVInvokedUrlCommand*)command {
    [self.connection disconnect];
}

-(void)rejectConnection:(CDVInvokedUrlCommand*)command {
    [self.connection reject];
}

-(void)muteConnection:(CDVInvokedUrlCommand*)command {
    if(self.connection.isMuted) {
        self.connection.muted = NO;
    } else {
        self.connection.muted = YES;
    }
}

-(void)sendDigits:(CDVInvokedUrlCommand*)command {
    [self.connection sendDigits:[command.arguments objectAtIndex:0]];
}

-(void)connectionStatus:(CDVInvokedUrlCommand*)command {
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
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void)connectionParameters:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self.connection parameters]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
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
    
    [self.commandDelegate sendPluginResult:result callbackId:self.callback];
}

-(void)javascriptCallback:(NSString *)event {
    [self javascriptCallback:event withArguments:nil];
}

-(void)javascriptErrorback:(NSError *)error {
    NSDictionary *object    = [NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], @"message", nil];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:object];
    result.keepCallback     = [NSNumber numberWithBool:YES];
    
    [self.commandDelegate sendPluginResult:result callbackId:self.callback];
}

@end
