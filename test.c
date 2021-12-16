#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "Token.h"

// void create_token(size_t type, char *value) {
//     char *allocation = malloc(56);
//     strcpy(allocation, value);
//     printf("argv: %s\n", allocation);
// }

// from debug.c
void print_token(Token *);
char * token_type_to_string(size_t);

// Token * lex(FILE *handle);
// int keyword(char *);

typedef struct {
    int count, capacity;
    void **data;
} Stack;

Stack * create_stack();
void push_stack(Stack *, void *);
void * pop_stack(Stack *);
void * top_stack(Stack *);

void error(char c) {
    printf("error: invalid token %c\n", c);
    exit(1);
}

void print_stack(Stack *s) {
    for (int i = 0; i < s->count; i++) {
        printf("%d ", s->data[i]);
    }
    puts("");
}

int main(int argc, char **argv) {
    // FILE *f = fopen(argv[1], "r");
    // Token *t = NULL;
    // while (!feof(f))
    //     if ((t = lex(f)))
    //         print_token(t);
    // fclose(f);

    Stack *s = create_stack();
    for (long i = 0; i < 20; i++) {
        push_stack(s, (void *)i);
    }

    print_stack(s);

    for (int i = 0; i < 30; i++) pop_stack(s);

    print_stack(s);

    // void *p = calloc(8, 1);
    // p = realloc(p, 16);

    // printf("type: %s\n", token_type_to_string(3));
    return 0;
}