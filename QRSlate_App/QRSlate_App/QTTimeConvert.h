//
//  QTTimeConvert.h
//  QRSlate_Print
//
//  Created by August Anderson on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>

@interface QTTimeConvert : NSObject
{

    QTMovie *mMovie;
    
    double fps;
    long timescale;
    long long timevalue;
    long sampleCount;
    
}

- (id) initWithMovie:(QTMovie*)initMovie;
- (id) initWithFPS:(double)setFPS sampleCount:(long)setSampleCount andTimeScale:(long)setTimescale;
- (id) initWithSampleCount:(long)setSampleCount timeValue:(long long)setTimeValue andTimeScale:(long)setTimescale;
- (id) initWithFPS:(double)setFPS timeValue:(long long)setTimeValue andTimeScale:(long)setTimescale;

- (void) setParameters;
- (QTTime) returnQTTimeOfLocationUsingFramecount:(int)mCurrentFrame;
- (int) returnIntegerOfLocationUsingQTTime:(QTTime)mCurrentTime;
- (double) returnTimevalue;

@end
