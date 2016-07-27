@import UIKit;
#import "RCTOpenTokPublisherView.h"
#import "RCTEventDispatcher.h"
#import <OpenTok/OpenTok.h>

@interface RCTOpenTokPublisherView () <OTSessionDelegate>

@end

@implementation RCTOpenTokPublisherView {
    BOOL _isMounted;
    OTSession *_session;
    OTPublisher *_publisher;
}

- (void)mount {
    _isMounted = YES;
    
    _session = [[OTSession alloc] initWithApiKey:_apiKey sessionId:_sessionId delegate:self];
    
    OTError *error = nil;
    [_session connectWithToken:_token error:&error];
    
    if (error) {
        _onStartFailure(@{});
    }
}

- (void)didMoveToWindow {
    [super didMoveToSuperview];
    if (!_isMounted) {
        [self mount];
    }
}

/**
 * Creates an instance of `OTPublisher` and publishes stream to the current
 * session
 *
 * Calls `onPublishError` in case of an error, otherwise, a camera preview is inserted
 * inside the mounted view
 */
- (void)startPublishing {
    _publisher = [[OTPublisher alloc] initWithDelegate:self];
    
    OTError *error = nil;
    
    [_session publish:_publisher error:&error];
    
    if (error) {
        _onPublishError(@{});
        return;
    }
    
    [_publisher.view setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self addSubview:_publisher.view];
}

- (void)cleanupPublisher {
    [_publisher.view removeFromSuperview];
    _publisher = nil;
}

# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session {
    _onConnected(@{});
    [self startPublishing];
}

- (void)sessionDidDisconnect:(OTSession*)session {
    _onDisconnected(@{});
}

- (void)session:(OTSession*)session streamCreated:(OTStream *)stream {
    _onStreamCreated(@{});
}

- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream {
    _onStreamDestroyed(@{});
}

- (void)session:(OTSession *)session connectionCreated:(OTConnection *)connection {
    _onConnectionCreated(@{});
}

- (void)session:(OTSession *)session connectionDestroyed:(OTConnection *)connection {
    _onConnectionDestroyed(@{});
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error {
    _onUnknownError(@{});
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher streamCreated:(OTStream *)stream {}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream *)stream
{
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher didFailWithError:(OTError*) error
{
    [self cleanupPublisher];
}

- (void)dealloc {
    [self cleanupPublisher];
}

@end
