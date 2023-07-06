maxOmega			= 2000;
numberPhysicalWheels = 3;

class Wheels
{
    disableWheelsWhenDestroyed = 1;
    class Wheel_1
    {
        boneName					= "Wheel_1";
        steering					= false;
        side						= "right";
        center						= "Wheel_1_center";
        boundary					= "Wheel_1_rim";
        width						= 0.4;
        mass						= 20;
        MOI							= 0.4;
        dampingRate					= 0.1;
        dampingRateDamaged			= 1;
        dampingRateDestroyed		= 1000;
        maxBrakeTorque				= 2000;
        maxHandBrakeTorque			= 0;
        suspTravelDirection[]		= {0, -1, -1};
        suspForceAppPointOffset		= "Wheel_1_center";
        tireForceAppPointOffset		= "Wheel_1_center";
        maxCompression				= 0.3;
        maxDroop					= 0.0;
        sprungMass					= 3400;
        springStrength				= 12000;
        springDamperRate			= 1280;
        longitudinalStiffnessPerUnitGravity	= 5000;
        latStiffX					= 3;
        latStiffY					= 20.0;
        frictionVsSlipGraph[]		= {{0, 1}, {0.5, 1}, {1,1}};
    };
    class Wheel_2: Wheel_1
    {
        steering					= false;
        boneName					= "Wheel_2";
        center						= "Wheel_2_center";
        boundary					= "Wheel_2_rim";
        suspForceAppPointOffset		= "Wheel_2_center";
        tireForceAppPointOffset		= "Wheel_2_center";
    };
    class Wheel_3: Wheel_2
    {
        boneName					= "Wheel_3";
        side						= "right";
        center						= "Wheel_3_center";
        boundary					= "Wheel_3_rim";
        //width						= 0.4;
        mass						= 20;
        MOI							= 0.4;
        dampingRate					= 0.1;
        dampingRateDamaged			= 1;
        dampingRateDestroyed		= 1000;
        maxBrakeTorque				= 2000;
        maxHandBrakeTorque			= 0;
        suspTravelDirection[]		= {0, -1, -0.65};
        suspForceAppPointOffset		= "Wheel_1_center";
        tireForceAppPointOffset		= "Wheel_1_center";
        maxCompression				= 0.3;
        maxDroop					= 0.0;
        sprungMass					= 3400;
        springStrength				= 12000;
        springDamperRate			= 1280;
        suspForceAppPointOffset		= "Wheel_3_center";
        tireForceAppPointOffset		= "Wheel_3_center";
    };
};