//
//  PreDefine.h
//  ScreenProjection
//
//  Created by Jiaxiang Li on 2017/3/22.
//  Copyright © 2017年 Jiaxiang Li. All rights reserved.
//



#ifndef PreDefine_h
#define PreDefine_h

#import <Foundation/Foundation.h>

#define COLOR_WITH_HEX(hexValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16)) / 255.0 green:((float)((hexValue & 0xFF00) >> 8)) / 255.0 blue:((float)(hexValue & 0xFF)) / 255.0 alpha:1.0f]


static NSString *ssdpAddres = @"239.255.255.250";
static UInt16   ssdpPort = 1900;

static NSString *serviceAVTransport         = @"urn:schemas-upnp-org:service:AVTransport:1";
static NSString *serviceRenderingControl    = @"urn:schemas-upnp-org:service:RenderingControl:1";

static NSString *unitREL_TIME = @"REL_TIME";
static NSString *unitTRACK_NR = @"TRACK_NR";

#endif /* PreDefine_h */
