#ifndef DEBUG_H
#define DEBUG_H
#include <stdio.h>
#include "Token.h"

static char * token_types[] = { 
    "break", "continue", 
    "else", "eq", "if", 
    "register", "return", 
    "struct", "while", 
    "integer", "identifier", 
    "string"
};

void print_token(Token *token) {
    if (token->type > 12) printf("%c:%s\n", (char)token->type, token->value);
    else printf("%s:%s\n", token_types[token->type], token->value);
}

char * token_type_to_string(unsigned long type) {
    return token_types[type];
}

#endif