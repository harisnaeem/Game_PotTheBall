//
//  AdHelper.m
//  PotTheBall
//
//  Created by PC on 7/8/15.
//  Copyright (c) 2015 Randel Smith. All rights reserved.
//

#import "AdHelper.h"

#import <BlocksKit/BlocksKit.h>


@interface AdHelper ()
@property(nonatomic, strong) GADInterstitial *interstitial;
@property BOOL didRqeuestAdMobInterstitial;
@property (nonatomic, strong)UIViewController *presentFromViewController;
@property BOOL presentInTopMostViewControler;

@property(nonatomic, strong) ADInterstitialAd *iAdInterstitial;

@property(nonatomic, strong) UIView *adPlaceholderView;
@property BOOL requestingAd;


@property (nonatomic, strong)RevMobFullscreen *revMobFullscreen;
@property (nonatomic, strong)RevMobFullscreen *revMobRewardFullscreen;

@property BOOL testMode;


@end

@implementation AdHelper

+ (instancetype)sharedManager {
    
    static AdHelper *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];

        sharedMyManager.interstitial = [sharedMyManager createAndLoadInterstitial];
        sharedMyManager.didRqeuestAdMobInterstitial = NO;
        
        
        sharedMyManager.testMode = NO;
    });
    return sharedMyManager;
}

- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

- (void)showInterstitial:(UIViewController *)vc {
    
    [self.interstitial presentFromRootViewController:vc];
    self.didRqeuestAdMobInterstitial = NO;
    
}

