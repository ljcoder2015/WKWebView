//
//  LJWebViewController.h
//  malai
//
//  Created by ljcoder on 16/10/11.
//  Copyright © 2016年 ljcoder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LJWebViewController : UIViewController

- (instancetype)initWithURL:(NSURL *)URL;

- (void)loadWKData;
- (void)reloadWKWebView;

@property (nonatomic, assign) BOOL needsPopToRoot;// 返回跟控制器

@property (nonatomic, assign) NSInteger productID;

@end
