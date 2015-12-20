//
//  AppDelegate.m
//  Boku
//
//  Created by Ashish Sharma on 28/07/15.
//  Copyright (c) 2015 Plural Voice. All rights reserved.
//

#import "AppDelegate.h"
#import "AlertView.h" 
#import "LoaderView.h"
#import "VerifyOtpVC.h"
#import "AddBusinessAccountVC.h"
#import "CreateProfileVC.h"
#import "OTP.h"
#import "DBConnect.h"
#import "BokuViewController.h"
#import "MenuVC.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"
#import "SIPService.h"

#import <DBChooser/DBChooser.h>
#import "ContactsVC.h"
#import "BokuNavVC.h"
#import "SingleChatVC.h"
#import "ContactsBokuNavVC.h"
#import "PushTopView.h"
#import "MediaUploading.h"
#import "Reachable.h"
#import "Media.h"
#import "CommonFunctions.h"
#import <Crittercism/Crittercism.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import "KINotificationView.h"
#import "ChatVC.h"
#import "GroupChatVC.h"
#import "XMPPRoomMembers.h"


@interface AppDelegate ()<MediaUploadDelegate> {
    CTCallCenter *callCenter;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    dispatchCounter = 0;
    
    [Crittercism enableWithAppID:@"5626449ed224ac0a00ed40c1"];
    
    //Createing MultiCast Delegate Object
    self.multiCastDelegate = (KIPLMultiCastDelegate <AppUtilityDelegate> *)[[KIPLMultiCastDelegate alloc] init];
    
    self.service = [[GTLServiceDrive alloc] init];
    self.service.authorizer =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientID
                                                      clientSecret:kClientSecret];
    
    reachable = [[Reachable alloc] init];
    [reachable setUPReachable];
    
    if ([CommonFunctions networkConnectionAvailability]) {
        self.mediaUploading = [[MediaUploading alloc] init];
        self.mediaUploading.delegate = self;
    }
    
    NSLog(@"deviceToken is %@",[CommonFunctions getUserDefaultValue:@"deviceToken"]);
    
    //Keyboardframe change notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChangedFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    //Keyboard hide notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkOnline) name:BokuNetworkReachableNotify object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkOffline) name:BokuNetworkUnReachableNotify object:nil];
    
    
    //Keyboard show notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processMessageNotification:) name:BokuPushTapNotification object:nil];
    
    //pushViewHideNotification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hidePushView) name:BokuPushViewHideNotification object:nil];
    
    
    NSLog(@"%@",[UIFont fontNamesForFamilyName:@"Gentona"]);
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    [[UINavigationBar appearance] setBarTintColor:UIColorFromRedGreenBlue(0.f, 171.f, 234.f)];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Gentona-Light" size:18.f],NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    
    //Registering for Push Notification
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }else{
        //Registering Application for Push Notification
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    
    //Keeping weak reference of NavigationController
    _containerController = self.window.rootViewController;
    
    
    
    //AlertView Initialization
    self.alert = [[AlertView alloc] init];
    
    
    //Loader Initialization
    self.loader = [[LoaderView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    
    /**
     *  Database handler shared singleton entity
     */
    self.databaseHandler = [DBConnect sharedInstance];
    
    
    //XMPP Streaming object allocation
    self.xmppDelegate = [[XMPPDelegate alloc] init];
    
    [self.xmppDelegate setupStream];
    
    _sipService = [[SIPService alloc] init];
    
    //Contacts Authorization check and fetch Contacts
    if ([CommonFunctions isBKAuthorizedForAddressBookWithCompletionBlock:AddressBookCompletionHandler]) {
        dispatch_queue_t myQueue = dispatch_queue_create("CONTACTS_DISPATCH",NULL);
        dispatch_async(myQueue, ^{
            //Calling Contacts
            [[Contacts sharedInstance] BKContactsWithAddressBook];
        });
    }
    
    
    NSLog(@"app status is %d",[(NSNumber *)[CommonFunctions getUserDefaultValue:@"app_status"] intValue]);
    
    
    NSDictionary *dictPushNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if ( dictPushNotification )
    {
        application.applicationIconBadgeNumber = [[[dictPushNotification valueForKey:@"aps"] valueForKey:@"badge"]integerValue];
        NSLog(@"remote notification is %@",dictPushNotification);
        
        NSLog(@"user logged in with push notification");
    }
    
    
    //Deciding Landing Screen
    if ([CommonFunctions getUserDefaultValue:@"app_status"]) {
        BOKU_APP_STATUS appStatus = [(NSNumber *)[CommonFunctions getUserDefaultValue:@"app_status"] intValue];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        if (appStatus == VERIFIED_OTP_PENDING) {
            
            VerifyOtpVC *vovc = [sb instantiateViewControllerWithIdentifier:@"VerifyOtpVC"];
            vovc.otp = [[OTP alloc] init];
            vovc.otp.systemOTP = [CommonFunctions getUserDefaultValue:@"otp"];
            vovc.otp.systemOTPID = [CommonFunctions getUserDefaultValue:@"otp_id"];
            
            id containerController = self.window.rootViewController;
            if ([containerController isKindOfClass:[UINavigationController class]]) {
                UINavigationController* navContainerController = (UINavigationController *)self.window.rootViewController;
                [navContainerController pushViewController:vovc animated:NO];
            }
            
            
            
        }else if (appStatus == CREATE_PROFILE_PENDING){
            CreateProfileVC *cpvc = [sb instantiateViewControllerWithIdentifier:@"CreateProfileVC"];
            id containerController = self.window.rootViewController;
            if ([containerController isKindOfClass:[UINavigationController class]]) {
                UINavigationController* navContainerController = (UINavigationController *)self.window.rootViewController;
                [navContainerController pushViewController:cpvc animated:NO];
            }
        }else if (appStatus == ADD_BUSINESS_ACCOUNT_PENDING){
            AddBusinessAccountVC *abavc = [sb instantiateViewControllerWithIdentifier:@"AddBusinessAccountVC"];
            id containerController = self.window.rootViewController;
            if ([containerController isKindOfClass:[UINavigationController class]]) {
                UINavigationController* navContainerController = (UINavigationController *)self.window.rootViewController;
                [navContainerController pushViewController:abavc animated:NO];
            }
        }else if([CommonFunctions getUserDefaultValue:@"token"] &&
                 ((NSString *)[CommonFunctions getUserDefaultValue:@"token"]).length>0){
            NSLog(@"token is  = %@",[CommonFunctions getUserDefaultValue:@"token"]);
            
            [_sipService setUserWithUsername:[CommonFunctions getUserDefaultValue:@"sip_username"] andPassword:[CommonFunctions getUserDefaultValue:@"sip_password"]];
            
            [self makeTabbarAsRootController:dictPushNotification];

        }
    }else if([CommonFunctions getUserDefaultValue:@"token"] &&
             ((NSString *)[CommonFunctions getUserDefaultValue:@"token"]).length>0){
        NSLog(@"token is  = %@",[CommonFunctions getUserDefaultValue:@"token"]);
        
        [_sipService setUserWithUsername:[CommonFunctions getUserDefaultValue:@"sip_username"] andPassword:[CommonFunctions getUserDefaultValue:@"sip_password"]];

        [self makeTabbarAsRootController:dictPushNotification];
    }
    
    callCenter = [[CTCallCenter alloc] init];
    __weak AppDelegate *weakSelf =self;
    callCenter.callEventHandler=^(CTCall* call){
        NSLog(@"%@", call.callState);
        if ([call.callState isEqualToString:@"CTCallStateIncoming"] || [call.callState isEqualToString:@"CTCallStateDialing"] ) {
            [weakSelf.sipService holdAllCall];
        }
        else if ([call.callState isEqualToString:@"CTCallStateDisconnected"]){
            sleep(6);
            [weakSelf.sipService unholdCall];
        }
    };
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    NSLog(@"applicationWillResignActive delegate");
    
    //Sending UnAvailable Presence
    if ([_xmppStream isConnected]) {
        [_xmppDelegate goOffline];
    }
    
    [_multiCastDelegate KIPLApplicationBecomeBackground];
    
    //Disable to save battery, or when you don't need incoming calls while APP is in background.
    //When you need background, TCP and TLS SIP transport is save battery, UDP takes more battery
    [_sipService.sipSDK startKeepAwake];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"applicationDidEnterBackground delegate");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    //Sending Foreground notification to each interested context
    
    NSLog(@"applicationWillEnterForeground delegate");
    
    //Sending Available Presence
    if ([_xmppStream isConnected]) {
        [_xmppDelegate goOnline];
    }
    
    [self keepMediaUploadingStreamingLive];
    
    [_multiCastDelegate KIPLApplicationBecomeForeground];
    
    [_sipService.sipSDK stopKeepAwake];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[DBChooser defaultChooser] handleOpenURL:url]) {
        // This was a Chooser response and handleOpenURL automatically ran the
        // completion block
        return YES;
    }
    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    application.applicationIconBadgeNumber = 0;
    
    NSLog(@"applicationDidBecomeActive delegate");
    
    if ([_xmppStream isConnected]) {
        [_xmppDelegate goOnline];
    }
    
    [self keepMediaUploadingStreamingLive];
    
    [_multiCastDelegate KIPLApplicationBecomeForeground];
    
    [_sipService.sipSDK stopKeepAwake];
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.mediaUploading = nil;
    
}

