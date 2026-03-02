//
//  CordovaGoogleMaps.m
//  cordova-googlemaps-plugin v2
//
//  Created by Masashi Katsumata.
//
//

#import "CordovaGoogleMaps.h"

@implementation CordovaGoogleMaps

- (void)pluginInitialize {
    NSLog(@"CordovaGoogleMaps pluginInitialize");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pageDidLoad)
                                                 name:CDVPageDidLoadNotification
                                               object:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.executeQueue =  [NSOperationQueue new];
        self.executeQueue.maxConcurrentOperationCount = 10;
    });

    // Check and set the Google Maps API key
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *APIKey = [((CDVViewController *)self.viewController).settings objectForKey:@"google_maps_ios_api_key"];
        
        // Show error if the API key is not set
        if (APIKey == nil) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:[PluginUtil PGM_LOCALIZATION:@"APIKEY_IS_UNDEFINED_TITLE"]
                                                                           message:[PluginUtil PGM_LOCALIZATION:@"APIKEY_IS_UNDEFINED_MESSAGE"]
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:[PluginUtil PGM_LOCALIZATION:@"CLOSE_BUTTON"]
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction* action) {
                                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                                     }]];

            [self.viewController presentViewController:alert
                                              animated:YES
                                            completion:nil];
            return;
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];

        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

        // Set API key in Google Maps SDK
        [GMSServices provideAPIKey:APIKey];
        
        // Store api key in userDefaults
        NSUserDefaults *myDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"cordova.plugin.googlemaps"];
        [myDefaults setObject:APIKey forKey:@"GOOGLE_MAPS_API_KEY"];
        [myDefaults synchronize];
    }];

    // Plugin initialization
    self.viewPlugins = [[NSMutableDictionary alloc] init];
  
    // Initialize the plugin layer
    // This removes the webView from the view hierarchy and adds it to the plugin layer
    self.pluginLayer = [[MyPluginLayer alloc] initWithWebView:self.webView];
    self.pluginLayer.backgroundColor = [UIColor clearColor]; // Set to clear to avoid white screen
    self.pluginLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.pluginLayer.userInteractionEnabled = NO; // Ensure the plugin layer does not intercept touch events
  
    // Add the plugin layer to the back, so it is not disturbing the splash screen
    // When the plugin layer is in the back, the plugin layer and the containing webView is not clickable
    [self.viewController.view addSubview:self.pluginLayer];
    [self.viewController.view sendSubviewToBack:self.pluginLayer];
  
    // Move the plugin layer, after the splash screen is dismissed, to the front
    // so the plugin layer and the webView is clickable
    // Read the SplashScreenDelay value from config.xml
    NSString *splashScreenDelayString = [((CDVViewController *)self.viewController).settings objectForKey:@"splashscreendelay"];
    
    // If no SplashScreenDelay ist set, set no delay. Cordova states, that the default value for
    // iOS is 3000ms, but it seems, when testing it, that the splash screen is hidden, right after the initialization is complete
    double splashScreenDelay = splashScreenDelayString ? [splashScreenDelayString doubleValue] : 0;
    
    // Add some extra delay, to let the splash screen fade out, otherwise it will be hidden, without the animation
    // This can have the side effect, that the app is not clickable for a short period of time, after the splash screen is dismissed
    splashScreenDelay += 2000;
  
    // Move the plugin layer to the front
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(splashScreenDelay * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self.viewController.view bringSubviewToFront:self.pluginLayer];
    });
}
- (void) didRotate:(id)sender {
    NSArray *keys = [self.viewPlugins allKeys];
    
    for (int i = 0; i < keys.count; i++) {
        NSString *key = [keys objectAtIndex:i];
        
        if ([self.viewPlugins objectForKey:key]) {
            CDVPlugin<IPluginProtocol, IPluginView> *viewPlugin = [self.viewPlugins objectForKey:key];
            
            if ([viewPlugin isKindOfClass:[PluginMap class]]) {
                PluginMap *pluginMap = (PluginMap *)viewPlugin;
                // Trigger the CAMERA_MOVE_END mandatory
                [pluginMap.mapCtrl mapView:pluginMap.mapCtrl.map idleAtCameraPosition:pluginMap.mapCtrl.map.camera];
            }
        }
    }
}


