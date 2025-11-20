import oscP5.*;  // Librería OSC
import netP5.*;  // Red

OscP5 oscP5;  // Manejador OSC
int puerto;   // Puerto local

ArrayList<Tile> tiles = new ArrayList<Tile>();  // Lista de cuadrados (tiles)
float tileHeight = 60;  // Alto del tile
int maxTiles = 500;  // Máximo de tiles
int numCirculosActual = 0;  // Contador de tiles creados

int numLanes = 5;  // Q, W, E, R, T
float laneWidth;  // Ancho de cada carril
float hitZoneY;   // Y de la zona de golpe
float hitZoneHeight = 50;  // Altura de la zona de golpe

color[] coloresTeclas = {          // Color base por carril
  color(255, 165, 0),
  color(255, 255, 0),
  color(255, 165, 0),
  color(255, 255, 0),
  color(255, 165, 0)
};
color colorCorrecto = color(173, 216, 230);  // Azul claro acierto
boolean[] teclasPresionadas = new boolean[5];  // Estado Q,W,E,R,T

int contadorAciertos = 0;  // Aciertos seguidos
int nivel = 0;  // Nivel actual
int contadorEstrellas = 0;  // Estrellas
color[] coloresFondo = {
  color(0),
  color(50, 50, 150),
  color(100, 50, 100),
  color(50, 150, 50),
  color(150, 100, 50),
  color(100, 50, 50)
};

void setup() {
  size(400, 400);  // Ventana
  background(255); // Fondo

  puerto = 11111;  // Puerto OSC
  oscP5 = new OscP5(this, puerto);  // Inicializa OSC

  laneWidth = width / float(numLanes);  // Ancho por carril
  hitZoneHeight = 50;  // Zona de golpe
  hitZoneY = height - hitZoneHeight;  // Abajo

  cargarDatosDeArchivo("melbourne_tiles.csv");  // Carga CSV
}

void draw() {
  background(coloresFondo[nivel]);  // Fondo por nivel
  noStroke();

  // Carriles y zonas de golpe
  for (int i = 0; i < numLanes; i++) {
    float xStart = i * laneWidth;  // Inicio carril

    drawRectangle(xStart, hitZoneY, laneWidth, hitZoneHeight, color(255));  // Base blanca

    boolean hayTileEnArea = false;  // Indica si hay tile en la zona de golpe
    for (Tile t : tiles) {
      if (t.laneIndex == i && t.y + t.h / 2 >= hitZoneY && t.y - t.h / 2 <= hitZoneY + hitZoneHeight) {  // Tile en zona
        hayTileEnArea = true;  // True si está en la zona
        break;
      }
    }

    color rectColor = coloresTeclas[i];  // Color base del carril

    if (teclasPresionadas[i]) {  // Si se presiona tecla
      rectColor = hayTileEnArea ? colorCorrecto : color(255, 0, 0);  // Acierto o fallo
    }

    drawRectangle(xStart, 0, laneWidth, height, color(0, 0, 0, 20));  // Carril tenue
    drawRectangle(xStart, hitZoneY, laneWidth, hitZoneHeight, rectColor);  // Zona activa
  }

  // Actualizar y dibujar tiles
  for (int i = tiles.size() - 1; i >= 0; i--) {
    Tile t = tiles.get(i);  // Tile actual
    if (millis() >= t.tiempoGeneracion) {  // Solo se mueve si ya llegó su tiempo
      t.update();  // Actualiza posición
      t.display(); // Dibuja el tile

      // Revisión de acierto en zona de golpe
      for (int j = 0; j < numLanes; j++) {
        if (t.laneIndex == j && t.y + t.h / 2 >= hitZoneY && t.y - t.h / 2 <= hitZoneY + hitZoneHeight) {  // Está en la zona
          if (teclasPresionadas[j] && !t.mensajeImpreso) {  // Tecla correcta y aún no contado
            println("Nota del tile: " + t.nota);  // Mensaje
            t.mensajeImpreso = true;  // Marca como usado

            OscMessage mensajeOSC = new OscMessage("/notaCorrecta");  // Mensaje OSC acierto
            mensajeOSC.add(t.nota);  // Envia nota
            oscP5.send(mensajeOSC, new NetAddress("192.168.1.9", 11111));  // IP destino

            contadorAciertos++;  // Suma aciertos

            if (contadorAciertos % 10 == 0) {  // Cada 10 aciertos
              contadorEstrellas++;  // Suma estrella
              if (contadorEstrellas > 10) contadorEstrellas = 10;  // Máx 10
              nivel++;  // Sube nivel
              if (nivel >= coloresFondo.length) nivel = coloresFondo.length - 1;  // Límite superior

              OscMessage nextLevelMsg = new OscMessage("/nextLevel");  // Mensaje cambio de nivel
              nextLevelMsg.add(1);  // Usa 1 en vez de true
              oscP5.send(nextLevelMsg, new NetAddress("192.168.1.9", 11111));  // IP destino
            }
          }
        }
      }
    }

    if (t.y - t.h / 2 > height) {  // Si el tile sale de pantalla
      tiles.remove(i);  // Eliminar
    }
  }

  // Fallos (tecla sin tile en zona)
  for (int i = 0; i < numLanes; i++) {
    if (teclasPresionadas[i]) {  // Solo si se presiona tecla
      boolean hayTileEnArea = false;  // Reset bandera

      for (Tile t : tiles) {
        if (t.laneIndex == i && t.y + t.h / 2 >= hitZoneY && t.y - t.h / 2 <= hitZoneY + hitZoneHeight) {  // Hay tile
          hayTileEnArea = true;
          break;
        }
      }

      if (!hayTileEnArea) {  // No hay tile y se presionó tecla
        println("No hay tiles en el carril " + (i + 1) + ".");  // Mensaje fallo

        OscMessage mensajeOSC = new OscMessage("/notaIncorrecta");  // Mensaje fallo
        mensajeOSC.add(1);  // Usa 1 en vez de true
        oscP5.send(mensajeOSC, new NetAddress("192.168.1.9", 11111));  // IP destino

        contadorAciertos = 0;  // Reset aciertos
        nivel = 0;  // Reset nivel
        contadorEstrellas = 0;  // Reset estrellas
      }
    }
  }

  fill(255);  // Texto blanco
  textSize(16);  // Tamaño texto
  text("Aciertos: " + contadorAciertos, 10, 20);  // Mostrar aciertos

  for (int i = 0; i < contadorEstrellas; i++) {
    fill(255, 215, 0);  // Dorado
    text("★", 10 + i * 15, 40);  // Estrellas
  }
}