#pragma mark - Remote Notification Handler

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    NSString* strDeviceToken = [deviceToken description];
    strDeviceToken = [strDeviceToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    strDeviceToken = [strDeviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"device token is %@",strDeviceToken);
    //NSLog(@"device token is %@",strDeviceToken);
    [CommonFunctions setUserDefault:@"deviceToken" value:strDeviceToken];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
     
    NSLog(@"user info is %@",userInfo);
    
    UIApplicationState state = [application applicationState];
    // user tapped notification while app was in background
    if (state == UIApplicationStateInactive || state == UIApplicationStateBackground) {
        //Coming from Inactive / Background State
        
        
        
        NSString *message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        message = [CommonFunctions convertBokuUnicodeToEmoji:message];
        
        NSDictionary *dictUserInfo = [userInfo objectForKey:@"message_data"];
        
        if ([[dictUserInfo objectForKey:@"push_type"] isEqualToString:@"chat"]) {
            
            NSString *senderJID = [NSString stringWithFormat:@"%@@%@",[dictUserInfo objectForKey:@"jid"],CHAT_SERVER_IP];
            NSLog(@"sender JID == %@",senderJID);
            
            if (![senderJID isEqualToString:APPDELEGATE.xmppDelegate.currentContxtJID]) {
                
                //We received message and user is not on this sender chat window. now we proceed local notification for PushTopView.
                NSLog(@"not on chat window");
                
                if ([Contacts sharedInstance].isContactsContainerVerified) {
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.isToBeIgnored == %@ && SELF.bokuXMPPUserName MATCHES[cd] %@",[NSNumber numberWithBool:NO],[dictUserInfo objectForKey:@"jid"]];
                    
                    NSArray *arrContactsContainer;
                    [[Contacts sharedInstance] sharedContactsWeakReference:&arrContactsContainer];
                    
                    NSArray *arrFilteredContainer = [arrContactsContainer filteredArrayUsingPredicate:predicate];
                    
                    if (arrFilteredContainer.count>0) {
                        
                        Person *person = [arrFilteredContainer objectAtIndex:0];
                        
                        NSMutableDictionary *dictPush = [[NSMutableDictionary alloc] init];
                        
                        [dictPush setObject:message forKey:@"message"];
                        [dictPush setObject:[dictUserInfo objectForKey:@"jid"] forKey:@"jid"];
                        [dictPush setObject:@"chat" forKey:@"type"];
                        if (person.is_unknown_user) {
                            [dictPush setObject:person.bokuPhoneNo forKey:@"displayName"];
                        }else{
                            [dictPush setObject:person.displayName forKey:@"displayName"];
                        }
                        [dictPush setObject:person.bokuProfilePicURL forKey:@"picURL"];
                        
                        [self processMessageNotification:dictPush];
                        
                    }
                    
                }
            }
            
        }else if ([[dictUserInfo objectForKey:@"push_type"] isEqualToString:@"groupchat"]){
            
            //roomJIDStr should be room@conference.ip
            NSString *roomJIDStr = [dictUserInfo objectForKey:@"jid"];
            
            if (![roomJIDStr isEqualToString:APPDELEGATE.xmppDelegate.currentContxtJID]) {
                
                XMPPJID *roomJID = [XMPPJID jidWithString:roomJIDStr];
                XMPPRoom *xmppRoom = [_xmppMUC roomWithJID:roomJID];
                
                if (xmppRoom && [dictUserInfo objectForKey:@"member_jid"]) {
                    
                    //fromJIDUser should be user only (user@ip)
                    NSString *fromJIDUser = [dictUserInfo objectForKey:@"member_jid"];
                    
                    NSLog(@"fromJIDUser == %@",fromJIDUser);
                    XMPPRoomMembers *roomMember = [self roomMemberWithJID:[XMPPJID jidWithUser:fromJIDUser domain:CHAT_SERVER_IP resource:nil] inRoom:xmppRoom];
                    
                    
                    if (roomMember) {
                        
                        NSMutableDictionary *dictPush = [[NSMutableDictionary alloc] init];
                        
                        [dictPush setObject:message forKey:@"message"];
                        [dictPush setObject:roomJIDStr forKey:@"jid"];
                        [dictPush setObject:@"groupchat" forKey:@"type"];
                        
                        
                        if (roomMember.referenceObject && [roomMember.referenceObject isKindOfClass:[Person class]]) {
                            
                            //user is in contact list
                            Person *person = (Person *)roomMember.referenceObject;
                            [dictPush setObject:person.displayName forKey:@"displayName"];
                            [dictPush setObject:person.bokuProfilePicURL forKey:@"picURL"];
                            
                        }else if (roomMember.referenceObject && [roomMember.referenceObject isKindOfClass:[NSString class]]){
                            
                            //user is not in contact list we have displayName only
                            NSString *displayName = (NSString *)roomMember.referenceObject;
                            [dictPush setObject:displayName forKey:@"displayName"];
                            [dictPush setObject:@"" forKey:@"picURL"];
                            
                        }
                        
                        
                        [self processMessageNotification:dictPush];
                        
                    }
                }
                
            }
        }
        
        
    }else {
        //App is already in foreground mode
        
    }
    
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    NSLog(@"local user info is %@",notification.alertBody);
    
    if ([notification.alertBody rangeOfString:@"Call from"].location == NSNotFound) {
        [KINotificationView showPopUpOnView:[notification.userInfo objectForKey:@"displayName"] message:[notification.userInfo objectForKey:@"message"] imageUrl:[notification.userInfo objectForKey:@"picURL"] andDelegate:self data:notification.userInfo];
    }
}


