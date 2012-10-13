CC=rdmd
CFLAGS=--build-only -version=CL_VERSION_1_1 -L-lOpenCL -Icl4d -d
RELEASEFLAGS=-release -O -inline
DEBUGFLAGS=-debug -gc

FILES=main.d CLUtils.d

all: qwap

release: qwap
debug: qwapd

qwap: ${FILES}
	${CC} ${CFLAGS} ${RELEASEFLAGS} -of$@ $<

qwapd: ${FILES}
	${CC} ${CFLAGS} ${DEBUGFLAGS} -of$@ $<

clean:
	rm -f qwap qwapd
