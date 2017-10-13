//
//  SearchUPnPDevice.m
//  ScreenProjection
//
//  Created by Jiaxiang Li on 2017/3/22.
//  Copyright © 2017年 Jiaxiang Li. All rights reserved.
//

#import "SearchUPnPDevice.h"
#import "PreDefine.h"
#import "GCDAsyncUdpSocket.h"
#import "GDataXMLNode.h"
#import "CLUPnPModel.h"



@interface  SearchUPnPDevice ()<GCDAsyncUdpSocketDelegate>

@property (nonatomic,strong) NSString *urlRequest;
@property (nonatomic,strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) NSInteger count;

@end


@implementation SearchUPnPDevice


static SearchUPnPDevice *_instance = nil;

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super alloc] init];
    
    });
    
    return _instance;
}


- (void)searchAboutDevices {
    NSError *error;
    NSData *data = [self.urlRequest dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:data toHost:ssdpAddres port:ssdpPort withTimeout:5 tag:0];
    [self.udpSocket bindToPort:ssdpPort error:&error];
    [self.udpSocket joinMulticastGroup:ssdpAddres error:&error];
    [self.udpSocket beginReceiving:&error];
    
    _count = 0;
    __weak typeof(self) weakSelf = self;
    if (error) {
        [self stopSearching];
        [self onError:error];
    }else{
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:10];
        [_timer invalidate];
        _timer = nil;
        _timer = [[NSTimer alloc] initWithFireDate:date interval:1 target:weakSelf selector:@selector(stopSearching) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}



- (void)stopSearching {
    [self.udpSocket close];
    [_timer invalidate];
    _timer = nil;
}


- (void)onError:(NSError *) error {
    if ([self.delegate respondsToSelector:@selector(searchFailedWithError:)]) {
        [self.delegate searchFailedWithError:error];
    }
}


// 解析搜索设备获取Location
- (NSURL *)deviceUrlWithData:(NSData *)data{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *subArray = [string componentsSeparatedByString:@"\n"];
    for (int j = 0 ; j < subArray.count; j++){
        NSArray *dicArray = [subArray[j] componentsSeparatedByString:@": "];
        if ([dicArray[0] isEqualToString:@"LOCATION"] || [dicArray[0] isEqualToString:@"Location"]) {
            if (dicArray.count > 1) {
                NSString *location = dicArray[1];
                location = [location stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSURL *url = [NSURL URLWithString:location];
                return url;
            }
        }
    }
    return nil;
}

// 获取UPnP信息
- (void)getUPnPInfoWithLocation:(NSURL *)url{
    
    NSLog(@"Location: %@", url);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLRequest  *request=[NSURLRequest requestWithURL:url];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if(error || data == nil){
                [self onError:error];
                return;
            }else{
                CLUPnPModel *deviceModel = [[CLUPnPModel alloc] init];
                CLServiceModel *serviceModel = [[CLServiceModel alloc] init];
                deviceModel.urlHeader = [NSString stringWithFormat:@"%@://%@:%@", [url scheme], [url host], [url port]];
                NSString *_dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSString *documentPathStr =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
                //构造字符串文件的存储路径
                NSString *strPath = [documentPathStr stringByAppendingPathComponent:[NSString stringWithFormat:@"ddd+%ld.txt",_count]];
                NSLog(@"Path:%@",strPath);
                 _count++;
                [_dataStr writeToFile:strPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithXMLString:_dataStr options:0 error:nil];
                GDataXMLElement *xmlEle = [xmlDoc rootElement];
                
                NSArray *xmlArray = [xmlEle children];
                
                for (int i = 0; i < [xmlArray count]; i++) {
                    GDataXMLElement *element = [xmlArray objectAtIndex:i];
                    if ([[element name] isEqualToString:@"device"]) {
                        [deviceModel setArray:[element children]];
                        deviceModel.locationUrl = [NSString stringWithFormat:@"%@",url];
                        for (GDataXMLElement *childElement in [element children]) {
                            if ([[childElement name] isEqualToString:@"serviceList"]) {
                                NSArray *serviceListArr = [childElement children];
                                for (GDataXMLElement *serviceEle in serviceListArr) {
                                    if ([[serviceEle name] isEqualToString:@"service"]) {
                                        CLServiceModel *tempServiceModel = [[CLServiceModel alloc] init];
                                        [tempServiceModel setArray:[serviceEle children]];
                                        if ([tempServiceModel.serviceType isEqualToString: @"urn:schemas-upnp-org:service:AVTransport:1"]) {
                                            serviceModel = tempServiceModel;
                                        }
                                    }
                                }
                            }
                        }
                        continue;
                    }
                }
    
                if (deviceModel.AVTransport.controlURL) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([self.delegate respondsToSelector:@selector(searchSucessWithDeviceModel:serviceModel:)]) {
                            [self.delegate searchSucessWithDeviceModel:deviceModel serviceModel:serviceModel];
                        }
                    });
                }
            }
        }];
        // 执行任务
        [dataTask resume];
    });
}




#pragma mark -- GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"Socket Connect Successfully! Tag:%ld",tag);
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    NSLog(@"Socket Connect Failed! Error:%@",error.localizedDescription);
}



- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    NSLog(@"Socket Closed, Error:%@",error.localizedDescription);
}



- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *addressStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Data From Address:%@",addressStr);
    
    NSURL *location = [self deviceUrlWithData:data];
    if (location) {
        [self getUPnPInfoWithLocation:location];
    }
}


#pragma mark -- Getter & Setter 方法

- (NSString *)urlRequest {
    if (!_urlRequest) {
        _urlRequest = [NSString stringWithFormat:@"M-SEARCH * HTTP/1.1\r\nHOST: %@:%d\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: %@\r\nUSER-AGENT: iOS UPnP/1.1 TestApp/1.0\r\n\r\n",ssdpAddres,ssdpPort,serviceAVTransport];
    }
    
    return _urlRequest;
}

- (GCDAsyncUdpSocket *)udpSocket {
    __weak typeof(self) weakSelf = self;
    if (!_udpSocket) {
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:weakSelf delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    return _udpSocket;
}



@end
