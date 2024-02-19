
DEBUGFLAGS=-o:none -debug
ODINFLAGS=$(DEBUGFLAGS)

all: shadertube.exe

.PHONY:
shadertube.exe: .PHONY
	odin build shadertube $(ODINFLAGS)
