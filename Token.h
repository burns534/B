#ifndef TOKEN_H
#define TOKEN_H
#include <stdlib.h>

typedef struct {
    size_t type;
    char *value;
} Token;

#endif