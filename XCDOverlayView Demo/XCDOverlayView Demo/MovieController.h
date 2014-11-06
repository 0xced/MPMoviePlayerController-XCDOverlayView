//
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MovieController : NSObject

- (instancetype) initWithMovieURL:(NSURL *)movieURL;

- (NSURLSessionDownloadTask *) startDownload;
- (void) cancelDownload;

- (BOOL) hasLocalMovie;

// Returns the remote movie URL while downloading and the local movie URL once download is finished
@property (readonly) NSURL *movieURL;

- (void) getMovieInfo:(void (^)(NSDictionary *movieInfo))completionHandler;

@end
