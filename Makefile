#
# Makefile for tonclib.
#

#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(GBA_LLVM)),)
$(error Please set GBA_LLVM in your environment. export GBA_LLVM=<path to gba-llvm installation>)
endif

BIN         :=  $(GBA_LLVM)/bin
BUILD		:=	build
DESTDIR		?=	$(BUILD)
SRCDIRS		:=	asm src src/font src/tte src/pre1.3
INCDIRS		:=	include
DATADIRS	:=	data

DATESTRING	:=	$(shell date +%Y)$(shell date +%m)$(shell date +%d)

ARCH		:=	-mthumb

bTEMPS		:= 0	# Save gcc temporaries (.i and .s files)
bDEBUG2		:= 0	# Generate debug info (bDEBUG2? Not a full DEBUG flag. Yet)

VERSION		:=	1.4.3

#---------------------------------------------------------------------------------
# Clang config file
#---------------------------------------------------------------------------------

CONFIG=armv4t-gba.cfg

#---------------------------------------------------------------------------------
# Options for code generation
#---------------------------------------------------------------------------------

CBASE   := $(INCLUDE) -Wall -fno-strict-aliasing #-fno-tree-loop-optimize
CBASE	+= -O2

CFLAGS := $(CBASE) $(ARCH)

ASFLAGS := $(INCLUDE)

# --- Save temporary files ? ---
ifeq ($(strip $(bTEMPS)), 1)
	CFLAGS	 += -save-temps
	CXXFLAGS += -save-temps
endif

# --- Debug info ? ---

ifeq ($(strip $(bDEBUG2)), 1)
	CFLAGS	+= -g
	LDFLAGS	+= -g
endif

#---------------------------------------------------------------------------------
# Tools
#---------------------------------------------------------------------------------

export CC	:=	$(BIN)/clang
export CXX	:=	$(BIN)/clang++
export AS	:=	$(BIN)/clang
export AR	:=	$(BIN)/llvm-ar
export OBJCOPY	:=	$(BIN)/llvm-objcopy
export STRIP	:=	$(BIN)/llvm-strip
export NM	:=	$(BIN)/llvm-nm

#---------------------------------------------------------------------------------

ifneq ($(BUILD),$(notdir $(CURDIR)))

export TARGET	:=	$(CURDIR)/lib/libtonc.a

export VPATH	:=	$(foreach dir,$(DATADIRS),$(CURDIR)/$(dir)) $(foreach dir,$(SRCDIRS),$(CURDIR)/$(dir))

CFILES		:=	$(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.c)))

SFILES		:=	$(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(DATADIRS),$(notdir $(wildcard $(dir)/*.*)))

export OFILES	:=	$(addsuffix .o,$(BINFILES)) $(CFILES:.c=.o) $(SFILES:.s=.o)
export INCLUDE	:=	$(foreach dir,$(INCDIRS),-I$(CURDIR)/$(dir))
export DEPSDIR	:=	$(CURDIR)/build

.PHONY: $(BUILD) clean docs

$(BUILD):
	@[ -d lib ] || mkdir -p lib
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

docs:
	doxygen libtonc.dox

clean:
	@echo clean ...
	@rm -fr $(BUILD)

install:
	@mkdir -p $(DESTDIR)/lib
	@mkdir -p $(DESTDIR)/include
	@cp -rv include/* $(DESTDIR)/include/
	@cp -v lib/libtonc.a $(DESTDIR)/lib/

#-------------------------------------------------------------------------------
dist:
#-------------------------------------------------------------------------------
	@tar -cvjf libtonc-src-$(VERSION).tar.bz2 asm src include \
		Makefile todo.txt libtonc.dox base.c base.h

#---------------------------------------------------------------------------------

else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------

%.a :

$(TARGET): $(OFILES)

%.a : $(OFILES)
	@echo Building $@
	@rm -f $@
	@$(AR) -crs $@ $^
	$(NM) -Sn $@ > $(basename $(notdir $@)).map

%.o : %.c
	@echo $(notdir $<)
	$(CC) --config $(CONFIG) -MMD -MP -MF $(DEPSDIR)/$*.d $(CFLAGS) -c $< -o $@

%.o : %.s
	@echo $(notdir $<)
	$(CC) --config $(CONFIG) -MMD -MP -MF $(DEPSDIR)/$*.d -x assembler-with-cpp $(ASFLAGS) -c $< -o $@

-include $(DEPENDS)

endif

#---------------------------------------------------------------------------------
