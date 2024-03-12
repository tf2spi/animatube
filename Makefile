
DEBUGFLAGS=-o:none -debug
ODINFLAGS=$(DEBUGFLAGS)

all: animatube.exe

.PHONY:
animatube.exe: .PHONY
	odin build . $(ODINFLAGS)
