%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(const char *s);

int labelCount = 0;
char *newLabel() {
    char *label = malloc(20);
    sprintf(label, "LBL%d", labelCount++);
    return label;
}
%}

%union {
    int intVal;
    char *strVal;
    struct {
        char *code;
    } exprVal;
    struct {
        char *elseLabel;
        char *endLabel;
    } ifLabels;
}

%token PROGRAM ENDIF END DO IF THEN ELSE ELSEIF PRINT ASSIGN COMMA LPAREN RPAREN
%token PLUS MINUS MULT DIV POW
%token <intVal> NUM
%token <strVal> ID

%type <ifLabels> if_stmt_start elseif_stmt elserep
%type <exprVal> exp term factor base
%type <strVal> opt_step

%%

program:
    PROGRAM ID stmts END PROGRAM ID {
        if (strcasecmp($2, $6) != 0) {
            fprintf(stderr, "Error: Los identificadores del programa no coinciden.\n");
            exit(1);
        }
    }
    ;

stmts:
    /* vacío */
|
    stmts stmt
    ;

stmt:
    DO ID ASSIGN exp COMMA exp opt_step stmts END DO {
        char *initExp = $4.exprVal.code;
        char *limitExp = $6.exprVal.code;
        char *stepExp = $<strVal>7; // Especificamos el tipo de $7
        char *id = $2;
        char *labelStart = newLabel();
        char *labelEnd = newLabel();

        // Inicialización de la variable de control
        printf("\tvalori %s\n", id);
        printf("%s\n", initExp);
        printf("\tasigna\n");

        // Etiqueta de inicio del bucle
        printf("%s:\n", labelStart);

        // Código del bloque 'stmts' ya generado

        // Incremento de la variable de control
        printf("\tvalori %s\n", id);
        printf("\tvalord %s\n", id);
        if (stepExp != NULL) {
            printf("%s\n", stepExp);
        } else {
            printf("\tmete 1\n");
        }
        printf("\tsum\n");
        printf("\tasigna\n");

        // Comparación de la variable de control con el límite
        printf("\tvalord %s\n", id);
        printf("%s\n", limitExp);
        printf("\tsub\n"); // Calculamos x - limit

        // Si x <= limit, continuamos el bucle
        printf("\tsiciertovea %s\n", labelStart);

        // Etiqueta de fin del bucle
        printf("%s:\n", labelEnd);
    }
|
    if_stmt_start stmts elserep {
        printf("\tvea %s\n", $1.endLabel); // endLabel
        printf("%s:\n", $1.elseLabel);     // elseLabel
        // Código de 'elserep' ya generado
        printf("%s:\n", $1.endLabel);      // endLabel
    }
|
    PRINT MULT COMMA exp {
        printf("%s\n", $4.exprVal.code);
        printf("\tprint\n");
    }
|
    ID ASSIGN exp {
        printf("\tvalori %s\n", $1);
        printf("%s\n", $3.exprVal.code);
        printf("\tasigna\n");
    }
    ;

opt_step:
    /* vacío */ { $$ = NULL; }
|
    COMMA exp {
        $$ = $2.exprVal.code;
    }
    ;

if_stmt_start:
    IF LPAREN exp RPAREN THEN {
        $$.elseLabel = newLabel();
        $$.endLabel = newLabel();
        printf("%s\n", $3.exprVal.code);
        printf("\tsifalsovea %s\n", $$.elseLabel);
    }
    ;

elserep:
    ENDIF { /* Nada que hacer */ }
|
    ELSE stmts ENDIF { /* Código de 'stmts' ya generado */ }
|
    elseif_stmt stmts elserep {
        printf("\tvea %s\n", $1.endLabel);      // endLabel
        printf("%s:\n", $1.elseLabel);          // newElseLabel
        // Código de 'stmts' y 'elserep' ya generado
    }
    ;

elseif_stmt:
    ELSEIF LPAREN exp RPAREN THEN {
        $$.elseLabel = newLabel();
        $$.endLabel = newLabel(); // Generamos un nuevo endLabel
        printf("%s\n", $3.exprVal.code);
        printf("\tsifalsovea %s\n", $$.elseLabel);
    }
    ;

exp:
    exp PLUS term {
        char *code = malloc(strlen($1.exprVal.code) + strlen($3.exprVal.code) + 10);
        sprintf(code, "%s\n%s\n\tsum", $1.exprVal.code, $3.exprVal.code);
        $$.exprVal.code = code;
    }
|
    exp MINUS term {
        char *code = malloc(strlen($1.exprVal.code) + strlen($3.exprVal.code) + 10);
        sprintf(code, "%s\n%s\n\tsub", $1.exprVal.code, $3.exprVal.code);
        $$.exprVal.code = code;
    }
|
    term {
        $$.exprVal.code = $1.exprVal.code;
    }
    ;

term:
    term MULT factor {
        char *code = malloc(strlen($1.exprVal.code) + strlen($3.exprVal.code) + 10);
        sprintf(code, "%s\n%s\n\tmul", $1.exprVal.code, $3.exprVal.code);
        $$.exprVal.code = code;
    }
|
    term DIV factor {
        char *code = malloc(strlen($1.exprVal.code) + strlen($3.exprVal.code) + 10);
        sprintf(code, "%s\n%s\n\tdiv", $1.exprVal.code, $3.exprVal.code);
        $$.exprVal.code = code;
    }
|
    factor {
        $$.exprVal.code = $1.exprVal.code;
    }
    ;

factor:
    base POW NUM {
        if ($3 == 2) {
            char *code = malloc(strlen($1.exprVal.code) * 2 + 10);
            sprintf(code, "%s\n%s\n\tmul", $1.exprVal.code, $1.exprVal.code);
            $$.exprVal.code = code;
        } else {
            char *code = malloc(strlen($1.exprVal.code) + 20);
            sprintf(code, "%s\n\tmete %d\n\tpow", $1.exprVal.code, $3);
            $$.exprVal.code = code;
        }
    }
|
    base {
        $$.exprVal.code = $1.exprVal.code;
    }
    ;

base:
    NUM {
        char *code = malloc(20);
        sprintf(code, "\tmete %d", $1);
        $$.exprVal.code = code;
    }
|
    ID {
        char *code = malloc(strlen($1) + 20);
        sprintf(code, "\tvalord %s", $1);
        $$.exprVal.code = code;
    }
|
    LPAREN exp RPAREN {
        $$.exprVal.code = $2.exprVal.code;
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error de sintaxis: %s\n", s);
    exit(1);
}

int main() {
    yyparse();
    return 0;
}