- (GADInterstitial *)createAndLoadInterstitial {
    GADInterstitial *interstitial;
    if (![[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Admob_Config"] objectForKey:@"interstitialAdUnitID"] isEqualToString:@""]) {
        NSString *string = [[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Admob_Config"] objectForKey:@"interstitialAdUnitID"];
        interstitial = [[GADInterstitial alloc] initWithAdUnitID:@""];
        
        interstitial.delegate = self;
        GADRequest *request = [GADRequest request];
        
        request.testDevices = @[
                                @"2077ef9a63d2b398840261c8221a0c9a"  // Eric's iPod Touch
                                ];
        [interstitial loadRequest:request];
    }
    
    return interstitial;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitial = [self createAndLoadInterstitial];
}
- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error{
    
}

-(void)interstitialDidReceiveAd:(GADInterstitial *)ad{
    if (self.didRqeuestAdMobInterstitial == YES) {
        
        if (self.presentFromViewController == nil && self.presentInTopMostViewControler == YES) {
            [self showInterstitial:[self topViewController]];
            
        } else if (self.presentFromViewController){
            [self showInterstitial:self.presentFromViewController];
        }
    }
}


-(void)loadAdNetworks{
    if (![[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Chatboost_Config"] objectForKey:@"appId"] isEqualToString:@""] &&
        ![[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Chatboost_Config"] objectForKey:@"appSignature"] isEqualToString:@""]) {
        [Chartboost startWithAppId:[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Chatboost_Config"] objectForKey:@"appId"]
                      appSignature:[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Chatboost_Config"] objectForKey:@"appSignature"]
                          delegate:self];
        
        if ([[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Chatboost_Config"] objectForKey:@"showRewardVideos"] boolValue]) {
            //        if([Chartboost hasRewardedVideo:CBLocationIAPStore]) {
            
            [Chartboost cacheRewardedVideo:CBLocationIAPStore];
            //        }
        }
        
    }
    
    if (![[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Remob_Config"] objectForKey:@"appId"] isEqualToString:@""]) {
        [RevMobAds startSessionWithAppID:[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Remob_Config"] objectForKey:@"appId"] withSuccessHandler:^{
//            self.revMobFullscreen = [[RevMobAds session] fullscreen];
//            [self.revMobFullscreen loadAd];
            
            self.revMobRewardFullscreen = [[RevMobAds session] fullscreen];
            self.revMobRewardFullscreen.delegate = self;
            [self.revMobRewardFullscreen loadRewardedVideo];
            
            
            if ([AdHelper shouldShowRemobInterstitialOnStartUp]) {
                [NSTimer bk_scheduledTimerWithTimeInterval:0.8 block:^(NSTimer *timer) {
                    [self showRemobInterstitial];
                } repeats:NO];
            }
            
        } andFailHandler:^(NSError *error) {
            NSLog(@"simple print-----no start of revmob------{%@}", error);
        }];
    }
    
    

}

+(BOOL)shouldShowInterstitialOnStartUp{
    return [[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnStartUp"] boolValue];
}

+(BOOL)shouldShowAdmobInterstitialOnStartUp{
    return [[[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Admob_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnStartUp"] boolValue] ;
}

+(BOOL)shouldShowChartboostInterstitialOnStartUp{
    return [[[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Chatboost_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnStartUp"] boolValue] ;
}

+(BOOL)shouldShowRemobInterstitialOnStartUp{
    return [[[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Remob_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnStartUp"] boolValue] ;
}

+(BOOL)shouldShowIAdsInterstitialOnStartUp{
    return [[[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"IAds_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnStartUp"] boolValue] ;
}

+(BOOL)shouldShowInterstitialOnEnterForeground{
    return [[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnEnterForeground"] boolValue];
}

+(BOOL)shouldShowAdmobInterstitialOnEnterForeground{
    return [[[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Admob_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnEnterForeground"] boolValue] ;
}

+(BOOL)shouldShowChartboostInterstitialOnEnterForeground{
    return [[[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Chatboost_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnEnterForeground"] boolValue] ;
}

+(BOOL)shouldShowRemobInterstitialOnEnterForeground{
    return [[[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Remob_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnEnterForeground"] boolValue] ;
}

+(BOOL)shouldShowIAdsInterstitialOnEnterForeground{
    return [[[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"IAds_Config"] objectForKey:@"Interstitial"] objectForKey:@"showOnEnterForeground"] boolValue] ;
}


-(void)showAdmobInterstitial{
    self.didRqeuestAdMobInterstitial = YES;
    
    self.presentInTopMostViewControler = YES;
    
    if ([self.interstitial isReady]) {
        
        [self showInterstitial:[self topViewController]];
    }
}

-(void)showChartboostInterstitial{
    [Chartboost showInterstitial:CBLocationStartup];
}

-(void)showRemobInterstitial{
    [self.revMobFullscreen showAd];
}

-(void)showRevmobRewardVideo{
    if(self.revMobRewardFullscreen) [self.revMobRewardFullscreen showRewardedVideo];
}



-(void)showIAdsInterstitial{
    [self topViewControllerWithRootViewController:[self topViewController]].interstitialPresentationPolicy = ADInterstitialPresentationPolicyManual;
    
    BOOL ccan = [[self topViewControllerWithRootViewController:[self topViewController]] requestInterstitialAdPresentation];
    
    NSLog(@"simple print-----can------{%@}", ccan);

}

-(void)showRewardVideoWithSuccessBlock:(void (^)(BOOL))successBlock{
    if (self.testMode) {
        if (successBlock) {
            successBlock(YES);
            successBlock = nil;
        }
    } else {
        if ([[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Chatboost_Config"] objectForKey:@"showRewardVideos"] boolValue]) {
            //        if([Chartboost hasRewardedVideo:CBLocationIAPStore]) {
            
            [Chartboost showRewardedVideo:CBLocationIAPStore];
            //        }
        }
        if ([[[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Ad_Config"] objectForKey:@"Remob_Config"] objectForKey:@"showRewardVideos"] boolValue]) {
            [self showRevmobRewardVideo];
        }
    }
    
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location
                         withError:(CBLoadError)error{
    NSLog(@"simple print-----locaction------{%@}", location);
    
    NSLog(@"simple print-----error------{%lu}", (unsigned long)error);
}

- (void)didCompleteRewardedVideo:(CBLocation)location
                      withReward:(int)reward{
    
    NSLog(@"simple print-----compete------{}");
}
- (void)didCloseRewardedVideo:(CBLocation)location{
    NSLog(@"simple print-----close------{}");
}


@end
