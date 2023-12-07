# swy: -- Raw-TCP flash memory dumper script for Tasmota32 through Berry REPL
#         without saving anything to storage; via straight network transfer.
#      -- made by swyter in december 2023
#      --
# swy: -- copy-paste the different chunks as instructed; see the comments below. pasting the whole thing at once won't work
import flash

tmem = tasmota.memory()
print(string.format("[i] real flash memory size: %#x KB (%x bytes)", tmem['flash_real'], tmem['flash_real'] * 1024))

# swy: see https://tasmota.github.io/docs/Berry/#tcpserver-class
s = tcpserver(8855)    # listen on port 8855
s.hasclient()

# swy: copy the lines above in the Consoles > Berry Scripting console (Berry REPL Web UI) to open the socket: https://yukaii.tw/hi-tips/2017-09-04-nc-transfer-upload-binary-data-without-scp/
#      after running that, the Tasmota hardware is already listening, so we need to connect our TCP netcat client
#      (in our computer side) to dump the raw received data to a binary file. like this:
# $ nc -w 3 --tcp tasmota.lan 8855 > tasmota-flash.bin

s.hasclient()
c = s.accept()

c.read()

# swy: send 1024 bytes of flash data per loop, I recommend making a copy once it finishes and
#      loop again to have a second file to compare against, and to ensure they are identical
dump_packet_size = 1024
dump_total_flash_bytes = tmem['flash_real'] * 1024

i = 0
while i < dump_total_flash_bytes
    #print(string.format("[-] dumped from %#8x to %#8x", i, i + dump_packet_size))
    f = flash.read(i, dump_packet_size) # swy: the f variable contains a byte range that the connection.read() function understands without ASCII conversion
    c.write(f)
    i = i + dump_packet_size
end
print("")
print("[/] done!")

# swy: copy-paste until here, you can then close the connection and
#      socket after you finish by pasting the two lines below
c.close()
s.close()