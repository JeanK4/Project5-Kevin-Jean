# Data-Driven Visual & Audio Sonification System  
### *Processing + Pure Data — Mini-Project 5 (Sistemas de Interacción)*

## Team Members
- **Kevin Yavari Yoshioka**  
- **Jean Karlo Buitrago Orozco**

---

## Project Overview
This project implements a **real-time visualizer and sonification system** using **Processing** and **Pure Data (Pd)**.  
Based on a public dataset, the program transforms numerical information into a **Piano Tiles–style visual gameplay system** and a **dynamic audio output** triggered by the user’s interactions.

As the data is processed, tiles fall across 5 lanes. The user plays by pressing the corresponding keys (Q, W, E, R, T). Each interaction sends OSC messages to Pure Data, which generates different types of sound depending on the event:

- **Correct Hit** → Plays a note derived from dataset values  
- **Incorrect Hit / Miss** → Triggers an error sound  
- **10 Consecutive Hits** → Plays a special “level-up” sound  

This system demonstrates how **visual changes** and **sound behavior** can represent data in parallel, fulfilling the visualization + sonification requirements of the assignment.

---

## Dataset  
We used the **Melbourne Temperature Dataset**, converted into a structured CSV (`melbourne_tiles.csv`) with the following fields:

- `beat` — time at which the tile should appear  
- `lane` — lane index (0–4)  
- `vel` — falling speed  
- `mag` — magnitude (temperature) mapped to color and pitch  

This dataset was chosen because it provides continuous numeric values that can be intuitively mapped to:

- **Pitch** (higher temperatures → higher notes)  
- **Color** (hotter colors → higher magnitudes)  
- **Speed** (greater variation → dynamic motion)  

This creates a meaningful, data-driven multimodal experience.

---

## Visual System (Processing)
The Processing sketch creates a **5-lane rhythm-game interface** with:

- Falling tiles whose **color, pitch, and behavior** come directly from the dataset  
- A **hit zone** at the bottom used to detect timing accuracy  
- Background color variations depending on the current level  
- Live counters for:
  - Consecutive hits  
  - Stars earned (every 10 hits)  
  - Current difficulty level  

### User Interaction  
- Keys **Q W E R T** correspond to the 5 lanes  
- A hit is considered correct when a tile is in the hit zone  
- Wrong timing resets the streak, level, and stars  

---

## Sonification with Pure Data
Pure Data receives OSC messages from Processing and generates the corresponding audio signal.

### OSC Events Implemented
| OSC Address       | Trigger Condition                           | Description |
|------------------|-----------------------------------------------|-------------|
| `/notaCorrecta`  | Correct hit                                   | Plays a dataset-derived note |
| `/notaIncorrecta`| Key press without tile in hit zone            | Miss/error sound |
| `/nextLevel`     | Every 10 consecutive correct hits             | Level-up sound |

The Pd patch processes these events using oscillators, envelopes, and sample playback to produce a clear audio representation of accuracy and progression.

---

## OSC Communication
Processing uses the `oscP5` library to send events to Pure Data.

### **IP Address**
The IP address corresponds to **the device where Pure Data is running**.  
It must be updated depending on the machine executing Pd:

new NetAddress("<device-IP-address>", 11111)

### **Port**
The OSC port used is:

11111

## Demonstration Video  
A demonstration video is included showing how visual and sound output evolve according to the dataset [Video](https://javerianacaliedu-my.sharepoint.com/:v:/g/personal/jkbuitragoo_javerianacali_edu_co/IQCum3nrzhR1RbZNizUL_gyHAXR7FhVLwFCRv29RQBZFENg?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=c8mBYs)
