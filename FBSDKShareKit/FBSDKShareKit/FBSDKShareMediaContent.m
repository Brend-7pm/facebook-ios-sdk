/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareMediaContent.h"

#import <FBSDKShareKit/FBSDKShareErrorDomain.h>

#import "FBSDKHasher.h"
#import "FBSDKHashtag.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKShareUtility.h"
#import "FBSDKShareVideo.h"

#define FBSDK_SHARE_MEDIA_CONTENT_CONTENT_URL_KEY @"contentURL"
#define FBSDK_SHARE_MEDIA_CONTENT_HASHTAG_KEY @"hashtag"
#define FBSDK_SHARE_MEDIA_CONTENT_PEOPLE_IDS_KEY @"peopleIDs"
#define FBSDK_SHARE_MEDIA_CONTENT_MEDIA_KEY @"media"
#define FBSDK_SHARE_MEDIA_CONTENT_PLACE_ID_KEY @"placeID"
#define FBSDK_SHARE_MEDIA_CONTENT_REF_KEY @"ref"
#define FBSDK_SHARE_MEDIA_CONTENT_PAGE_ID_KEY @"pageID"
#define FBSDK_SHARE_MEDIA_CONTENT_UUID_KEY @"uuid"

@implementation FBSDKShareMediaContent

#pragma mark - Properties

@synthesize contentURL = _contentURL;
@synthesize hashtag = _hashtag;
@synthesize peopleIDs = _peopleIDs;
@synthesize placeID = _placeID;
@synthesize ref = _ref;
@synthesize pageID = _pageID;
@synthesize shareUUID = _shareUUID;

#pragma mark - Initializer

- (instancetype)init
{
  self = [super init];
  if (self) {
    _shareUUID = [NSUUID UUID].UUIDString;
  }
  return self;
}

#pragma mark - Setters

- (void)setPeopleIDs:(NSArray *)peopleIDs
{
  [FBSDKShareUtility assertCollection:peopleIDs ofClass:NSString.class name:@"peopleIDs"];
  if (![FBSDKInternalUtility.sharedUtility object:_peopleIDs isEqualToObject:peopleIDs]) {
    _peopleIDs = [peopleIDs copy];
  }
}

- (void)setMedia:(NSArray<id<FBSDKShareMedia>> *)media
{
  [FBSDKShareUtility assertCollection:media ofClassStrings:@[NSStringFromClass(FBSDKSharePhoto.class), NSStringFromClass(FBSDKShareVideo.class)] name:@"media"];
  if (![FBSDKInternalUtility.sharedUtility object:_media isEqualToObject:media]) {
    _media = [media copy];
  }
}

#pragma mark - FBSDKSharingContent

- (NSDictionary<NSString *, id> *)addParameters:(NSDictionary<NSString *, id> *)existingParameters
                                  bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
{
  // FBSDKShareMediaContent is currently available via the Share extension only (thus no parameterization implemented at this time)
  return existingParameters;
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  if (![FBSDKShareUtility validateArray:_media minCount:1 maxCount:20 name:@"photos" error:errorRef]) {
    return NO;
  }
  int videoCount = 0;
  for (id media in _media) {
    if ([media isKindOfClass:FBSDKSharePhoto.class]) {
      FBSDKSharePhoto *photo = (FBSDKSharePhoto *)media;
      if (![photo validateWithOptions:bridgeOptions error:NULL]) {
        if (errorRef != NULL) {
          id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
          *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                              name:@"media"
                                                             value:media
                                                           message:@"photos must have UIImages"
                                                   underlyingError:nil];
        }
        return NO;
      }
    } else if ([media isKindOfClass:FBSDKShareVideo.class]) {
      if (videoCount > 0) {
        if (errorRef != NULL) {
          id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
          *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                              name:@"media"
                                                             value:media
                                                           message:@"Only 1 video is allowed"
                                                   underlyingError:nil];
          return NO;
        }
      }
      videoCount++;
      FBSDKShareVideo *video = (FBSDKShareVideo *)media;
      if (![FBSDKShareUtility validateRequiredValue:video name:@"video" error:errorRef]) {
        return NO;
      }
      if (![video validateWithOptions:bridgeOptions error:errorRef]) {
        return NO;
      }
    } else {
      if (errorRef != NULL) {
        id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
        *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                            name:@"media"
                                                           value:media
                                                         message:@"Only FBSDKSharePhoto and FBSDKShareVideo are allowed in `media` property"
                                                 underlyingError:nil];
      }
      return NO;
    }
  }
  return YES;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _contentURL.hash,
    _hashtag.hash,
    _peopleIDs.hash,
    _media.hash,
    _placeID.hash,
    _ref.hash,
    _pageID.hash,
    _shareUUID.hash,
  };
  return [FBSDKHasher hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKShareMediaContent.class]) {
    return NO;
  }
  return [self isEqualToShareMediaContent:(FBSDKShareMediaContent *)object];
}

