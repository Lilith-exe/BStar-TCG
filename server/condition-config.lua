-- All condition rates and timing live here. Values are percentage POINTS.
BStarConditionConfig = {
    enabled = true,
    recoveryKey = 'bstar:condition:completed:v1',
    sweepSeconds = 60,
    checkpointSeconds = 900,
    maxBatch = 100,
    daySeconds = 86400,
    hourSeconds = 3600,
    starting = { -- 80% of fresh copies land at 87-94; inclusive limits.
        { min=77, max=86, weight=12 },
        { min=87, max=94, weight=80 },
        { min=95, max=100, weight=8 }
    },
    duelWear = 2,
    daily = {
        box = { loss=1, noWearChance=0 },
        binder = { loss=1, noWearChance=30 },
        loose = { {loss=2,weight=75}, {loss=3,weight=20}, {loss=5,weight=5} },
        protected = { loss=1, wearChance=5 }
    },
    bulk = { graceSeconds=3*3600, minLoss=5, maxLoss=15 },
    public = { goodMin=70, playedMin=40 }
}
