%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(const char *s);

int labelCount = 0;
char *endLabel; // Variable global para la etiqueta final

%}

%union {
    int intval;
    char *strval;
    char *code;
}

%token <strval> ID
%token <intval> NUM

%token PROGRAM END DO IF ELSE ELSEIF THEN ENDIF PRINT MUL PLUS MINUS DIV POWER EQ COMMA LPAREN RPAREN

%left PLUS MINUS
%left MUL DIV
%right POWER

%type <code> program stmts stmt elserep exp multexp value

%%

program:
    PROGRAM ID stmts END PROGRAM ID
        {
            printf("%s\n", $3);
        }
    ;

stmts:
    stmt stmts
        {
            asprintf(&$$, "%s\n%s", $1, $2);
        }
    |
    stmt
        {
            $$ = $1;
        }
    ;

stmt:
    IF LPAREN exp RPAREN THEN stmts elserep
        {
            // Generar etiquetas en el orden deseado
            asprintf(&endLabel, "LBL%d", labelCount++);
            char *falseLabel;
            asprintf(&falseLabel, "LBL%d", labelCount++);

            asprintf(&$$, "%s\n\tsifalsovea %s\n%s\n\tvea %s\n%s:\n%s\n%s:",
                $3, falseLabel, $6, endLabel, falseLabel, $7, endLabel);
        }
    |
    DO ID EQ exp COMMA NUM stmts END DO
        {
            char *startLabel;
            asprintf(&startLabel, "LBL%d", labelCount++);

            char *initCode;
            asprintf(&initCode, "\tvalori %s\n%s\n\tasigna", $2, $4);

            char *conditionCode;
            asprintf(&conditionCode, "\tvalord %s\n\tmete %d\n\tsub\n\tsiciertovea %s", $2, $6, startLabel);

            char *incrementCode;
            asprintf(&incrementCode, "\tvalori %s\n\tvalord %s\n\tmete 1\n\tsum\n\tasigna", $2, $2);

            asprintf(&$$, "%s\n%s:\n%s\n%s\n%s", initCode, startLabel, $7, incrementCode, conditionCode);
        }
    |
    DO ID EQ exp COMMA NUM COMMA NUM stmts END DO
        {
            char *startLabel;
            asprintf(&startLabel, "LBL%d", labelCount++);

            char *initCode;
            asprintf(&initCode, "\tvalori %s\n%s\n\tasigna", $2, $4);

            char *conditionCode;
            asprintf(&conditionCode, "\tvalord %s\n\tmete %d\n\tsub\n\tsiciertovea %s", $2, $6, startLabel);

            char *incrementCode;
            asprintf(&incrementCode, "\tvalori %s\n\tvalord %s\n\tmete %d\n\tsum\n\tasigna", $2, $2, $8);

            asprintf(&$$, "%s\n%s:\n%s\n%s\n%s", initCode, startLabel, $9, incrementCode, conditionCode);
        }
    |
    PRINT MUL COMMA exp
        {
            asprintf(&$$, "%s\n\tprint", $4);
        }
    |
    ID EQ exp
        {
            asprintf(&$$, "\tvalori %s\n%s\n\tasigna", $1, $3);
        }
    ;

elserep:
    ENDIF
        {
            $$ = strdup("");
        }
    |
    ELSE stmts ENDIF
        {
            $$ = $2;
        }
    |
    ELSEIF LPAREN exp RPAREN THEN stmts elserep
        {
            char *falseLabel;
            asprintf(&falseLabel, "LBL%d", labelCount++);
            asprintf(&endLabel, "LBL%d", labelCount);
            // Construir el código para el elseif
            asprintf(&$$, "%s\n\tsifalsovea %s\n%s\n\tvea %s\n%s:\n%s",
                $3, falseLabel, $6, endLabel, falseLabel, $7);
        }
    ;

exp:
    multexp PLUS exp
        {
            asprintf(&$$, "%s\n%s\n\tsum", $1, $3);
        }
    |
    multexp MINUS exp
        {
            asprintf(&$$, "%s\n%s\n\tsub", $1, $3);
        }
    |
    multexp
        {
            $$ = $1;
        }
    |
    ID POWER NUM
        {
            if ($3 == 2)
            {
                asprintf(&$$, "\tvalord %s\n\tvalord %s\n\tmul", $1, $1);
            }
            else
            {
                asprintf(&$$, "\tvalord %s\n\tmete %d\n\tpow", $1, $3);
            }
        }
    ;

multexp:
    value MUL multexp
        {
            asprintf(&$$, "%s\n%s\n\tmul", $1, $3);
        }
    |
    value DIV multexp
        {
            asprintf(&$$, "%s\n%s\n\tdiv", $1, $3);
        }
    |
    value
        {
            $$ = $1;
        }
    ;

value:
    NUM
        {
            asprintf(&$$, "\tmete %d", $1);
        }
    |
    ID
        {
            asprintf(&$$, "\tvalord %s", $1);
        }
    |
    LPAREN exp RPAREN
        {
            $$ = $2;
        }
    ;

%%

void yyerror(const char *s)
{
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char **argv)
{
    labelCount = 0; // Reiniciar labelCount
    if (argc > 1)
    {
        extern FILE *yyin;
        yyin = fopen(argv[1], "r");
        if (!yyin)
        {
            perror(argv[1]);
            return 1;
        }
    }
    yyparse();
    return 0;
}
