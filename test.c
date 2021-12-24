#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "Token.h"
#include "Symbol.h"

typedef struct {
    int top, capacity;
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

// map.s
Map * m_create();
void m_insert(Map *, char *, void *);
size_t m_contains(Map *, char *);
void * m_get(Map *, char *);
void * m_remove(Map *, char *);

// stack.s
Stack * s_create();
void s_push(Stack *, void *);
void * s_pop(Stack *);
void * s_top(Stack *);

// symbol_table.s
void create_symbol_table();
void enter_scope();
void exit_scope();
size_t * get_entry(char *);
void save_entry(char *, size_t *);

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
    for (int i = 0; i < m->capacity; i++) 
        printf("%s: %lu\n", (long)m->keys[i] >= 0 ? m->keys[i] : "DUMMY", (size_t)m->data[i]);
}

static size_t DJBHash(char* str) {
   size_t hash = 5381;
   while (*str) hash += (hash << 5) + *str++;
   return hash;
}
#include <assert.h>

// static void * map_get(Map *m, char *key) {
//     size_t index = DJBHash(key) % m->capacity;
//     while (1) {
//         if (m->keys[index] == 0) return 0;
//         else if (m->keys[index] == -1) {
//             index = (index + 1) % m->capacity;
//             continue;
//         } else {
//             return m->data[index];
//         }
//     }
// }

void m_resize(Map *);
// void m_insert_util(Map *, char *, void *);

int main(int argc, char **argv) {
    // FILE *f = fopen(argv[1], "r");
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
    for (int i = 0; i < 20; i ++) s_push(s, (size_t)i);

    
    print_stack(s);

    for (int i = 0; i < 20; i++) s_pop(s);

    print_stack(s);

    s_push(s, 80UL);
    s_push(s, 480UL);
    s_push(s, 8300UL);

    print_stack(s);
*/
    create_symbol_table();

    save_entry("foo", 4UL);
    
    printf("foo: %lu\n", (size_t)get_entry("foo"));

    save_entry("foo", 5UL);

    printf("foo: %lu\n", (size_t)get_entry("foo"));

    enter_scope();

    save_entry("foo", 7UL);

    printf("foo: %lu\n", (size_t)get_entry("foo"));


//    FILE *infile = fopen(argv[1], "r");
//    Token *t;
//     while ((t = lex(infile))->type != TS_EOF) print_token(t);
   return 0;
}