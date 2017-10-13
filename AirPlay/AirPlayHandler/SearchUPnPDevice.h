//
//  SearchUPnPDevice.h
//  ScreenProjection
//
//  Created by Jiaxiang Li on 2017/3/22.
//  Copyright © 2017年 Jiaxiang Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SearchUPnPDeviceDelegate <NSObject>

@required

/**
 搜索成功返回

 @param deviceModel 设备描述文档返回设备基本信息数据
 @param serviceModel 设备描述文档返回设备基服务信息数据
 */
- (void)searchSucessWithDeviceModel:(id) deviceModel serviceModel:(id) serviceModel;

@optional


/**
 搜索失败返回

 @param error 错误信息
 */
- (void)searchFailedWithError:(NSError *)error;

@end

@interface SearchUPnPDevice : NSObject


@property (nonatomic,weak)id<SearchUPnPDeviceDelegate> delegate;

+ (instancetype)shareInstance;

/** 开始搜索设备 */
- (void)searchAboutDevices;

/**停止搜索设备*/
- (void)stopSearching;

@end
