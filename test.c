#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "Token.h"

// void create_token(size_t type, char *value) {
//     char *allocation = malloc(56);
//     strcpy(allocation, value);
//     printf("argv: %s\n", allocation);
// }

Token * lex(FILE *handle);
void print_token(Token *);
int keyword(char *);
char * token_type_to_string(size_t);

void error(char c) {
    printf("error: invalid token %c\n", c);
    exit(1);
}

int main(int argc, char **argv) {
    FILE *f = fopen(argv[1], "r");
    Token *t = NULL;
    while (!feof(f))
        if ((t = lex(f)))
            print_token(t);
    fclose(f);
    // printf("type: %s\n", token_type_to_string(3));
    return 0;
}