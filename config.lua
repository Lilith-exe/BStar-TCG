print('[BStar Config] config.lua loaded on client/server side')
print('[BStar Config] Config before init =', Config)

Config = Config or {}

Config.Debug = true

Config.TestCommand = 'cardtest'

Config.DefaultCardId = 'ALPH_LAYLA_HART'

Config.DuelTables = {
    {
        id = "beach_table_1",
        label = "BStar Duel Table",
        coords = vec3(-1267.44, -1457.14, 4.18),
        heading = 126.25,

        target = {
            length = 1.6,
            width = 1.0,
            minZ = 3.4,
            maxZ = 5.0
        },

        seat = {
            coords = vec3(-1268.10, -1457.95, 4.18),
            heading = 310.25
        },

        camera = {
            pos = vec3(-1266.38, -1456.30, 5.80),
            point = vec3(-1267.45, -1457.15, 4.20),
            fov = 27.0
        }
    }
}