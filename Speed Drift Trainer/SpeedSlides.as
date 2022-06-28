float prevSpeed;
int accelArraySize = 4;
array<float> accelArray = {0, 0, 0, 0};
array<float> accelArrayNoAdjust = {0,0,0,0};
array<float> angleArray = {0,0,0,0};

float roadIntercept = -15.26260872;
float roadGradient = 0.4478882302;
float dirtIntercept = 46.06512662;
float dirtGradient = 0.990689286;
float greenIntercept = -76.41821143;
float greenGradient = 1.425354153;
float metalIntercept = -5.403709409;
float metalGradient = 0.439021825;
float plasticIntercept = -55.61774718;
float plasticGradient = 1.46779259;


vec3 worldNormalVec;
vec3 DriftDirVec = vec3(0,0,0);
vec3 prevDriftDirVec = vec3(0,0,0);
array<float> dotProductOfCarSlipArray = {0,0,0,0};
float dotProductOfCarSlipAverage = 0;
array<float> interialVectorArray = {0,0,0,0};
float averageinterialVector;
bool isDrifting = false;

array<float> leftBlueXPosArr = {0,0,0,0};
array<float> rightYellowXPosArr = {0,0,0,0};

vec3 currentVelocity;
vec3 normalisedCurrentVelocity;
float currAdjustedAngle;
float averageAngleDifference = 0;

int accelArrayIndex = 0;

CSceneVehicleVisState::EPlugSurfaceMaterialId surface;

float acc = 0;
float slope_adjusted_acc = 0;
float global_dt = 0;

int screenWidth;
int screenHeight;

[Setting name="Enable Plugin" description="Enables/ Disables the plugin."]
bool pluginEnabled = true;

[Setting name="Acceleration bar" description="Enables/ Disables acceleration bar."]
bool alwaysShowAccelBar = true;

[Setting name="Start Point of Accel bar vertically" description="" min="0" max="1" drag="true"]
float startBarAtFactor = 0.6f;

[Setting name="End Point of Accel bar vertically" description="" min="0" max="1" drag="true"]
float endBarAtFactor = 0.95f;

[Setting name="Position of bar horizontally"  min="0.1" max="0.9" drag="true"]
float leftBarAtFactor = 0.65f;

[Setting name="Acceleration Bar width" description="Width of the bar in pixels" min="5" max="200" drag="true"]
int barWidth = 50;

[Setting name="Display Raw Acceleration" description="Show Exact Current Velocity Delta below Accel Graph"]
bool displayRawAccel = false;

[Setting name="Gravity Acceleration Adjustment" description="Calculate acceleration independently of gravity"]
bool useSlopeAdjustedAcc = true;

[Setting name="Steer Coach On" description="Show Steer Coach Guide for Speed Drifts (400+)"]
bool showSteerSuggestion = true;

[Setting name="Steer Coach Horizontal Start Point" min="0.05" max="0.95" drag="true"]
float steerCoachHorizontalFactor = 0.65f;

[Setting name="Steer Coach Vertical Start Point" min="0.05" max="0.95" drag="true"]
float steerCoachVerticalFactor = 0.557f ;

[Setting name="Steer Coach Width" min="100" max="600"  ]
float steerCoachWidth = 364.0f;

[Setting name="Steer Coach Drift Sensitivity" min="0.1" max="1" description="Higher sensitivity gives more feedback but increases jumping" ]
float angleDiffFactor = 0.45;

[Setting name="Steer Coach Text" description="Show Steer Coach Instructions (Steer More/ Steer Less)"]
bool DisplayCoachText = true;

[Setting name="Steer Coach Raw Angular Acceleration" description="Show Exact Angular Acceleration and target Acceleration values above Coach bar"]
bool displayRawAngularAcc = false;

[Setting name="Steer Coach Always on" description="Display Speech Coach even at speeds too low to speed slide"]
bool alwaysShowSpeedSlide = false;

