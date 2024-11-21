%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Declaraciones para Flex
extern int yylex();
extern int yyparse();
extern FILE *yyin;

// Contador para etiquetas únicas
int labelCount = 0;

// Función para generar nuevas etiquetas
char* newLabel() {
    char* label = malloc(20);
    if (!label) {
        fprintf(stderr, "Error de memoria al generar etiquetas.\n");
        exit(1);
    }
    sprintf(label, "LBL%d", labelCount++);
    return label;
}

// Prototipos de funciones
void yyerror(const char *s);
%}

%union {
    int num;
    char* id;
}

%token <id> ID
%token <num> NUM
%token PROGRAM END DO IF THEN ELSE ENDIF ELSEIF PRINT 
%token ASSIGN MULT DIV POW SUM RESTA LPAREN RPAREN COMMA

/* Definición de operadores y precedencia */
%left SUM RESTA
%left MULT DIV
%right POW
%nonassoc ELSE

/* No definimos %type para los no terminales que no necesitan devolver valores */

%%
/* Regla de inicio */
program:
    PROGRAM ID stmts END PROGRAM ID
    {
        // Verificar que los IDs de inicio y fin coincidan
        if (strcmp($2, $6) != 0) {
            fprintf(stderr, "Error: El identificador del programa al inicio y al final no coinciden.\n");
            exit(1);
        }
    }
    ;

/* Reglas para declaraciones de sentencias */
stmts:
      stmts stmt
    | stmt
    ;

/* Reglas para sentencias individuales */
stmt:
      asigna_stmt
    | do_stmt
    | if_stmt
    | print_stmt
    ;

/* Sentencia de asignación */
asigna_stmt:
    ID ASSIGN exp
    {
        printf("\tvalori %s\n", $1);
        printf("%s\n", $3);
        printf("\tasigna\n");
    }
    ;

/* Sentencia de impresión */
print_stmt:
    PRINT MULT COMMA exp
    {
        printf("%s\n\tprint\n", $4);
    }
    ;

/* Sentencia IF */
if_stmt:
    IF LPAREN exp RPAREN THEN stmts elserep
    {
        char* falseLabel = newLabel();
        char* endLabel = newLabel();
        printf("%s\n\tsifalsovea %s\n", $3, falseLabel);
        printf("\tvea %s\n", endLabel);
        printf("%s:\n", falseLabel);
        // 'elserep' ya maneja las etiquetas adicionales
        printf("\tvea %s\n", endLabel);
    }
    ;

/* Alternativas de ELSE */
elserep:
      ENDIF
    | ELSE stmts ENDIF
    | ELSEIF LPAREN exp RPAREN THEN stmts elserep
    ;

/* Sentencia DO */
do_stmt:
    /* Forma con un incremento implícito de 1 */
    DO ID ASSIGN exp COMMA NUM
    {
        /* Generación de etiquetas */
        char* startLabel = newLabel();
        char* endLabel = newLabel();

        /* Asignación inicial */
        printf("\tvalori %s\n", $2);
        printf("\tmete %d\n", $4); // Asignar el valor inicial
        printf("\tasigna\n");
        printf("%s:\n", startLabel);

        /* Guardar etiquetas en variables locales */
        $$ = 0; // No necesitamos un valor
    }
    stmts 
    {
        /* Incremento por defecto (1) */
        printf("\tvalori %s\n", $2);
        printf("\tvalord %s\n", $2);
        printf("\tmete 1\n\tsum\n\tasigna\n");
        printf("\tvalord %s\n\tmete %d\n\tsub\n\tsiciertovea %s\n", $2, $5, "LBL0"); // Ajusta "LBL0" con la etiqueta real
    }
    END DO
    /* Forma con incremento explícito */
    | DO ID ASSIGN exp COMMA NUM COMMA NUM
    {
        /* Generación de etiquetas */
        char* startLabel = newLabel();
        char* endLabel = newLabel();

        /* Asignación inicial */
        printf("\tvalori %s\n", $2);
        printf("\tmete %d\n", $4); // Asignar el valor inicial
        printf("\tasigna\n");
        printf("%s:\n", startLabel);

        /* Guardar etiquetas en variables locales */
        $$ = 0; // No necesitamos un valor
    }
    stmts 
    {
        /* Incremento personalizado */
        printf("\tvalori %s\n", $2);
        printf("\tvalord %s\n", $2);
        printf("\tmete %d\n\tsum\n\tasigna\n", $6);
        printf("\tvalord %s\n\tmete %d\n\tsub\n\tsiciertovea %s\n", $2, $5, "LBL1"); // Ajusta "LBL1" con la etiqueta real
    }
    END DO
    ;
    
/* Reglas para expresiones aritméticas */
exp:
      exp SUM multexp
    {
        printf("%s\n%s\n\tsum\n", $1, $3);
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    | exp RESTA multexp
    {
        printf("%s\n%s\n\tsub\n", $1, $3);
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    | multexp
    {
        /* Pasar el valor de multexp */
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    | ID POW NUM
    {
        if ($3 == 2) {
            printf("\tvalord %s\n\tvalord %s\n\tmult\n", $1, $1);
        } else {
            printf("\tvalord %s\n\tmete %d\n\tpow\n", $1, $3);
        }
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    ;

/* Reglas para operaciones de multiplicación y división */
multexp:
      multexp MULT value
    {
        printf("%s\n%s\n\tmul\n", $1, $3);
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    | multexp DIV value
    {
        printf("%s\n%s\n\tdiv\n", $1, $3);
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    | value
    {
        /* Pasar el valor de value */
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    ;

/* Reglas para valores básicos */
value:
      NUM
    {
        printf("\tmete %d\n", $1);
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    | ID
    {
        printf("\tvalord %s\n", $1);
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    | LPAREN exp RPAREN
    {
        /* No necesitamos devolver un valor, así que no asignamos $$ */
    }
    ;

%%

/* Función para manejar errores */
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

/* Función principal */
int main(int argc, char** argv) {
    if(argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if(!file) {
            perror(argv[1]);
            return 1;
        }
        yyin = file;
    }
    yyparse();
    return 0;
}
