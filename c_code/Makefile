CC=gcc
LINK_OPT=-lbluetooth -lncurses
RM=rm

default: bt_scan

bt_scan: 
	$(CC) -o bt_scan bt_scan.c $(LINK_OPT)

clean:
	$(RM) -f *.o
	$(RM) -f bt_scan
