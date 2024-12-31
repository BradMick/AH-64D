


private _fixedUpdateRate = 50; //frames per second
private _fixedUpdateTime = 0.02;//1 / _fixedUpdateRate;

if (isGamePaused) exitWith { _fza_sfmplus_fixedDeltaTime = 0.0; };

fza_sfmplus_accumulator  = fza_sfmplus_accumulator + fza_sfmplus_deltaTime;

while { fza_sfmplus_accumulator >= _fixedUpdateTime } do {
    fza_sfmplus_fixedCurrentTime  = diag_tickTime;
    fza_sfmplus_fixedDeltaTime    = fza_sfmplus_fixedCurrentTime - fza_sfmplus_fixedPreviousTime;
    fza_sfmplus_fixedPreviousTime = fza_sfmplus_fixedCurrentTime;

    fza_sfmplus_fixedDeltaTime   = fza_sfmplus_fixedDeltaTime * accTime;

    systemChat format ["Fixed Update!"];

   
    fza_sfmplus_accumulator = fza_sfmplus_accumulator - _fixedUpdateTime;
};

systemChat format ["FPS = %1 -- _fixedDeltaTime = %2", diag_fps, fza_sfmplus_fixedDeltaTime toFixed 3];