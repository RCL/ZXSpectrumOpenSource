       
        .00000&,       .000000. &00000&       .@@@000.%&@@@@@@@@@@@@@@       
        ,@@@@@@%.      &@@@@@@@@&@@@@@&     .@@@0000&#.@@@@@@@@@@@@@@@       
        .@@@@@@@@.     #@@@@@@&@%@@@@@@     @@@00000@.@@@@@@@0@@@@@@@&        
         .@@@@@@@@.    %@@@@@@@@%@@@@@%   &&&@000000.@@%                    
          .@@@@@@@@@.  %&@@@@@@@%@@@@@@.,@@@@0000%.@@#       
            .@@@@@@@@%.&@@@@@@@@%@@@@@@@,@@@@@000.%%%&                 
              .@@@@@@@@@@@@@@@@@%@@@@@@@@@@@00&%.@@@@        .&&&&&&&       
                %@@@@@@@@@@@@@@@%@@@@@@@@@@@@00.%@@@@.       &@@@@@@@   
                 .@@@@@@@@@@@@@@%@@@@@@@@@@@&0.%@@@@@.       @@@@@@@@       
                  .@@@@@@@@@@@@@%%@@@@@@@@@@@.%&@@@@@@&      @@@@@@@@       
                    #@@@@@@@@@@@%@@@@@@@@@@% .@@@@@@@@@@@@@@@@@@@@@@@       
                      @@@@@@@@@&%0@@@@@@@@%   @@@@@@@@@@@@@@@@@@@@@@@      
                       #@@@@@@@@.%@@@@@@%     .@@@@@@@@@@@@@@@@@@@@@%     
                         #&@@@@% %#&@@@# 2o24  .#@@@@@@@@@@@@@@@@@@@#       
                          ''''''  '''''          ''''''''''''''''''' 
-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

           Snownonono 1k into - a contribution to DiHalt 2025 Winter
                      by RCL of Virtual Vision Group.

                           ZX Spectrum 128K only

-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

  OMG too much snow... no no no...

  It doesn't snow in winter here, so I decided to add some. But it might be too
too much (let it snow for at least 5 minutes). Also enjoy a PSG player in 1k ;)

### How to run

  - This intro is 128K only. Works in USR0 mode too ofc. 
    Will exit with "Out of memory" message if run in 48K.

  - Minimal BASIC loader provided in snownonono.tap, just LOAD "" and enjoy.

  - To load manually using snownonono_codeonly_24576.tap, type
     CLEAR 24575: LOAD "" CODE: RANDOMIZE USR 24576

  - The binary is also placed separately (snownonono.bin) for easier inspection


### Under the hood

   Visually the effect is "unlimited bobs meet point cloud". Unlimited bobs are
normally done by cycling N buffers while printing into the current one, and the
idea here is the same. There are 48 2KB buffers into which the snow (21 unique
snowflakes) is printed (hence the need for ZX Spectrum 128K). A 2KB buffer is of
course too small to cover the whole screen (it corresponds to one third), so the
buffer is printed only into each 3rd scanline (two are skipped),and the starting
scanline rotates 0-1-2 each frame to fill the whole screen. Each music cycle the
print direction is reversed just for fun.

   Audio gave me more trouble. The music is a PT2 song that I converted from a
MOD in 1998 and it has been lying buried in my personal archive (thanks to LeMIC
for finding it!). Unfortunately I did not record the name of the module back in
1998, so I don't know the original author (if you recognize the melody, feel
free to let me know).

   Of course playing a PT2 file in a 1KB intro is a no go, so instead it is cut
into a register dump, which has been carefully massaged to compress well. The
dump size is 16128 bytes and it compresses to 556 bytes (with ZX0, UPKR gives
463 bytes but has a worse overall result, when you consider its larger depack
routine). I had to edit the samples and ornaments to make them simpler, so that
there aren't too many distinct tones and volumes,but the tune still plays close
to the original (which I am including here for comparison). Only three patterns
of the PT2 track are used in the 1K intro.

   A 48K/128K test is a last minute addition (and almost pushed the size beyond
1024 bytes), so hopefully it works reliably.

  Full credits:
  - Code - RCL
  - Music - AY track by RCL, conversion of an unknown MOD file by ???

  Expect the sources on github shortly after the party.

 -RCL, 2025-01-03
------------------ ----- ---- --- -- -  
