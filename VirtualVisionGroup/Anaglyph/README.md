       
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

             Anaglyph 1k intro - a contribution to Xenium 2025
                  by Virtual Vision Group & Otomata Labs.

                           ZX Spectrum 128K only

-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

   Probably the first anaglyph rendering on the classic ZX Spectrum? You will
need red-blue glasses to enjoy this one. Also, make sure you're watching it on
a real hardware or a good emulator - too slow emulators and emulators running
with a 60Hz refresh can botch the effect, although it arguably remains there.
Enjoy the excellent music fragment by Pator of Otomata Labs while donning your
cool stereo glasses.

  Pouet: https://www.pouet.net/prod.php?which=104845 \
  Youtube: https://www.youtube.com/watch?v=FhSCPMz-MB0 \
  These sources are hereby placed in the public domain.

### How to run

  - This intro is 128K only (both regular and USR0 mode are supported). 

  - Minimal BASIC loader provided in anaglyph.tap, just LOAD "" and enjoy.

  - To load manually using anaglyph_codeonly_24576.tap, type
     CLEAR 24575: LOAD "" CODE: RANDOMIZE USR 24576

  - The binary is also placed separately (anaglyph.bin) for easier inspection.
   The starting address it is expected to be loaded and run at is 24576 (#6000).


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

   The effect itself is nothing special and in a way is a continuation of the
"Noise in lines" 256b intro I submitted to Xenium 2024, except in 3D. Probably
not the most optimal, but readily available fixed point math routines have been
reused from RTZX series of prods by VVG.

   Music is straight from VortexTracker, and is stored as a register dump in
a more compressible format. It is written for the mono audio output of the 
original Speccy (+2 grey in particular), so we recommend listening to it in mono.
Kudos to Pator for being able to accommodate the last minute changes needed to
get everything under the 1k budget.

  Full credits:
  - Code - RCL / VVG
  - Music - Pator / Otomata Labs

 -RCL, 2025-08-18
------------------ ----- ---- --- -- -  
