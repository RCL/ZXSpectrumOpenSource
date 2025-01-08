       
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
                         #&@@@@% %#&@@@# 2o25  .#@@@@@@@@@@@@@@@@@@@#       
                          ''''''  '''''          ''''''''''''''''''' 
-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

           SnownonoNext 1k into - a contribution to DiHalt 2025 Winter
                      by RCL of Virtual Vision Group.

                    for the ZX Spectrum Next and clones

-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

  OMG too much snow... no no no...

  It doesn't snow in winter here, so I decided to add some. But it might be too
too much (let it snow for at least 5 minutes). Also enjoy a PSG player in 1k ;)

  This intro is an extended version of my ZX 128K intro Snownonono, released at
the same party contemporarily (albeit of course in different compos). I debated
whether to release it separately, but the code and visuals are IMO sufficiently
different to warrant that, not to mention a different compo category.

  Also, there are no 1k intros for the ZX Spectrum Next yet to my knowledge, so
this might be the first one (correct me if I'm wrong :) ).

---

  Pouet: https://www.pouet.net/prod.php?which=102926 \
  Youtube: https://www.youtube.com/watch?v=lgSneH-Uw0s \
  These sources are hereby placed in the public domain.

### How to run

  - You can run the .dot file anywhere from the SD card using NextZXOS browser.

  - If you put it into the dot command folder you should be able to run it from
    the BASIC as well, but I did not test that.

  - Supports both 50Hz and 60Hz modes.

  - Does not return, RESET will be needed.

### Under the hood

   Visually the effect is "unlimited bobs meet point cloud". Unlimited bobs are
normally done by cycling N buffers while printing into the current one, and the
idea here is the same. There are 80 6144 byte buffers into which the snow (940
snowflakes - could have been more in 50Hz, but a 60Hz frame is 1/6 shorter) is 
printed.

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

  Full credits:
  - Code - RCL
  - Music - AY track by RCL, conversion of an unknown MOD file by ???

 -RCL, 2025-01-05
------------------ ----- ---- --- -- -  
