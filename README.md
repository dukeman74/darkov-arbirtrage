# darkov-arbirtrage

Script to automate picking up mislists on the dark and darker market.

!!!! CTRL ALT Q to stop the script at any time !!!!

due to how the network communication works, if you are looking to buy an item with very little data such as gold ingots, you should change the last character of "data/snif.bat" to 1 instead of 2 ie "-w data\packets -c 1".\
failure to set this correctly will result in less frequent market checks than optimal.


comes with two strategies, OCR and Packets.\
for OCR, you need to have Tesseract-OCR\
https://github.com/UB-Mannheim/tesseract/wiki

for Packets, you need wireshark, or more specifically Tshark, which comes bundled with it.\
https://www.wireshark.org/download.html

either of these can be tested by pressing "read cheapest price" for OCR or "sniff" for packet sniffing.\
Once the search is set up correctly in the game, the price you want to buy if an item is listed under and the preferred strategy are set in the gui, press "engage". 

it will take a screenshot of your gold at the begining so that you can compare at the end.\
Packet sniffing will also produce a summary.txt with every purchase exactly detailed as well as the total spent and on what rarities.

downsides:

OCR can misread, in fact, it seems to somewhat fequently.  It is especially susceptible to thinking strings of 1's are a letter such as n or m.  This can lead to buying things above your set price.

Packet sniffing relies on their communication protocol being exactly what it is right now.  If they change at all it will need to be reverse engineered again.  In addition to this, sometimes the ip of the market server changes, when this happens one must rediscover it manually using wireshark and write the new ip into "data/snif.bat".

Currently only works on 1920x1080 fullscreen or borderless windowed.  If you want to use it on another resolution please open an issue listing your resolution.
