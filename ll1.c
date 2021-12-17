#include "Token.h"
#include <stdio.h>

// E ::= M E'
// E' ::= + E
// E' ::= ''
// M ::= id M'
// M' ::= * M
// M' ::= ''

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

char * symbol_to_string(Symbol s) {
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

typedef struct {
    int count, capacity;
    void **data;
} Stack;
// child array null terminated
// value only on leaf nodes
typedef struct {
    int child_count, child_cap;
    void *parent;
    void **children;
    char *value;
    int type;
} CSTNode;

Symbol P_E[] = { TS_CLOSE, NTS_EP, NTS_M, TS_END_PROD };
Symbol P_EP[] = { TS_CLOSE, NTS_E, TS_ADD, TS_END_PROD };
Symbol P_M[] = { TS_CLOSE, NTS_MP, TS_INTEGER, TS_END_PROD };
Symbol P_MP[] = { TS_CLOSE, NTS_M, TS_MUL, TS_END_PROD };

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

static Symbol * get_production(int top, Token *t) {
    // printf("lookup called with top: %s and input: %s\n", symbol_to_string(top), symbol_to_string(t->type));
    int ts_index;
    switch (t->type) {
        case TS_EOF: ts_index = 0;
        break;
        case TS_ADD: ts_index = 1;
        break;
        case TS_INTEGER: ts_index = 2;
        break;
        case TS_MUL: ts_index = 3;
        break;
        default:
        puts("error");
        exit(1);
    }
    return lookup_table[top - 34][ts_index];
}

#include <string.h>
#include <ctype.h>

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
// parser.s
CSTNode * create_node(int, CSTNode *); // type, parent
void add_child(CSTNode *child, CSTNode *parent);

// utility
static void print_stack(Stack *s) {
    for (int i = 0; i < s->count; i++) printf("%s ", symbol_to_string(s->data[i]));
    puts("");
}

static inline void print_space(int count, int num) {
    for (int i = 0; i < count * num; i++) putchar(' ');
}

static void print_tree_util(CSTNode *node, int level) {
    if (!node) return;
    print_space(level, 2);
    printf("%s: %s: %u\n", symbol_to_string(node->type), node->value, node->child_count);

    if (node->child_count) {
        print_space(level, 2); putchar('\r');
    }
    for (int i = 0; i < node->child_count; i++) 
        print_tree_util(node->children[i], level + 1);
}

static void print_cst_tree(CSTNode *root) {
    print_tree_util(root, 0);
}

int main(int argc, char **argv) {
    FILE *f = fopen(argv[1], "r");
    Stack *ss = create_stack();
    push_stack(ss, TS_EOF);
    push_stack(ss, NTS_E); // start symbol

    CSTNode *current = create_node(NTS_E, NULL);
    // CSTNode *child = create_node(NTS_M, current);
    // CSTNode *child2 = create_node(NTS_MP, current);
    // CSTNode *gchild = create_node(NTS_EP, child);


    // printf("child count: %u\n", current->child_count);
    
    // print_cst_tree(current);
    // return 0;

    Token *t = lex(f);
    while (1) {
        if (top_stack(ss) == TS_EOF) {
            if (t->type != TS_EOF) {
                puts("parse error");
                return 1;
            } else {
                puts("parse successful");
                print_cst_tree(current);
                return 0;
            }
        }
        
        // printf("loop with token %s:%s and top %s\n", symbol_to_string(t->type), t->value, symbol_to_string(top_stack(ss)));
        printf("current: %s, stack: ", symbol_to_string(current->type));
        print_stack(ss);
        
        if (top_stack(ss) == TS_CLOSE) {
            current = current->parent;
            pop_stack(ss);
            continue;
            // do stuff
        } else if (top_stack(ss) == t->type) {
            // save value if integer
            switch (t->type) {
                case TS_INTEGER:
                    puts("assigning integer value");
                    current->value = t->value;
                    break;
                default:
                    break;
            }
            // pop stack
            pop_stack(ss);
            // get new input
            t = lex(f);
            continue;
        }
        // look up production
        Symbol *production = get_production(top_stack(ss), t);
        if (production == EPSILON) {
            pop_stack(ss);
        } else if (production == ERROR) {
            puts("parse error");
            return 1; 
        } else {
            // note the stack is popped here
            current = create_node(pop_stack(ss), current);
            printf("created current with type: %d: %s\n", current->type, symbol_to_string(current->type));
            while (*production != TS_END_PROD) {
                // printf("pushing stack with production: %s\n", symbol_to_string(*production));
                push_stack(ss, *production);
                production++;
            }
        }
    }
    fclose(f);

    return 0;
}