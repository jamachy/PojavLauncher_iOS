#import <WebKit/WebKit.h>
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherPreferences.h"
#import "utils.h"

#define sidebarNavController ((UINavigationController *)self.splitViewController.viewControllers[0])
#define sidebarViewController ((LauncherMenuViewController *)sidebarNavController.viewControllers[0])

@interface LauncherNewsViewController()<WKNavigationDelegate>
@end

@implementation LauncherNewsViewController
WKWebView *webView;
UIEdgeInsets insets;

- (NSString *)imageName {
    return @"MenuNews";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGSize size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    insets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://pojavlauncherteam.github.io/changelogs/IOS.html"]];

    WKWebViewConfiguration *webConfig = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:webConfig];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    webView.opaque = NO;
    [self adjustWebViewForSize:size];
    webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    NSString *javascript = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *nozoom = [[WKUserScript alloc] initWithSource:javascript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [webView.configuration.userContentController addUserScript:nozoom];
    [webView.scrollView setShowsHorizontalScrollIndicator:NO];
    [webView loadRequest:request];
    [self.view addSubview:webView];

    if(!getenv("POJAV_DETECTEDJB") && [getPreference(@"limited_ram_warn") boolValue] == YES && (roundf(NSProcessInfo.processInfo.physicalMemory / 1048576) < 32900)) {
        // "This device has a limited amount of memory available."
        [self showWarningAlert:@"limited_ram" hasPreference:YES];
    }
    
    self.title = localize(@"News", nil);
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.rightBarButtonItem = [sidebarViewController drawAccountButton];
    self.navigationItem.leftItemsSupplementBackButton = true;
}

-(void)showWarningAlert:(NSString *)key hasPreference:(BOOL)isPreferenced {
    UIAlertController *warning = [UIAlertController
                                      alertControllerWithTitle:localize([NSString stringWithFormat:@"login.warn.title.%@", key], nil)
                                      message:localize([NSString stringWithFormat:@"login.warn.title.%@", key], nil)
                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action;
    if(isPreferenced) {
        action = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            setPreference([NSString stringWithFormat:@"%@_warn", key], @NO);
        }];
    } else {
        action = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
    }
    warning.popoverPresentationController.sourceView = self.view;
    warning.popoverPresentationController.sourceRect = self.view.bounds;
    [warning addAction:action];
    [self presentViewController:warning animated:YES completion:nil];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x > 0)
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self adjustWebViewForSize:size];
}

- (void)adjustWebViewForSize:(CGSize)size {
    BOOL isPortrait = size.height > size.width;
    if (isPortrait) {
        webView.scrollView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height + insets.top, 0, self.navigationController.navigationBar.frame.size.height + insets.bottom, 0);
    } else {
        webView.scrollView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height, 0, self.navigationController.navigationBar.frame.size.height, 0);
    }
}

- (void)webView:(WKWebView *)webView 
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction 
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
     if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        openLink(self, navigationAction.request.URL);
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
