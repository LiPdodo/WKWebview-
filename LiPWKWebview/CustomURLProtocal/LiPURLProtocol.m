//
//  LiPURLProtocol.m
//  LiPWKWebview
//
//  Created by Li Peng on 2018/6/29.
//  Copyright © 2018年 Li Peng. All rights reserved.
//

#import "LiPURLProtocol.h"
#import <UIKit/UIKit.h>
#import "NSData+ImageContentType.h"
#import "UIImage+MultiFormat.h"
#import "SDWebImageManager.h"

static NSString * const hasInitKey = @"LPCustomWebViewProtocolKey";
@interface LiPURLProtocol ()<NSURLSessionDelegate>
@property (nonnull,strong) NSURLSessionDataTask *task;

@property (nonatomic, strong) NSMutableData *responseData;

@end


@implementation LiPURLProtocol
//注册后，客户端所有请求走这个方法
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSLog(@"request.URL.absoluteString = %@",request.URL.absoluteString);
    NSString *scheme = [[request URL] scheme];
    if ( ([scheme caseInsensitiveCompare:@"http"]  == NSOrderedSame ||
          [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame ))
    {
        NSString *str = request.URL.path;
        NSLog(@"schemestr == %@", request.URL.path);
        //只处理http和https请求的图片
        if (![NSURLProtocol propertyForKey:hasInitKey inRequest:request]) {
            return YES;
        }else {
            return NO;
        }
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    
    //request截取重定向
    //    if ([request.URL.absoluteString isEqualToString:sourUrl])
    //    {
    //        NSURL* url1 = [NSURL URLWithString:localUrl];
    //        mutableReqeust = [NSMutableURLRequest requestWithURL:url1];
    //    }
    
    return mutableReqeust;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //做下标记，防止递归调用
    [NSURLProtocol setProperty:@YES forKey:hasInitKey inRequest:mutableReqeust];
    //查看本地是否已经缓存了图片
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
    //    NSData *data = [[SDImageCache sharedImageCache] diskImageDataBySearchingAllPathsForKey:key];
    NSData *data = [[SDImageCache sharedImageCache] performSelector:@selector(diskImageDataBySearchingAllPathsForKey:) withObject:key];
    
        //这里加上缓存判断，加载本地离线文件
        if (data)
        {
            
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:mutableReqeust.URL              MIMEType:@"image/png/jpg" expectedContentLength:data.length textEncodingName:nil];
            [self.client URLProtocol:self
                  didReceiveResponse:response
                  cacheStoragePolicy:NSURLCacheStorageAllowed];
            [self.client URLProtocol:self didLoadData:data];
            [self.client URLProtocolDidFinishLoading:self];
        }
        else
        {
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
            self.task = [session dataTaskWithRequest:self.request];
            [self.task resume];
        }
}
- (void)stopLoading
{
    if (self.task != nil)
    {
        [self.task  cancel];
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    self.responseData = [[NSMutableData alloc] init];

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if (error) {
        
    }else {
        UIImage *cacheImage = [UIImage sd_imageWithData:self.responseData];
        //利用SDWebImage缓存图片
        [[SDImageCache sharedImageCache]  storeImage:cacheImage imageData:self.responseData forKey:[[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL] toDisk:YES completion:^{
            NSLog(@"completion == ");
        }];
    }
    [self.client URLProtocolDidFinishLoading:self];
}

@end
