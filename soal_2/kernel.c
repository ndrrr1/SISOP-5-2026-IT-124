int cursor = 0;
char color = 0x07;

void putInMemory(int segment, int address, char character);
int getChar();

void printChar(char c) {
    int addr;
    int col;

    if (c == '\n') {
        col = cursor;
        while (col >= 80) {
            col = col - 80;
        }
        cursor = cursor + (80 - col);
        return;
    }

    addr = cursor * 2;
    putInMemory(0xB800, addr, c);
    putInMemory(0xB800, addr + 1, color);
    cursor++;

    if (cursor >= 2000) {
        cursor = 0;
    }
}

void printString(char *s) {
    int i;
    i = 0;
    while (s[i] != 0) {
        printChar(s[i]);
        i++;
    }
}

void newline() {
    printChar('\n');
}

void clearScreen() {
    int i;
    int addr;

    i = 0;
    while (i < 2000) {
        addr = i * 2;
        putInMemory(0xB800, addr, ' ');
        putInMemory(0xB800, addr + 1, color);
        i++;
    }

    cursor = 0;
}

void readString(char *buffer) {
    int i;
    int c;

    i = 0;

    while (1) {
        c = getChar();

        if (c == 13 || c == 10) {
            buffer[i] = 0;
            return;
        }

        if (c == 8) {
            if (i > 0) {
                i--;
                cursor--;
                printChar(' ');
                cursor--;
            }
        } else {
            if (i < 63) {
                buffer[i] = c;
                i++;
                printChar(c);
            }
        }
    }
}

int strcmp(char *a, char *b) {
    int i;
    i = 0;

    while (a[i] != 0 || b[i] != 0) {
        if (a[i] != b[i]) {
            return 0;
        }
        i++;
    }

    return 1;
}

int startsWith(char *a, char *b) {
    int i;
    i = 0;

    while (b[i] != 0) {
        if (a[i] != b[i]) {
            return 0;
        }
        i++;
    }

    return 1;
}

int skipArg(char *s, int i) {
    while (s[i] == ' ' || s[i] == '<') {
        i++;
    }

    while (s[i] >= '0' && s[i] <= '9') {
        i++;
    }

    while (s[i] == ' ' || s[i] == '>') {
        i++;
    }

    return i;
}

int parseNumber(char *s, int i) {
    int n;
    n = 0;

    while (s[i] == ' ' || s[i] == '<') {
        i++;
    }

    while (s[i] >= '0' && s[i] <= '9') {
        n = n * 10 + (s[i] - '0');
        i++;
    }

    return n;
}

void printNumber(int n) {
    int place;
    int digit;
    int started;

    if (n == 0) {
        printChar('0');
        return;
    }

    if (n < 0) {
        printChar('-');
        n = -n;
    }

    place = 10000;
    started = 0;

    while (place > 0) {
        digit = 0;

        while (n >= place) {
            n = n - place;
            digit++;
        }

        if (digit > 0 || started == 1 || place == 1) {
            printChar('0' + digit);
            started = 1;
        }

        if (place == 10000) {
            place = 1000;
        } else if (place == 1000) {
            place = 100;
        } else if (place == 100) {
            place = 10;
        } else if (place == 10) {
            place = 1;
        } else {
            place = 0;
        }
    }
}

void commandAdd(char *cmd) {
    int a;
    int b;
    int idx;

    idx = 3;
    a = parseNumber(cmd, idx);
    idx = skipArg(cmd, idx);
    b = parseNumber(cmd, idx);

    printNumber(a + b);
}

void commandSub(char *cmd) {
    int a;
    int b;
    int idx;

    idx = 3;
    a = parseNumber(cmd, idx);
    idx = skipArg(cmd, idx);
    b = parseNumber(cmd, idx);

    printNumber(a - b);
}

void commandFac(char *cmd) {
    int n;
    int i;
    int result;

    n = parseNumber(cmd, 3);

    if (n > 8) {
        printString("know your limit little bro.");
        return;
    }

    result = 1;
    i = 1;

    while (i <= n) {
        result = result * i;
        i++;
    }

    printNumber(result);
}

void commandSeason(char *cmd) {
    if (strcmp(cmd, "season winter")) {
        color = 0x0B;
        printString("winter mode");
    } else if (strcmp(cmd, "season spring")) {
        color = 0x0A;
        printString("spring mode");
    } else if (strcmp(cmd, "season summer")) {
        color = 0x0E;
        printString("summer mode");
    } else if (strcmp(cmd, "season fall")) {
        color = 0x0C;
        printString("fall mode");
    } else if (strcmp(cmd, "season radiant")) {
        color = 0x0D;
        printString("radiant mode");
    } else {
        printString("unknown season");
    }
}

void commandTriangle(char *cmd) {
    int n;
    int i;
    int j;

    n = parseNumber(cmd, 8);

    i = 1;
    while (i <= n) {
        j = 0;
        while (j < i) {
            printChar('x');
            j++;
        }
        if (i < n) {
            newline();
        }
        i++;
    }
}

void printHelp() {
    printString("check");
    newline();
    printString("add a b");
    newline();
    printString("sub a b");
    newline();
    printString("fac n");
    newline();
    printString("season winter");
    newline();
    printString("season spring");
    newline();
    printString("season summer");
    newline();
    printString("season fall");
    newline();
    printString("season radiant");
    newline();
    printString("triangle n");
    newline();
    printString("clear");
    newline();
    printString("about");
}

void main() {
    char cmd[64];

    clearScreen();

    printString("Welcome to Season OS");
    newline();
    printString("type help");
    newline();
    newline();

    while (1) {
        printString("> ");
        readString(cmd);
        newline();

        if (strcmp(cmd, "check")) {
            printString("ok");
        } else if (startsWith(cmd, "add")) {
            commandAdd(cmd);
        } else if (startsWith(cmd, "sub")) {
            commandSub(cmd);
        } else if (startsWith(cmd, "fac")) {
            commandFac(cmd);
        } else if (startsWith(cmd, "season")) {
            commandSeason(cmd);
        } else if (startsWith(cmd, "triangle")) {
            commandTriangle(cmd);
        } else if (strcmp(cmd, "clear")) {
            clearScreen();
        } else if (strcmp(cmd, "help")) {
            printHelp();
        } else if (strcmp(cmd, "about")) {
            printString("Season OS Final Challenge");
        } else {
            printString("unknown command");
        }

        newline();
    }
}
