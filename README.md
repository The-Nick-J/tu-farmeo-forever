# Tu Farmeo Forever

Alfa 0.1.1 para WoW Forever (interfaz 16001). Muestra zonas sombreadas y un HUD con objetivos, botín y sesiones manuales.

## Instalar

Descarga el ZIP de la versión o copia la carpeta del repositorio a `World of Warcraft/_forever_/Interface/AddOns/TuFarmeoForever`. El archivo `TuFarmeoForever.toc` debe quedar directamente dentro de esa carpeta. Reinicia WoW si está abierto y activa el add-on.

## Usar

- Abre con M y entra al mapa de Crestagrana, Los Humedales o Vega de Tuercespina.
- Pasa el mouse sobre el sombreado para ver la ficha. Pulsa el marcador de moneda para elegir el spot.
- `/tf` abre o cierra el HUD. También puedes escoger el spot desde el HUD con **Siguiente**.
- Inicia una sesión, farmea y pulsa **Detener**. Ingresa el oro directo más el de vendedor y, opcionalmente, el valor estimado de AH **ya descontada la comisión**. Usa decimales en oro, por ejemplo 0,75 para 75 de plata.
- El promedio usa todo el tiempo de las sesiones guardadas. La AH estimada se suma al oro directo y de vendedor y se muestra como estimación. Las sesiones y preferencias se guardan localmente en SavedVariables.
- Los contornos son aproximados. En la vista continua de OpenMap, el add-on usa su API para proyectar las zonas y dibujarlas sobre el mapa. Acércate a la región para ver el sombreado con detalle.

El repositorio contiene código legible y fichas breves redactadas para el add-on. Los números de página sirven para consultar una copia propia de la guía V1.2. El PDF, sus imágenes y las sesiones personales se mantienen fuera del repositorio.
