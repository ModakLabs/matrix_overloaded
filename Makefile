# To build matrix_overloaded:
#
#   make
#
# run with
#
#   ./build/matrix_overloaded

D_COMPILER=ldc2

LDMD=ldmd2

DUB_INCLUDE += -I~/.dub/packages/cuda_d-0.1.0/cuda_d/source/
DUB_LIBS    += $(HOME)/.dub/packages/cuda_d-0.1.0/cuda_d/libcuda_d.a

DUB_LIBS =

DFLAGS = -wi -I./source $(DUB_INCLUDE)
RPATH  =
LIBS        += -L=-lcuda -L=-lcublas -L=-lcudart
SRC    = $(wildcard source/matrix_overloaded/*.d  source/test/*.d)
IR     = $(wildcard source/matrix_overloaded/*.ll source/test/*.ll)
BC     = $(wildcard source/matrix_overloaded/*.bc source/test/*.bc)
OBJ    = $(SRC:.d=.o)
OUT    = build/matrix_overloaded

debug: DFLAGS += -O0 -g -d-debug $(RPATH) -link-debuglib $(BACKEND_FLAG) -unittest
release: DFLAGS += -O -release $(RPATH)

profile: DFLAGS += -fprofile-instr-generate=fast_lmm_d-profiler.out

getIR: DFLAGS += -output-ll

getBC: DFLAGS += -output-bc

gperf: LIBS += -L=-lprofiler

gperf: DUB_INCLUDE += -I~/.dub/packages/gperftools_d-0.1.0/gperftools_d/source/

gperf: DUB_LIBS += $(HOME)/.dub/packages/gperftools_d-0.1.0/gperftools_d/libgperftools_d.a

.PHONY:test

all: debug

build-setup:
	mkdir -p build/

build-cuda-setup:
	mkdir -p build/cuda/

ifeq ($(FORCE_DUPLICATE),1)
  DFLAGS += -d-version=FORCE_DUPLICATE
endif


default debug release profile getIR getBC gperf: $(OUT)

# ---- Compile step
%.o: %.d
	$(D_COMPILER) -lib $(DFLAGS) -c $< -od=$(dir $@) $(BACKEND_FLAG)

# ---- Link step
$(OUT): build-setup $(OBJ)
	$(D_COMPILER) -of=build/matrix_overloaded $(DFLAGS)  $(OBJ) $(LIBS) $(DUB_LIBS) $(BACKEND_FLAG)

test:
	chmod 755 build/matrix_overloaded
	./run_tests.sh

debug-strip: debug

run-profiler: profile test
	ldc-profdata merge matrix_overloaded-profiler.out -output matrix_overloaded.profdata

run-gperf: gperf
	$ CPUPROFILE=./prof.out ./run_tests.sh
	pprof --gv build/matrix_overloaded ./prof.out

clean:
	rm -rf build/*
	rm -f $(OBJ) $(OUT) trace.{def,log}
