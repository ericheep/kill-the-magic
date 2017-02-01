// kill-the-magic.ck
// Eric Heep

// communication classes
HandshakeID talk;
3.5::second => now;
talk.talk.init();
2.5::second => now;

6 => int NUM_PUCKS;
16 => int NUM_LEDS;

// led class
Puck puck[NUM_PUCKS];

for (0 => int i; i < NUM_PUCKS; i++) {
    puck[i].init(i);
}

float puckValue[NUM_PUCKS];
float puckColor[NUM_PUCKS];

float hue[NUM_PUCKS][NUM_LEDS];
float sat[NUM_PUCKS][NUM_LEDS];
float val[NUM_PUCKS][NUM_LEDS];

5.0 => float decibelThreshold;
75::ms => dur baseSpeed;

// led behavior
2 => int NUM_LINES;

float ledSpeed[NUM_LINES];
float ledWidth[NUM_LINES];
float sinBuild[NUM_LINES];
float ledChance;

int linePhase[NUM_LINES];
int sinPhase[NUM_LINES];
int darkPhase[NUM_LINES];
int sidePhase[NUM_LINES];
int fuckPhase[NUM_LINES];
int endPhase[NUM_LINES];
int side[2];

for (int i; i < NUM_LINES; i++) {
    1 => linePhase[i];
    0 => sinPhase[i];
    0 => darkPhase[i];
    0 => sidePhase[i];
    0 => fuckPhase[i];
}

// audio
Gain gain[2];
Analyze ana[2];
for (0 => int i; i < 2; i++) {
    adc.chan(i) => gain[i] => dac.chan(i);
    adc.chan(i) => ana[i];
}


0.80 => float low;
0.00 => float transition;
1.0 => float slow;
0.0 => float fuckSpeed;

fun int convert(float value, int scale) {
    return Std.clamp(Math.floor(value * scale) $ int, 0, scale);
}

fun void updateColors() {
    for (int i; i < NUM_PUCKS; i++) {
        for (int j; j < 16; j++) {
            puck[i].color(j,
                convert(hue[i][j], 1023),  // hue
                convert(sat[i][j], 255),   // saturation
                convert(val[i][j], 255)  // value
            );
        }
    }
}

[[15, 14, 13, 12, 11],
 [ 4,  3,  2,  1,  0]] @=> int matrix[][];

[15, 14, 13, 12, 11,
  4,  3,  2,  1,  0] @=> int bread[];

 [ 5, 6, 7, 8, 9, 10] @=> int middle[];

fun void firstPhase(int which) {
    matrix[which].size() => int shieldLength;
    NUM_PUCKS * matrix[which].size() => int rowLength;
    int rowLed, dirLed, led, shield, width, modLed;
    which => int dir;

    hueAll(0.85);
    satAll(1.0);

    while (linePhase[which] == 1) {
        (rowLed + 1) % rowLength => rowLed;

        // incrementer
        if (dir == 0) {
            rowLed => dirLed;
        }
        else if (dir == 1) {
            (rowLength - 1) - rowLed => dirLed;
        }

        if (ana[which].decibel() > decibelThreshold) {
            1.0 => val[dirLed / shieldLength][matrix[which][dirLed % shieldLength]];
        }
        else {
            low => val[dirLed / shieldLength][matrix[which][dirLed % shieldLength]];
        }

        baseSpeed * (Math.pow((-ledSpeed[which] + 1.0), 3) + 0.15) => now;

        // clear previous led
        clearRow(which);

        if (rowLed == rowLength - 1) {
            repeat(rowLength) {
                baseSpeed * (Math.pow((-ledSpeed[which] + 1.0), 3) + 0.15) => now;
            }
        }
    }

    float sinInc;

    while (sinPhase[which] == 1) {
        (ledWidth[which] * rowLength)$int => width;

        // incrementer
        (sinInc + 0.1) % (2 * pi) => sinInc;

        Math.floor(((Math.sin(sinInc) + 1.0) / 2.0) * rowLength)$int => rowLed;

        if (ana[which].decibel() > decibelThreshold) {
            1.0 => val[rowLed / shieldLength][matrix[which][rowLed % shieldLength]];
        }
        else {
            low => val[rowLed / shieldLength][matrix[which][rowLed % shieldLength]];
        }

        for (0 => int i; i < width; i++) {
            (rowLed + (i + 1)) % rowLength => modLed;
            if (ana[which].decibel() > decibelThreshold) {
                1.0 => val[modLed / shieldLength][matrix[which][modLed % shieldLength]];
            }
            else {
                low => val[modLed / shieldLength][matrix[which][modLed % shieldLength]];
            }
        }

        baseSpeed * (Math.pow((-ledSpeed[which] + 1.0), 3) + 0.15) => now;

        // clear previous led
        clearRow(which);
    }
}

fun void clearRow(int which) {
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < matrix[which].size(); j++) {
            0.0 => val[i][matrix[which][j]];
        }
    }
}

fun void hueAll(float h) {
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < NUM_LEDS; j++) {
            h => hue[i][j];
        }
    }
}

