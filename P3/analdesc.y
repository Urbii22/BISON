/* docuemnto de analisis sintactico */
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
}

%token PROGRAM ENDIF END DO IF THEN ELSE ELSEIF PRINT ASSIGN COMMA LPAREN RPAREN
%token PLUS MINUS MULT DIV POW NUM ID

%type <strVal> ID
%type <intVal> NUM
%type <exprVal> exp term factor base

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
    DO ID ASSIGN exp COMMA exp opt_step {
        char *initExp = $4.code;
        char *limitExp = $6.code;
        char *stepExp = $7;
        char *id = $2;
        char *labelStart = newLabel();
        char *labelEnd = newLabel();
        printf("\tvalori %s\n", id);
        printf("%s\n", initExp);
        printf("\tasigna\n");
        printf("%s:\n", labelStart);
    }
    stmts END DO {
        // Incremento y comparación
        char *id = $2;
        printf("\tvalori %s\n", id);
        printf("\tvalord %s\n", id);
        if ($7 != NULL) {
            printf("%s\n", $7);
        } else {
            printf("\tmete 1\n");
        }
        printf("\tsum\n");
        printf("\tasigna\n");
        printf("\tvalord %s\n", id);
        printf("%s\n", $6.code);
        printf("\tsub\n");
        printf("\tsiciertovea %s\n", labelStart);
        printf("%s:\n", labelEnd);
    }
    |
    IF LPAREN exp RPAREN THEN {
        char *elseLabel = newLabel();
        char *endLabel = newLabel();
        printf("%s\n", $3.code);
        printf("\tsifalsovea %s\n", elseLabel);
        $$ = strdup(elseLabel);
        yyerrok;
    }
    stmts elserep {
        printf("%s:\n", $$.strVal); // elseLabel
        printf("%s:\n", $3.strVal); // endLabel
    }
    |
    PRINT MULT COMMA exp {
        printf("%s\n", $4.code);
        printf("\tprint\n");
    }
    |
    ID ASSIGN exp {
        printf("\tvalori %s\n", $1);
        printf("%s\n", $3.code);
        printf("\tasigna\n");
    }
    ;

opt_step:
    /* vacío */ { $$ = NULL; }
    |
    COMMA exp { $$ = $2.code; }
    ;

elserep:
    ENDIF { /* Nada que hacer */ }
    |
    ELSE stmts ENDIF { /* stmts ya procesados */ }
    |
    ELSEIF LPAREN exp RPAREN THEN {
        char *newElseLabel = newLabel();
        printf("%s\n", $3.code);
        printf("\tsifalsovea %s\n", newElseLabel);
    }
    stmts elserep {
        printf("\tvea %s\n", $$.strVal); // endLabel
        printf("%s:\n", $3.strVal); // newElseLabel
    }
    ;

exp:
    term {
        $$ = $1;
    }
    |
    exp PLUS term {
        char *code = malloc(strlen($1.code) + strlen($3.code) + 10);
        sprintf(code, "%s\n%s\n\tsum", $1.code, $3.code);
        $$ = (struct { char *code; }){code};
    }
    |
    exp MINUS term {
        char *code = malloc(strlen($1.code) + strlen($3.code) + 10);
        sprintf(code, "%s\n%s\n\tsub", $1.code, $3.code);
        $$ = (struct { char *code; }){code};
    }
    ;

term:
    factor {
        $$ = $1;
    }
    |
    term MULT factor {
        char *code = malloc(strlen($1.code) + strlen($3.code) + 10);
        sprintf(code, "%s\n%s\n\tmul", $1.code, $3.code);
        $$ = (struct { char *code; }){code};
    }
    |
    term DIV factor {
        char *code = malloc(strlen($1.code) + strlen($3.code) + 10);
        sprintf(code, "%s\n%s\n\tdiv", $1.code, $3.code);
        $$ = (struct { char *code; }){code};
    }
    ;

factor:
    base {
        $$ = $1;
    }
    |
    factor POW NUM {
        if ($3 == 2) {
            char *code = malloc(strlen($1.code) * 2 + 10);
            sprintf(code, "%s\n%s\n\tmul", $1.code, $1.code);
            $$ = (struct { char *code; }){code};
        } else {
            char *code = malloc(strlen($1.code) + 20);
            sprintf(code, "%s\n\tmete %d\n\tpow", $1.code, $3);
            $$ = (struct { char *code; }){code};
        }
    }
    ;

base:
    NUM {
        char *code = malloc(20);
        sprintf(code, "\tmete %d", $1);
        $$ = (struct { char *code; }){code};
    }
    |
    ID {
        char *code = malloc(strlen($1) + 20);
        sprintf(code, "\tvalord %s", $1);
        $$ = (struct { char *code; }){code};
    }
    |
    LPAREN exp RPAREN {
        $$ = $2;
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
