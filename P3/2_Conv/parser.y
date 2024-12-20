%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

int labelCount = 0;
char *forVarName = NULL;
%}

%union {
    int intval;
    char *strval;
    char *code;
    char *varsave; // Para guardar el estado anterior del forVarName
}

%token <intval> NUM
%token <strval> ID
%token IF THEN ELSE FI DO WHILE FOR TO PRINT OD
%token ASSIGN PLUS MINUS MUL DIV LPAREN RPAREN

%type <code> liststmt stmt assig struc arithexp multexp val
%type <varsave> forsave

%left PLUS MINUS
%left MUL DIV

%%
program:
    /* vacío */
  | liststmt { printf("%s\n", $1); }
  ;

liststmt:
    stmt { $$ = $1; }
  | stmt liststmt { asprintf(&$$, "%s\n%s", $1, $2); }
  ;

stmt:
    assig { $$ = $1; }
  | struc { $$ = $1; }
  ;

assig:
    ID ASSIGN arithexp {
        asprintf(&$$,
"\tvalori %s\n"
"%s\n"
"\tasigna",
$1, $3);
        if (forVarName) free(forVarName);
        forVarName = strdup($1);
    }
  ;

struc:
    /* IF sin ELSE */
    IF arithexp THEN liststmt FI {
        char *lblEnd;
        asprintf(&lblEnd, "LBL%d", labelCount++);
        asprintf(&$$,
"%s\n"
"\tsifalsovea %s\n"
"%s\n"
"%s:",
$2, lblEnd, $4, lblEnd);
    }
  | IF arithexp THEN liststmt ELSE liststmt FI {
        char *lblFalse, *lblEnd;
        asprintf(&lblFalse, "LBL%d", labelCount++);
        asprintf(&lblEnd,   "LBL%d", labelCount++);
        asprintf(&$$,
"%s\n"
"\tsifalsovea %s\n"
"%s\n"
"\tvea %s\n"
"%s:\n"
"%s\n"
"%s:",
$2, lblFalse, $4, lblEnd, lblFalse, $6, lblEnd);
    }
  | DO liststmt WHILE arithexp {
        char *lblStart, *lblEnd;
        asprintf(&lblStart, "LBL%d", labelCount++);
        asprintf(&lblEnd,   "LBL%d", labelCount++);
        asprintf(&$$,
"%s:\n"
"%s\n"
"%s\n"
"\tsifalsovea %s\n"
"\tvea %s\n"
"%s:",
lblStart, $2, $4, lblEnd, lblStart, lblEnd);
    }
  /* Aquí introducimos forsave para guardar la variable anterior del FOR */
  | FOR forsave assig TO NUM DO liststmt OD {
        char *oldVar = $2; // Valor guardado por forsave
        char *loopVar = strdup(forVarName);

        char *lblStart, *lblEnd;
        asprintf(&lblStart, "LBL%d", labelCount++);
        asprintf(&lblEnd,   "LBL%d", labelCount++);

        asprintf(&$$,
"%s\n"
"%s:\n"
"\tvalord %s\n"
"\tmete %d\n"
"\tsub\n"
"\tsifalsovea %s\n"
"%s\n"
"\tvalori %s\n"
"\tvalord %s\n"
"\tmete 1\n"
"\tsum\n"
"\tasigna\n"
"\tvea %s\n"
"%s:",
$3,           // Asignación inicial del FOR
lblStart,
loopVar, $5, lblEnd,
$7,
loopVar, loopVar,
lblStart,
lblEnd);

        // Restaurar la variable anterior del FOR externo
        if (forVarName) free(forVarName);
        forVarName = oldVar;
        free(loopVar);
    }
  | PRINT arithexp {
        asprintf(&$$,
"%s\n"
"\tprint",
$2);
    }
  ;

forsave:
    /* vacío */
    {
      char *oldVar = NULL;
      if (forVarName) oldVar = strdup(forVarName);
      $$ = oldVar;
    }
  ;

arithexp:
    arithexp PLUS multexp {
        asprintf(&$$,
"%s\n"
"%s\n"
"\tsum",
$1, $3);
    }
  | arithexp MINUS multexp {
        asprintf(&$$,
"%s\n"
"%s\n"
"\tsub",
$1, $3);
    }
  | multexp {
        $$ = $1;
    }
  ;

multexp:
    multexp MUL val {
        asprintf(&$$,
"%s\n"
"%s\n"
"\tmul",
$1, $3);
    }
  | multexp DIV val {
        asprintf(&$$,
"%s\n"
"%s\n"
"\tdiv",
$1, $3);
    }
  | val {
        $$ = $1;
    }
  ;

val:
    LPAREN arithexp RPAREN {
        $$ = $2;
    }
  | NUM {
        asprintf(&$$, "\tmete %d", $1);
    }
  | ID {
        asprintf(&$$, "\tvalord %s", $1);
    }
  ;

%%

void yyerror(const char *s)
{
    fprintf(stderr, "Error sintáctico: %s\n", s);
}

int main(int argc, char **argv)
{
    labelCount = 0;
    if (argc > 1) {
        extern FILE *yyin;
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror(argv[1]);
            return 1;
        }
    }
    yyparse();
    return 0;
}
