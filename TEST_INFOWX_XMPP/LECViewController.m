//
//  LECViewController.m
//  TEST_INFOWX_XMPP
//
//  Created by lecter on 14-9-10.
//  Copyright (c) 2014年 lecter. All rights reserved.
//

#import "LECViewController.h"
#import "XMPPFramework.h"
#import "NSData+Base64.h"

#define DEFAULT_LOGIN @"peng.gao@vision-info.com"
#define DEFAULT_USERNAME @"user1"
//@"10002"
#define DEFAULT_TOUSERNAME @"user2"
//@"10002"
#define DEFAULT_PASS @"111111"
//@"Qwer1234"
#define DEFAULT_SERVER @"127.0.0.1"
//@"175.102.130.42"
#define DEFAULT_SERVER_PORT 5222
#define DEFAULT_SERVER_NAME @"127.0.0.1"
//@"xue.vision-info.com"

#define DEFAULT_MSGCONTENT @"test"

@interface LECViewController ()

@property (strong, nonatomic) XMPPStream *xmppStream;
@property (assign, nonatomic) BOOL isXMPPConnected;

@end

@implementation LECViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _isXMPPConnected = NO;
    [self setupStream];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [self teardownStream];
}

#pragma mark - IBAction
- (IBAction)toLoginIn:(id)sender {
    if (_isXMPPConnected) {
        [self showCustomAlertView:@"账号已登陆！"];
        return;
    }
    
    [self connect];
}

- (IBAction)toLoginOut:(id)sender {
    if (!_isXMPPConnected) {
        [self showCustomAlertView:@"账号已登出！"];
        return;
    }
    
    [self disconnect];
}

- (IBAction)toSendText:(id)sender {
    if (!_isXMPPConnected) {
        [self showCustomAlertView:@"请先登陆！"];
        return;
    }
    
    //[self sendMessage:DEFAULT_MSGCONTENT];
    [self sendMessageWithFormat:DEFAULT_MSGCONTENT];
}

- (IBAction)toSendVoice:(id)sender {
    if (!_isXMPPConnected) {
        [self showCustomAlertView:@"请先登陆！"];
        return;
    }
    
    NSString *mp3Path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"];
    NSData *mp3Data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:mp3Path]];
    NSString *msgContent = [NSString stringWithFormat:@"[V]%@", [mp3Data base64EncodedString]];
    //[self sendMessage:msgContent];
    [self sendMessageWithFormat:msgContent];
}

#pragma mark - Function
- (void)sendMessage:(NSString *)msgContent
{
	NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
	[body setStringValue:msgContent];
	
	NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@@%@",DEFAULT_TOUSERNAME, DEFAULT_SERVER_NAME]];
    [message addAttributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@@%@",DEFAULT_USERNAME, DEFAULT_SERVER_NAME]];
	[message addChild:body];
	
	[_xmppStream sendElement:message];
}

/*
 <message type="chat" id="" to="10003@xue.vision-info.com">
 <properties xmlns="http://www.jivesoftware.com/xmlns/xmpp/properties">
 <property>
 <name>name</name>
 <value type="string">鹏</value>
 </property>
 <property>
 <name>lengtime</name>
 <value type="string">2.000000</value>
 </property>
 </properties>
 <request xmlns="renesola:xmpp:receipts"></request>
 </message>
 */

- (void)sendMessageWithFormat:(NSString *)msgContent
{
	NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
	[body setStringValue:msgContent];
    
    NSXMLElement *properties = [NSXMLElement elementWithName:@"properties"];
    [properties addAttributeWithName:@"xmlns" stringValue:@"http://www.jivesoftware.com/xmlns/xmpp/properties"];
    
    NSXMLElement *singleproperty = [NSXMLElement elementWithName:@"property"];
    NSXMLElement *name = [NSXMLElement elementWithName:@"name"];
    [name setStringValue:@"name"];
    NSXMLElement *namevalue = [NSXMLElement elementWithName:@"value"];
    //获取不到昵称以登录名替换
    [namevalue setStringValue:DEFAULT_LOGIN];
    [namevalue addAttributeWithName:@"type" stringValue:@"string"];
    [singleproperty addChild:name];
    [singleproperty addChild:namevalue];
    [properties addChild:singleproperty];
    
//    //如果有语音添加时间长度等参数
//    NSXMLElement *singleproperty = [NSXMLElement elementWithName:@"property"];
//    NSXMLElement *name = [NSXMLElement elementWithName:@"name"];
//    [name setStringValue:@"lengtime"];
//    NSXMLElement *namevalue = [NSXMLElement elementWithName:@"value"];
//    //获取不到昵称以登录名替换
//    [namevalue setStringValue:@"2.0"];
//    [namevalue addAttributeWithName:@"type" stringValue:@"string"];
//    [singleproperty addChild:name];
//    [singleproperty addChild:namevalue];
//    [properties addChild:singleproperty];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@@%@",DEFAULT_TOUSERNAME, DEFAULT_SERVER_NAME]];
    [message addAttributeWithName:@"id" stringValue:@""];
	[message addChild:body];
	
	[_xmppStream sendElement:message];
}

- (void)showCustomAlertView:(NSString *)strContent {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                        message:strContent
                                                       delegate:nil
                                              cancelButtonTitle:@"知道了"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)setupStream {
    _xmppStream = [[XMPPStream alloc] init];
    [_xmppStream setHostName:DEFAULT_SERVER];
    [_xmppStream setHostPort:DEFAULT_SERVER_PORT];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)teardownStream {
    [_xmppStream removeDelegate:self];
    [_xmppStream disconnect];
	_xmppStream = nil;
}

-(void)goOnline {
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"available"];
	[self.xmppStream sendElement:presence];
}

//发送下线通知
-(void)goOffline {
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	[self.xmppStream sendElement:presence];
}

- (BOOL)connect {
	if (![_xmppStream isDisconnected]) {
		return YES;
	}
    
	[_xmppStream setMyJID:[XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@",DEFAULT_USERNAME, DEFAULT_SERVER_NAME]]];
    
	NSError *error = nil;
	if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		NSLog(@"login ERROR:%@",error);
		return NO;
	}
    
    NSLog(@"login SUCCESS");
	return YES;
}

- (void)disconnect {
    [self goOffline];
	[_xmppStream disconnect];
}

#pragma mark XMPPStream Delegate
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	NSError *error = nil;
	if (![_xmppStream authenticateWithPassword:DEFAULT_PASS error:&error])
	{
		NSLog(@"login ERROR:%@",error);
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    _isXMPPConnected = NO;
    [self showCustomAlertView:@"登出成功！"];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    _isXMPPConnected = YES;
	[self goOnline];
    [self showCustomAlertView:@"登陆成功！"];
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    NSLog(@"send message SUCCESS:%@",message.body);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    NSLog(@"receive message SUCCESS:%@",message.body);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"接受到得消息"
                                                        message:message.body
                                                       delegate:nil
                                              cancelButtonTitle:@"知道了"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence {
    NSLog(@"send presence SUCCESS:%@",presence.status);
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    NSLog(@"receive presence SUCCESS:%@",presence.status);
}

@end
