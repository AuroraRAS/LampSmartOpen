#include <stdio.h>
#include <getopt.h>

#include "opencodeV3/opencodeV3.h"

int main(int argc, char *argv[]) {
    int c;
    unsigned int addr = 0;
    uint8_t outbuf[32];

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            {"Address",       required_argument, 0, 'a' },
            {"Dimming",       required_argument, 0, 'd' },
            {"DimmingNight",  no_argument,       0, 'n' },
            {"Binding",       required_argument, 0, 'b' },
            {"LampOnOff",     required_argument, 0, 'o' },
            {0,         0,                 0,  0 }
        };

        c = getopt_long(argc, argv, "a:d:nb:o:",
                        long_options, &option_index);
        if (c == -1)
            break;

        switch (c) {
        case 'a':
            sscanf(optarg, "%i", &addr);
            break;
        case 'd':
            int orange, white;
            sscanf(optarg, "%i,%i", &orange, &white);
            opencodeV3_Dimming(outbuf, 256, addr, 0, orange, white);
            break;
        case 'n':
            opencodeV3_DimmingNight(outbuf, 256, addr, 0);
            break;
        case 'b':
            int bind = 0;
            sscanf(optarg, "%i", &bind);
            opencodeV3_Binding(outbuf, 256, addr, 0, bind);
            break;
        case 'o':
            int onoff = 0;
            sscanf(optarg, "%i", &onoff);
            opencodeV3_LampOnOff(outbuf, 256, addr, 0, onoff);
            break;
        case '?':
            break;
        default:
        }
    }

    for (int i=5; i<31; i++) {
        if(i%2)
            printf("-u %02x%02x ", outbuf[i+1], outbuf[i]);
    }
    return 0;
}
