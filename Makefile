# C/C++ and x86 Assembly Makefile

# Compiler and tool flags
CC=gcc
XC=g++
NC=nasm
DEFS=
FLAG=
FLAGS=$(strip -Wall -Wextra -no-pie $(FLAG) $(DEFS))
CSTD=-std=gnu11
XSTD=-std=gnu++11
FLAGC=$(FLAGS) $(CSTD)
FLAGX=$(FLAGS) $(XSTD)
FLAGN=$(FLAG) -f elf64
LIBS=-lpython3.8 -lm

# Directories
RSC_DIR=assets
BIN_DIR=bin
OBJ_DIR=build
DOC_DIR=doc
SRC_DIR=src
TST_DIR=tests

# If src/ dir does not exist, use current directory .
ifeq "$(wildcard $(SRC_DIR) )" ""
	SRC_DIR=.
endif

# Files
DIRS=$(shell find -L $(SRC_DIR) -type d)
APPNAME=$(shell basename $(shell pwd))
HEADERC=$(wildcard $(DIRS:%=%/*.h))
HEADERX=$(wildcard $(DIRS:%=%/*.hpp))
SOURCEC=$(wildcard $(DIRS:%=%/*.c))
SOURCEX=$(wildcard $(DIRS:%=%/*.cpp))
SOURCEN=$(wildcard $(DIRS:%=%/*.asm))
OBJECTC=$(SOURCEC:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
OBJECTX=$(SOURCEX:$(SRC_DIR)/%.cpp=$(OBJ_DIR)/%.o)
OBJECTN=$(SOURCEN:$(SRC_DIR)/%.asm=$(OBJ_DIR)/%.o)
OBJECTS=$(strip $(OBJECTN) $(OBJECTC) $(OBJECTX))
INCLUDE=$(DIRS:%=-I%)
INCLUDEP=-I/usr/include/python3.8
DEPENDS=$(OBJECTS:%.o=%.d)
REMOVES=$(BIN_DIR)/ $(OBJ_DIR)/ $(DOC_DIR)/
EXEFILE=$(BIN_DIR)/$(APPNAME)
LD=$(if $(SOURCEX),$(XC),$(CC))
TARGETS+=$(EXEFILE)
EXEARGS+=$(strip $(EXEFILE) $(ARGS))
DOCTARG+=cppdoc

# Targets
default: debug
debug: FLAG += -g
debug: $(TARGETS)

-include *.mk $(DEPENDS)
.SECONDEXPANSION:

# C/C++ Linker call
$(EXEFILE): $(OBJECTS) | $$(@D)/.
	$(LD) $(FLAGS) $(INCLUDE) $^ -o $@ $(LIBS)

# Compile C source file
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $$(@D)/.
	$(CC) -c $(FLAGC) $(INCLUDE) -MMD $< -o $@

# Compile C++ source file
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp | $$(@D)/.
	$(XC) -c $(FLAGX) $(INCLUDE) $(INCLUDEP) -MMD $< -o $@

# Compile x86 source file
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm | $$(@D)/.
	$(NC) $(FLAGN) $(INCLUDE) $< -o $@

# Create a subdirectory if not exists
.PRECIOUS: %/.
%/.:
	mkdir -p $(dir $@)

format:
	find . -name "*.cpp" -o -name "*.c" -o -name "*.h" -o -name "*.hpp" \
	| xargs -I {} clang-format -i {}

run: $(EXEFILE)
	$(EXEARGS)

clean:
	rm -rf $(REMOVES)

# Install dependencies (Debian)
instdeps:
	sudo apt install build-essential nasm doxygen clang-format python3-pip \
	python3-dev python3-gpg python-numpy && sudo pip3 install numpy ipython