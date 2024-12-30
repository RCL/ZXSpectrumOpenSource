       
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

               RTZX Next demo - a contribution to Demosplash 2024
                     by Virtual Vision Group & friends.

                         F I N A L  V E R S I O N
-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

  This is a continuation of ray tracing adventure that began with RTZX 1k on
the classic ZX Spectrum. Given the extended capabilities of ZX Spectrum Next
(8x the speed, and 8-bit MUL instruction) it was interesting to see how much
faster it could be on this hardware.
  The Speccy version rendered the picture in 45 seconds, so a straigforward 8x
speed up was still taking about 5 seconds, with the MUL instructions not making
a tremendous difference either (still grateful the Next has it). We identified
more optimization opportunities, most importantly, an approach of using the
key rays with a subdivision between them wherever the details warranted that
(inspired by Heaven 7 PC intro of yore). This helped bring the rendering up to
near realtime speeds.

  It tooks us more than a month after the party to produce the final version,
mostly because it was a busy season before (and between) the holidays and life
intervened. Here's what is different between the party and final versions:

  - initial and final screens were redone in classic 256x192x15 Spectrum format
  - support for 60Hz display added (music is always updated at 50Hz)
    (60Hz projector was used at the party place and it sped up the music, ugh.
     Going forward we will always account for the need to support 60Hz).
  - bug fixes and optimizations
    (final version is visibly faster than the party one. I don't think it would
     change our ranking though).
  - the executable binary has been compressed (as if size still mattered! :))

  Tested to work on ZX Spectrum Next KS2, KS1 / clones (N-GO, Xberry Pi), 
also on Next-alikes like Mister's ZX Spectrum Next core.

  Pouet link: https://www.pouet.net/prod.php?which=101337 \
  Link to Youtube video: https://youtu.be/73S-f-YqT24 \
  Sources are available and hereby placed in the public domain.

  Full credits:
  - Main code & visual design - RCL
  - Music - 'Ascendant' by Pator (custom edition for the demo)
  - Graphics by Grongy
  - Prototyping and synch, testing - LeMIC

 Happy holidays!

 -RCL, 2024-12-29
------------------ ----- ---- --- -- -  
