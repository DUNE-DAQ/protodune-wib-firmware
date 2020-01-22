import socket

UDP_IP = "192.168.200.2"
UDP_PORT = 0x7d03
#MESSAGE = "Hello, World!"
MESSAGE = "\xDE\xAD\xBE\xEF\x00\x00\x00\x00\x00\x00\x00\x00"

print "UDP target IP:", UDP_IP
print "UDP target port:", UDP_PORT
print "message:", MESSAGE

sock = socket.socket(socket.AF_INET, # Internet
             socket.SOCK_DGRAM) # UDP
sock.sendto(MESSAGE, (UDP_IP, UDP_PORT))


while True:
    data_str,src = sock.recvfrom(1000)
    print src
    if src[0] == UDP_IP and src[1] == 32001:
        for i in range(0,len(data_str),2):            
            print i/2,"0x"+((hex((ord(data_str[i])<<8)  +
                                 ord(data_str[i+1]))[2:]).zfill(4))

        print "\n"
