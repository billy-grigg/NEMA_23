{{
How it works:

The A and B phase from the encoder are Combined with the previous two readings to make a 4-bit number.
This number provides an index to a table containing 0's,1's and -1's.
If the combination of old and new readings means no rotation a zero is found in the table,
if the rotation is clockwise a 1 is found and if anticlockwise a -1 is found.

These can then be simply added to the position register used.

In this instance the lookup table is contained in a single 32-bit long,
there are 16 pairs of numbers, one for each possible combination
(note encoders cannot produce all 16 combinations of a 4-bit number).

To produce an index the 4-bit number is multiplied by 2 (shift once left)
and then used as the argument for a left shift performed on a copy of the table.
Note that element 15 in the table is in bits 0:1 so they are shifted 30 times into 30:31.
Then an arithmetic right shift is performed, this ensures that the 2-bit negative number retains
its sign because the msb is extended during the shift:

11000000_00000000_00000000_00000000

becomes

11111111_11111111_11111111_11111111 Or minus one!

Simple!


(Table based on quadrature code)

'-------------|-------------|-----------------|----------------|-----------
'             |             |                 |   2-bit table  |  Meaning
'old -> new   |   4-bit     |  Index in Table |     content    |
'-------------|-------------|-----------------|----------------|-----------
' 00  ->  00  |    0000     |        0        |      00        |
' 01  ->  01  |    0101     |        5        |      00        |  No movement 
' 11  ->  11  |    1111     |        15       |      00        |
' 10  ->  10  |    1010     |        10       |      00        |
'-------------|-------------|-----------------|----------------|-----------
' 00  ->  01  |    0001     |        1        |      01        |
' 01  ->  11  |    0111     |        7        |      01        |
' 11  ->  10  |    1110     |        14       |      01        |  Clockwise
' 10  ->  00  |    1000     |        8        |      01        |
'-------------|-------------|-----------------|----------------|-----------
' 00  ->  10  |    0010     |        2        |      11   (-1) |
' 10  ->  11  |    1011     |        11       |      11   (-1) |  Anticlockwise
' 11  ->  01  |    1101     |        13       |      11   (-1) |
' 01  ->  00  |    0100     |        4        |      11   (-1) |


                        x  x  x     x  x     x  x    x  x     x  x  x
'                       0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
Look_Up_Table long    %00_01_11_00_11_00_00_01_01_00_00_11_00_11_01_00  
                  

The Assembly routine executes in 60 clock cycles  (02OCT2020)
        mov     4
        mov     4
        and     4
        shr     4
        shl     4
        or      4
        and     4
        mov     4
        shl     4
        shl     4
        sar     4
        adds    4
        wrlong  23
        jmp     4
                                
        Total Clocks =  75
        Clock runs at 80,000,000
        1 / 80,000,000 = 0.0000000125 seconds per clock
        75 clocks = 0.0000009375 seconds to execute check for motion
        doubling it to make sure to catch event = 0.000001875 seconds
        encoder reads per second = 533,333.3333333333
        533,333.3333333333 / 200 ppr =   2,666.666666666667 rev per second
         or 160,000 maxium RPM and still be able to read encoder.

_
}}
CON
       _clkmode = xtal1 + pll16x
       _xinfreq = 5_000_000

OBJ

       PST : "Parallax Serial Terminal"
       
VAR

  long  Ram
  long  Time
  
PUB start : okay


  okay := cognew(@Read_Encoder, @Ram)
  if okay =< 0                  'Wait for Cog to Launch.               
     repeat

  okay := PST.start(115_200)
  if okay =< 0                  'Wait for PST to Launch.               
     repeat
     

  PST.Clear
  repeat
   PST.Home
   PST.Str(STRING("Encoder Counts =            "))'           
   PST.PositionX(17)
   PST.Dec(Ram)
   waitcnt(8_000_000 + cnt)
 
DAT
                        
Read_Encoder            mov     Combined, #0          ' Clear last run data(Inita;ize)
                        mov     Main_Ram, par         ' Load pointer to main ram
                       
                                        
:Loop_Endlessly         mov     Table, Look_Up_Table  ' Load Look Up Table
                        mov     State, ina            ' Read Inputs
                        and     State, Pin_Mask       ' Mask
                        shr     State, #4             ' Shift Input Pins to Bits 1 and Zero.
                        shl     Combined,#2           ' Shift old bits left
                        or      Combined,State        ' Combine to provide 4 bit word
                        and     Combined,#15          ' Mask off really old bits
                        mov     Shift_Index,Combined  ' Make ready to use as index 
                        shl     Shift_Index,#1        ' Shift to multiply by two
                        shl     Table,Shift_Index     ' Use to shift look up table bits to bits 30,31                                       
                        sar     Table,#30             ' Shift to bits 0 and 1 keeping the sign 
                        adds    Count,Table           ' Add the result to the Count                        
                        wrlong  Count, Main_Ram       ' Write Count to Main Ram                        
                        jmp     #:Loop_Endlessly      ' Repeat endlessly

Combined                long    0
Count                   long    0

Pin_Mask                long    %00000000_00000000_00000000_00110000

'                                 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
Look_Up_Table           long    %00_01_11_00_11_00_00_01_01_00_00_11_00_11_01_00  

State                   res     1
Table                   res     1
Shift_Index             res     1
Main_Ram                res     1

             