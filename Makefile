# Make does not offer a recursive wildcard function, so here's one:
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

DEBUG = 1
CPP_BUILD ?= 0
EMSCRIPTEN_BUILD ?= 0
#if you provide other source folders this sets the number which one to use by default (for example to set colored assets as default)
DEFAULTSOURCEDIR ?= 0
#Resolution default is 400x240 if other values than 400x240 are given the scaling mode option below defines whats happens
SCREENRESX ?= 400 
SCREENRESY ?= 240
#to set the window's default size it's the resolution times this value 
WINDOWSCALE ?= 1
#SET SCALING MODE
# 0: Lower Resolutions than 400x240 cut out / crop the screen and center it, Higher resolution will center the 400x240 screen from playdate 
#   can be handy if a game is not using the full 400x240 resolution and draws everything in the center

# 1: Scale to fit window size (distortions will happen !)

# 2: Render using default SDL2 way it will letterbox if resolutions are not same aspect ration of 400x240
SCALINGMODE ?= 2
FULLSCREENATSTARTUP ?= 0

FORCE_ACCELERATED_RENDER ?= 0

# disable for games making much use of pattern or xor drawing without masks or so it will speed them up like twinracer (can break games if disabled like dynamate)
MASKPRIMITIVES ?= 1

SRC_CPP_DIR = src/srcstub/sdl_rotate src/srcstub/gfx_primitives_surface src/srcstub/bump src/srcstub/bump/src src/srcstub src/srcstub/pd_api
SRC_C_DIR = src/srcgame \
  src/srcgame_ycgb src/srcgame_ycgb/levels \
  src/srcgame_cascada src/srcgame_cascada/chipmunk \
  src/srcgame_ff src/srcgame_ff/buildings src/srcgame_ff/ui
OBJ_DIR = ./obj
OUT_DIR = ./Source
SOURCE_DIR = Source
EXE=game

ifeq ($(CPP_BUILD), 1)
SRC_CPP_DIR += src/srcgame
SRC_C_DIR =
endif

