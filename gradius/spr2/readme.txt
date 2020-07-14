this spr2
is the test to draw sprite
from system memory to display memory

sprite data format:

tem o programa java ViewSystemMemory.java que faz 
a conversao do bmp para esse formato.

spr_data:
		   dw spr_page_0, spr_page_1, spr_page_2, spr_page_3
spr_page_0 db 0,84,1,77,81,1,15,80,2,77,77,80,3,77,77,0,79,3,77,77,77,79,3,77,0,77,79,3,0,42,15,79,3,77,42,15,79,3,77,0,15,79,3,15,77,77,79,3,15,15,77,79,3,77,77,77,80,1,77,243,0
spr_page_1 db 0,84,1,77,80,2,77,77,80,2,77,15,80,2,15,77,80,2,15,0,80,3,77,77,77,79,3,77,0,77,79,3,0,0,77,79,3,77,77,77,79,3,77,77,77,79,3,15,77,77,79,2,15,77,0
spr_page_2 db 0,83,1,77,81,2,77,77,80,2,15,77,80,2,15,0,80,2,77,77,80,2,77,15,79,3,0,0,77,79,4,77,0,77,77,78,4,77,77,0,77,79,2,77,77,80,2,77,77,80,2,15,77,80,1,77,244,0
spr_page_3 db 0,83,1,77,81,1,77,81,2,15,77,80,2,77,0,80,2,77,77,80,2,0,15,79,3,0,42,15,79,3,77,42,77,79,3,15,0,77,79,3,77,77,0,79,3,77,15,0,80,2,15,0,80,1,77,244,0


spr_page_0 db 0,84,1,77,81,1,15,80,2,77,77,80,3,77,77,0,79,3,77,77,77,79,3,77,0,77,79,3,0,42,15,79,3,77,42,15,79,3,77,0,15,79,3,15,77,77,79,3,15,15,77,79,3,77,77,77,80,1,77,243,0

offset 0 = 0 or 1:
0 = start with transparent pixels
1 = start with opaque

if transparent:
n = number of transparent pixels

if opaque:
n = number of opaque pixels
followed by pixel colors: c1, c2, c3, ..., cn

if 0:
end of sprite


a funcao final fica mais ou menos assim:
draw_sprite(spr_data, vram_location, x % 4, plane no.)

