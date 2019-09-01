//
//  _UIBlurThroughEffect.h
//  MasterDetail
//
//  Created by Vladislav Prusakov on 01.09.2019.
//  Copyright © 2019 Vladislav Prusakov. All rights reserved.
//

#ifndef _UIBlurThroughEffect_h
#define _UIBlurThroughEffect_h

#import <UIKit/UIVisualEffect.h>

@interface _UIBlurThroughEffect : UIVisualEffect {

    long long _style;

}
+(UIVisualEffect *)_blurThroughWithStyle:(long long)arg1 ;
-(BOOL)isEqual:(id)arg1 ;
-(void)_updateEffectNode:(id)arg1 forTraitCollection:(id)arg2 ;
-(BOOL)_needsUpdateForTransitionFromTraitCollection:(id)arg1 toTraitCollection:(id)arg2 ;
-(BOOL)_needsUpdateForOption:(id)arg1 ;
-(BOOL)_needsUpdateForMovingToSuperview:(id)arg1 fromSuperview:(id)arg2 inEffectView:(id)arg3 ;
-(BOOL)_needsUpdateForMovingToWindow:(id)arg1 fromWindow:(id)arg2 inEffectView:(id)arg3 ;
@end


#endif /* _UIBlurThroughEffect_h */
