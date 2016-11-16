//
//  LJWebViewController+JsHandler.m
//  malai
//
//  Created by ljcoder on 16/10/28.
//  Copyright © 2016年 ljcoder. All rights reserved.
//

#import "LJWebViewController+JsHandler.h"
#import "LJWebViewController.h"

@implementation LJWebViewController (JsHandler)

- (BOOL)jsActionWithUrlString:(NSString *)urlString {
    NSLog(@"%@", urlString);
    NSArray *urlArray = [urlString componentsSeparatedByString:@"://"];
    //https 为你的URLScheme
    if ([urlArray[0] isEqualToString:@"https"]) {
        if (urlArray.count>1) {
            // 判断路由，决定调用哪个方法
            if ([urlArray[1] isEqualToString:@"m.baidu.com/"]) {
                [self baidu];
            }
        }
    }

    return YES;
}

#pragma mark jsAction
- (void)baidu {
    NSLog(@"this is a baidu site");
}
@end
