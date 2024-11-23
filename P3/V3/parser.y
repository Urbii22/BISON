%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Definición de yylex
int yylex(void);
void yyerror(const char *s);

// Contador de etiquetas
int labelCount = 0;

// Definición de YYSTYPE
typedef struct {
    int num;
    char* id;
    char* code;
} YYSTYPE;

#define YYSTYPE YYSTYPE
%}

%union {
    int num;
    char* id;
    char* code;
}

%token PROGRAM END DO IF ELSE ELSEIF THEN ENDIF PRINT
%token NUM ID
%token MUL DIV PLUS MINUS POWER
%token EQ COMMA LPAREN RPAREN

%left PLUS MINUS
%left MUL DIV
%right POWER
%nonassoc LOWER_THAN_ELSE

%start program

%%

program:
    PROGRAM ID stmts END PROGRAM ID
    {
        // Verificar que los nombres de programa coincidan
        if (strcmp($2, $6) != 0) {
            fprintf(stderr, "Error: El nombre del programa al inicio y al final no coinciden.\n");
            exit(1);
        }
    }
    ;

stmts:
    stmts stmt
    | stmt
    ;

stmt:
    do_stmt
    | if_stmt
    | print_stmt
    | asigna_stmt
    ;

do_stmt:
    DO ID EQ expr COMMA NUM opt_step stmts END DO
    {
        // Asignación inicial de la variable de control
        printf("\tvalori %s\n", $2);
        printf("%s\n", $4);
        printf("\tasigna\n");

        // Etiqueta para el inicio del bucle
        char startLabel[20];
        sprintf(startLabel, "LBL%d", labelCount++);
        printf("%s\n", startLabel);

        // Cuerpo del bucle
        // Ya impreso a través de 'stmts'

        // Incremento de la variable de control
        printf("\tvalord %s\n", $2);
        if ($6.hasStep) {
            printf("\tmete %d\n", $6.step);
        } else {
            printf("\tmete 1\n");
        }
        printf("\tsum\n");
        printf("\tasigna\n");

        // Evaluación de la condición del bucle
        printf("\tvalord %s\n", $2);
        printf("\tmete %d\n", $5);
        printf("\tsub\n");

        // Salto condicional
        char endLabel[20];
        sprintf(endLabel, "LBL%d", labelCount++);
        printf("\tsiciertovea %s\n", endLabel);

        // Salto al inicio del bucle
        printf("\tvea %s\n", startLabel);

        // Etiqueta de fin del bucle
        printf("%s\n", endLabel);
    }
    ;

opt_step:
    COMMA NUM
    {
        $$ .hasStep = 1;
        $$ .step = $2;
    }
    |
    /* vacío */
    {
        $$ .hasStep = 0;
        $$ .step = 0;
    }
    ;

if_stmt:
    IF LPAREN expr RPAREN THEN stmts elserep ENDIF
    ;

elserep:
    ELSE stmts
    | ELSEIF LPAREN expr RPAREN THEN stmts elserep
    |
    /* vacío */
    ;

print_stmt:
    PRINT MUL COMMA expr
    {
        printf("%s\n", $4);
        printf("\tprint\n");
    }
    ;

asigna_stmt:
    ID EQ expr
    {
        printf("\tvalori %s\n", $1);
        printf("%s\n", $3);
        printf("\tasigna\n");
    }
    ;

expr:
    expr PLUS term
    {
        $$ = malloc(strlen($1) + strlen($3) + 10);
        sprintf($$, "%s\n%s\n\t%s", $1, $3, "sum");
    }
    | expr MINUS term
    {
        $$ = malloc(strlen($1) + strlen($3) + 10);
        sprintf($$, "%s\n%s\n\t%s", $1, $3, "sub");
    }
    | term
    {
        $$ = $1;
    }
    ;

term:
    term MUL factor
    {
        $$ = malloc(strlen($1) + strlen($3) + 10);
        sprintf($$, "%s\n%s\n\t%s", $1, $3, "mul");
    }
    | term DIV factor
    {
        $$ = malloc(strlen($1) + strlen($3) + 10);
        sprintf($$, "%s\n%s\n\t%s", $1, $3, "div");
    }
    | factor
    {
        $$ = $1;
    }
    ;

factor:
    ID POWER NUM
    {
        if ($3 == 2) {
            // Potencia de 2
            $$ = malloc(strlen($1)*2 + 20);
            sprintf($$, "\tvalord %s\n\tvalord %s\n\tmult", $1, $1);
        }
        else {
            // Potencia general
            $$ = malloc(strlen($1) + 20);
            sprintf($$, "\tvalord %s\n\tmete %d\n\tpow", $1, $3);
        }
    }
    | ID
    {
        char* code = malloc(strlen($1) + 20);
        sprintf(code, "\tvalord %s", $1);
        $$ = code;
    }
    | NUM
    {
        char* code = malloc(50);
        sprintf(code, "\tmete %d", $1);
        $$ = code;
    }
    | LPAREN expr RPAREN
    {
        $$ = $2;
    }
    ;

%%

#include "lex.yy.c"

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
    exit(1);
}

int main(int argc, char** argv) {
    if (argc > 1) {
        FILE* file = fopen(argv[1], "r");
        if (!file) {
            perror("No se pudo abrir el archivo");
            return 1;
        }
        yyin = file;
    }
    yyparse();
    return 0;
}
