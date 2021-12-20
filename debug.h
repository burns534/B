#ifndef DEBUG_H
#define DEBUG_H
#include <stdio.h>
#include "Token.h"

static char * token_types[] = { 
    "break", "continue", 
    "else", "if", 
    "register", "return", 
    "struct", "while", 
    "integer", "identifier", 
    "string"
};


char * token_type_to_string(unsigned long type) {
    return token_types[type];
}

#endif