- (BOOL)isEqualToShareMediaContent:(FBSDKShareMediaContent *)content
{
  return (content
    && [FBSDKInternalUtility.sharedUtility object:_contentURL isEqualToObject:content.contentURL]
    && [FBSDKInternalUtility.sharedUtility object:_hashtag isEqualToObject:content.hashtag]
    && [FBSDKInternalUtility.sharedUtility object:_peopleIDs isEqualToObject:content.peopleIDs]
    && [FBSDKInternalUtility.sharedUtility object:_media isEqualToObject:content.media]
    && [FBSDKInternalUtility.sharedUtility object:_placeID isEqualToObject:content.placeID]
    && [FBSDKInternalUtility.sharedUtility object:_ref isEqualToObject:content.ref]
    && [FBSDKInternalUtility.sharedUtility object:_shareUUID isEqualToObject:content.shareUUID]
    && [FBSDKInternalUtility.sharedUtility object:_pageID isEqualToObject:content.pageID]);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _contentURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_SHARE_MEDIA_CONTENT_CONTENT_URL_KEY];
    _hashtag = [decoder decodeObjectOfClass:FBSDKHashtag.class forKey:FBSDK_SHARE_MEDIA_CONTENT_HASHTAG_KEY];
    _peopleIDs = [decoder decodeObjectOfClass:NSArray.class forKey:FBSDK_SHARE_MEDIA_CONTENT_PEOPLE_IDS_KEY];
    NSSet<Class> *classes = [NSSet setWithObjects:NSArray.class, FBSDKSharePhoto.class, nil];
    _media = [decoder decodeObjectOfClasses:classes forKey:FBSDK_SHARE_MEDIA_CONTENT_MEDIA_KEY];
    _placeID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_MEDIA_CONTENT_PLACE_ID_KEY];
    _ref = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_MEDIA_CONTENT_REF_KEY];
    _pageID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_MEDIA_CONTENT_PAGE_ID_KEY];
    _shareUUID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_MEDIA_CONTENT_UUID_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_contentURL forKey:FBSDK_SHARE_MEDIA_CONTENT_CONTENT_URL_KEY];
  [encoder encodeObject:_hashtag forKey:FBSDK_SHARE_MEDIA_CONTENT_HASHTAG_KEY];
  [encoder encodeObject:_peopleIDs forKey:FBSDK_SHARE_MEDIA_CONTENT_PEOPLE_IDS_KEY];
  [encoder encodeObject:_media forKey:FBSDK_SHARE_MEDIA_CONTENT_MEDIA_KEY];
  [encoder encodeObject:_placeID forKey:FBSDK_SHARE_MEDIA_CONTENT_PLACE_ID_KEY];
  [encoder encodeObject:_ref forKey:FBSDK_SHARE_MEDIA_CONTENT_REF_KEY];
  [encoder encodeObject:_pageID forKey:FBSDK_SHARE_MEDIA_CONTENT_PAGE_ID_KEY];
  [encoder encodeObject:_shareUUID forKey:FBSDK_SHARE_MEDIA_CONTENT_UUID_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKShareMediaContent *copy = [FBSDKShareMediaContent new];
  copy->_contentURL = [_contentURL copy];
  copy->_hashtag = [_hashtag copy];
  copy->_peopleIDs = [_peopleIDs copy];
  copy->_media = [_media copy];
  copy->_placeID = [_placeID copy];
  copy->_ref = [_ref copy];
  copy->_pageID = [_pageID copy];
  copy->_shareUUID = [_shareUUID copy];
  return copy;
}

@end
