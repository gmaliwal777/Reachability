//
//  AppDelegate.h
//  Boku
//
//  Created by Ashish Sharma on 28/07/15.
//  Copyright (c) 2015 Plural Voice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTLDrive.h"
#import "SIPService.h"

@class DBConnect;
@class XMPPDelegate;
@class LoaderView;
@class AlertView;
@class XMPPStream;
@class XMPPRoster;
@class XMPPLastActivity;
@class XMPPvCardAvatarModule;
@class XMPPvCardTempModule;
@class KIPLMultiCastDelegate;
@class XMPPBlocking;
@class XMPPMUC;
@class XMPPRoom;
@class XMPPMessage;

@class PushTopView;
@class MediaUploading;
@class Reachable;
@class XMPPJID;


@protocol AppUtilityDelegate <NSObject>
@optional

-(void)KIPLApplicationBecomeForeground;
-(void)KIPLApplicationBecomeBackground;
-(void)KIPLKeyboardWillShow:(NSNotification *)notification;
-(void)KIPLKeyboardWillHide:(NSNotification *)notification;
-(void)KIPLkeyboardFrameChange:(NSNotification *)notification;
-(void)NetworkGone;
-(void)NetworkCame;
-(void)ContactsReadyToUse;
-(void)ContactsVerified;
-(void)ContactsRefreshed;
-(void)NewRoomCreatedWithRoom:(XMPPRoom *)room message:(XMPPMessage *)message;
-(void)AppPushReceived:(NSDictionary *)dictPush;
-(void)didSendGroupNotificationMessage:(XMPPMessage *)message;
-(void)didAddMembers;
-(void)didRemoveMemberWithMemberJID:(XMPPJID *)memberJID roomJID:(XMPPJID *)roomJID;
-(void)BokuMediaUploaded:(Media *)media;
-(void)BokuMediaFailure:(Media *)media;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate,AppUtilityDelegate>{
    
    Reachable               *reachable;
    
    
    int dispatchCounter ;
}

/**
 *  Reference to MediaUploading Streaming Channel
 */
@property (nonatomic, strong)   MediaUploading  *mediaUploading;


/**
 *  Reference to Push Dictionary info , it will have value when your App Launches due to Push
 */
@property (nonatomic, strong)   NSDictionary    *dictPushInfo;


/**
 *  Reference to PushTopView
 */
@property (strong, nonatomic)               PushTopView             *pushView;

// Google Drive
@property (nonatomic, strong) GTLServiceDrive *service;

/**
 * keep keyboard animation time frame
 */
@property(nonatomic,assign) NSTimeInterval keyboardAnimationTime;

/**
 *  keyboard height , when keyboard appears on screen
 */
@property(nonatomic,assign) float keyBoardHeight;


/**
 *  Multicaste delegate referencing
 */
@property(nonatomic, strong)    KIPLMultiCastDelegate<AppUtilityDelegate>   *multiCastDelegate;

/**
 *  Weal reference to XMPPStream Channel
 */
@property (nonatomic,weak)  XMPPStream      *xmppStream;


/**
 *  Weal reference to XMPPRoster Channel
 */
@property (nonatomic,weak)  XMPPRoster      *xmppRoster;


/**
 *  Weak reference to XMPPLastActivity
 */
@property (nonatomic,weak)  XMPPLastActivity    *xmppLastActivity;

/**
 *  Weak referecne to XMPPvCardTempModule
 */
@property (nonatomic,weak)  XMPPvCardTempModule *xmppvCardTempModule;

/**
 *  Weak reference to XMPPvCardAvatarModule
 */
@property (nonatomic,weak)  XMPPvCardAvatarModule   *xmppvCardAvatarModule;

/**
 *  XMPP Handler Reference
 */
@property (strong, nonatomic) XMPPDelegate    *xmppDelegate;

/**
 *  Reference to XMPP Block
 */
@property (strong, nonatomic)   XMPPBlocking    *xmppBlocking;



@property (nonatomic, strong)   XMPPMUC     *xmppMUC;


/**
 *  Reference to shared singleton Database Handler entity
 */
@property (nonatomic,strong) DBConnect   *databaseHandler;

/**
 *  Refrence to App window object
 */
@property (strong, nonatomic) UIWindow *window;

/**
 *  Reference to widow rootController (NavigationController,TabbarController)
 */
@property (strong, nonatomic)   id  containerController;


/**
 *  AlertView to show over entire App
 */
@property (nonatomic,strong)    AlertView       *alert;


/**
 *  LoaderView to show activity ingoing 
 */
@property (nonatomic,strong)    LoaderView      *loader;


@property (nonatomic,strong) SIPService *sipService;

/**
 *  Used to make TabBarController as Application RootController
 */
-(void)makeTabbarAsRootController:(NSDictionary *)dictPushLaunch;


/**
 *  Used to setup Navigation As window root controller
 */
-(void)makeNavigationAsRootController;


/**
 *  Used to save media offline
 *
 *  @param media Media Model
 */
-(void)saveMediaforOfflineUse:(Media *)media;


/**
 *  Used to upload boku media
 *
 *  @param media : Media Model representing media
 */
-(void)uploadBokuMedia:(Media *)media;

/**
 *  Used to identify whether Boku Media Can be uploaded or not
 *
 *  @return YES/NO
 */
-(BOOL)canUploadBokuMedia;

/**
 *  Used to proceed OfflineMedias
 */
-(void)processOfflineMedias;

-(Media *)lookForSharedUploadingMediaWithMediaIdentifier:(NSString *)mediaIdentifier;

/*
 1) XMPP_USER_NAME  should have following pattern
    contact_no@chat_server_ip/resource
 
    contact_no should be bareString , since we add unknown no with this bareString when we get subscription request. see in XMPPRoster (Customization here).
 
 2) 
 */

@end

