#include "Token.h"
#include <stdio.h>

Token * lex(FILE *);

// E ::= M E'
// E' ::= + E
// E' ::= ''
// M ::= id M'
// M' ::= * M
// M' ::= ''

typedef enum {
    E, EP, M, MP,
    // terminals
    CLOSE,
    IDENTIFIER = 10,
    END

} Symbol;

Symbol P_E[] = { CLOSE, EP, M, 0 };
Symbol P_EP[] = { CLOSE, E, '+', 0 };
Symbol P_M[] = { CLOSE, MP, IDENTIFIER, 0 };
Symbol P_MP[] = { CLOSE, M, '*', 0 };

Symbol epsilon, error;
#define EPSILON &epsilon
#define ERROR &error

// cols: $, +, id, *
// rows: E, E', M, M'
Symbol *lookup_table[4][4] = {
    { ERROR, ERROR, P_E, ERROR },
    { EPSILON, P_EP, ERROR, ERROR },
    { ERROR, ERROR, P_M, ERROR },
    { EPSILON, EPSILON, ERROR, P_MP }
};

int main (int argc, char **argv) {
    if (argc != 2) {
        puts("must provide filename");
        return 1;
    }

    FILE *f = fopen(argv[1], "r");

    // push start symbol and end symbol on symbol stack

    Token *current;
    while ((current = lex(f))) {
        // if current matches top of stack, pop stack
        // if top of stack is close, set current node to parent of current node
    }


    fclose(f);
    return 0;
}