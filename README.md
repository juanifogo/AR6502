# AR6502
 Codigo para mi implementacion de la computadora [BE6502](https://eater.net/6502)

## Como compilar
 Para poder compilar los archivos .asm en el directorio /src, es necesario tener instalado el ensamblador vasm para la familia de microprocesadores 6502. Este tiene su codigo fuente en la [pagina oficial](http://sun.hasenbraten.de/vasm/). Alternativamente se pueden instalar los binarios precompilador para Windows, Mac, o Linux mediante este [link directo.](http://www.ibaug.de/vasm/vasm6502.zip)

 Tambien es necesario tener acceso a la utilidad hexdump, la cual viene preinstalada en la mayoría de sistemas operativos. Yo usé la version de Linux que viene con el kit de desarrollo  de C/C++ para Windows [w64devkit.](https://bjansen.github.io/scoop-apps/extras/w64devkit/) Es posible que otras versiones no funcionen.

 Ambas utilidades deben estar dentro del PATH, para que el script build.ps1 pueda correr. Este script toma como entrada un archivo de assembly, con sintaxis para el MOS6502, lo ensambla y lo guarda en ./src/bin. Opcionalmente tom la flag ```-wozmon```, la cual crea un archivo de texto en ./src/wozmonInstructions. Este archivo contendrá comandos en un formato directamente copiable a la interfaz de Wozmon, el programa monitor con el que venía la computadora Apple 1, diseñada por Steve Wozniak en 1976.
 
 Al enviar estas instrucciones a la computadora, se cargará el programa ensamblado en la memoria de la computadora, a partir de la dirección $1000.

 Siguiendo el modelo en el que me basé, Wozmon usa como interfaz con el usuario un puerto serial en vez de una pantalla y un teclado, por lo que los programas no tienen que ser escritos a mano en binario. Usando la utilidad ```paste_delay.py``` en ./src/wozmonInstructions, uno puede pasar como parametro el archivo de texto generado con la otra utilidad, y escribir los caracteres en en un emulador de terminal como [TeraTerm](https://tera-term.softonic.com/?ex=RAMP-1097.1) de manera automatica. Además se pueden pasar dos parametros opcionales para retrasar el enviado de los caracteres.

 ## Creditos
  Gracias a Ben Eater por crear su excelente serie de videos sobre como crear esta computadora, sin ellos este proyecto nunca podría haber existido