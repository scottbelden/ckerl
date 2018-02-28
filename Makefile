# Since we distribute the generated C file for simplicity (and so that end users
# won't need to install cython). You can re-create the C file using this
# Makefile.


ifndef PYTHON
	PYTHON=python
endif

%.c: %.pyx
	cython $(<D)/$(<F)
	cython -a $(<D)/$(<F)

c_files = ckerl/conv.c ckerl/kerl.c

all: $(c_files)

clean:
	rm -fv $(c_files)
	rm -fv ckerl/*.so

fresh: clean all

.PHONY: all clean fresh
