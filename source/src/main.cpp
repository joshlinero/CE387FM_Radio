

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <unistd.h>

#include "fm_radio.h"
#include "audio.h"

using namespace std;

int main(int argc, char **argv)
{
    static unsigned char IQ[SAMPLES*4];
    static int left_audio[AUDIO_SAMPLES];
    static int right_audio[AUDIO_SAMPLES];

    if ( argc < 2 )
    {
        printf("Missing input file.\n");
        return -1;
    }
    
    // initialize the audio output
    int audio_fd = audio_init( AUDIO_RATE );
    if ( audio_fd < 0 )
    {
        printf("Failed to initialize audio!\n");
        return -1;
    }

    FILE * usrp_file = fopen(argv[1], "rb");
    if ( usrp_file == NULL )
    {
        printf("Unable to open file.\n");
        return -1;
    }    
    
    // run the FM receiver 
    // while( !feof(usrp_file) )
    // {
        // get I/Q from data file
        fread( IQ, sizeof(char), SAMPLES*4, usrp_file );

        // fm radio in mono
        fm_radio_stereo( IQ, left_audio, right_audio );

        // write to audio output
        audio_tx( audio_fd, AUDIO_RATE, left_audio, right_audio, AUDIO_SAMPLES );
    //}

    FILE * left = fopen("./src/txt_files/left_audio.txt", "w");
    FILE * right = fopen("./src/txt_files/right_audio.txt", "w");
    if ( left != NULL && right != NULL)
    {
        for (int i = 0; i < AUDIO_SAMPLES; i++)
        {
            fprintf(left, "%08x\n", left_audio[i]);
            fprintf(right, "%08x\n", right_audio[i]);
        }
    }

    fclose(left);
    fclose(right);
    fclose( usrp_file );
    close( audio_fd );

    return 0;
}

