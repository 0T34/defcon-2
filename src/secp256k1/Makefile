LIB=libsecp256k1.a

CFLAGS=-O3 -g -std=c89 -pedantic -Wall -Wextra -Wcast-align -Wnested-externs -Wshadow -Wstrict-prototypes -Wno-unused-function -Wno-long-long -Wno-overlength-strings
DEFS=-DUSE_NUM_NONE -DUSE_FIELD_INV_BUILTIN -DUSE_SCALAR_INV_BUILTIN -DUSE_FIELD_10X26 -DUSE_SCALAR_8X32

OBJECTS = obj/secp256k1.o
	
all: $(LIB)

obj/%.o: src/%.c
	$(CC) $(CFLAGS) $(DEFS) -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
