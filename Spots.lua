local _, addon = ...
addon.spots = {
    {
        id = "condores", map = 1433, level = "16+", page = 43,
        name = "Carne de cóndor", zone = "Montañas Crestagrana",
        target = "Dire Condor · busca los cóndores al norte y al sur del lago Everstill.",
        loot = "Tough Condor Meat (1080) → Casa de subastas",
        areas = {{.43, .31, .062, .029}, {.62, .69, .103, .045}},
        color = {.95, .68, .24},
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
