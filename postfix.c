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
void emit_add(FILE *);
void emit_sub(FILE *);
void emit_mul(FILE *);
void emit_div(FILE *);
void static_load(FILE *, char *, long);
void stack_load(FILE *, long, long);
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
        print_token(t);
        if (t->type > 13 && t->type < 22) { // is operator
            while (top_stack(opstack) && precedence(((Token *)top_stack(opstack))->type) >= precedence(t->type))
                push_stack(outstack, pop_stack(opstack));
            push_stack(opstack, t);
        } else if (t->type == TS_INTEGER || t->type == TS_IDENTIFIER ) {
            push_stack(outstack, t);
        }
    }

    while (top_stack(opstack)) push_stack(outstack, pop_stack(opstack));

    print_stack(outstack);
    print_stack(opstack);

    fclose(infile);
    fclose(outfile);

    return 0;
}