float steerCoachXPos;
float steerCoachXPosZeroPoint;
float steerCoachYPos;

float CoachTextXPos;
float CoachTextYPos;

float steerCoachHeight = 41.0f;
int updateRate = 1; //this is no longer a setting. it might as well be 1 since anything else just decreases the accuracy of calculations.
float Max_Accel_Value = 16.0f;

int barTop;
int barLeft;
int barHeight;

int barActiveTop;
int barActiveHeight;

float curAverAngleYPos;
float steer_Angle_Text_Y_Pos;
float radio_y_pos;

int renderTimeout = 0;

void OnSettingsChanged()
{
    CalculateBarCoordinates();
}

void CalculateBarCoordinates(){
    screenWidth = Draw::GetWidth();
    screenHeight = Draw::GetHeight();

    barHeight = int(screenHeight * (endBarAtFactor - startBarAtFactor));

    barTop = int(screenHeight*startBarAtFactor);
    barLeft = int(screenWidth*leftBarAtFactor);


    barActiveTop = int( barTop + barHeight * 10/13);
    barActiveHeight = int(barHeight * -1);

    steerCoachXPos =  int( steerCoachHorizontalFactor* screenWidth) - (steerCoachWidth-44)/2 - 2 ;
    steerCoachXPosZeroPoint = int( steerCoachHorizontalFactor* screenWidth);
    
    leftBlueXPosArr = {steerCoachXPos, steerCoachXPos, steerCoachXPos, steerCoachXPos};
    rightYellowXPosArr = {steerCoachXPos, steerCoachXPos, steerCoachXPos, steerCoachXPos};

    steerCoachYPos = int(screenHeight*steerCoachVerticalFactor);
    radio_y_pos = steerCoachYPos +38;
    curAverAngleYPos = steerCoachYPos -27;
    steer_Angle_Text_Y_Pos = steerCoachYPos -52;

    steerCoachHeight = 41.0;
    
    CoachTextXPos = steerCoachXPosZeroPoint-15;
    CoachTextYPos = radio_y_pos-40;
}

float CalculateVectorMagnitude(vec3 vector1){
    return Math::Sqrt( vector1.x * vector1.x + vector1.y * vector1.y + vector1.z * vector1.z );
}

float CalculateVectorDotProduct(vec3 vector1, vec3 vector2){
    return (vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z);
}

vec3 CalculateCrossProduct(vec3 vector1, vec3 vector2){
    float vecX = vector1.y * vector2.z - vector1.z * vector2.y;
    float vecY = vector1.z * vector2.x - vector1.x * vector2.z;
    float vecZ = vector1.x * vector2.y - vector1.y * vector2.x;
    vec3 returnVec = vec3(vecX, vecY, vecZ);

    return returnVec;
}

float CalculateAngle(vec3 vector1, vec3 vector2){
    float calculatedLiveAngle;

    float adjacent = CalculateVectorDotProduct(vector1, vector2);
    float magLivePosition = CalculateVectorMagnitude(vector1);
    float magvector2 = CalculateVectorMagnitude(vector2);
    float hypot = magLivePosition * magvector2;

    if(adjacent < 0.000001){
        calculatedLiveAngle = 0;
    }
    else if (adjacent > hypot){//bad trig
        calculatedLiveAngle = 0;
    }
    else{
        if(hypot < 0.000001){
            hypot = 0.000001;
        }

        calculatedLiveAngle = Math::Acos( Math::Abs(adjacent / hypot)  );
    }
    calculatedLiveAngle = calculatedLiveAngle * 1000;
    
    return calculatedLiveAngle;
}

void CalculateVelocityAngleDelta(){
    prevDriftDirVec = DriftDirVec;
    DriftDirVec = CalculateCrossProduct(worldNormalVec, normalisedCurrentVelocity); 
    dotProductOfCarSlipArray[accelArrayIndex] = CalculateAngle(prevDriftDirVec, DriftDirVec);
    
    float sum0 = 0;
    for (int n = 0; n < accelArraySize; n++) {
        sum0 += dotProductOfCarSlipArray[n];
    }
    dotProductOfCarSlipAverage = sum0 / accelArraySize;
    averageAngleDifference = dotProductOfCarSlipAverage / 1000;
}

