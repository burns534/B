#include "Token.h"
#include "debug.h"
#include <stdio.h>

typedef enum {
    TS_END_PROD = -1,
    TS_BREAK,
    TS_CONTINUE,
    TS_ELSE,
    TS_EQ,
    TS_IF,
    TS_REGISTER,
    TS_RETURN,
    TS_STRUCT,
    TS_WHILE,

    TS_INTEGER,
    TS_IDENTIFIER,
    TS_STRING,

    TS_EOF,
    TS_CLOSE,

    TS_INVALID,
    TS_ADD,
    TS_SUB,
    TS_DIV,
    TS_MUL,
    TS_MOD,
    TS_ASSIGN,
    TS_LT,
    TS_NOT,
    TS_ADR,
    TS_OPEN_PAREN,
    TS_CLOSE_PAREN,
    TS_OPEN_SQ_BRACE,
    TS_CLOSE_SQ_BRACE,
    TS_OPEN_CURL_BRACE,
    TS_CLOSE_CURL_BRACE,
    TS_DOT,
    TS_SEMICOLON,
    TS_COLON,
    TS_COMMA,

    NTS_E,
    NTS_EP,
    NTS_M,
    NTS_MP

} Symbol;

typedef struct {
    int count, capacity;
    void **data;
} Stack;

static char * symbol_to_string(Symbol s) {
    switch (s) {
        case NTS_E: return "E";
        case NTS_EP: return "EP";
        case NTS_M: return "M";
        case NTS_MP: return "MP";
        case TS_EOF: return "$";
        case TS_INTEGER: return "INTEGER";
        case TS_IDENTIFIER: return "IDENTIFIER";
        case TS_STRING: return "STRING";
        case TS_CLOSE: return "CLOSE";
        case TS_ADD: return "+";
        case TS_MUL: return "*";
        default: return "unknown";
    }
}

// lexer.s
Token * lex(FILE *);
// stack.s
Stack * create_stack();
void push_stack(Stack *, void *);
void * pop_stack(Stack *);
void * top_stack(Stack *);
// utility
static void print_stack(Stack *s) {
    for (int i = 0; i < s->count; i++) printf("%s ", symbol_to_string((Symbol)(long)s->data[i]));
    puts("");
}

// emitter.s
void emit_add(FILE *);
void emit_sub(FILE *);
void emit_mul(FILE *);
void emit_div(FILE *);
void static_load(FILE *, char *, long);

int main (int argc, char **argv) {
    if (argc != 3) return 0;

    FILE *infile = fopen(argv[1], "r");
    FILE *outfile = fopen(argv[2], "w");

    emit_add(outfile);
    // emit_sub(outfile);
    // emit_mul(outfile);
    // emit_div(outfile);

    fclose(infile);
    fclose(outfile);

    return 0;
}