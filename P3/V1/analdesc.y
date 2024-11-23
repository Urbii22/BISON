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
    int intVal;
    char* strVal;
    void* voidVal; // Para no terminales que no retornan valor
}

%token <strVal> ID
%token <intVal> NUM
%token PROGRAM ENDIF END DO IF THEN ELSE ELSEIF PRINT
%token ASSIGN COMMA LPAREN RPAREN PLUS MINUS MULT DIV POW

%type <strVal> exp term factor base opt_step
%type <voidVal> stmts stmt elserep

%start program

%%

program:
    PROGRAM ID stmts END PROGRAM ID
    {
        prog_id1 = $2;
        prog_id2 = $6;
        if (strcasecmp(prog_id1, prog_id2) != 0) {
            fprintf(stderr, "Error: Los identificadores del programa no coinciden.\n");
            exit(1);
        }
    }
    ;

stmts:
    /* Regla vacía */
    { $$ = NULL; }
    |
    stmts stmt
    { $$ = NULL; }
    ;

stmt:
    /* Bucle DO con acciones intermedias */
    DO ID ASSIGN exp COMMA exp opt_step 
    {
        // Inicialización de la variable
        printf("\tvalori %s\n", $2); // ID
        printf("\t%s\n", $4);        // 'mete <exp>'
        printf("\tasigna\n");

        // Generación de etiquetas
        currentLabelStart = newLabel();
        printf("%s:\n", currentLabelStart);
    }
    /* Acción intermedia: procesar el cuerpo del bucle */
    stmts 
    { 
        // Después de procesar el cuerpo del bucle, generar el código de incremento y condición

        // Obtener el valor actual de la variable
        printf("\tvalori %s\n", $2); // ID
        printf("\tvalord %s\n", $2); // ID

        // Paso del bucle
        if ($7 != NULL) {            // opt_step
            printf("\t%s\n", $7);    // Código del paso (ya incluye 'mete')
        } else {
            printf("\tmete 1\n");     // Paso por defecto
        }

        // Sumar el paso al valor actual
        printf("\tsum\n");
        printf("\tasigna\n");

        // Obtener el nuevo valor de la variable
        printf("\tvalord %s\n", $2); // ID

        // Comparar con el límite
        printf("\t%s\n", $6);        // 'mete <límite>'
        printf("\tsub\n");

        // Salto condicional al inicio del bucle si la condición se cumple
        printf("\tsiciertovea %s\n", currentLabelStart);
    }
    END DO 
    { 
        // Definir etiqueta de fin del bucle (no utilizada en este caso)
        printf("%s:\n", newLabel());
        $$ = NULL; // Asignar valor para <voidVal>
    }
    |
    /* Condicional IF con ELSEIF y ELSE */
    IF LPAREN exp RPAREN THEN
    {
        // Generar etiquetas para else y fin
        char* elseLabel = newLabel();
        char* endLabel = newLabel();
        printf("%s\n", $3); // exp
        printf("\tsifalsovea %s\n", elseLabel);
        // Guardar etiquetas en variables globales para usarlas en elserep
        strcpy(currentElseLabel, elseLabel);
        strcpy(currentEndLabel, endLabel);
    }
    stmts
    elserep
    {
        // Imprimir salto hacia el final del bloque condicional
        printf("\tvea %s\n", currentEndLabel);
        // Definir etiquetas de else y fin
        printf("%s:\n", currentElseLabel);
        printf("%s:\n", currentEndLabel);
        $$ = NULL; // Asignar valor para <voidVal>
    }
    |
    /* Sentencia PRINT */
    PRINT MULT COMMA exp
    {
        printf("\t%s\n", $4); // exp
        printf("\tprint\n");
        $$ = NULL; // Asignar valor para <voidVal>
    }
    |
    /* Asignación */
    ID ASSIGN exp
    {
        printf("\tvalori %s\n", $1); // ID
        printf("\t%s\n", $3);        // exp
        printf("\tasigna\n");
        $$ = NULL; // Asignar valor para <voidVal>
    }
    ;

opt_step:
    /* Paso opcional */
    COMMA exp
    {
        $$ = $2; // exp (incluye 'mete <step>')
    }
    |
    /* Regla vacía */
    {
        $$ = NULL;
    }
    ;

elserep:
    /* Manejo de ENDIF o END IF */
    ENDIF
    { $$ = NULL; }
    |
    END IF
    { $$ = NULL; }
    |
    /* Manejo de ELSE */
    ELSE stmts ENDIF
    { $$ = NULL; }
    |
    /* Manejo de ELSEIF */
    ELSEIF LPAREN exp RPAREN THEN
    {
        // Generar una nueva etiqueta para el siguiente ELSEIF
        char* newElseLabel = newLabel();
        printf("%s\n", $3); // exp
        printf("\tsifalsovea %s\n", newElseLabel);
        // Actualizar la etiqueta ELSE, no el endLabel
        strcpy(currentElseLabel, newElseLabel);
        // 'currentEndLabel' permanece apuntando al endLabel original
    }
    stmts
    elserep
    { $$ = NULL; }
    ;

exp:
    term
    |
    exp PLUS term
    {
        char buffer[256];
        sprintf(buffer, "%s\n%s\nsum", $1, $3);
        $$ = strdup(buffer);
    }
    |
    exp MINUS term
    {
        char buffer[256];
        sprintf(buffer, "%s\n%s\nsub", $1, $3);
        $$ = strdup(buffer);
    }
    ;

term:
    factor
    |
    term MULT factor
    {
        char buffer[256];
        sprintf(buffer, "%s\n\t%s\n\tmul", $1, $3);
        $$ = strdup(buffer);
    }
    |
    term DIV factor
    {
        char buffer[256];
        sprintf(buffer, "%s\n\t%s\n\tdiv", $1, $3);
        $$ = strdup(buffer);
    }
    ;

factor:
    base
    |
    base POW NUM
    {
        if ($3 == 2) {
            char buffer[256];
            sprintf(buffer, "%s\n%s\n\tmul", $1, $1);
            $$ = strdup(buffer);
        } else {
            char buffer[256];
            sprintf(buffer, "%s\nmete %d\npow", $1, $3);
            $$ = strdup(buffer);
        }
    }
    ;

base:
    NUM
    {
        char buffer[50];
        sprintf(buffer, "mete %d", $1);
        $$ = strdup(buffer);
    }
    |
    ID
    {
        char buffer[50];
        sprintf(buffer, "\tvalord %s", $1);
        $$ = strdup(buffer);
    }
    |
    LPAREN exp RPAREN
    {
        $$ = $2;
    }
    ;

%%

#include <ctype.h>

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