void keyPressed() {
  if (key == 'q' || key == 'Q') teclasPresionadas[0] = true;  // Q
  if (key == 'w' || key == 'W') teclasPresionadas[1] = true;  // W
  if (key == 'e' || key == 'E') teclasPresionadas[2] = true;  // E
  if (key == 'r' || key == 'R') teclasPresionadas[3] = true;  // R
  if (key == 't' || key == 'T') teclasPresionadas[4] = true;  // T


}

void keyReleased() {
  if (key == 'q' || key == 'Q') teclasPresionadas[0] = false;  // Q
  if (key == 'w' || key == 'W') teclasPresionadas[1] = false;  // W
  if (key == 'e' || key == 'E') teclasPresionadas[2] = false;  // E
  if (key == 'r' || key == 'R') teclasPresionadas[3] = false;  // R
  if (key == 't' || key == 'T') teclasPresionadas[4] = false;  // T
}

// Lee melbourne_tiles.csv con columnas beat,lane,vel,mag
void cargarDatosDeArchivo(String rutaArchivo) {
  Table tabla = loadTable(rutaArchivo, "header");  // Carga tabla

  for (TableRow row : tabla.rows()) {
    if (numCirculosActual >= maxTiles) break;  // Límite de tiles

    int beat = row.getInt("beat");  // Beat temporal
    int laneIndex = row.getInt("lane");  // Carril 0..4
    float vel = row.getFloat("vel");  // Velocidad
    float mag = row.getFloat("mag");  // Magnitud (temperatura)

    int tiempoGeneracion = beat * 400;  // Cada beat = 400 ms

    laneIndex = constrain(laneIndex, 0, numLanes - 1);  // Seguridad

    float tileWidth = laneWidth * 0.8;  // Tile un poco más angosto que el carril
    float inicioX = laneIndex * laneWidth + laneWidth / 2.0;  // Centro del carril
    float inicioY = -tileHeight;  // Arriba de la pantalla

    color col = color(  // Color basado en magnitud
      map(mag, 0, 20, 0, 255),
      200,
      map(mag, 0, 20, 255, 50)
    );

    float nota = map(mag, 0, 20, 60, 84);  // Nota MIDI aproximada
    nota = constrain(nota, 0, 127);  // Límite MIDI

    tiles.add(new Tile(inicioX, inicioY, tileWidth, tileHeight, col, vel, tiempoGeneracion, nota, laneIndex));  // Añadir tile
    numCirculosActual++;  // Contador
  }
}

// Clase Tile para cuadrados tipo Piano Tiles
class Tile {
  float x, y;  // Centro
  float w, h;  // Ancho y alto
  float velocidad;  // Velocidad de caída
  color col;  // Color
  int tiempoGeneracion;  // Cuándo aparece
  float nota;  // Nota asociada
  int laneIndex;  // Carril
  boolean mensajeImpreso = false;  // Para no repetir OSC

  Tile(float x, float y, float w, float h, color col, float velocidad, int tiempoGeneracion, float nota, int laneIndex) {
    this.x = x;  // Centro X
    this.y = y;  // Centro Y
    this.w = w;  // Ancho
    this.h = h;  // Alto
    this.col = col;  // Color
    this.velocidad = velocidad;  // Velocidad
    this.tiempoGeneracion = tiempoGeneracion;  // Tiempo aparición
    this.nota = nota;  // Nota
    this.laneIndex = laneIndex;  // Carril
  }

  void update() {
    y += velocidad;  // Caer hacia abajo
  }

  void display() {
    fill(col);  // Color del tile
    rect(x - w / 2, y - h / 2, w, h);  // Rectángulo centrado
  }
}

void drawRectangle(float x, float y, float w, float h, color c) {
  fill(c);  // Color
  rect(x, y, w, h);  // Rect modo CORNER
}