-(void)viewDidLayoutSubviews {
    // Update contentSize of pluginScrollView to match the scrollView of the WebView
    if ([self.webView respondsToSelector:@selector(scrollView)]) {
        UIScrollView *webViewScrollView = [self.webView performSelector:@selector(scrollView)];
        self.pluginLayer.pluginScrollView.contentSize = webViewScrollView.contentSize;
    }
  
    [self.pluginLayer.pluginScrollView flashScrollIndicators];
}

- (void)onReset
{
  [super onReset];

  // Reset the background color
  self.pluginLayer.backgroundColor = [UIColor whiteColor];

  dispatch_async(dispatch_get_main_queue(), ^{

    // Remove all url caches
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    // Remove old plugins that are used in the previous html.
    NSString *mapId;
    NSArray *keys=[self.viewPlugins allKeys];
    for (int i = 0; i < [keys count]; i++) {
      mapId = [keys objectAtIndex:i];
      [self _destroyMap:mapId];
    }
    [self.viewPlugins removeAllObjects];

    @synchronized(self.pluginLayer.pluginScrollView.HTMLNodes) {
      [self.pluginLayer.pluginScrollView.HTMLNodes removeAllObjects];
      self.pluginLayer.pluginScrollView.HTMLNodes = nil;
    }
    [self.pluginLayer.pluginScrollView.mapCtrls removeAllObjects];

  });

}
-(void)pageDidLoad {
  self.webView.backgroundColor = [UIColor clearColor];
  self.webView.opaque = NO;

}

- (void)_destroyMap:(NSString *)mapId {
  if (![self.viewPlugins objectForKey:mapId]) return;

  CDVPlugin<IPluginView> *pluginView = [self.viewPlugins objectForKey:mapId];

  if ([mapId hasPrefix:@"streetview_"]) {
    PluginStreetViewPanorama *pluginSV = (PluginStreetViewPanorama *)pluginView;
    pluginSV.isRemoved = YES;
    [pluginSV pluginUnload];
    [self.pluginLayer removePluginOverlay:pluginSV.panoramaCtrl];
    pluginSV.panoramaCtrl.view = nil;
    pluginSV = nil;

  } else {
    PluginMap *pluginMap = (PluginMap *)pluginView;
    pluginMap.isRemoved = YES;
    [pluginMap pluginUnload];
    [self.pluginLayer removePluginOverlay:pluginMap.mapCtrl];
    pluginMap.mapCtrl.view = nil;
    [pluginMap.mapCtrl.plugins removeAllObjects];
    pluginMap.mapCtrl.plugins = nil;
    pluginMap.mapCtrl.view = nil;
    pluginMap.mapCtrl = nil;
    pluginMap = nil;
  }

  [self.viewPlugins removeObjectForKey:mapId];
}
/**
 * Remove the map
 */
- (void)removeMap:(CDVInvokedUrlCommand *)command {
  NSString *mapId = [command.arguments objectAtIndex:0];
  [self _destroyMap:mapId];

  if (command != nil) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }

}

/**
 * Intialize the map
 */
