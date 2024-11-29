%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Declaración de la función de análisis léxico
int yylex();

// Declaración de la función de manejo de errores
void yyerror(const char *s);

// Contador para generar etiquetas únicas
int labelCount = 0;

// Variable global para la etiqueta final
char *endLabel;
%}

%union {
    int intval;    // Valor entero
    char *strval;  // Valor de cadena
    char *code;    // Código generado
}

// Definición de tokens con sus tipos asociados
%token <strval> ID           // Token para identificadores
%token <intval> NUM          // Token para números

%token PROGRAM END DO IF ELSE ELSEIF THEN ENDIF PRINT MUL PLUS MINUS DIV POWER EQ COMMA LPAREN RPAREN

// Definición de las precedencias y asociaciones de los operadores
%left PLUS MINUS
%left MUL DIV
%right POWER

// Definición de tipos para los no terminales
%type <code> program stmts stmt elserep exp multexp value

%%

/* Regla para el programa completo */
program:
    PROGRAM ID stmts END PROGRAM ID
        {
            // Imprimir el código generado del programa
            printf("%s\n", $3);
        }
    ;

/* Regla para una lista de sentencias */
stmts:
    stmt stmts
        {
            // Concatenar el código de la sentencia actual con el de las sentencias siguientes
            asprintf(&$$, "%s\n%s", $1, $2);
        }
    |
    stmt
        {
            // Asignar el código de la única sentencia
            $$ = $1;
        }
    ;

/* Regla para una sentencia individual */
stmt:
    IF LPAREN exp RPAREN THEN stmts elserep
        {
            // Generar etiquetas en el orden deseado
            asprintf(&endLabel, "LBL%d", labelCount++);
            char *falseLabel;
            asprintf(&falseLabel, "LBL%d", labelCount++);

            // Construir el código para la estructura if-else
            asprintf(&$$, "%s\n\tsifalsovea %s\n%s\n\tvea %s\n%s:\n%s\n%s:",
                $3, falseLabel, $6, endLabel, falseLabel, $7, endLabel);
        }
    |
    DO ID EQ exp COMMA NUM stmts END DO
        {
            // Generar una etiqueta de inicio para el bucle
            char *startLabel;
            asprintf(&startLabel, "LBL%d", labelCount++);

            // Código de inicialización de la variable de control
            char *initCode;
            asprintf(&initCode, "\tvalori %s\n%s\n\tasigna", $2, $4);

            // Código de la condición del bucle
            char *conditionCode;
            asprintf(&conditionCode, "\tvalord %s\n\tmete %d\n\tsub\n\tsiciertovea %s", $2, $6, startLabel);

            // Código para incrementar la variable de control
            char *incrementCode;
            asprintf(&incrementCode, "\tvalori %s\n\tvalord %s\n\tmete 1\n\tsum\n\tasigna", $2, $2);

            // Construir el código completo del bucle
            asprintf(&$$, "%s\n%s:\n%s\n%s\n%s", initCode, startLabel, $7, incrementCode, conditionCode);
        }
    |
    DO ID EQ exp COMMA NUM COMMA NUM stmts END DO
        {
            // Generar una etiqueta de inicio para el bucle
            char *startLabel;
            asprintf(&startLabel, "LBL%d", labelCount++);

            // Código de inicialización de la variable de control
            char *initCode;
            asprintf(&initCode, "\tvalori %s\n%s\n\tasigna", $2, $4);

            // Código de la condición del bucle
            char *conditionCode;
            asprintf(&conditionCode, "\tvalord %s\n\tmete %d\n\tsub\n\tsiciertovea %s", $2, $6, startLabel);

            // Código para incrementar la variable de control con un paso específico
            char *incrementCode;
            asprintf(&incrementCode, "\tvalori %s\n\tvalord %s\n\tmete %d\n\tsum\n\tasigna", $2, $2, $8);

            // Construir el código completo del bucle
            asprintf(&$$, "%s\n%s:\n%s\n%s\n%s", initCode, startLabel, $9, incrementCode, conditionCode);
        }
    |
    PRINT MUL COMMA exp
        {
            // Generar código para imprimir el valor de una expresión
            asprintf(&$$, "%s\n\tprint", $4);
        }
    |
    ID EQ exp
        {
            // Generar código para asignar el resultado de una expresión a una variable
            asprintf(&$$, "\tvalori %s\n%s\n\tasigna", $1, $3);
        }
    ;

/* Regla para la representación del else y elseif */
elserep:
    ENDIF
        {
            // No hay sentencia else, cadena vacía
            $$ = strdup("");
        }
    |
    ELSE stmts ENDIF
        {
            // Incluir el código de las sentencias del else
            $$ = $2;
        }
    |
    ELSEIF LPAREN exp RPAREN THEN stmts elserep
        {
            // Generar etiqueta falsa para el elseif
            char *falseLabel;
            asprintf(&falseLabel, "LBL%d", labelCount++);
            // Generar etiqueta final
            asprintf(&endLabel, "LBL%d", labelCount);
            // Construir el código para el elseif
            asprintf(&$$, "%s\n\tsifalsovea %s\n%s\n\tvea %s\n%s:\n%s",
                $3, falseLabel, $6, endLabel, falseLabel, $7);
        }
    ;

/* Reglas para expresiones aritméticas */
exp:
    multexp PLUS exp
        {
            // Generar código para la suma de dos expresiones
            asprintf(&$$, "%s\n%s\n\tsum", $1, $3);
        }
    |
    multexp MINUS exp
        {
            // Generar código para la resta de dos expresiones
            asprintf(&$$, "%s\n%s\n\tsub", $1, $3);
        }
    |
    multexp
        {
            // Pasar el código de multexp
            $$ = $1;
        }
    |
    ID POWER NUM
        {
            // Generar código para la potencia de una variable elevada a un número
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

/* Reglas para multiplicaciones y divisiones */
multexp:
    value MUL multexp
        {
            // Generar código para la multiplicación de dos valores
            asprintf(&$$, "%s\n%s\n\tmul", $1, $3);
        }
    |
    value DIV multexp
        {
            // Generar código para la división de dos valores
            asprintf(&$$, "%s\n%s\n\tdiv", $1, $3);
        }
    |
    value
        {
            // Pasar el código del valor
            $$ = $1;
        }
    ;

/* Reglas para valores individuales */
value:
    NUM
        {
            // Generar código para un número literal
            asprintf(&$$, "\tmete %d", $1);
        }
    |
    ID
        {
            // Generar código para el valor de una variable
            asprintf(&$$, "\tvalord %s", $1);
        }
    |
    LPAREN exp RPAREN
        {
            // Pasar el código de una expresión entre paréntesis
            $$ = $2;
        }
    ;

%%

/* Función para manejar errores de sintaxis */
void yyerror(const char *s)
{
    fprintf(stderr, "Error: %s\n", s);
}

/* Función principal */
int main(int argc, char **argv)
{
    // Inicializar el contador de etiquetas
    labelCount = 0;

    if (argc > 1)
    {
        extern FILE *yyin;
        // Abrir el archivo de entrada
        yyin = fopen(argv[1], "r");
        if (!yyin)
        {
            // Manejar errores al abrir el archivo
            perror(argv[1]);
            return 1;
        }
    }
    // Iniciar el análisis sintáctico
    yyparse();
    return 0;
}