void Update(float dt){
    global_dt = dt;
    //this is essential since framerate is not universal
}

void SimulationStep(){
    auto vis = VehicleState::ViewingPlayerState();
    surface = CSceneVehicleVisState::EPlugSurfaceMaterialId(vis.FLGroundContactMaterial);
    if(vis.FLSlipCoef > 0 and surface != CSceneVehicleVisState::EPlugSurfaceMaterialId::XXX_Null ){
        isDrifting = true;
    }
    else{
        isDrifting = false;
    }

    worldNormalVec = vis.WorldCarUp;
    currentVelocity = vis.WorldVel;
    normalisedCurrentVelocity = vis.Dir;
    float xzChangeEstimate = 0;
    float slopeEstimate = 0;

    xzChangeEstimate = Math::Sqrt(currentVelocity.x * currentVelocity.x + currentVelocity.z * currentVelocity.z);

    if(xzChangeEstimate < 0.01){
        xzChangeEstimate = 0.01;
    }

    slopeEstimate = Math::Atan(currentVelocity.y / xzChangeEstimate);
    CalculateVelocityAngleDelta();
    
    float front_speed = vis.FrontSpeed;
    float side_speed = VehicleState::GetSideSpeed(vis);
    float scalar_speed = Math::Sqrt(front_speed*front_speed + side_speed*side_speed);

    float raw_acc = (scalar_speed - prevSpeed) / (global_dt/1000);
    float true_acc = raw_acc + 29 * Math::Sin(slopeEstimate); 
    //until an exact value is found, 29 appears to be very close to certain clear cases

    if(useSlopeAdjustedAcc){
        accelArrayNoAdjust[accelArrayIndex] = true_acc;
    }
    else{
        accelArrayNoAdjust[accelArrayIndex] = raw_acc;
    }
    float sum2 = 0;
    for (int n = 0; n < accelArraySize; n++) {
        sum2 += accelArrayNoAdjust[n];
    }
    acc = sum2 / accelArraySize;
    if(Math::Abs(acc) < 0.2){
        acc = 0;
    }

    accelArray[accelArrayIndex] = true_acc;
    accelArrayIndex = (accelArrayIndex+1) % accelArraySize;
    float sum = 0;
    for (int n = 0; n < accelArraySize; n++) {
        sum += accelArray[n];
    }
    slope_adjusted_acc = sum / accelArraySize;
	
    if(Math::Abs(slope_adjusted_acc) < 0.2){
        slope_adjusted_acc = 0;
    }
    prevSpeed = scalar_speed;

    float adjustedSpeed = scalar_speed * 3.6;

    renderTimeout = updateRate;
}

void Main()
{
    print('main');
    while (Draw::GetWidth() == -1) {
		yield();
	}

    CalculateBarCoordinates();
}

