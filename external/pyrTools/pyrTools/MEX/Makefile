MLAB = /opt/matlab

MXSFX = mexhp7
MEX = ${MLAB}/bin/mex

MFLAGS = 
INC = -I ${MLAB}/extern/include
LIB = -L ${MLAB}/extern/lib/hp700

CC = gcc
CFLAGS = -O2 ${INC} ${LIB}

all: corrDn.${MXSFX} upConv.${MXSFX} pointOp.${MXSFX} \
	histo.${MXSFX} range2.${MXSFX}

clean:
	/bin/rm *.o

corrDn.${MXSFX}: corrDn.c wrap.c convolve.c edges.c
	${MEX} ${MFLAGS} corrDn.c wrap.c convolve.c edges.c

upConv.${MXSFX}: upConv.c wrap.c convolve.c edges.c
	${MEX} ${MFLAGS} upConv.c wrap.c convolve.c edges.c

pointOp.${MXSFX}: pointOp.c
	${MEX} ${MFLAGS} pointOp.c

histo.${MXSFX}: histo.c
	${MEX} ${MFLAGS} histo.c

range2.${MXSFX}: range2.c
	${MEX} ${MFLAGS} range2.c

convolve.o wrap.o edges.o: convolve.h 

%.o : %.c
	${CC} -c ${CFLAGS} $<		

