%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);               // Declaración de la función de análisis léxico
void yyerror(const char *s);   // Declaración de la función de manejo de errores

int labelCount = 0;            // Contador para generar etiquetas únicas
char *forVarName = NULL;       // Nombre de la variable utilizada en estructuras FOR
%}

%union {
    int intval;         // Valor entero
    char *strval;       // Cadena de caracteres
    char *code;         // Código generado
    char *varsave;      // Para guardar el estado anterior de forVarName
}

%token <intval> NUM               // Token para números enteros
%token <strval> ID                // Token para identificadores
%token IF THEN ELSE FI DO WHILE FOR TO PRINT OD  // Tokens para palabras clave
%token ASSIGN PLUS MINUS MUL DIV LPAREN RPAREN     // Tokens para operadores y paréntesis

%type <code> liststmt stmt assig struc arithexp multexp val
%type <varsave> forsave         // Tipo para guardar el estado de variables en FOR

%left PLUS MINUS                 // Definición de precedencia para operadores aditivos
%left MUL DIV                    // Definición de precedencia para operadores multiplicativos

%%

/* Definición de la regla principal del programa */
program:
    /* vacío */
  | liststmt { 
      /* Al finalizar la lista de sentencias, se imprime el código generado */
      printf("%s\n", $1); 
    }
  ;

/* Definición de una lista de sentencias */
liststmt:
    stmt { 
      /* Una única sentencia */
      $$ = $1; 
    }
  | stmt liststmt { 
      /* Concatenación de sentencias separadas por saltos de línea */
      asprintf(&$$, "%s\n%s", $1, $2); 
    }
  ;

/* Definición de una sentencia */
stmt:
    assig { 
      /* Sentencia de asignación */
      $$ = $1; 
    }
  | struc { 
      /* Sentencia de estructura de control */
      $$ = $1; 
    }
  ;

/* Definición de una asignación */
assig:
    ID ASSIGN arithexp {
        /* Genera código para asignar el resultado de una expresión aritmética a una variable */
        asprintf(&$$,
    "\tvalori %s\n"
    "%s\n"
    "\tasigna",
    $1, $3);
        /* Actualiza forVarName con el nombre de la variable asignada */
        if (forVarName) free(forVarName);
        forVarName = strdup($1);
    }
  ;

/* Definición de estructuras de control */
struc:
    /* IF sin ELSE */
    IF arithexp THEN liststmt FI {
        /* Genera etiquetas para manejar el flujo del IF */
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
        /* Genera etiquetas para manejar el flujo del IF-ELSE */
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
        /* Genera etiquetas para manejar el bucle DO-WHILE */
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
  /* Manejo de la estructura FOR con almacenamiento de variable previa */
  | FOR forsave assig TO NUM DO liststmt OD {
        /* Guarda la variable anterior antes de modificar forVarName */
        char *oldVar = $2; // Valor guardado por forsave
        char *loopVar = strdup(forVarName);

        /* Genera etiquetas para el inicio y fin del bucle FOR */
        char *lblStart, *lblEnd;
        asprintf(&lblStart, "LBL%d", labelCount++);
        asprintf(&lblEnd,   "LBL%d", labelCount++);

        /* Genera el código del bucle FOR */
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

        /* Restaura la variable anterior del FOR externo */
        if (forVarName) free(forVarName);
        forVarName = oldVar;
        free(loopVar);
    }
  | PRINT arithexp {
        /* Genera código para imprimir el resultado de una expresión aritmética */
        asprintf(&$$,
    "%s\n"
    "\tprint",
    $2);
    }
  ;

/* Regla para guardar el estado anterior de la variable en un FOR */
forsave:
    /* vacío */
    {
      char *oldVar = NULL;
      if (forVarName) oldVar = strdup(forVarName);
      $$ = oldVar;
    }
  ;

/* Definición de expresiones aritméticas */
arithexp:
    arithexp PLUS multexp {
        /* Genera código para la suma de dos expresiones */
        asprintf(&$$,
    "%s\n"
    "%s\n"
    "\tsum",
    $1, $3);
    }
  | arithexp MINUS multexp {
        /* Genera código para la resta de dos expresiones */
        asprintf(&$$,
    "%s\n"
    "%s\n"
    "\tsub",
    $1, $3);
    }
  | multexp {
        /* Propaga el valor de multexp */
        $$ = $1;
    }
  ;

/* Definición de expresiones multiplicativas */
multexp:
    multexp MUL val {
        /* Genera código para la multiplicación de dos valores */
        asprintf(&$$,
    "%s\n"
    "%s\n"
    "\tmul",
    $1, $3);
    }
  | multexp DIV val {
        /* Genera código para la división de dos valores */
        asprintf(&$$,
    "%s\n"
    "%s\n"
    "\tdiv",
    $1, $3);
    }
  | val {
        /* Propaga el valor de val */
        $$ = $1;
    }
  ;

/* Definición de valores básicos */
val:
    LPAREN arithexp RPAREN {
        /* Maneja expresiones entre paréntesis */
        $$ = $2;
    }
  | NUM {
        /* Genera código para un número entero */
        asprintf(&$$, "\tmete %d", $1);
    }
  | ID {
        /* Genera código para acceder al valor de una variable */
        asprintf(&$$, "\tvalord %s", $1);
    }
  ;

%%

/* Función para manejar errores sintácticos */
void yyerror(const char *s)
{
    fprintf(stderr, "Error sintáctico: %s\n", s);
}

/* Función principal */
int main(int argc, char **argv)
{
    labelCount = 0; // Inicializa el contador de etiquetas
    if (argc > 1) {
        extern FILE *yyin;
        yyin = fopen(argv[1], "r"); // Abre el archivo de entrada
        if (!yyin) {
            perror(argv[1]);
            return 1;
        }
    }
    yyparse(); // Inicia el análisis sintáctico
    return 0;
}
