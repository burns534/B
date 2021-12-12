from io import TextIOWrapper
import sys
import re

T_MUL = 0
T_DIV = 1
T_ADD = 2
T_SUB = 3
T_MOD = 4
T_NOT = 5
T_ADR = 6
T_AND = 7
T_OR = 8
T_PTR_OP = 9
T_EQ = 10
T_NE = 11
T_LT = 12
T_ASSIGN = 13
T_KEYWORD = 14
T_STRING_LITERAL = 15
T_INTEGER_LITERAL = 16
T_IDENTIFIER = 17
T_OPERATOR = 18

keywords = [ "break", "continue", "else", "if", "register", "return", "struct", "while"]

class Token:
    def __init__(self, tokenType, value):
        self.tokenType = tokenType
        self.value = value
class ASTNode:
    def __init__(self, nodeType):
        self.nodeType = nodeType

cursor = 0

def string_token(fs: str) -> Token:
    global cursor
    if not fs[cursor].isalpha():
        return None
    buffer = ""
    while cursor < len(fs):
        if not fs[cursor] or not fs[cursor].isalpha():
            if buffer in keywords:
                return Token(T_KEYWORD, buffer)
            return Token(T_IDENTIFIER, buffer)
        buffer += fs[cursor]
        cursor += 1

def string_literal(fs: str) -> Token:
    global cursor
    if fs[cursor] == '"':
        cursor += 1
        buffer = ""
        while cursor < len(fs) and fs[cursor] != '"':
            buffer += fs[cursor]
            cursor += 1
        cursor += 1
        return Token(T_STRING_LITERAL, buffer)
    return None

def integer_literal(fs: str) -> Token:
    global cursor
    if not fs[cursor].isdigit():
        return None
    buffer = ""
    while cursor < len(fs) and fs[cursor].isdigit():
        buffer += fs[cursor]
        cursor += 1
    return Token(T_INTEGER_LITERAL, buffer)

def comment(fs: str) -> bool:
    global cursor
    if cursor < len(fs) + 1 and fs[cursor] == '/' and fs[cursor + 1] == '/':
        cursor += 2
        while cursor < len(fs) and fs[cursor] != '\n':
            cursor += 1
    return False

def operator(fs: str) -> Token:
    global cursor
    char = fs[cursor]
    if char == '+':
        cursor += 1
        return Token(T_ADD, char)
    elif char == '!':
        cursor += 1
        if fs[cursor] == '=':
            cursor += 1
            return Token(T_NE, '!=')
        return Token(T_NOT, char)
    elif char == '-':
        cursor += 1
        return Token(T_SUB, char)
    elif char == '*':
        cursor += 1
        return Token(T_MUL, char)
    elif char == '/':
        cursor += 1
        return Token(T_DIV, char)
    elif char == '%':
        cursor += 1
        return Token(T_DIV, char)
    elif char == '&':
        cursor += 1
        if fs[cursor] == '&':
            cursor += 1
            return Token(T_AND, '&&')
        return Token(T_ADR, char)
    elif char == '|':
        cursor += 1
        if fs[cursor] == '|':
            cursor += 1
            return Token(T_OR, '||')
        raise SyntaxError("invalid token |")
    elif char == '=':
        cursor += 1
        if fs[cursor] == '=':
            cursor += 1
            return Token(T_EQ, '==')
        return Token(T_ASSIGN, '=')
    elif char == '<':
        cursor += 1
        return Token(T_LT, '<')
    return None
    

def lex(fs: str) -> list[Token]:
    global cursor
    tokens = []
    while cursor < len(fs):
        if comment(fs):
            continue
        token = operator(fs)
        if token:
            tokens.append(token)
            continue
        token = string_literal(fs)
        if token:
            tokens.append(token)
            continue
        token = string_token(fs)
        if token:
            tokens.append(token)
            continue
        token = integer_literal(fs)
        if token:
            tokens.append(token)
            continue
        cursor += 1
    return tokens 

def parse() -> ASTNode:
    return None

def main():
    if len(sys.argv) != 2:
        return
    with open(sys.argv[1], "r") as infile:
        fs = infile.read()
        print(list(map(lambda x: str(x.tokenType) + ":" + x.value, lex(fs))))
        # tree = parse(lex(fs)))

if __name__ == "__main__":
    main()
    