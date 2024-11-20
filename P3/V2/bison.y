%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Declaración de yyin */
extern FILE *yyin;

/* Declaración de yylex */
int yylex(void);
void yyerror(const char *s);

/* Generador de etiquetas */
int labelCount = 0;
char* newLabel() {
    char *label = malloc(10);
    if (!label) {
        fprintf(stderr, "Error de memoria al generar una nueva etiqueta.\n");
        exit(1);
    }
    sprintf(label, "LBL%d", labelCount++);
    return label;
}

/* Variables globales para etiquetas en bucles y condicionales */
char *current_labelStart;
char *current_labelEnd;

/* Variables para manejar datos del bucle */
char *do_ID;
int do_step;
%}

%union {
    int num;
    char *id;
    char *code;
}

%token <id> PROGRAM ENDIF END DO IF THEN ELSE ELSEIF PRINT
%token ASSIGN COMMA LPAREN RPAREN PLUS MINUS MULT DIV POW
%token <num> NUM
%token <id> ID

%type <code> program stmts stmt do_stmt if_stmt elserep print_stmt assign_stmt exp term factor base
%type <num> optional_step

%%

program:
    PROGRAM ID stmts END PROGRAM ID
    {
        if (strcasecmp($2, $6) != 0) {
            fprintf(stderr, "Error: Los identificadores del programa no coinciden.\n");
            exit(1);
        }
        $$ = strdup("");
    }
    ;

stmts:
    /* vacío */
    { 
        $$ = strdup(""); 
    }
    | stmts stmt 
    { 
        /* Las acciones de los statements ya manejan la impresión */
        free($1); 
        $$ = strdup(""); 
    }
    ;

stmt:
    do_stmt
    | if_stmt
    | print_stmt
    | assign_stmt
    ;

do_stmt:
    DO ID ASSIGN exp COMMA NUM optional_step stmts END DO
    {
        /* Asignar variables */
        do_ID = $2;
        int limit = $6;
        do_step = $7;

        /* Inicialización del bucle */
        printf("\tvalori %s\n", do_ID);
        printf("\t%s\n", $4); // Código de la expresión inicial
        printf("\tasigna\n");

        /* Generación de etiquetas */
        current_labelStart = newLabel();
        current_labelEnd = newLabel();

        /* Imprimir etiqueta de inicio del bucle */
        printf("%s\n", current_labelStart);

        /* Las sentencias ya han sido procesadas y sus acciones han sido ejecutadas */

        /* Incremento de la variable de control */
        printf("\tvalori %s\n", do_ID);
        printf("\tvalord %s\n", do_ID);
        if (do_step != 0) {
            printf("\tmete %d\n", do_step);
        } else {
            printf("\tmete 1\n");
        }
        printf("\tsum\n");
        printf("\tasigna\n");

        /* Comparación con el límite */
        printf("\tvalord %s\n", do_ID);
        printf("\tmete %d\n", limit);
        printf("\tsub\n");

        /* Salto condicional */
        printf("\tsiciertovea %s\n", current_labelStart);

        /* Imprimir etiqueta de fin del bucle */
        printf("%s\n", current_labelEnd);

        /* Asignar a $$ */
        $$ = strdup("");
    }
    ;

optional_step:
    /* vacío */ 
    { 
        $$ = 0; 
    }
    | COMMA NUM 
    { 
        $$ = $2; 
    }
    ;

if_stmt:
    IF LPAREN exp RPAREN THEN stmts elserep
    {
        /* Generación de etiquetas */
        current_labelStart = newLabel();
        current_labelEnd = newLabel();
        
        /* Imprimir código de la condición */
        printf("%s\n", $3); /* Código de la expresión */
        printf("\tsifalsovea %s\n", current_labelStart);
        
        /* Saltar al fin del condicional */
        printf("\tvea %s\n", current_labelEnd);
        
        /* Imprimir etiqueta else */
        printf("%s\n", current_labelStart);
        
        /* Etiqueta de fin */
        printf("%s\n", current_labelEnd);
        
        /* Asignar a $$ */
        $$ = strdup("");
    }
    ;

elserep:
    ENDIF
    { 
        /* No hay else, nada que hacer */
        $$ = strdup("");
    }
    |
    ELSE stmts ENDIF
    { 
        /* Else: las acciones de los stmts ya manejan la impresión */
        $$ = strdup("");
    }
    |
    ELSEIF LPAREN exp RPAREN THEN stmts elserep
    {
        char *newElseLabel = newLabel();
        
        /* Imprimir condición de elseif */
        printf("%s\n", $3); /* Código de la expresión */
        printf("\tsifalsovea %s\n", newElseLabel);
        
        /* Saltar al fin del condicional */
        printf("\tvea %s\n", current_labelEnd);
        
        /* Imprimir nueva etiqueta else */
        printf("%s\n", newElseLabel);
        
        /* Actualizar etiqueta else actual */
        current_labelStart = newElseLabel;
        
        /* Asignar a $$ */
        $$ = strdup("");
    }
    ;

print_stmt:
    PRINT MULT COMMA exp
    {
        printf("\t%s\n", $4); /* Código de la expresión */
        printf("\tprint\n");
        $$ = strdup("");
    }
    ;

assign_stmt:
    ID ASSIGN exp
    {
        printf("\tvalori %s\n", $1);
        printf("\t%s\n", $3); /* Código de la expresión */
        printf("\tasigna\n");
        $$ = strdup("");
    }
    ;

exp:
    exp PLUS term
    {
        /* Generar código para la suma */
        printf("%s\n%s\nsum\n", $1, $3);
        /* No se necesita retornar código */
        $$ = strdup("");
    }
    |
    exp MINUS term
    {
        /* Generar código para la resta */
        printf("%s\n%s\nsub\n", $1, $3);
        /* No se necesita retornar código */
        $$ = strdup("");
    }
    |
    term
    { 
        /* El código ya fue generado en term */
        $$ = strdup("");
    }
    ;

term:
    term MULT factor
    {
        /* Generar código para la multiplicación */
        printf("%s\n%s\nmul\n", $1, $3);
        /* No se necesita retornar código */
        $$ = strdup("");
    }
    |
    term DIV factor
    {
        /* Generar código para la división */
        printf("%s\n%s\ndiv\n", $1, $3);
        /* No se necesita retornar código */
        $$ = strdup("");
    }
    |
    factor
    { 
        /* El código ya fue generado en factor */
        $$ = strdup("");
    }
    ;

factor:
    base POW NUM
    {
        if ($3 == 2) {
            /* Optimización para elevar al cuadrado */
            printf("%s\n%s\n\tmul\n", $1, $1);
        }
        else {
            /* General para potencias diferentes de 2 */
            printf("%s\nmete %d\npow\n", $1, $3);
        }
        /* No se necesita retornar código */
        $$ = strdup("");
    }
    |
    base
    { 
        /* El código ya fue generado en base */
        $$ = strdup("");
    }
    ;

base:
    NUM
    {
        printf("mete %d\n", $1);
        $$ = strdup("");
    }
    |
    ID
    {
        printf("\tvalord %s\n", $1);
        $$ = strdup("");
    }
    |
    LPAREN exp RPAREN
    { 
        /* El código ya fue generado en exp */
        $$ = strdup("");
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror("fopen");
            return 1;
        }
        yyin = file;
    }
    yyparse();
    return 0;
}
