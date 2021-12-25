#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "Token.h"
#include "Symbol.h"

#define MAX_TOKEN 1 << 16

static Token *tokens[MAX_TOKEN];
static long cur = 0;

typedef struct {
    int top, capacity;
    void **data;
} Stack;

typedef struct {
    unsigned count, capacity;
    void **keys, **data;
} Map;

typedef struct {
    size_t type;
    Stack *params;
    size_t entry_point;
} function_entry;

typedef struct {
    size_t type, value;
} variable_entry;

// lexer.s
Token * lex(FILE *);
// stack.s
Stack * s_create();
void s_push(Stack *, void *);
void * s_pop(Stack *);
void * s_top(Stack *);
// symbol_table.s
void create_symbol_table();
void enter_scope();
void exit_scope();
Stack * get_symbol_table();
size_t * get_entry(char *);
void save_entry(char *, size_t *);
// return_stack.s
void create_return_stack();
// bc.s
variable_entry * create_variable_entry(size_t);
function_entry * create_function_entry(Stack *, size_t);
size_t variable_definition(Token *, size_t *);
size_t function_definition(Token *, size_t *);
void function_call(Token *, size_t *);
size_t precedence(long);
void runtime_error(char *);
size_t unary_eval(Token *, Token *);
size_t binary_eval(size_t, size_t, Token *);
size_t primary_eval(Token *);
size_t expression_eval(Token *, size_t *);
void if_statement(Token *, size_t *);
void return_statement(Token *, size_t *);
void while_statement(Token *, size_t *);
void evaluate(Token *, size_t *);
// map.s
Map * m_create();
void m_insert(Map *, char *, void *);
void * m_get(Map *, char *);
size_t m_contains(Map *, char *);
void * m_remove(Map *, char *);


// utility
static void print_stack(Stack *s) {
    for (int i = 0; i < s->capacity; i++) 
        printf("%lu ", (size_t)s->data[i]);
    puts("");
}

static void print_keys(Map *m) {
    for (int i = 0; i < m->capacity; i++)
        printf("%lu\n", (size_t)m->keys[i]);
}

static void print_map(Map *m) {
    for (int i = 0; i < m->capacity; i++)  {
        if ((size_t)m->keys[i] > 0) {
            printf("\t%s: %lu\n", m->keys[i], (size_t)m->data[i]);
        }
    }
}

static void print_map_entries(Map *m) {
    for (int i = 0; i < m->capacity; i++) {
        if ((size_t)m->keys[i] > 0) {
            if (*(size_t *)(m->data[i]) == 64)
                printf("\t%s: entry: %lu: %lu ", (char *)m->keys[i], *(size_t *)(m->data[i]), *(size_t *)(m->data[i] + 8));
            else
                printf("\t%s: entry: %lu: %p: %lu ", (char *)m->keys[i], *(size_t *)(m->data[i]), *(size_t *)(m->data[i] + 8), *(size_t *)(m->data[i] + 16));
        }
    }
}

static size_t DJBHash(char* str) {
   size_t hash = 5381;
   while (*str) hash += (hash << 5) + *str++;
   return hash;
}

void print_symbol_table() {
    Stack *s = get_symbol_table();
    for (int i = 0; i < s->top + 1; i++) {
        printf("scope: %d\n", i);
        print_map_entries((Map *)s->data[i]);
        puts("");
    }
}

void print_function_entry(function_entry *e) {
    printf("type: %lu, entry: %lu\n", e->type, e->entry_point);
    Stack *s = e->params;
    for (int i = 0; i < s->top + 1; i++)
        printf("%s ", s->data[i]);
}


int main(int argc, char **argv) {
/*
    Map *m = m_create();
    m_insert(m, "count", 0UL);
    m_insert(m, "count1", 1UL);
    m_insert(m, "count2", 4UL);
    m_insert(m, "count3", 9UL);
    m_insert(m, "count4", 16UL);
    m_insert(m, "username", 34UL);
    m_insert(m, "username1", 98UL);
    m_insert(m, "username2", 73UL);
    m_insert(m, "another username", "kburns8");

    m_remove(m, "username2");

    print_map(m);

    printf("contains: %lu\n", m_contains(m, "username2"));

    // printf("username: %s\n", m_get(m, "another username"));
*/
/*
    Stack *s = s_create();
    printf("top: %lu\n", s_top(s));
    s_push(s, 5UL);
    printf("top: %lu\n", s_top(s));

    for (int i = 0; i < 20; i ++) s_push(s, (size_t)i);

    print_stack(s);

    for (int i = 0; i < 20; i++) s_pop(s);

    print_stack(s);

    s_push(s, 80UL);
    s_push(s, 480UL);
    s_push(s, 8300UL);

    

    print_stack(s);

    return 0;
*/
/*
    create_symbol_table();

    save_entry("foo", 4UL);
    
    printf("foo: %lu\n", (size_t)get_entry("foo"));

    save_entry("foo", 5UL);

    printf("foo: %lu\n", (size_t)get_entry("foo"));

    enter_scope();

    save_entry("foo", 7UL);

    printf("foo: %lu\n", (size_t)get_entry("foo"));

    save_entry("new_foo", 23UL);

    enter_scope();

    save_entry("username", 25290UL);

    save_entry("foo", 19UL);

    save_entry("new_foo", 13UL);

    exit_scope();

    print_symbol_table(); // change back map_entries if you want to use this for UL
*/

    if (argc != 2) return 0;

    FILE *infile = fopen(argv[1], "r");

    // first collect all the tokens in the program
    Token *t;
    while ((t = lex(infile))->type != TS_EOF) tokens[cur++] = t;
    tokens[cur] = t; // eof
    for (int i = 0; i < cur; i++) {
        printf("%d:", i); print_token(tokens[i]);
    }
    cur = 0;

    create_symbol_table();
    create_return_stack();

    // Stack *s = get_symbol_table();

    // printf("s: %p\n", s);

    // print_stack(s);

    function_definition(tokens, &cur);

    print_symbol_table();

   return 0;
}