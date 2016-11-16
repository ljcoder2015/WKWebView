//
//  LJWebViewController.m
//  malai
//
//  Created by ljcoder on 16/10/11.
//  Copyright © 2016年 ljcoder. All rights reserved.
//

#import "LJWebViewController.h"
#import "LJWebViewController+JsHandler.h"

#import <WebKit/WebKit.h>

@interface LJWebViewController ()  <WKNavigationDelegate, UIWebViewDelegate>

@property (strong, nonatomic) WKWebView *wkWebView;
@property (strong, nonatomic) UIProgressView *progressView;

@property (strong, nonatomic) NSMutableArray *pages;// webView页面数组，处理多级页面返回的问题
@property (strong, nonatomic) NSString *lastTitleString;

@property (strong, nonatomic) NSURL *baseURL;

@property (nonatomic, assign) BOOL isCurrentPage;// 是否为当前页面，处理js筛选引发的返回问题

@end

@implementation LJWebViewController

/*
 * 1. 筛选以及二级页面筛选返回
 * 2. js交互
 * 3. 进度条
 * 4. 添加参数
 */

#pragma mark - init
- (instancetype)initWithURL:(NSURL *)URL {
    if (self = [super init]) {
        _baseURL = URL;
        _productID = 0;
    }
    return self;
}

#pragma mark - setter and getter
- (NSMutableArray *)pages {
    if (!_pages) {
        _pages = [[NSMutableArray alloc] init];
    }
    return _pages;
}

#pragma mark - life cycle
- (void)dealloc {
    [self.wkWebView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-back"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    self.navigationItem.leftBarButtonItem = backItem;
    
    [self configureView];
    
    // 添加进度条监听
    [self.wkWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    // 加载网页
    [self loadWKData];
    // 刷新网页

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (self.wkWebView.estimatedProgress < 1.0) {
            self.progressView.alpha = 1;
            self.progressView.hidden = NO;
            self.progressView.progress = self.wkWebView.estimatedProgress;
        }
        else {
            [UIView animateWithDuration:0.3 animations:^{
                self.progressView.alpha = 0;
            } completion:^(BOOL finished) {
                self.progressView.hidden = YES;
            }];
            
        }
    }
}

#pragma mark - configureView
- (void)configureView {

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.wkWebView = ({
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        webView.navigationDelegate = self;
//        webView.scrollView.scrollEnabled = NO;
        webView.allowsBackForwardNavigationGestures = YES;
        webView.allowsLinkPreview = YES;
        webView;
    });
    [self.view addSubview:self.wkWebView];

    self.progressView = ({
        UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 3)];
        progressView.trackTintColor = [UIColor clearColor];
        progressView;
    });
    [self.view addSubview:self.progressView];
    
    
}

#pragma mark - loadData
- (void)loadWKData {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.baseURL];
    [request setValue:@"token" forHTTPHeaderField:@"token"];
    [self.wkWebView loadRequest:request];
}

#pragma mark - notificationAction
- (void)reloadWKWebView {
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.wkWebView.URL];
    [request setValue:@"token" forHTTPHeaderField:@"token"];
    [self.wkWebView loadRequest:request];
}

- (void)reloadWKWebViewWitURL:(NSURL *)URL {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setValue:@"token" forHTTPHeaderField:@"token"];
    [self.wkWebView loadRequest:request];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // 判断条件需要替换下面这个，demo没有登录逻辑，就不判断登录了
    //!navigationAction.request.allHTTPHeaderFields[@"token"] && 已登录
//    if (!navigationAction.request.allHTTPHeaderFields[@"token"] && YES) {
//        decisionHandler(WKNavigationActionPolicyCancel);
//        [self reloadWKWebViewWitURL:navigationAction.request.URL];
//    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
    // 处理js交互
    [self jsActionWithUrlString:navigationAction.request.URL.absoluteString];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    // 调用js
    [webView evaluateJavaScript:@"getElementsByTagName('title').innerHTML" completionHandler:^(id _Nullable title, NSError * _Nullable error) {
        NSLog(@"%@", title);
        self.navigationItem.title = title;
    }];
    // 判断是否当前页
    self.isCurrentPage = [webView.title isEqualToString:self.lastTitleString];
    if (!self.isCurrentPage) {
        [self.pages addObject:self.wkWebView.URL.absoluteString];
    }
    self.lastTitleString = webView.title;

}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    // 判断是否当前页
    self.isCurrentPage = [webView.title isEqualToString:self.lastTitleString];
    if (!self.isCurrentPage) {
        [self.pages addObject:self.wkWebView.URL.absoluteString];
    }
    self.lastTitleString = webView.title;
}

#pragma mark - backAction
- (void)backAction {
    
    if (self.pages.count > 1) {
     [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.pages[self.pages.count-2]]]];
        [self.pages removeLastObject];
        [self.pages removeLastObject];
    }
    else {
        if (self.presentingViewController) {
            // present一个navigation，push了页面
            if (self.navigationController.viewControllers.count <= 1) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                [self.navigationController popViewControllerAnimated:YES];
            }
            
        }
        else {
            [self.navigationController popViewControllerAnimated:YES];
            
        }
    }
}

@end