- (void)getMap:(CDVInvokedUrlCommand *)command {
    if (self.pluginLayer != nil) self.pluginLayer.isSuspended = false;

    dispatch_async(dispatch_get_main_queue(), ^{
        
        CDVViewController *cdvViewController = (CDVViewController*)self.viewController;
        NSDictionary *meta = [command.arguments objectAtIndex:0];
        NSString *mapId = [meta objectForKey:@"__pgmId"];
        NSDictionary *initOptions = [command.arguments objectAtIndex:1];
        
        // Wrapper view
        PluginMapViewController* viewCtrl = [[PluginMapViewController alloc] initWithOptions:nil];
        viewCtrl.webView = self.webView;
        viewCtrl.isFullScreen = YES;
        viewCtrl.overlayId = mapId;
        viewCtrl.title = mapId;
        viewCtrl.divId = nil;
        [viewCtrl.view setHidden:YES];
        
        // Create an instance of the Map class everytime.
        PluginMap *pluginMap = [PluginMap new];
        [pluginMap pluginInitialize];
        pluginMap.mapCtrl = viewCtrl;
        
        // Hack:
        // In order to load the plugin instance of the same class but different names,
        // register the map plugin instance into the pluginObjects directly.
        if ([pluginMap respondsToSelector:@selector(setViewController:)]) {
            [pluginMap setViewController:cdvViewController];
        }
        
        if ([pluginMap respondsToSelector:@selector(setCommandDelegate:)]) {
            [pluginMap setCommandDelegate:cdvViewController.commandDelegate];
        }
        
        [cdvViewController registerPlugin:pluginMap withPluginName:mapId];
        [pluginMap pluginInitialize];
        
        [self.viewPlugins setObject:pluginMap forKey:mapId];
        
        CGRect rect = CGRectZero;
        
        // Sets the map div id.
        if ([command.arguments count] == 3) {
            pluginMap.mapCtrl.divId = [command.arguments objectAtIndex:2];
            if (pluginMap.mapCtrl.divId != nil) {
                NSDictionary *domInfo = [self.pluginLayer.pluginScrollView.HTMLNodes objectForKey:pluginMap.mapCtrl.divId];
                if (domInfo != nil) rect = CGRectFromString([domInfo objectForKey:@"size"]);
            }
        }
        
        // Generate an instance of GMSMapView;
        GMSCameraPosition *camera = nil;
        int bearing = 0;
        double angle = 0, zoom = 0;
        NSDictionary *latLng = nil;
        double latitude = 0;
        double longitude = 0;
        GMSCoordinateBounds *cameraBounds = nil;
        NSDictionary *cameraOptions = [initOptions valueForKey:@"camera"];
        
        if (cameraOptions) {
            if ([cameraOptions valueForKey:@"bearing"] && [cameraOptions valueForKey:@"bearing"] != [NSNull null]) {
                bearing = (int)[[cameraOptions valueForKey:@"bearing"] integerValue];
            } else {
                bearing = 0;
            }
            
            if ([cameraOptions valueForKey:@"tilt"] && [cameraOptions valueForKey:@"tilt"] != [NSNull null]) {
                angle = [[cameraOptions valueForKey:@"tilt"] doubleValue];
            } else {
                angle = 0;
            }
            
            if ([cameraOptions valueForKey:@"zoom"] && [cameraOptions valueForKey:@"zoom"] != [NSNull null]) {
                zoom = [[cameraOptions valueForKey:@"zoom"] doubleValue];
            } else {
                zoom = 0;
            }
            
            if ([cameraOptions objectForKey:@"target"] && [cameraOptions valueForKey:@"target"] != [NSNull null]) {
                NSString *targetClsName = [[cameraOptions objectForKey:@"target"] className];
                
                /**
                 * cameraPosition.target = [
                 *    new plugin.google.maps.LatLng(),
                 *    ...
                 *    new plugin.google.maps.LatLng()
                 *  ]
                 */
                if ([targetClsName isEqualToString:@"__NSCFArray"] || [targetClsName isEqualToString:@"__NSArrayM"] ) {
                    int i = 0;
                    NSArray *latLngList = [cameraOptions objectForKey:@"target"];
                    GMSMutablePath *path = [GMSMutablePath path];
                    
                    for (i = 0; i < [latLngList count]; i++) {
                        latLng = [latLngList objectAtIndex:i];
                        latitude = [[latLng valueForKey:@"lat"] doubleValue];
                        longitude = [[latLng valueForKey:@"lng"] doubleValue];
                        [path addLatitude:latitude longitude:longitude];
                    }
                    
                    cameraBounds = [[GMSCoordinateBounds alloc] initWithPath:path];
                    //CLLocationCoordinate2D center = cameraBounds.center;
                    
                    latitude = cameraBounds.center.latitude;
                    longitude = cameraBounds.center.longitude;
                    
                    /**
                     * cameraPosition.target = new plugin.google.maps.LatLng();
                     */
                } else {
                    latLng = [cameraOptions objectForKey:@"target"];
                    latitude = [[latLng valueForKey:@"lat"] floatValue];
                    longitude = [[latLng valueForKey:@"lng"] floatValue];
                }
            }
            //[pluginMap.mapCtrl.view setHidden:YES];
        }
        
        camera = [GMSCameraPosition cameraWithLatitude:latitude
                                             longitude:longitude
                                                  zoom:zoom
                                               bearing:bearing
                                          viewingAngle:angle];
        
        // Google Maps SDK 8.3.0 uses GMSMapView.initWithOptions with GMSMapViewOptions
        // If the deployment target is set to iOS 14.0 or newer, this version will be used minimum
        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_14_0
            GMSMapViewOptions *gmsMapViewOptions = [GMSMapViewOptions new];
            gmsMapViewOptions.frame = rect;
            gmsMapViewOptions.camera = camera;
            viewCtrl.map = [[GMSMapView alloc] initWithOptions:gmsMapViewOptions];
        
        #else
            // Before Google Maps SDK 8.3.0 GMSMapView.mapWithFrame has to be used
            // If the deployment target is older then iOS 14.0 and older Google Maps SDK will be used
            viewCtrl.map = [GMSMapView mapWithFrame:rect camera:camera];
        #endif
        
        viewCtrl.view = viewCtrl.map;

        // mapType and styles
        NSString *styles = [initOptions valueForKey:@"styles"];

        if (styles) {
            NSError *error;
            GMSMapStyle *mapStyle =
                [GMSMapStyle styleWithJSONString:styles error:&error];

            if (mapStyle != nil) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    ((GMSMapView *)viewCtrl.view).mapStyle = mapStyle;
                }];
            } else {
                NSLog(@"Your specified map style is incorrect : %@",
                      error.description);
            }
        } else {
            NSString *typeStr = [initOptions valueForKey:@"mapType"];

            if (typeStr) {
                NSDictionary *mapTypes = @{
                    @"MAP_TYPE_HYBRID"    : ^{ return kGMSTypeHybrid; },
                    @"MAP_TYPE_SATELLITE" : ^{ return kGMSTypeSatellite; },
                    @"MAP_TYPE_TERRAIN"   : ^{ return kGMSTypeTerrain; },
                    @"MAP_TYPE_NORMAL"    : ^{ return kGMSTypeNormal; },
                    @"MAP_TYPE_NONE"      : ^{ return kGMSTypeNone; }
                };

                typedef GMSMapViewType (^CaseBlock)(void);

                CaseBlock caseBlock = mapTypes[typeStr];

                if (caseBlock) {
                    GMSMapViewType mapType = caseBlock();

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        ((GMSMapView *)viewCtrl.view).mapType = mapType;
                    }];
                }
            }
        }
        
        viewCtrl.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;


        //indoor display
        ((GMSMapView *)(viewCtrl.view)).delegate = viewCtrl;
        ((GMSMapView *)(viewCtrl.view)).indoorDisplay.delegate = viewCtrl;
        [self.pluginLayer addPluginOverlay:viewCtrl];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [pluginMap getMap:command];
        });
    });
}