INC = $(wildcard *.h $(foreach fd, $(SRC_C_DIR), $(fd)/*.h)) $(wildcard *.hpp $(foreach fd, $(SRC_CPP_DIR), $(fd)/*.hpp))
SRC = $(wildcard *.c $(foreach fd, $(SRC_C_DIR), $(fd)/*.c)) 
SRCCPP = $(wildcard *.cpp $(foreach fd, $(SRC_CPP_DIR), $(fd)/*.cpp)) 
NODIR_SRC = $(notdir $(SRC_C_DIR)) $(notdir $(SRC_CPP_DIR))
OBJSC = $(addprefix $(OBJ_DIR)/, $(SRC:.c=.o)) 
OBJSCPP = $(addprefix $(OBJ_DIR)/, $(SRCCPP:.cpp=.o))
OBJS = $(OBJSC) $(OBJSCPP)
INC_DIRS = -I./ $(addprefix -I, $(SRC_C_DIR)) $(addprefix -I, $(SRC_CPP_DIR))

OPT_LEVEL ?= -O2
SDL2CONFIG = sdl2-config
CC = gcc
CPP = g++
CPP_VERSION = c++17
OUTPUT_ASSETS_DIR =
CFLAGS = -D_USE_MATH_DEFINES -DSDL2API -DTARGET_EXTENSION -Wall -Wextra -Wno-unused-parameter -Wno-error=implicit-function-declaration
LDFLAGS = 
CFLAGS_EXTRA = 
LDFLAGS_EXTRA =
LDUSEX11 = 1

# Windows Cross-Compilation Settings
ifeq ($(TARGET), windows)
    # Ensure you have mingw-w64 installed
    CC = x86_64-w64-mingw32-gcc
    CPP = x86_64-w64-mingw32-g++
    EXE = game.exe
    LDUSEX11 = 0
    
    # Path to where you extracted the SDL2 MinGW development libraries
    # Download from: https://github.com
    SDL_WIN_PATH ?= /home/timboe/playdate/SDL2-2.30.12/x86_64-w64-mingw32
    SDL_TTF_WIN_PATH ?= /home/timboe/playdate/SDL2_ttf-2.24.0/x86_64-w64-mingw32
    SDL_MIXER_WIN_PATH ?= /home/timboe/playdate/SDL2_mixer-2.8.1/x86_64-w64-mingw32
    SDL_IMAGE_WIN_PATH ?= /home/timboe/playdate/SDL2_image-2.8.10/x86_64-w64-mingw32
    SDL_GFX_WIN_PATH ?= /home/timboe/playdate/mingw64

    WIN_SYS_LIBS = -lkernel32 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lshell32 -lsetupapi -lversion -luuid
    
    # Override SDL2 flags for Windows
    CFLAGS += -I$(SDL_WIN_PATH)/include/SDL2 -I$(SDL_TTF_WIN_PATH)/include/SDL2 \
      -I$(SDL_MIXER_WIN_PATH)/include/SDL2 -I$(SDL_IMAGE_WIN_PATH)/include/SDL2 \
      -I$(SDL_GFX_WIN_PATH)/include/SDL2 
    # Order matters: mingw32 and SDL2main must come before SDL2
    LDFLAGS += -L$(SDL_WIN_PATH)/lib -L$(SDL_TTF_WIN_PATH)/lib -L$(SDL_MIXER_WIN_PATH)/lib \
      -L$(SDL_IMAGE_WIN_PATH)/lib -L$(SDL_GFX_WIN_PATH)/lib \
      -lmingw32 -lSDL2main -lSDL2 -lSDL2_image -lSDL2_ttf -lSDL2_mixer -lSDL2_gfx $(WIN_SYS_LIBS) -mwindows

    LDFLAGS += -static-libgcc -static-libstdc++
else
    # Standard Linux Flags
    CFLAGS += `$(SDL2CONFIG) --cflags` $(CFLAGS_EXTRA)
    LDFLAGS += `$(SDL2CONFIG) --libs` $(LDFLAGS_EXTRA) -lSDL2_image -lSDL2_ttf -lSDL2_mixer -lSDL2_gfx
endif

ifneq ($(PLATFORM),)
include build_platforms/$(PLATFORM).mk
endif

ifneq ($(PLATFORM),)
include build_platforms/$(PLATFORM).mk
endif

ifeq ($(FORCE_ACCELERATED_RENDER), 1)
CFLAGS += -DFORCE_ACCELERATED_RENDER
endif

PLATFORM=msys_mingw

# CFLAGS += `$(SDL2CONFIG) --cflags` $(CFLAGS_EXTRA)
# LDFLAGS += `$(SDL2CONFIG) --libs` $(LDFLAGS_EXTRA)

#provide OUTPUT_ASSETS_DIR in <platform>.mk to convert audio to ogg
ifneq ($(OUTPUT_ASSETS_DIR),)
#used for converting sound to ogg with ffmpeg
ALL_SOUND_MUSIC_WAV = $(call rwildcard, $(SOURCE_DIR)/,*.wav)
ALL_SOUND_MUSIC_OGG_SOURCE = $(ALL_SOUND_MUSIC_WAV:.wav=.ogg)
ALL_SOUND_MUSIC_OGG_ASSETS = $(subst $(SOURCE_DIR)/,$(OUTPUT_ASSETS_DIR)/,$(ALL_SOUND_MUSIC_OGG_SOURCE))

ALL_SOUND_MUSIC_MP3 = $(call rwildcard, $(SOURCE_DIR)/,*.mp3)
ALL_SOUND_MUSIC_OGG_MP3_SOURCE = $(ALL_SOUND_MUSIC_MP3:.mp3=.ogg)
ALL_SOUND_MUSIC_OGG_MP3_ASSETS = $(subst $(SOURCE_DIR)/,$(OUTPUT_ASSETS_DIR)/,$(ALL_SOUND_MUSIC_OGG_MP3_SOURCE))
endif

ifeq ($(DEBUG), 1)
CFLAGS += -g
OPT_LEVEL =
endif

ifeq ($(LDUSEX11), 1)
LDFLAGS += -lX11
endif

CFLAGS += -DMASKPRIMITIVES=$(MASKPRIMITIVES) -DSCALINGMODE=$(SCALINGMODE) -DFULLSCREENATSTARTUP=$(FULLSCREENATSTARTUP) -DDEFAULTSOURCEDIR=$(DEFAULTSOURCEDIR) -DSCREENRESX=$(SCREENRESX) -DSCREENRESY=$(SCREENRESY) -DWINDOWSCALE=$(WINDOWSCALE)

.PHONY: all clean

all: $(EXE)

$(EXE): $(OUTPUT_ASSETS_DIR) $(ALL_SOUND_MUSIC_OGG_ASSETS) $(ALL_SOUND_MUSIC_OGG_MP3_ASSETS) $(OBJS) $(INC)
	mkdir -p $(OUT_DIR)
	$(CPP) -o $(OUT_DIR)/$@ -std=$(CPP_VERSION) $(OBJS) $(LDFLAGS)

$(OBJ_DIR)/%.o: %.cpp
	mkdir -p $(@D)
	$(CPP) -o $@ -std=$(CPP_VERSION) $(OPT_LEVEL) $(CFLAGS) -c $< $(INC_DIRS)

$(OBJ_DIR)/%.o: %.c
	mkdir -p $(@D)
	$(CC) -o $@ $(OPT_LEVEL) $(CFLAGS) -c $< $(INC_DIRS)

$(ALL_SOUND_MUSIC_OGG_ASSETS):
	mkdir -p "$(dir $@)"
	ffmpeg -y -i "$(subst .ogg,.wav,$(subst $(OUTPUT_ASSETS_DIR)/,$(SOURCE_DIR)/,$@))" $(FFMPEG_OPTS) "$@"
	
$(ALL_SOUND_MUSIC_OGG_MP3_ASSETS):
	mkdir -p "$(dir $@)"
	ffmpeg -y -i "$(subst .ogg,.mp3,$(subst $(OUTPUT_ASSETS_DIR)/,$(SOURCE_DIR)/,$@))" $(FFMPEG_OPTS) "$@"

$(OUTPUT_ASSETS_DIR):
	cp -r $(SOURCE_DIR) $@
	find $@ -name '*.wav' -delete
	find $@ -name '*.mp3' -delete

clean:
	$(RM) -rv *~ $(OBJS) $(EXE) $(OUTPUT_ASSETS_DIR)
