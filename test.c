#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "Token.h"
#include "Symbol.h"

typedef struct {
    int count, capacity;
    void **data;
} Stack;

typedef struct {
    unsigned count, capacity;
    void **keys, **data;
} Map;

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
// map.s
Map * m_create();
void m_insert(Map *, char *, void *);
void * m_get(Map *, char *);
void * m_remove(Map *, char *);

// utility
static void print_stack(Stack *s) {
    for (int i = 0; i < s->count; i++) {
        Token *t = s->data[i];
        printf("%ld:%s ", t->type, t->value);
    }
    puts("");
}

static void print_map(Map *m) {
    for (int i = 0; i < m->capacity; i++) 
        printf("%s: %lu\n", (long)m->keys[i] >= 0 ? m->keys[i] : "DUMMY", (size_t)m->data[i]);
}

static size_t DJBHash(char* str) {
   size_t hash = 5381;
   while (*str) hash += (hash << 5) + *str++;
   return hash;
}

int main(int argc, char **argv) {
    FILE *f = fopen(argv[1], "r");

    Map *m = m_create();

    m_insert(m, "file handle", f);
    m_insert(m, "file handle", 45);
    print_map(m);
    m_remove(m, "file handle");
    print_map(m);
    printf("count: %u\n", m->count);

    printf("value: %lu\n", (size_t)m_get(m, "file handle"));

    return 0;
}