/**
 * Intialize the panorama
 */
- (void)getPanorama:(CDVInvokedUrlCommand *)command {
  if (self.pluginLayer != nil) {
    self.pluginLayer.isSuspended = false;
  }

  dispatch_async(dispatch_get_main_queue(), ^{

    CDVViewController *cdvViewController = (CDVViewController*)self.viewController;
    NSDictionary *meta = [command.arguments objectAtIndex:0];
    NSString *panoramaId = [meta objectForKey:@"__pgmId"];
    NSString *divId = [command.arguments objectAtIndex:2];

    // Wrapper view
    PluginStreetViewPanoramaController* panoramaCtrl = [[PluginStreetViewPanoramaController alloc] initWithOptions:nil];
    panoramaCtrl.webView = self.webView;
    panoramaCtrl.isFullScreen = YES;
    panoramaCtrl.overlayId = panoramaId;
    panoramaCtrl.divId = divId;
    panoramaCtrl.title = panoramaId;
    //[mapCtrl.view setHidden:YES];

    // Create an instance of the PluginStreetViewPanorama class everytime.
    PluginStreetViewPanorama *pluginStreetView = [[PluginStreetViewPanorama alloc] init];
    [pluginStreetView pluginInitialize];

    // Hack:
    // In order to load the plugin instance of the same class but different names,
    // register the street view plugin instance into the pluginObjects directly.
    if ([pluginStreetView respondsToSelector:@selector(setViewController:)]) {
      [pluginStreetView setViewController:cdvViewController];
    }
    if ([pluginStreetView respondsToSelector:@selector(setCommandDelegate:)]) {
      [pluginStreetView setCommandDelegate:cdvViewController.commandDelegate];
    }
    
    [cdvViewController registerPlugin:pluginStreetView withPluginName:panoramaId];
    [pluginStreetView pluginInitialize];

    [self.viewPlugins setObject:pluginStreetView forKey:panoramaId];

    CGRect rect = CGRectZero;
    // Sets the panorama div id.
    pluginStreetView.panoramaCtrl = panoramaCtrl;
    pluginStreetView.panoramaCtrl.divId = divId;
    if (pluginStreetView.panoramaCtrl.divId != nil) {
      NSDictionary *domInfo = [self.pluginLayer.pluginScrollView.HTMLNodes objectForKey:pluginStreetView.panoramaCtrl.divId];
      if (domInfo != nil) {
        rect = CGRectFromString([domInfo objectForKey:@"size"]);
      }
    }

    panoramaCtrl.panoramaView = [GMSPanoramaView panoramaWithFrame:rect nearCoordinate: CLLocationCoordinate2DMake(0, 0)];
    panoramaCtrl.view = panoramaCtrl.panoramaView;
    panoramaCtrl.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    ((GMSPanoramaView *)(panoramaCtrl.view)).delegate = panoramaCtrl;
    [self.pluginLayer addPluginOverlay:panoramaCtrl];

    [pluginStreetView getPanorama:command];

  });
}


