       
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

        RED REDUX 256 byte intro - a contribution to Multimatograf 2025
                         by Virtual Vision Group.

                         for ZX Spectrum 48K+AY
                        and also ZX Spectrum Next

-------- ------ ----- ---- --- -- - - -- --- ---- ----- ------ ------- --------

  This 256 byte intro refers to Red Supremacy,a 4KB intro released earlier this
month at Speccy.PL Party 2025 (https://www.pouet.net/prod.php?which=103873).
While the visuals here convey the basic idea, calling it a "redux" is of course
tongue-in-cheek, as the 4KB intro has much much more in it - go watch it if you
haven't.

  The intro is supplied both as a 48K+AY and as a ZX Spectrum Next binary, but
it had been entered in the classic (48/128K) compo. I decided to pay respects
to the original platform (plus it doesn't benefit from the Next capabilities).

  HOWEVER, this means that unlike many 256 byte intros for 48/128K, this intro
does not use any ZX Spectrum ROM routines.

---

  Pouet: https://www.pouet.net/prod.php?which=104112 \
  Youtube: https://youtu.be/3jANNM2zHTM?si=XABTBd4ZcB731glb \
  These sources are hereby placed in the public domain.

### Credits

  - Code - RCL

  - Music - Kenotron (with modifications by RCL).

### How to run

  For the 48K + AY / 128K version:

  - Just load the provided .tap file that contains the BASIC loader
  or
  - Load the separate code block at 24576 and run it:
        CLEAR 24575: LOAD "" CODE: RANDOMIZE USR 24576

  Note: if you don't turn on the sound or don't have the AY, you will be rather
disappointed.


  For the ZX Spectrum Next version:

  - You can run the .dot file anywhere from the SD card using NextZXOS browser.

### Under the hood

  This was born out of my music compression experiments while working on Red
Supremacy. I noticed that the beginning of the (excellent) Kenotron soundtrack
(originally from Voodoo invtro from 2000 by the way) had a rather simple 
structure and stood a chance to be redone to fit a 256b intro format.

  Of course it wasn't that simple. The music structure wasn't regular enough 
to rewrite it in the code, so I decided to compress the register dump. A 
pattern of music (64 notes) with tempo 4 takes 256 bytes per AY register, so 
I was looking at compressing up to 3584 bytes into <= 256. Gladly, as I said
Kenotron's track was somewhat simple in the beginning so it only needed values 
for 12 registers, one of which was a constant. That simplified things but still
the result compressed to about 200-220 bytes, not leaving much space for the
player or the decompressor routine (I used ZX2 with some minor mods).

  I had to make compromises and reduced the AY register update from once per 
frame to once per 4 frames, effectively bringing the dump size to 1/4. Most 
of the track was regular enough to allow that with minimal differences for 
the ear, but the kick in the beginning noticeably suffered. However I still 
wanted to have at least some visuals so I had to leave it at that.

  First version of the code ran fine and was ready for submission, but when 
doing a soak test on my real Spectrum 48K+AY, I noticed that it would stomp 
the memory and lock up after several minutes of running. While I judged that 
practically unimportant as no one would leave it running for that long, it 
didn't sit well with me. I rewrote the code so it can now run indefinitely long
without any ill effects.

  As I said above, due to the code being able to run both on 48K/128K and the
Next (within the same 256 byte limit), it is self-contained and free from
any ZX Spectrum ROM use. Ded aka Unbeliever aka MMA would approve of this :-)

 -RCL, 2025-04-26
------------------ ----- ---- --- -- -  
