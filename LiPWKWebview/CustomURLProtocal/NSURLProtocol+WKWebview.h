//
//  NSURLProtocol+WKWebview.h
//  LiPWKWebview
//
//  Created by Li Peng on 2018/6/29.
//  Copyright © 2018年 Li Peng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLProtocol (WKWebview)
+ (void)wk_registerScheme:(NSString*)scheme;

+ (void)wk_unregisterScheme:(NSString*)scheme;
@end
