//
//  QTTimeConvert.m
//  QRSlate_Print
//
//  Created by August Anderson on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "QTTimeConvert.h"


@implementation QTTimeConvert

- (id) initWithMovie:(QTMovie*)initMovie
{
    mMovie = initMovie;
    [self setParameters];
    return self;
}

- (void)dealloc
{
    [super dealloc];

    [mMovie release];
    
}

//---------------------------------------------------------------------------------------------------------------------------
- (id) initWithFPS:(double)setFPS sampleCount:(long)setSampleCount andTimeScale:(long)setTimeScale
{
    fps = setFPS;
    sampleCount = setSampleCount;
    timescale = setTimeScale;
    return self;    
}

//---------------------------------------------------------------------------------------------------------------------------
- (id) initWithSampleCount:(long)setSampleCount timeValue:(long long)setTimeValue andTimeScale:(long)setTimeScale
{
    sampleCount = setSampleCount;
    timevalue = setTimeValue;
    timescale = setTimeScale;
    return self;    
}

//---------------------------------------------------------------------------------------------------------------------------
- (id) initWithFPS:(double)setFPS timeValue:(long long)setTimeValue andTimeScale:(long)setTimeScale
{
    fps = setFPS;
    timevalue = setTimeValue;
    timescale = setTimeScale;
    return self;    
}

//---------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------
- (void) setParameters
{
    fps = 0;
    
    for (QTTrack* track in [mMovie tracks])
    {
        QTMedia* trackMedia = [track media];
        
        if ([trackMedia hasCharacteristic:QTMediaCharacteristicHasVideoFrameRate])
        {            
            QTTime mediaDuration = [(NSValue*)[trackMedia attributeForKey:QTMediaDurationAttribute] QTTimeValue];
            
            timescale = mediaDuration.timeScale;
            timevalue = mediaDuration.timeValue;
            sampleCount = [(NSNumber*)[trackMedia attributeForKey:QTMediaSampleCountAttribute] longValue];
            
            // Equation supplied by Apple to determine FPS
            fps = (double)sampleCount * ((double)timescale / (double)timevalue);
                        
            break;
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------------
- (QTTime) returnQTTimeOfLocationUsingFramecount:(int)mCurrentFrame
{
    double localTimevalue = 0;
    
    localTimevalue = ((double)mCurrentFrame*(double)timescale)/(double)fps;
    
    QTTime time = QTMakeTime(localTimevalue, timescale);
    return time;
}

//---------------------------------------------------------------------------------------------------------------------------
- (int) returnIntegerOfLocationUsingQTTime:(QTTime)mCurrentTime
{
    double currentFrame = 0;
    
    long long currentDurationTimeValue = mCurrentTime.timeValue;
    long currentDurationScaleValue = mCurrentTime.timeScale;
            
    // Uses a variation of determining framerate to determine the frame that is currently being viewed.
    currentFrame = fps / ( (double)currentDurationScaleValue / (double)currentDurationTimeValue );
    
    return (int)currentFrame;

}

//---------------------------------------------------------------------------------------------------------------------------
- (double) returnTimevalue
{    
    double newTimeValue;
    newTimeValue = ((double)sampleCount * (double)timescale) / (double)fps;
    
    // Returns the TimeValue, which is representative of Location or Duration
    return newTimeValue;    
}

@end
