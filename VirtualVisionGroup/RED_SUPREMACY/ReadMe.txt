       
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

          RED SUPREMACY 4k intro - a contribution to Speccy.pl Party
                         by Virtual Vision Group.

                   for the ZX Spectrum Next and clones

-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

  You can be forgiven for thinking of this intro as of a compo filler, but it
truly isn't. Indeed, it does not have effects, but it has some depth. You need
to channel your inner Kazimierz Malewicz to better understand the idea.

  Although I wouldn't go as far as to label it suprematist, for that movement
strives to divorce art from real life and distill pure artistic feelings,
whereas this intro remains firmly rooted in the observable reality.

  The intro should not be misread as a glorification or endorsement of anything. 
It is rather a distillation of recent sobering thoughts of its main author.

---

  Pouet: https://www.pouet.net/prod.php?which=103873 \
  Youtube: https://youtu.be/DgDRcARbwyY?si=umJtMrbK5lb8fWbr \
  These sources are hereby placed in the public domain.

### Credits

  - Code, graphics and design - RCL

  - Music - Kenotron + RCL (originally a soundtrack from "Voodoo" CC'2000 
     invitation, remixed by RCL to fit the 4KB format, reviewed and approved by 
     Kenotron himself).

### How to run

  - You can run the .dot file anywhere from the SD card using NextZXOS browser.

  - If you put it into the dot command folder you should be able to run it from
    the BASIC as well, but I did not test that.

  - Supports both 50Hz and 60Hz modes.

  - Does not return, RESET will be needed.

  - I do not recommend using CSpect to watch it, at least as of version 19.9.
    Despite CSpect being arguably the best ZX Next emulators, the sound is quite
    botched.

### Under the hood

  The PT3 soundtrack of 2:32 duration is compressed to about 2KB of upkr-packed
data. Some pre- and post-processing has been applied to the AY register dump to
simplify it and remove features not important to the human ear.

  The remainder of the sources likely isn't very interesting. Two nested kick
starts to decompress stuff properly, support for 50 and 60Hz (by skipping each
6th update), LoRes 128x96x4bpp mode with everything drawn in software (sprites
would have been probably a better fit but I'm not yet proficient with them),
taking advantage of 28Mhz clock and double buffering at times.

 -RCL, 2025-04-02
------------------ ----- ---- --- -- -  
