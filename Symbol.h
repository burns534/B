#ifndef SYMBOL_H
#define SYMBOL_H

#include "Token.h"

typedef enum {
    TS_END_PROD = -1,
    TS_BREAK,
    TS_CONTINUE,
    TS_FUNC,
    TS_IF,
    TS_RETURN,
    TS_STRUCT,
    TS_VAR,
    TS_WHILE,

    TS_INTEGER,
    TS_IDENTIFIER,
    TS_STRING,

    TS_EOF,
    TS_CLOSE,
    TS_INVALID,
    // precedence groups
    TS_ASSIGN, // lowest

    TS_EQ,
    TS_LT, 

    TS_ADD,
    TS_SUB,

    TS_DIV,
    TS_MUL,
    TS_MOD,

    TS_NOT, // right associative unary
    TS_ADR, // right associative unary
    TS_PTR,

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

static char * symbol_strings[] = {
    "break", "continue", "func", "if", "return",
    "struct", "var", "while"
};

static char * symbol_to_string(Symbol s) {
    if (s < 8 && s != -1) {
        return symbol_strings[s];
    }
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
        case TS_SUB: return "-";
        case TS_DIV: return "/";
        case TS_MOD: return "%";
        case TS_EQ: return "?";
        case TS_ASSIGN: return "=";
        case TS_LT: return "<";
        case TS_ADR: return "&";
        case TS_OPEN_PAREN: return "(";
        case TS_CLOSE_PAREN: return ")";
        case TS_OPEN_CURL_BRACE: return "{";
        case TS_CLOSE_CURL_BRACE: return "}";
        case TS_SEMICOLON: return ";";
        case TS_COMMA: return ",";
        default: return "unknown";
    }
}

static void print_token(Token *t) {
    printf("%s:%s\n", symbol_to_string(t->type), t->value);
}

#endif