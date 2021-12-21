#include "Token.h"
#include "debug.h"
#include "Symbol.h"
#include <stdio.h>

typedef struct {
    int count, capacity;
    void **data;
} Stack;

// lexer.s
Token * lex(FILE *);
// stack.s
Stack * create_stack();
void push_stack(Stack *, void *);
void * pop_stack(Stack *);
void * top_stack(Stack *);

static void print_stack(Stack *s) {
    for (int i = 0; i < s->count; i++) {
        Token *t = s->data[i];
        printf("%s ", t->value);
    }
    puts("");
}

// emitter.s
void emit_bin(FILE *, Token *, Token *, Token *);
long precedence(long);

int main (int argc, char **argv) {
    if (argc != 3) return 0;

    FILE *infile = fopen(argv[1], "r");
    FILE *outfile = fopen(argv[2], "w");

    // emit_add(outfile);
    // emit_sub(outfile);
    // emit_mul(outfile);
    // emit_div(outfile);
    // static_load(outfile, "_count", 8);
    // stack_load(outfile, 9, 128);
    Stack *opstack = create_stack();
    Stack *outstack = create_stack();
  
    Token *t = NULL;
    while (((t = lex(infile))->type != TS_EOF)) {
        // print_token(t);
        if (t->type > 13 && t->type < 22) { // is operator
            while (top_stack(opstack) && precedence(((Token *)top_stack(opstack))->type) >= precedence(t->type)) {
                // emit asm for operands to be in proper registers
                emit_bin(outfile, pop_stack(opstack), pop_stack(outstack), pop_stack(outstack));
            }
            push_stack(opstack, t);
        } else if (t->type == TS_INTEGER || t->type == TS_IDENTIFIER) {
            push_stack(outstack, t);
        }
    }

    while (top_stack(opstack)) {
        // emit asm for operands before this call
        emit_bin(outfile, pop_stack(opstack), pop_stack(outstack), pop_stack(outstack));
    }

    // print_stack(outstack);
    // print_stack(opstack);

    fclose(infile);
    fclose(outfile);

    return 0;
}