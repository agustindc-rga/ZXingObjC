/*
 * Copyright 2012 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ZXFinderPatternInfo.h"
#import "ZXQRCodeFinderPattern.h"

@interface ZXFinderPatternInfo ()

@property (nonatomic, retain) ZXQRCodeFinderPattern *bottomLeft;
@property (nonatomic, retain) ZXQRCodeFinderPattern *topLeft;
@property (nonatomic, retain) ZXQRCodeFinderPattern *topRight;

@end

@implementation ZXFinderPatternInfo

@synthesize bottomLeft;
@synthesize topLeft;
@synthesize topRight;

- (id)initWithPatternCenters:(NSArray *)patternCenters {
  if (self = [super init]) {
    self.bottomLeft = patternCenters[0];
    self.topLeft = patternCenters[1];
    self.topRight = patternCenters[2];
  }

  return self;
}

@end
