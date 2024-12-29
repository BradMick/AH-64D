


private _fixedUpdateRate = 50; //frames per second
private _fixedUpdateTime = 1 / _fixedUpdateRate;

private _accumulator = 0.0;
_accumulator         = _accumulater + fza_sfmplus_deltaTime;

while (_accumulator >= _fixedUpdateTime) do {
    

    _accumulator -= _fixedUpdateTime;
};