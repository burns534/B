#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "Token.h"
#include "Symbol.h"

typedef struct {
    int count, capacity;
    void **data;
} Stack;

// from debug.c
void print_token(Token *);
char * token_type_to_string(size_t);
// lexer.s
Token * lex(FILE *handle);
// stack.s
Stack * create_stack();
void push_stack(Stack *, void *);
void * pop_stack(Stack *);
void * top_stack(Stack *);

// emitter.s
long precedence(long);

// utility
static void print_stack(Stack *s) {
    for (int i = 0; i < s->count; i++) {
        Token *t = s->data[i];
        printf("%ld:%s ", t->type, t->value);
    }
    puts("");
}

int main(int argc, char **argv) {
    FILE *f = fopen(argv[1], "r");

    for (long i = 14; i < 22; i++) printf("precedence: %ld\n", precedence(i));

    return 0;
}