void Render()
{
    if(!pluginEnabled){
        return;
    }
    
    //only display if actually in a drive state
    auto app = GetApp();
    auto sceneVis = app.GameScene;
    if (sceneVis is null) {
        return;
    }

    //render timeout/ update rate doesnt seem to cause performance issues so the need for this is slightly deprecated
    if (renderTimeout == 0)
	{
        SimulationStep();
	}


    float adjustedMaxAccelRoad = Max_Accel_Value * updateRate;

    float speedAdjustOpacityFactor = 0.5f;
    if(prevSpeed * 3.6 > 400){
        speedAdjustOpacityFactor = 1.0f;
    }
    else if (prevSpeed * 3.6 > 300){
        speedAdjustOpacityFactor = 0.75f;
    }

    if(alwaysShowAccelBar){
        nvg::BeginPath();
        nvg::RoundedRect(barLeft, barTop, barWidth, barHeight, 5.0f);
        nvg::StrokeWidth(3.0f);
        nvg::StrokeColor(vec4(1, 1, 1, 0.5));
        nvg::FillColor(vec4(0.3, 0.3, 0.3, 0.9f));
        nvg::Fill();
        nvg::ClosePath();
    }

    float speedCriticalValue = 400;
    float perfectBuffer = 0.3;//0.3 because test slides are not perfect and its more useful to not max out the bar

    float adjustedMaxAccelNoSlide = 16;
    float adjustedMaxAccelSpeedSlide = 16;
    float adjustedMaxAccelSpeed = 16;
    if(prevSpeed * 3.6 > 800){
        adjustedMaxAccelNoSlide = 1.05;
    }
    else if(prevSpeed * 3.6 > 400){
        adjustedMaxAccelNoSlide = 5.7;
    }
    else if(prevSpeed * 3.6 > 300){
        adjustedMaxAccelNoSlide = 7.3;
    }
    else if(prevSpeed * 3.6 > 200){
        adjustedMaxAccelNoSlide = 11;
    }
    if(prevSpeed * 3.6 > 400){
        adjustedMaxAccelSpeedSlide = 4.915 + prevSpeed*3.6*0.003984518249 + perfectBuffer; 
    }

    float steer_angle = 100 / (roadIntercept + prevSpeed *3.6 * roadGradient);
    if(surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Dirt){
        steer_angle = 100 / (dirtIntercept + prevSpeed *3.6 * dirtGradient);
        adjustedMaxAccelSpeedSlide = 9.39951+perfectBuffer;
        speedCriticalValue = 300;
    }
    else if(surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Green){
        steer_angle = 100 / (greenIntercept + prevSpeed *3.6 * greenGradient);
        adjustedMaxAccelSpeedSlide = 9.10985+perfectBuffer;
        speedCriticalValue = 300;
    }
    else if(surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::ResonantMetal){
        steer_angle = 100 / (metalIntercept + prevSpeed *3.6 * metalGradient);
        adjustedMaxAccelSpeedSlide = 5.116468878 + prevSpeed*3.6* 0.003598542825 + perfectBuffer;
    }
    else if(surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Plastic){
        steer_angle = 100 / (plasticIntercept + prevSpeed *3.6 * plasticGradient);
        adjustedMaxAccelSpeedSlide = 9.637077091 + prevSpeed*3.6*0.0004516594273 + perfectBuffer; 
        //debatably this is not even linear. r=>0.4
        //but since sin(x) approximates to x at low values, at worst this is only slightly wrong
        speedCriticalValue = 300;
    }
    else if(surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::XXX_Null){
        steer_angle = 0;
    }
    if(steer_angle < 0.01){steer_angle = 0.01;}

    if(alwaysShowAccelBar){
        nvg::BeginPath();
    }


    int superSlide;
    float barFactor = slope_adjusted_acc / adjustedMaxAccelSpeedSlide;
    if(slope_adjusted_acc - adjustedMaxAccelNoSlide > 1){
        superSlide = 0;
    }
    else if(slope_adjusted_acc - adjustedMaxAccelNoSlide > 0.5){
        superSlide = 1;
    }
    else if(slope_adjusted_acc - adjustedMaxAccelNoSlide > 0){
        superSlide = 2;
    }
    else if(slope_adjusted_acc - adjustedMaxAccelNoSlide > -0.5){
        superSlide = 3;
    }
    else{
        superSlide = 4;
    }

    if(barFactor > 1){
        barFactor = 1;
    }
    if(barFactor < -1){
        barFactor = -1;
    }

    float barPosColor = 0.5 + 0.5 * Math::Abs(barFactor);


    if(alwaysShowAccelBar){
        if(barFactor > 0){
            if(superSlide == 0){
                barPosColor = (barPosColor + 1)/2;
                nvg::Rect(barLeft, barActiveTop, barWidth, barActiveHeight * barFactor * 10/13 );
                nvg::FillColor(vec4(0, barPosColor, 0, 0.8f));
            }
            else if(superSlide == 1){
                barPosColor = (barPosColor*2 + 1)/3;
                nvg::Rect(barLeft, barActiveTop, barWidth, barActiveHeight * barFactor * 10/13 );
                nvg::FillColor(vec4(0, barPosColor, 0, 0.8f));
            }
            else if(superSlide == 2){
                barPosColor = (barPosColor*3 + 1)/4;
                nvg::Rect(barLeft, barActiveTop, barWidth, barActiveHeight * barFactor * 10/13 );
                nvg::FillColor(vec4(0.2*barPosColor, barPosColor, 0, 0.8f));
            }
            else if(superSlide == 3){
                nvg::Rect(barLeft, barActiveTop, barWidth, barActiveHeight * barFactor * 10/13 );
                nvg::FillColor(vec4(0.5*barPosColor, barPosColor, 0, 0.8f));
            }
            else{
                nvg::Rect(barLeft, barActiveTop, barWidth, barActiveHeight * barFactor * 10/13 );
                nvg::FillColor(vec4(barPosColor, barPosColor, 0, 0.8f));
            }
        }
        else if (barFactor < 0){
            nvg::Rect(barLeft, barActiveTop, barWidth, barActiveHeight * barFactor * 3/13 );
            nvg::FillColor(vec4(barPosColor, 0, 0, 0.8f));
        }
        else if(barFactor == 0){
            nvg::Rect(barLeft, barActiveTop, barWidth, barActiveHeight * barFactor * 3/13 );
            nvg::FillColor(vec4(0, 0, 0, 0));
        }
        nvg::Fill();
        nvg::ClosePath();

        nvg::BeginPath();
        nvg::Rect(barLeft, barActiveTop, barWidth, 3);
        nvg::FillColor(vec4(0, 0, 0, 1 * speedAdjustOpacityFactor));
        nvg::Fill();
        nvg::ClosePath();

        for(int n = 1; n < 13; n++){
            int height = barTop + n * barHeight / 13;
            nvg::BeginPath();
            nvg::Rect(barLeft+2, height, int(barWidth/4), 1);
            nvg::FillColor(vec4(1, 1, 1, 1 * speedAdjustOpacityFactor));
            nvg::Fill();
            nvg::ClosePath();
        }


        if(displayRawAccel){
            float accel_y_pos = barTop + barHeight + 20;
            nvg::FontSize(25.0f);
            if(slope_adjusted_acc > 0){
                nvg::FillColor(vec4(0, 1, 0, 1));
                nvg::TextBox(barLeft, accel_y_pos, 80.0f, Text::Format("%.1f", Math::Abs(slope_adjusted_acc)));

            }
            else{
                nvg::FillColor(vec4(1, 0, 0, 1));
                nvg::TextBox(barLeft, accel_y_pos, 80.0f, Text::Format("%.1f", Math::Abs(slope_adjusted_acc)));

            }
        }
    }

    if(showSteerSuggestion){
        if(prevSpeed *3.6 > speedCriticalValue or alwaysShowSpeedSlide){
            
            float currRawAngle = 100*averageAngleDifference;
            currAdjustedAngle = 100*averageAngleDifference - 100*averageinterialVector;
            nvg::FontSize(25.0f);
            
            if(displayRawAngularAcc){
                nvg::FillColor(vec4(0, 0, 0, 1*speedAdjustOpacityFactor));
                nvg::TextBox(steerCoachXPosZeroPoint, curAverAngleYPos, 80.0f, Text::Format("%.1f",  10*currAdjustedAngle ));	

                nvg::FillColor(vec4(1, 1, 1, 1*speedAdjustOpacityFactor));
                nvg::TextBox(steerCoachXPosZeroPoint, steer_Angle_Text_Y_Pos, 80.0f, Text::Format("%.1f",  10*steer_angle ));
            }

            //blue and yellow radio icons, when crosssed (close to ideal, show green RadioChecked)
            float percAngleDiff = (steer_angle - currAdjustedAngle)/(steer_angle);
            float angleDiffOverlay = percAngleDiff * 1200 * angleDiffFactor;
            if(angleDiffOverlay > (steerCoachWidth-44)/2){
                angleDiffOverlay = (steerCoachWidth-44)/2;
            }
            if(angleDiffOverlay < -1 * (steerCoachWidth-44)/2){
                angleDiffOverlay = -1 * (steerCoachWidth-44)/2;
            }

            //coach box
            vec4 fillColorCoachBox = vec4(0.8, 0.8, 0.8, 0.9f);
            if(isDrifting == true ){
                fillColorCoachBox = vec4(0.3, 0.3, 0.3, 0.9f);
            }
            nvg::BeginPath();
            nvg::RoundedRect(steerCoachXPos, steerCoachYPos, steerCoachWidth, steerCoachHeight, 5.0f);
            nvg::StrokeColor(vec4(1, 1, 1, 0.5));
            nvg::FillColor(fillColorCoachBox);
            nvg::Fill();
            nvg::ClosePath();

            leftBlueXPosArr[accelArrayIndex] = Math::Round(steerCoachXPosZeroPoint + angleDiffOverlay);
            rightYellowXPosArr[accelArrayIndex] = Math::Round(steerCoachXPosZeroPoint - angleDiffOverlay);
            
            float leftBlueXPosSum = 0;
            float rightYellowXPosSum = 0;

            for (int n = 0; n < accelArraySize; n++) {
                leftBlueXPosSum += leftBlueXPosArr[n];
                rightYellowXPosSum += rightYellowXPosArr[n];
            }

            float leftBlueXPos = leftBlueXPosSum / accelArraySize;
            float rightYellowXPos = rightYellowXPosSum / accelArraySize;

            nvg::FontSize(40.0f);
            float criticalOverlap =0.05;

            if(isDrifting == true){
                nvg::FillColor(vec4(0, 1, 1, 0.8f));
                nvg::TextBox(leftBlueXPos, radio_y_pos, 20.0f, Icons::Kenney::Radio );

                nvg::FillColor(vec4(1, 1, 0, 0.8f));
                nvg::TextBox(rightYellowXPos, radio_y_pos, 20.0f, Icons::Kenney::Radio );

                if(Math::Abs(percAngleDiff) < criticalOverlap){
                    //display overlap
                    float checkedVariance = 0.4 + 10* Math::Abs(steer_angle - currAdjustedAngle);
                    
                    nvg::FillColor(vec4(1, 1, 1, 0.8f));
                    nvg::TextBox(steerCoachXPosZeroPoint, radio_y_pos, 20.0f, Icons::Kenney::RadioChecked );
                }
            }


            if(DisplayCoachText){
                nvg::FontSize(25.0f);

                if(isDrifting ==true){
                    if(percAngleDiff > criticalOverlap){
                        //steer more 
                        nvg::FillColor(vec4(1, 1, 0, 0.8f));
                        nvg::TextAlign(nvg::Align::Center);
                        nvg::TextBox(CoachTextXPos, CoachTextYPos, 80.0f, "More" );
                    }
                    else if (percAngleDiff < -1* criticalOverlap){
                        nvg::FillColor(vec4(0, 1, 1, 0.8f));
                        nvg::TextAlign(nvg::Align::Center);
                        nvg::TextBox(CoachTextXPos, CoachTextYPos, 80.0f, "Less" );
                    }
                }
                else{
                    nvg::FillColor(vec4(1, 0, 1, 0.8f));
                    nvg::TextAlign(nvg::Align::Center);
                    nvg::TextBox(CoachTextXPos, CoachTextYPos, 80.0f, "Drift!" );
                }
            }
        }
    }

    renderTimeout = renderTimeout - 1;
}
