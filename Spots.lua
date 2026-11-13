local _, addon = ...
addon.spots = {
    {
        id = "condores", map = 1433, level = "16+", page = 43,
        name = "Carne de cóndor", zone = "Montañas Crestagrana",
        target = "Dire Condor · busca los cóndores al norte y al sur del lago Everstill.",
        loot = "Tough Condor Meat (1080) → Casa de subastas",
        areas = {{.395, .344, .065, .039}, {.572, .777, .105, .048}},
        outlines = {
            {{.326,.346},{.352,.327},{.400,.326},{.441,.303},{.453,.312},
             {.451,.350},{.420,.376},{.372,.373},{.345,.362}},
            {{.468,.777},{.482,.754},{.514,.745},{.551,.751},{.607,.772},
             {.647,.774},{.677,.757},{.669,.783},{.649,.800},{.614,.818},
             {.565,.823},{.521,.812},{.485,.798}},
        },
        color = {.25, .87, 1},
    },
    {
        id = "perlas", map = 1437, level = "20 norte / 25 sur", page = 72,
        name = "Perlas iridiscentes", zone = "Los Humedales",
        target = "Busca múrlocs costeros y abre las almejas del botín. Comprueba qué enemigos las sueltan en tu ruta.",
        loot = "Iridescent Pearl (5500) → Casa de subastas",
        areas = {{.16, .45, .036, .074}, {.095, .64, .052, .061}},
        color = {.46, .82, .94},
    },
    {
        id = "pieles", map = 1434, level = "30+", page = 50,
        name = "Pieles y botín gris", zone = "Norte de Vega de Tuercespina",
        target = "Mata bestias desollables cerca de Nesingwary y del lago Nazferiti.",
        loot = "Bristly Whisker → Vendedor · Cuero → Casa de subastas",
        areas = {{.35, .23, .116, .051}, {.47, .20, .085, .048}},
        color = {.51, .83, .42},
    },
}
