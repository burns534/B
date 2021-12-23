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

    print_map(m);

    printf("username: %s\n", m_get(m, "another username"));
    
    return 0;
}