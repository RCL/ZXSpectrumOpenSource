       
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

             Parallel Visions 4k intro - a contribution to Xenium 2025
                  by Virtual Vision Group & Otomata Labs.

                           ZX Spectrum 128K only

-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

   Probably the first anaglyph rendering on the classic ZX Spectrum? You will
need red-blue glasses to enjoy this one. Also, make sure you're watching it on
a real hardware or a good emulator - too slow emulators and emulators running
with a 60Hz refresh can botch the effect, although it arguably remains there.
Enjoy the excellent music by Pator of Otomata Labs while donning your cool
stereo glasses.

  Pouet: https://www.pouet.net/prod.php?which=104844 \
  Youtube: https://www.youtube.com/watch?v=d4Fo-Gv2XRA \
  These sources are hereby placed in the public domain.

### How to run

  - This intro is 128K only (both regular and USR0 mode are supported). 

  - Minimal BASIC loader provided in anaglyph.tap, just LOAD "" and enjoy.

  - To load manually using parallelvisions_codeonly_24576.tap, type
     CLEAR 24575: LOAD "" CODE: RANDOMIZE USR 24576

  - The binary is also placed separately (parallelvisions.bin) for easier 
    inspection. The starting address it is expected to be loaded and run at 
    is 24576 (#6000).

### Under the hood

   Anaglyph is a stereo rendering technique in which images for both eyes are
superimposed with different tints. Glasses with a different color for each eye
(usually red-cyan or red-blue) are then used to filter the images back into 
separate ones for each eye. 

   Of course the famous colour clash of the ZX Spectrum makes it impossible to
implement this technique as it is supposed to work, but this 25 Hz-per-eye
flicker is the closest alternative and it still works. Note: the final image 
you see in the red-blue glasses (you need red-blue glasses here, not red-cyan),
will appear white to you.

   Everything is projected twice for each of the eyes, with eyes being offset
by a distance that was calibrated while watching this on a monitor. I (RCL) am
a little worried that projector may require a different eye base, but I decided
to refrain from providing more binaries with various eye bases to avoid confusion. 
If we do more such anaglyph productions in the future, we may reconsider that
based on learnings from this one...

   This intro was born out of a last minute desire to expand on the 1k Anaglyph
intro we submitted earlier. It ended up being much better than we expected. As
a curiosity - the 3D letters you see in the demo are taken from the ROM font :-)
It took us a couple nights of hardcore party coding and music composing to
produce this one.

   Music is straight from VortexTracker, and is stored in a more compressible
format related to .PSG.

  Full credits:
  - Code - RCL / VVG
  - Music - Pator / Otomata Labs

  Thanks to ZX0 authors and authors of various small routines (Viper of
Techno Laboratory for the fast point routine in particular) for the excellent
tools that made this product possible. 

  Expect the sources on github shortly after the party.

 -RCL, 2025-08-21
------------------ ----- ---- --- -- -  
