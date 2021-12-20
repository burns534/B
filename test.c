#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "Token.h"

typedef struct {
    int count, capacity;
    void **data;
} Stack;


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

// utility
static void print_stack(Stack *s) {
    for (int i = 0; i < s->count; i++) {
        printf("%d ", (int)(long)s->data[i]);
    }
    puts("");
}

int main(int argc, char **argv) {
    FILE *f = fopen(argv[1], "r");
    // Stack *ss = create_stack();
    // Token *t = NULL;
    // // while (!feof(f)) {
    // //     // 
    // // }

    // for (int i = 0; i < 20; i++) {
    //     push_stack(ss, i);
    //     printf("top: %d\n", top_stack(ss));
    // }
    fprintf(f, "string %d", atoi(argv[2]));
    fclose(f);



    // printf("result: %ld\n", atol(argv[1]) / 41254820508);
    


    // void *p = calloc(8, 1);
    // p = realloc(p, 16);

    // printf("type: %s\n", token_type_to_string(3));
    return 0;
}