#pragma mark- MediaUploading Delegate

-(void)mediaUploaded:(Media *)media{
    NSLog(@"media uploaded with identifier == %@",media.mediaIdentifier);
    
    NSMutableDictionary *dictMediaMetaData;
    if (media.mediaType == LOCATION_MEDIA) {
        
        dictMediaMetaData = [NSMutableDictionary dictionaryWithObjectsAndKeys:media.mediaURL,@"furl",
                             media.thumbURL,@"turl",nil];
        
    }else if(media.mediaType == VIDEO_MEDIA ||
             media.mediaType == IMAGE_MEDIA ){
        
        dictMediaMetaData = [NSMutableDictionary dictionaryWithObjectsAndKeys:media.mediaURL,@"furl",
                             media.thumbURL,@"turl",nil];
        
    }else if(media.mediaType == AUDIO_MEDIA){
        
        dictMediaMetaData = [NSMutableDictionary dictionaryWithObjectsAndKeys:media.mediaURL,@"furl",
                             media.thumbURL,@"turl",nil];
        
    }else{
        
        dictMediaMetaData = [NSMutableDictionary dictionaryWithObjectsAndKeys:media.mediaURL,@"furl",
                             media.thumbURL,@"turl",nil];
        
    }
    
    XMPPMessage *xmppMessage = media.xmppMessage;
    
    
    if (xmppMessage) {
        //If we have 
        //Save Media with media Identifer in relevant directory of User
        [CommonFunctions saveMedia:media bokuUser:media.bokuXMPPJID chatType:media.chatType];
        
        
        
        
        //Saving XMPPMessage , so it can also be updated in DB
        [dictMediaMetaData setObject:xmppMessage forKey:@"xmppMessage"];
        
        
        NSXMLElement *body = [xmppMessage elementForName:@"body"];
        
        
        //Identifiying xmppMessage and modifying it with MediaMetaData
        NSString *messageBody = body.stringValue;
        
        NSData *dataMessage = [messageBody dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        id messageCheck = [NSJSONSerialization JSONObjectWithData:dataMessage options:NSJSONReadingMutableContainers error:&error];
        
        if ([messageCheck isKindOfClass:[NSDictionary class]]) {
            
            NSMutableDictionary *dictMediaMetaData = (NSMutableDictionary *)messageCheck;
            [dictMediaMetaData setObject:media.mediaURL forKey:@"furl"];
            [dictMediaMetaData setObject:media.thumbURL forKey:@"turl"];
            
            
            NSData *dataMediaMetaData = [NSJSONSerialization dataWithJSONObject:dictMediaMetaData options:NSJSONWritingPrettyPrinted error:&error];
            NSString *strMessageBody = [[NSString alloc] initWithData:dataMediaMetaData encoding:NSUTF8StringEncoding];
            
            //[xmppMessage removeElementForName:@"body"];
            [body setStringValue:strMessageBody];
            
        }
        
        
        //Now we are again updating relevant message for Media Meta Data and update XMPPMessage
        [APPDELEGATE.xmppDelegate updateMessageForMetaDataWithUUID:media.mediaIdentifier mediaMetaData:dictMediaMetaData];
        
        if ([CommonFunctions networkConnectionAvailability] && [APPDELEGATE.xmppStream isConnected]) {
            
            //Sending this message will not create any new record , it will update relevant message record in DB.
            [APPDELEGATE.xmppStream sendElement:xmppMessage];
            
        }
        
    }
    
    
    
    //Now broadcasting Media Upload success , so relevant context can be updated.
    [_multiCastDelegate BokuMediaUploaded:media];
    
}

-(void)mediaUploadFailure:(Media *)media{
    
    //Broadcasting Media Upload failure, so relevant context can be updated.
    [_multiCastDelegate BokuMediaFailure:media];
    
}


#pragma mark - App Utility Methods

-(XMPPRoomMembers *)roomMemberWithJID:(XMPPJID *)memberJID inRoom:(XMPPRoom *)room{
    
    XMPPGroups *_group = room.groupRecord;
    if (_group) {
        
        NSSet *set = _group.members;
        if (set.count>0) {
            
            NSArray *arrMembers = [NSArray arrayWithArray:[set allObjects]];
            
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.jidStr == %@",memberJID.bare];
            
            NSArray *arrfilteredMembers = [arrMembers filteredArrayUsingPredicate:predicate];
            if (arrfilteredMembers.count>0) {
                XMPPRoomMembers *roomMember = [arrfilteredMembers objectAtIndex:0];
                return roomMember;
            }
            
        }
        
    }
    
    
    return nil;
}

/**
 *  Used to proceed OfflineMedias
 */
-(void)processOfflineMedias{
    NSFetchRequest  *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
    
    //This Stage we are going to collect all Offline Messages
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.offline == %@ AND SELF.outgoing == %@ AND SELF.status == %@",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],[NSString stringWithFormat:@"%d",MESSAGE_NOT_SENT]];
    
    fetchRequest.predicate = predicate;
    
    NSError *error;
    NSManagedObjectContext *messageContext = [APPDELEGATE.xmppDelegate managedObjectContext_Messages];
    NSArray *arrOfflineMessages = [messageContext executeFetchRequest:fetchRequest error:&error];
    if(arrOfflineMessages){
        for(int counter = 0;counter<arrOfflineMessages.count;counter++){
            
            NSLog(@"counter == %d",counter);
            
            XMPPMessageArchiving_Message_CoreDataObject *coreObject = [arrOfflineMessages objectAtIndex:counter];
            
            if ([coreObject.type isEqualToString:@"text"]) {
                //Send text message
                XMPPMessage *xmppMessage = coreObject.message;
                
                if ([CommonFunctions networkConnectionAvailability] && [APPDELEGATE.xmppStream isConnected]) {
                    
                    //Sending this message will not create any new record , it will update relevant message record in DB.
                    [APPDELEGATE.xmppStream sendElement:xmppMessage];
                    
                }
            }else{
                if (coreObject.furl && coreObject.furl.length>0) {
                    //Send Media Message
                    XMPPMessage *xmppMessage = coreObject.message;
                    
                    if ([CommonFunctions networkConnectionAvailability] && [APPDELEGATE.xmppStream isConnected]) {
                        
                        //Sending this message will not create any new record , it will update relevant message record in DB.
                        [APPDELEGATE.xmppStream sendElement:xmppMessage];
                        
                    }
                    
                }else{
                    //Upload Media
                    
                    NSString *threadIdentifier = [NSString stringWithFormat:@"MEDIA_UPLOAD%d",dispatchCounter++];
                    dispatch_queue_t queue = dispatch_queue_create([threadIdentifier UTF8String], NULL);
                    
                    dispatch_async(queue, ^{
                        
                        Media *media = [[Media alloc] init];
                        
                        media.bokuXMPPJID = coreObject.bareJid.user;
                        NSLog(@"boku xmppjid == %@",media.bokuXMPPJID);
                        
                        media.chatType = [coreObject.chatType intValue];
                        
                        //Priority should be low level , so any live media can be processed soon.
                        media.mediaPriority = LOW_LEVEL_MEDIA;
                        
                        media.xmppMessage = coreObject.message;
                        
                        if ([coreObject.type isEqualToString:@"image"]) {
                            media.mediaType = IMAGE_MEDIA;
                            
                        }else if ([coreObject.type isEqualToString:@"video"]){
                            media.mediaType = VIDEO_MEDIA;
                            
                        }else if ([coreObject.type isEqualToString:@"audio"]){
                            media.mediaType = AUDIO_MEDIA;
                            
                        }else if ([coreObject.type isEqualToString:@"location"]){
                            media.mediaType = LOCATION_MEDIA;
                            
                        }
                        
                        media.mediaIdentifier = coreObject.uuid;
                        
                        /*Media Data Setup*/
                        //Indicating local Media file Name
                        NSString *localMediaFileName = coreObject.localFileName;
                        
                        //Creating Local Media File URL, basis on MediaIdentifier
                        NSString *path = [CommonFunctions getMediaDirectoryPathForOfflineFilesForBokuUser:media.bokuXMPPJID];
                        
                        NSLog(@"saving offline media url is == %@",path);
                        
                        //Appending FileName
                        NSString *offlineMediaURL = [path stringByAppendingPathComponent:localMediaFileName];
                        media.localMediaURL = offlineMediaURL;
                        
                        media.mediaData = [NSData dataWithContentsOfFile:media.localMediaURL];
                        
                        if (media.mediaType == VIDEO_MEDIA) {
                            UIImage *videoThumb = [CommonFunctions thumbnailFromVideoAtURL:[NSURL fileURLWithPath:media.localMediaURL]];
                            
                            media.mediaSubData = UIImageJPEGRepresentation(videoThumb, 1.0);
                        }
                        
                        [self uploadBokuMedia:media];
                    });
                     
                }
                
            }
            
        }
    }
}

/**
 *  Used to identify whether Boku Media Can be uploaded or not
 *
 *  @return YES/NO
 */
-(BOOL)canUploadBokuMedia{
    if (_mediaUploading && !_mediaUploading.communication.isDisConnected) {
        return YES;
    }else{
        return NO;
    }
}


-(Media *)lookForSharedUploadingMediaWithMediaIdentifier:(NSString *)mediaIdentifier{
    return [APPDELEGATE.mediaUploading lookForSharedMediaWithMediaIdentifier:mediaIdentifier];
}

/**
 *  Used to save media offline
 *
 *  @param media Media Model
 */
-(void)saveMediaforOfflineUse:(Media *)media{
    [CommonFunctions saveOfflineMedia:media bokuUser:media.bokuXMPPJID];
}

/**
 *  Used to upload boku media
 *
 *  @param media : Media Model representing media
 */
-(void)uploadBokuMedia:(Media *)media{
    
    //Here we store media first in OfflineFiles folder , so any failure in uploading or sending media message can be re-actioned later.
    
    
    if ([CommonFunctions networkConnectionAvailability]
        && _mediaUploading) {
        
        [_mediaUploading uploadMedia:media];
        return;
        
    }else if ([CommonFunctions networkConnectionAvailability]){
        
        [self keepMediaUploadingStreamingLive];
        
    }
    
    [_multiCastDelegate BokuMediaFailure:media];
}

/**
 *  Used to keep mediaUploading Streaming live
 */
-(void)keepMediaUploadingStreamingLive{
    if ([CommonFunctions networkConnectionAvailability]
        && _mediaUploading.communication.isDisConnected ) {
        //MediaUploading streaming is existing before but now disconnected
        
        [_mediaUploading reconnect];
        
    }else if ([CommonFunctions networkConnectionAvailability]
              && !_mediaUploading){
        
        //MediaUploading Streaming was not initially created
        self.mediaUploading = [[MediaUploading alloc] init];
        self.mediaUploading.delegate = self;
        
    }
}

-(void)processMessageNotification:(id)object{
    NSDictionary *dictNotification ;
    if ([object isKindOfClass:[NSNotification class]]) {
        dictNotification = ((NSNotification *)object).userInfo;
    }else{
        dictNotification = object;
    }
    
    UITabBarController *tabBarController = (UITabBarController *)APPDELEGATE.containerController;
    
    UINavigationController *selectedNavVC = (UINavigationController *)tabBarController.selectedViewController;
    
    XMPP_CHAT_TYPE chatType = SINGLE_CHAT;
    if ([[dictNotification objectForKey:@"type"] isEqualToString:@"chat"]) {
        chatType = SINGLE_CHAT;
    }else if ([[dictNotification objectForKey:@"type"] isEqualToString:@"groupchat"]){
        chatType = GROUP_CHAT;
    }
    
    if (selectedNavVC.topViewController.presentedViewController) {
        NSLog(@"some controller is presented already");
        
        [APPDELEGATE.window endEditing:YES];
        [selectedNavVC.topViewController.presentedViewController.view endEditing:YES];
        
        [selectedNavVC.topViewController.presentedViewController dismissViewControllerAnimated:NO completion:^{
            
            if ([self doesChatContextInNavigationStackNotOnTopWithChatType:chatType]) {
                
                [self moveToNewChatContextAndRemoveExistingFromNavigationStack:[dictNotification objectForKey:@"jid"] withChatType:chatType];
                
            }else if([self doesChatContextOnNavigationTopWithChatType:chatType]){
                
                [_multiCastDelegate AppPushReceived:dictNotification];
                
            }else{
                
                [self moveToNewChatContext:[dictNotification objectForKey:@"jid"] withChatType:chatType];
                
            }
            
        }];
    }else{
        
        if ([self doesChatContextInNavigationStackNotOnTopWithChatType:chatType]) {
            
            [self moveToNewChatContextAndRemoveExistingFromNavigationStack:[dictNotification objectForKey:@"jid"] withChatType:chatType];
            
        }else if([self doesChatContextOnNavigationTopWithChatType:chatType]){
            
            [_multiCastDelegate AppPushReceived:dictNotification];
            
        }else{
            
            [self moveToNewChatContext:[dictNotification objectForKey:@"jid"] withChatType:chatType];
            
        }
        
    }
    
}

-(void)hidePushView{
    self.pushView = nil;
}

-(void)showPushView:(NSDictionary *)dictInfo{
    if (self.pushView == nil) {
        CGRect frame = CGRectMake(0, -PUSH_VIEW_HEIGHT, [UIScreen mainScreen].bounds.size.width, PUSH_VIEW_HEIGHT);
        
        self.pushView = [[PushTopView alloc] initWithFrame:frame];
        self.pushView.dictInfo = dictInfo;
        [self.window addSubview:_pushView];
        [_pushView presentPushView];
    }
}

-(BOOL)doesChatContextOnNavigationTopWithChatType:(XMPP_CHAT_TYPE)chatType{
    if ([self.containerController isKindOfClass:[UITabBarController class]]) {
        //We are on Tab Bar Container Controller so now we check , we are on Contacts/ChatVC Navigation stack or not.
        UITabBarController *tabBarController = (UITabBarController *)self.containerController;
        UINavigationController *selectedNavVC = (UINavigationController *)tabBarController.selectedViewController;
        
        if (chatType == SINGLE_CHAT &&[selectedNavVC.topViewController isKindOfClass:[SingleChatVC class]]) {
            return YES;
        }else if (chatType == GROUP_CHAT && [selectedNavVC.topViewController isKindOfClass:[GroupChatVC class]]){
            return YES;
        }
        
    }
    return NO;
}

-(BOOL)doesChatContextInNavigationStackNotOnTopWithChatType:(XMPP_CHAT_TYPE)chatType{
    if ([self.containerController isKindOfClass:[UITabBarController class]]) {
        //We are on Tab Bar Container Controller so now we check , we are on Contacts/ChatVC Navigation stack or not.
        UITabBarController *tabBarController = (UITabBarController *)self.containerController;
        UINavigationController *selectedNavVC = (UINavigationController *)tabBarController.selectedViewController;
        
        if (chatType == SINGLE_CHAT && [selectedNavVC.topViewController isKindOfClass:[SingleChatVC class]]) {
            return NO;
        }else if (chatType == GROUP_CHAT && [selectedNavVC.topViewController isKindOfClass:[GroupChatVC class]]){
            return NO;
        }
        
        NSArray *arrVCs = selectedNavVC.viewControllers;
        
        for (UIViewController *vc in arrVCs) {
            if (chatType == SINGLE_CHAT && [vc isKindOfClass:[SingleChatVC class]]) {
                return YES;
            }else if (chatType == GROUP_CHAT && [vc isKindOfClass:[GroupChatVC class]]){
                return YES;
            }
        }
        
    }
    return NO;
}

-(void)moveToNewChatContext:(NSString *)JID withChatType:(XMPP_CHAT_TYPE)chatType{
    //We are fetching relevant Person Model
    
    if (chatType == SINGLE_CHAT) {
        
        NSMutableArray *arrPersons;
        [[Contacts sharedInstance] sharedContactsWeakReference:&arrPersons];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.isToBeIgnored == %@ && SELF.bokuXMPPUserName == %@",[NSNumber numberWithBool:NO],JID];
        NSLog(@"jid is %@",JID);
        NSArray *arrFilteredPersons = [arrPersons filteredArrayUsingPredicate:predicate];
        
        if (arrFilteredPersons.count>0) {
            
            Person *filteredPerson = [arrFilteredPersons objectAtIndex:0];
            
            UITabBarController *tabBarController = (UITabBarController *)APPDELEGATE.containerController;
            if (tabBarController.selectedIndex != 1) {
                //Means we are not on chat screen then we specify index 1
                tabBarController.selectedIndex = 1;
            }
            
            
            
            UINavigationController *selectedNavVC = (UINavigationController *)tabBarController.selectedViewController;
            
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            SingleChatVC *singleChat = [sb instantiateViewControllerWithIdentifier:@"SingleChatVC"];
            singleChat.person = filteredPerson;
            [selectedNavVC pushViewController:singleChat animated:YES];
            
        }
        
    }else if (chatType == GROUP_CHAT){
        
        XMPPJID *roomJID = [XMPPJID jidWithString:JID];
        XMPPRoom *xmppRoom = [_xmppMUC roomWithJID:roomJID];
        
        if (xmppRoom) {
        
            XMPPGroups *group = xmppRoom.groupRecord;
            
            UITabBarController *tabBarController = (UITabBarController *)APPDELEGATE.containerController;
            if (tabBarController.selectedIndex != 1) {
                //Means we are not on chat screen then we specify index 1
                tabBarController.selectedIndex = 1;
            }
            
            
            UINavigationController *selectedNavVC = (UINavigationController *)tabBarController.selectedViewController;
            
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            GroupChatVC *groupChat = [sb instantiateViewControllerWithIdentifier:@"GroupChatVC"];
            groupChat.group = group;
            [selectedNavVC pushViewController:groupChat animated:YES];
            
        }
        
    }
    
}

-(void)moveToNewChatContextAndRemoveExistingFromNavigationStack:(NSString *)JID withChatType:(XMPP_CHAT_TYPE)chatType{
    
    //We are fetching relevant Person Model
    if (chatType == SINGLE_CHAT) {
        
        NSMutableArray *arrPersons;
        [[Contacts sharedInstance] sharedContactsWeakReference:&arrPersons];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.isToBeIgnored == %@ && SELF.bokuXMPPUserName == %@",[NSNumber numberWithBool:NO],JID];
        NSLog(@"jid is %@",JID);
        NSArray *arrFilteredPersons = [arrPersons filteredArrayUsingPredicate:predicate];
        if (arrFilteredPersons.count>0) {
            
            //person model is existing, now we can have landing to that user chat window
            
            UITabBarController *tabBarController = (UITabBarController *)self.containerController;
            UINavigationController *selectedNavVC = (UINavigationController *)tabBarController.selectedViewController;
            
            NSMutableArray *arrNewStack = [[NSMutableArray alloc] init];
            
            NSArray *arrVCs = selectedNavVC.viewControllers;
            
            SingleChatVC *stackSingleChatVC ;
            for (UIViewController *vc in arrVCs) {
                if (![vc isKindOfClass:[SingleChatVC class]]) {
                    [arrNewStack addObject:vc];
                }else{
                    //Now remaining Context are removed from stack
                    stackSingleChatVC = (SingleChatVC *)vc;
                    break;
                }
            }
            
            //Now we check whether existing stacked Single Chat context is again related to user , whose push is going proceed.
            Person *filteredPerson = [arrFilteredPersons objectAtIndex:0];
            
            Person *chatPerson = stackSingleChatVC.person;
            if ([chatPerson.bokuXMPPUserName isEqualToString:filteredPerson.bokuXMPPUserName]) {
                
                [arrNewStack addObject:stackSingleChatVC];
                
            }else{
                //Adding new SinleChatVC Context
                
                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                SingleChatVC *singleChat = [sb instantiateViewControllerWithIdentifier:@"SingleChatVC"];
                singleChat.person = filteredPerson;
                [arrNewStack addObject:singleChat];
                
            }
            
            
            //Finally creating new navigation container
            selectedNavVC.viewControllers = arrNewStack;
        }
        
    }else if (chatType == GROUP_CHAT){
        
        XMPPJID *roomJID = [XMPPJID jidWithString:JID];
        XMPPRoom *xmppRoom = [_xmppMUC roomWithJID:roomJID];
        
        if (xmppRoom) {
            
            
            UITabBarController *tabBarController = (UITabBarController *)self.containerController;
            UINavigationController *selectedNavVC = (UINavigationController *)tabBarController.selectedViewController;
            
            NSMutableArray *arrNewStack = [[NSMutableArray alloc] init];
            
            NSArray *arrVCs = selectedNavVC.viewControllers;
            
            GroupChatVC *groupChatVC ;
            for (UIViewController *vc in arrVCs) {
                if (![vc isKindOfClass:[GroupChatVC class]]) {
                    [arrNewStack addObject:vc];
                }else{
                    //Now remaining Context are removed from stack
                    groupChatVC = (GroupChatVC *)vc;
                    break;
                }
            }
            
            //Now we check whether existing stacked Group Chat context is related to group , whose push is going proceed.
            
            XMPPGroups *group = groupChatVC.group;
            if ([[XMPPJID jidWithString:group.roomJIDStr].user isEqualToString:[XMPPJID jidWithString:JID].user]) {
                
                [arrNewStack addObject:groupChatVC];
                
            }else{
                //Adding new GroupChatVC Context
                
                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                GroupChatVC *groupChat = [sb instantiateViewControllerWithIdentifier:@"GroupChatVC"];
                groupChat.group = group;
                [arrNewStack addObject:groupChat];
                
            }
            
            
            //Finally creating new navigation container
            selectedNavVC.viewControllers = arrNewStack;
        }
        
    }
    
    
}


/**
 *  Used to make TabBarController as Application RootController
 */
-(void)makeTabbarAsRootController:(NSDictionary *)dictPushLaunch{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    MenuVC  *rearVC = (MenuVC *)[storyBoard instantiateViewControllerWithIdentifier:@"MENU_STORYBOARD_IDENTIFIER"];
    
    UITabBarController *tabContainerController = (UITabBarController *)[storyBoard instantiateViewControllerWithIdentifier:@"TABBAR_CONTAINER_STORYBOARD_ID"];
    
    if (dictPushLaunch) {
        
        self.dictPushInfo = dictPushLaunch;
        
        tabContainerController.tabBar.hidden = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        NSArray *arrVCs = tabContainerController.viewControllers;
        
        BokuNavVC *navVC = (BokuNavVC *)[arrVCs objectAtIndex:0];
        NSMutableArray *arrContactsStack = [NSMutableArray arrayWithArray:navVC.viewControllers];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        SingleChatVC *singleChat = [sb instantiateViewControllerWithIdentifier:@"SingleChatVC"];
        [arrContactsStack addObject:singleChat];
        [navVC setViewControllers:arrContactsStack];
        
    }
    
    
    
    BokuViewController  *bokuContainerController = [[BokuViewController alloc] initWithRootViewController:rearVC mainViewController:tabContainerController];
    
    self.containerController = tabContainerController;
    
    self.window.rootViewController = bokuContainerController;
    
    [self customizeTabBarAppearence:tabContainerController];
}

/**
 *  Used to setup Navigation As window root controller
 */
-(void)makeNavigationAsRootController{
    
    [CommonFunctions setUserDefault:@"token" value:nil];
    [CommonFunctions setUserDefault:@"userID" value:nil];
    [CommonFunctions setUserDefault:@"phoneNumber" value:nil];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UINavigationController *navContainerController = (UINavigationController *)[storyBoard instantiateViewControllerWithIdentifier:@"NAVIGATION_ROOT_STORYBOARD_IDENTIFIER"];
    
    self.containerController = navContainerController;
    
    self.window.rootViewController = navContainerController;
}

/**
 *  Used to customize tab bar Appearance
 *
 *  @param tabBarController : tabBarController Instance
 */
- (void)customizeTabBarAppearence:(UITabBarController *)tabBarController{
    
    //UITabBarController *tabBarController = (UITabBarController*) [self.window rootViewController];
    UITabBar *tabBar = tabBarController.tabBar;
    
    
    tabBar.backgroundColor = [UIColor colorWithRed:0.f green:171.f/255.f blue:234.f/255.f alpha:1.f];
    tabBar.tintColor = [UIColor whiteColor];
    tabBar.barTintColor = [UIColor colorWithRed:0.f green:171.f/255.f blue:234.f/255.f alpha:1.f];
    
    
    UITabBarItem *tab1 = [tabBar.items objectAtIndex:0];
    UITabBarItem *tab2 = [tabBar.items objectAtIndex:1];
    UITabBarItem *tab3 = [tabBar.items objectAtIndex:2];
    UITabBarItem *tab4 = [tabBar.items objectAtIndex:3];
    
    
    UIImage *tab1Image = [[UIImage imageNamed:@"tab1"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *tab2Image = [[UIImage imageNamed:@"tab2"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *tab3Image = [[UIImage imageNamed:@"tab3"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *tab4Image = [[UIImage imageNamed:@"tab4"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    [tab1 setImage:tab1Image];
    [tab1 setSelectedImage:[[UIImage imageNamed:@"tab1_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tab1 setTitle:@""];
    
    [tab2 setImage:tab2Image];
    [tab2 setSelectedImage:[[UIImage imageNamed:@"tab2_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tab2 setTitle:@""];
    
    [tab3 setImage:tab3Image];
    [tab3 setSelectedImage:[[UIImage imageNamed:@"tab3_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tab3 setTitle:@""];
    
    [tab4 setImage:tab4Image];
    [tab4 setSelectedImage:[[UIImage imageNamed:@"tab4_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tab4 setTitle:@""];
    
    tab1.imageInsets = UIEdgeInsetsMake((tabBar.frame.size.height-tab1Image.size.height)/4.f, 0.f, -(tabBar.frame.size.height-tab1Image.size.height)/4.f, 0.f);
    tab2.imageInsets = UIEdgeInsetsMake((tabBar.frame.size.height-tab2Image.size.height)/4.f, 0.f, -(tabBar.frame.size.height-tab2Image.size.height)/4.f, 0.f);
    tab3.imageInsets = UIEdgeInsetsMake((tabBar.frame.size.height-tab3Image.size.height)/4.f, 0.f, -(tabBar.frame.size.height-tab3Image.size.height)/4.f, 0.f);
    tab4.imageInsets = UIEdgeInsetsMake((tabBar.frame.size.height-tab4Image.size.height)/4.f, 0.f, -(tabBar.frame.size.height-tab4Image.size.height)/4.f, 0.f);
}




#pragma mark - Blocks

void(^AddressBookCompletionHandler)(bool granted, CFErrorRef error) = ^(bool granted, CFErrorRef error){
    
    dispatch_queue_t addressQueue = dispatch_queue_create("CONTACTS_DISPATCH", NULL);
    dispatch_async(addressQueue, ^{
        [[Contacts sharedInstance] BKContactsWithAddressBook];
    });
};


#pragma mark - Notification Handler

-(void)keyboardWillShow:(NSNotification *)notification{
    
    //Sending Keyboard will show notification to each interested context
    [_multiCastDelegate KIPLKeyboardWillShow:notification];
}

-(void)keyboardWillHide:(NSNotification *)notification{
    
    //Sending Keyboard will hide notification to each interested context
    [_multiCastDelegate KIPLKeyboardWillHide:notification];
}

-(void)keyboardChangedFrame:(NSNotification *)notification{
    NSDictionary* info = [notification userInfo];
    
    if ([info objectForKey:@"UIKeyboardAnimationDurationUserInfoKey"]) {
        _keyboardAnimationTime = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    }else{
        _keyboardAnimationTime = 0.25;
    }
    
    NSValue* aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey ];
    CGSize keyboardSize = [aValue CGRectValue].size;
    _keyBoardHeight = keyboardSize.height;
    
    //Sending Keyboard frame change notification to each interested context
    [_multiCastDelegate KIPLkeyboardFrameChange:notification];
    
}

-(void)networkOnline{
    
    NSLog(@"network came");
    [self keepMediaUploadingStreamingLive];
    
    [_multiCastDelegate NetworkCame];
    
}

-(void)networkOffline{
    
    NSLog(@"network gone");
    
    [_multiCastDelegate NetworkGone];
}

// Mind to remember

//Dropbox id of boku app, i am using other dropbox id currently
// Google Drive , needs to be changed with boku app , existing in Macros.

/*-------*/
//Carbon copy of message(Text / Media) , InviteUser is required.



@end
