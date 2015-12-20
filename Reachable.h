//
//  Reachable.h
//  TapDoctors
//
//  Created by Ghanshyam on 12/16/14.
//  Copyright (c) 2014 KT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface Reachable : NSObject

@property(strong) Reachability * googleReach;
@property(strong) Reachability * localWiFiReach;
@property(strong) Reachability * internetConnectionReach;


-(void)setUPReachable;

@end