fun void satAll(float s) {
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < NUM_LEDS; j++) {
            s => sat[i][j];
        }
    }
}

fun void valAll(float v) {
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < NUM_LEDS; j++) {
            v => val[i][j];
        }
    }
}

fun void clearPuck(int idx) {
    for (0 => int j; j < NUM_LEDS; j++) {
        0.0 => val[idx][j];
    }
}

fun void clearPuckBread(int idx) {
    for (0 => int j; j < bread.size(); j++) {
        0.0 => val[idx][bread[j]];
    }
}

fun void speed(int which) {
    while (true) {
        if (ana[which].decibel() > decibelThreshold) {
            if (linePhase[which]) {
                ledSpeed[which] + 0.001/slow => ledSpeed[which];
            }
            if (sinPhase[which]) {
                ledSpeed[which] + 0.0004/slow => ledSpeed[which];
                ledWidth[which] + 0.0004/slow => ledWidth[which];
            }
            if (darkPhase[which]) {
                ledChance + 0.0001/slow => ledChance;
            }
            if (sidePhase[which]) {
                Math.random2(0, NUM_PUCKS - 1) => side[which];
            }
            if (fuckPhase[which]) {
                fuckSpeed + 0.00004/slow => fuckSpeed;
            }
        }
        else if (ana[which].decibel() <= decibelThreshold) {
            if (linePhase[which]) {
                ledSpeed[which] - 0.0003/slow => ledSpeed[which];
            }
            if (sinPhase[which]) {
                ledSpeed[which] - 0.0002/slow => ledSpeed[which];
                ledWidth[which] - 0.0002/slow => ledWidth[which];
            }
            if (darkPhase[which]) {
                ledChance - 0.0001/slow => ledChance;
            }
            if (fuckPhase[which]) {
                fuckSpeed - 0.00004/slow => fuckSpeed;
            }
        }

        // clamps
        Std.clampf(ledSpeed[which], 0.0, 1.0) => ledSpeed[which];
        Std.clampf(ledWidth[which], 0.0, 1.0) => ledWidth[which];
        Std.clampf(ledChance, 0.0, 1.0) => ledChance;
        Std.clampf(fuckSpeed, 0.0, 1.0) => fuckSpeed;


        if (ledSpeed[which] >= 1.0 && linePhase[which] == 1) {
            0 => linePhase[which];
            1 => sinPhase[which];
        }
        if (ledWidth[which] >= 1.0 && sinPhase[which] == 1) {
            0 => sinPhase[which];
            1 => darkPhase[which];
        }

        10::ms => now;
    }
}

fun void secondPhase() {
    int ctr, mod;

    while (ledChance <= 0.99) {
        if (Math.random2f(0.0, 1.0) < Math.pow(ledChance, 3)) {
            for (0 => int i; i < NUM_PUCKS; i++) {
                for (0 => int j; j < middle.size(); j++) {
                    1.0 => val[i][middle[j]];

                    if (ledChance > 0.8) {
                        if (maybe) {
                            Math.random2f(0.85, 0.88) => hue[i][middle[j]];
                            0.0 => sat[i][middle[j]];
                        }
                        else {
                            0.85 => hue[i][middle[j]];
                            1.0 => sat[i][middle[j]];
                        }
                    }

                    if (ledChance > 0.5) {
                        noiseBurst(Math.pow((ledChance - 0.5) * 2, 3));
                    }
                }
            }
        }
        else {
            for (0 => int i; i < NUM_PUCKS; i++) {
                for (0 => int j; j < middle.size(); j++) {
                    0.0 => val[i][middle[j]];
                }
            }
        }

        (1.0/30.0)::second => now;
    }
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < middle.size(); j++) {
            1.0 => val[i][middle[j]];
        }
    }
}

fun void noiseBurst(float chance) {
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < NUM_LEDS; j++) {
            if (Math.random2f(0.0, 1.0) < chance) {
                0.0 => sat[i][j];
                0 => val[i][j];
            }
            else {
                1.0 => sat[i][j];
            }
        }
    }
}

fun void thirdPhase() {
    satAll(0.0);
    while (true) {
        for (int i; i < NUM_PUCKS; i++) {
            for (int j; j < NUM_LEDS; j++) {
                if (Math.random2f(0.0, 1.0) < fuckSpeed) {
                    1.0 => val[i][j];
                }
                else {
                    0.0 => val[i][j];
                }
            }
        }
        (0.01::second - (fuckSpeed * 0.01::second)) + 1::ms => now;
    }
}

fun void piece() {
    spork ~ speed(0);
    spork ~ speed(1);

    spork ~ firstPhase(0);
    spork ~ firstPhase(1);

    while (darkPhase[0] == 0 || darkPhase[1] == 0) {
        1::ms => now;
    }

    spork ~ secondPhase();

    while (ledChance < 0.8) {
        100::ms => now;
    }

    while (ledChance < 1.0) {
        1::ms => now;
    }

    15::second => now;

    1 => fuckPhase[0];
    1 => fuckPhase[1];

    thirdPhase();
}

spork ~ piece();

while (true) {
    // send hsv values to pucks
    updateColors();
    (1.0/30.0)::second => now;
}