- (void)clearHtmlElements:(CDVInvokedUrlCommand *)command {
  [self.executeQueue addOperationWithBlock:^{
    if (self.pluginLayer != nil) {
      [self.pluginLayer clearHTMLElements];
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }];
}

- (void)resume:(CDVInvokedUrlCommand *)command {
  if (self.pluginLayer != nil) {
    self.pluginLayer.isSuspended = NO;
  }
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}
- (void)pause:(CDVInvokedUrlCommand *)command {
  if (self.pluginLayer != nil) {
    if (!self.pluginLayer.isSuspended) {
      self.pluginLayer.isSuspended = YES;
      // cancel the timer
      [self.pluginLayer stopRedrawTimer];

      //[self.pluginLayer resizeTask:nil];
    }
  }
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void)updateMapPositionOnly:(CDVInvokedUrlCommand *)command {
  [self.executeQueue addOperationWithBlock:^{
    if (self.pluginLayer != nil) {

      NSDictionary *elementsDic = [command.arguments objectAtIndex:0];
      NSString *domId;
      CGRect rect = CGRectMake(0, 0, 0, 0);
      NSMutableDictionary *domInfo, *size, *currentDomInfo;
      @synchronized(self.pluginLayer.pluginScrollView.HTMLNodes) {
        for (domId in elementsDic) {

          domInfo = [elementsDic objectForKey:domId];
          size = [domInfo objectForKey:@"size"];
          rect.origin.x = [[size objectForKey:@"left"] doubleValue];
          rect.origin.y = [[size objectForKey:@"top"] doubleValue];
          rect.size.width = [[size objectForKey:@"width"] doubleValue];
          rect.size.height = [[size objectForKey:@"height"] doubleValue];

          currentDomInfo = [self.pluginLayer.pluginScrollView.HTMLNodes objectForKey:domId];
          if (currentDomInfo == nil) {
            currentDomInfo = domInfo;
          }
          [currentDomInfo setValue:NSStringFromCGRect(rect) forKey:@"size"];
          [self.pluginLayer.pluginScrollView.HTMLNodes setObject:currentDomInfo forKey:domId];
        }
      }

      self.pluginLayer.isSuspended = false;
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.pluginLayer resizeTask:nil];
      }];
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }];
}

- (void)putHtmlElements:(CDVInvokedUrlCommand *)command {
  [self.executeQueue addOperationWithBlock:^{

    NSDictionary *elements = [command.arguments objectAtIndex:0];

    if (self.pluginLayer != nil) {
      [self.pluginLayer putHTMLElements:elements];
    }
    /*
     if (self.pluginLayer.needUpdatePosition) {
     self.pluginLayer.needUpdatePosition = NO;
     NSArray *keys=[self.viewPlugins allKeys];
     NSString *mapId;
     PluginMap *pluginMap;

     for (int i = 0; i < [keys count]; i++) {
     mapId = [keys objectAtIndex:i];
     pluginMap = [self.viewPlugins objectForKey:mapId];
     [self.pluginLayer updateViewPosition:pluginMap.mapCtrl];
     }
     }
     */
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    pluginResult = nil;
    elements = nil;
  }];
}

@end

