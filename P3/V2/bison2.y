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

// Variables para almacenar identificadores del programa
char* prog_id1;
char* prog_id2;

// Variables para almacenar etiquetas actuales
char currentElseLabel[20];
char currentEndLabel[20];
char* currentLabelStart;
char* currentLabelEnd;

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

%%

/* Regla de inicio */
program:
    PROGRAM ID stmts END PROGRAM ID
    ;

/* Reglas para declaraciones de sentencias */
stmts:
      stmts stmt
    | stmt
    ;

/* Reglas para sentencias individuales */
stmt:
      DO ID ASSIGN exp COMMA NUM stmts END DO
    | DO ID ASSIGN exp COMMA NUM COMMA NUM stmts END DO
    | IF LPAREN exp RPAREN THEN stmts elserep
    | PRINT MULT COMMA exp
    | ID ASSIGN exp
    ;

/* Reglas para las alternativas de 'else' */
elserep:
      ENDIF
    | ELSE stmts ENDIF
    | ELSEIF LPAREN exp RPAREN THEN stmts elserep
    ;

/* Reglas para expresiones aritméticas */
exp:
      exp SUM exp
    | exp RESTA exp
    | multexp
    | ID POW NUM
    ;

/* Reglas para operaciones de multiplicación y división */
multexp:
      multexp MULT multexp
    | multexp DIV multexp
    | value
    ;

/* Reglas para valores básicos */
value:
      NUM
    | ID
    | LPAREN exp RPAREN
    ;

%%



// Función para manejar errores
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

// Función principal
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
