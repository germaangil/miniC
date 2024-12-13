%{
    #define _GNU_SOURCE
    #include <stdio.h>  
    #include <string.h>
    #include "listaSimbolos.h"
    #include "listaCodigo.h"

    extern int yylex();
    extern int yylineno;
    void yyerror(const char * msg);
    char *obtenerEtiqueta();

    Lista ListaSimbolos;
    Tipo tipo;

    int contadorEtiqueta = 1;
    int contadorCadena = 0;
    int nerror = 0;
%}

/* Tipos de datos de los símbolos de la gramática */
%union {
    char *lexema; 
    ListaC codigo; 
}

/* Para incluir en el léxico la definición de listaCódigo */
%code requires{
    #include "listaCodigo.h"
}

/* Declaración de no terminales */
%type <codigo> program declarations identifier_list asig statement_list statement print_list print_item read_list comparacion expresion asignacion_for

/* Definición de tokens */
%token VOID             "void"
%token VAR              "var"
%token CONST            "const"
%token IF               "if"
%token ELSE             "else"
%token WHILE            "while"
%token DO               "do"
%token FOR              "for"
%token PRINT            "print"
%token READ             "read"
%token <lexema> ID      "id"
%token <lexema> ENTERO  "int"
%token <lexema> STRING  "string"
%token PC               ";"
%token COMA             ","
%token MAS              "+"
%token MENOS            "-"
%token POR              "*"
%token DIV              "/"
%token IGUAL            "="
%token PARI             "("
%token PARD             ")"
%token LLAVEI           "{"
%token LLAVED           "}"
%token MENOR            "<"
%token MAYOR            ">"
%token EXCLAM           "!"

/* Asociatividad y precedencia de operadores */
%right "="
%left "+" "-"
%left "*" "/"      
%precedence UMINUS

/* Aceptación de conflictos */
%expect 1         

/* Mensaje de error detallado */
%define parse.error verbose


%%

program         :   { ListaSimbolos = creaLS(); } "void" "id" "(" ")" "{" declarations statement_list "}" 
                    {
                        
                        
                        $$ = creaLC();
                        concatenaLC($$, $7);
                        liberaLC($7);
                        concatenaLC($$, $8);
                        liberaLC($8);
                        imprimirListaS(ListaSimbolos);
                        imprimirCodigo($$);
                    
                        liberaLS(ListaSimbolos);
                    }
                ;

declarations    :   declarations "var" { tipo = VARIABLE; } identifier_list ";"
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        liberaLC($1);
                        concatenaLC($$, $4);
                        liberaLC($4);                        
                    }
                |   declarations "const" { tipo = CONSTANTE; } identifier_list ";"                
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        liberaLC($1);
                        concatenaLC($$, $4);
                        liberaLC($4);   
                    }
                |   %empty                                                  
                    {
                        $$ = creaLC();
                    }
                ;

identifier_list :   asig                                                    
                    {  
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        liberaLC($1);
                    }
                |   identifier_list "," asig                                
                    {                    
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        liberaLC($1);
                        concatenaLC($$, $3);
                        liberaLC($3);
                    }
                ;

asig            :   "id"                                                    
                    {
                        // Comprobamos si el simbolo no pertenece a la lista de simbolos y lo añadimos
                        if (!perteneceTablaS(ListaSimbolos, $1))
                            añadeEntrada(ListaSimbolos, $1, tipo);
                        else {
                            printf("Error en linea %d: Variable \"%s\" ya declarada.\n", yylineno, $1);
                            nerror++;
                        }
    
                        $$ = creaLC();
                    }
                |   "id" "=" expresion                                      
                    {
                        // Comprobamos si el simbolo no pertenece a la lista de simbolos y lo añadimos
                        if (!perteneceTablaS(ListaSimbolos, $1))
                            añadeEntrada(ListaSimbolos, $1, tipo);
                        else {
                            printf("Error en linea %d: Variable \"%s\" ya declarada.\n", yylineno, $1);
                            nerror++;
                        }
                        
                        $$ = creaLC();
                        concatenaLC($$, $3);
                        
                        
                        // Creamos operacion 'sw $ti, _x'
                        char * arg;
                        asprintf(&arg, "_%s", $1);  // Añadimos '_' para resolver conflictos
                        Operacion operacion = creaOp("sw", recuperaResLC($3), arg, NULL);
                        insertaLC($$, finalLC($$), operacion);
                        
                        // Liberar registro 
                        liberaReg(operacion.res); 

                        // Liberamos
                        liberaLC($3);
                    }
                ;

statement_list  :   statement_list statement                                
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        concatenaLC($$, $2);
                        liberaLC($1);
                        liberaLC($2);
                    }
                |   %empty                                                  
                    {    
                        $$ = creaLC();
                    }
                ;

statement       :   "id" "=" expresion ";"                                  
                    {
                        // Comprobamos que la variable existe y no es constante
                        if (!perteneceTablaS(ListaSimbolos, $1)) {
                            printf("Error en linea %d: Variable \"%s\" no declarada.\n", yylineno, $1);
                            nerror++;
                        } else if (esConstante(ListaSimbolos, $1)) {
                            printf("Error en linea %d: Variable \"%s\" es constante.\n", yylineno, $1);
                            nerror++;
                        }
                            
                        $$ = creaLC();
                        concatenaLC($$, $3);
                    
                        // Creamos operacion 'sw $ti, _x'
                        char * arg;
                        asprintf(&arg, "_%s", $1);  // Añadimos '_' para resolver conflictos
                        Operacion operacion = creaOp("sw", recuperaResLC($3), arg, NULL);
                        insertaLC($$, finalLC($$), operacion);
                        
                        // Liberar registro 
                        liberaReg(operacion.res);

                        // Liberamos
                        liberaLC($3);
                    }
                |   "{" statement_list "}"                                  
                    {
                        $$ = creaLC();
                        concatenaLC($$, $2);
                        liberaLC($2);
                    }
                |   "if" "(" comparacion ")" statement "else" statement       
                    {
                        char * etiqElse = obtenerEtiqueta();
                        insertarEtiqueta($3, etiqElse);
    
                        $$ = creaLC();
                        concatenaLC($$, $3);
                        concatenaLC($$, $5);

                        // Creamos operacion 'b $li'
                        char * finIf = obtenerEtiqueta();
                        Operacion oper = creaOp("j", finIf, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);    

                        // Operación que crea la etiqueta para el else
                        oper = creaOp("etiq", etiqElse, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Código si la expresión del if es igual a 0    
                        concatenaLC($$, $7);

                        // Operación que crea la etiqueta para el if
                        oper = creaOp("etiq", finIf, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos
                        liberaLC($3);
                        liberaLC($5);
                        liberaLC($7);
                    }
                |   "if" "(" comparacion ")" statement                        
                    {
                        char * finIf = obtenerEtiqueta();
                        insertarEtiqueta($3, finIf);

                        // Salto condicional + cuerpo del if
                        $$ = creaLC();
                        concatenaLC($$, $3);    
                        concatenaLC($$, $5);
                
                        // Operación que crea la etiqueta para el if
                        Operacion oper = creaOp("etiq", finIf, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos
                        liberaLC($3);
                        liberaLC($5);
                    }
                |   "while" "(" comparacion ")" statement                     
                    {
                        $$ = creaLC();

                        // Operación que crea la etiqueta para el inicio del while
                        char * inicioWhile = obtenerEtiqueta();
                        Operacion oper = creaOp("etiq", inicioWhile, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Salto condicional + cuerpo del while
                        char * finWhile = obtenerEtiqueta();
                        insertarEtiqueta($3, finWhile);
                        concatenaLC($$, $3);
                        concatenaLC($$, $5);

                        // Creamos operacion 'b $li'
                        oper = creaOp("j", inicioWhile, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);   

                        // Operación que crea la etiqueta para el fin del while
                        oper = creaOp("etiq", finWhile, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos
                        liberaLC($3);
                        liberaLC($5);
                    }
                |   "do" statement "while" "(" comparacion ")" ";"   
                    {
                        $$ = creaLC();

                        // Operación que crea la etiqueta para el inicio del do-while
                        char * inicioDo = obtenerEtiqueta();
                        Operacion oper = creaOp("etiq", inicioDo, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        char * finDo = obtenerEtiqueta();
                        // Salto condicional + cuerpo del do
                        concatenaLC($$, $2);
                        insertarEtiqueta($5, finDo);
                        concatenaLC($$, $5);
                        
                        // Creamos operacion 'b $li'
                        oper = creaOp("j", inicioDo, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);   

                        // Operación que crea la etiqueta para el fin del while
                        oper = creaOp("etiq", finDo, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos
                        liberaLC($2);
                        liberaLC($5);
                    }
                |   "for" "(" asignacion_for ";" comparacion ";" asignacion_for ")" statement
                    {        
                        $$ = creaLC();
                        concatenaLC($$, $3);

                        // Operación que crea la etiqueta para el inicio del for
                        char * inicioFor = obtenerEtiqueta();
                        Operacion oper = creaOp("etiq", inicioFor, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        //Salto condicional + cuerpo del for + asignacion(i++)
                        char * finFor = obtenerEtiqueta();
                        insertarEtiqueta($5, finFor);
                        concatenaLC($$, $5);
                        concatenaLC($$, $9);
                        concatenaLC($$, $7);
            
                        // Creamos operacion 'b $li'
                        oper = creaOp("j", inicioFor, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);   

                        // Operación que crea la etiqueta para el fin del for
                        oper = creaOp("etiq", finFor, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos
                        liberaLC($3);
                        liberaLC($5);
                        liberaLC($7);
                        liberaLC($9);
                    }
                |   "print" print_list ";"                                  
                    {
                        $$ = creaLC();
                        concatenaLC($$, $2);
                        liberaLC($2);
                    }
                |   "read" read_list ";"                                    
                    {
                        $$ = creaLC();
                        concatenaLC($$, $2);
                        liberaLC($2);
                    }
                ;

print_list      :   print_item                                              
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        liberaLC($1);
                    }
                |   print_list "," print_item                               
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        concatenaLC($$, $3);
                        liberaLC($1);
                        liberaLC($3);
                    }
                ;                                   

print_item      :   expresion                                               
                    {

                        $$ = creaLC();
                        concatenaLC($$, $1);

                        // Creamos operacion 'move $a0, $ti'
                        Operacion oper = creaOp("move", "$a0", recuperaResLC($1), NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos registro
                        liberaReg(oper.arg1);

                        // Creamos operacion 'li $v0, 1'
                        oper = creaOp("li", "$v0", "1", NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Creamos operacion 'syscall'
                        oper = creaOp("syscall", NULL, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos
                        liberaLC($1);
                    }
                |   "string"                                                
                    {
                        
                        $$ = creaLC();

                        // Añadimos la cadena a la lista de simbolos e incrementamos el contador
                        añadeEntrada(ListaSimbolos, $1, CADENA);
                        contadorCadena++;

                        // Reservamos memoria para la cadena y obtenemos '$stri'
                        char *cadena = (char *)malloc(4 + 2 + 1); // "$str" + "[1-99]" + 0
                        sprintf(cadena, "$str%d", contadorCadena);

                        // Creamos operacion 'la $a0, $stri'
                        Operacion oper = creaOp("la", "$a0", cadena, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Creamos operacion 'li $v0, 4'
                        oper = creaOp("li", "$v0", "4", NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Creamos operacion 'syscall'
                        oper = creaOp("syscall", NULL, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);
                    }
                ;

read_list       :   "id"                                                    
                    {
                        // Comprobamos que la variable existe y no es constante
                        if (!perteneceTablaS(ListaSimbolos, $1)) {
                            printf("Error en linea %d: Variable \"%s\" no declarada.\n", yylineno, $1);
                            nerror++;
                        }
                        else if (esConstante(ListaSimbolos, $1)){
                            printf("Error en linea %d: Variable \"%s\" es constante.\n", yylineno, $1);
                            nerror++;                        
                        }
                        
                        $$ = creaLC();

                        // Creamos operacion 'li $v0, 5'
                        Operacion oper = creaOp("li", "$v0", "5", NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Creamos operacion 'syscall'
                        oper = creaOp("syscall", NULL, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Creamos operacion 'sw $v0, _x'
                        char * arg;
                        asprintf(&arg, "_%s", $1);  // Añadimos '_' para resolver conflictos
                        oper = creaOp("sw", "$v0", arg, NULL);
                        insertaLC($$, finalLC($$), oper);
                    }
                |   read_list "," "id"                                      
                    {
                        // Comprobamos que la variable existe y no es constante
                        if (!perteneceTablaS(ListaSimbolos, $3)) {
                            printf("Error en linea %d: Variable \"%s\" no declarada.\n", yylineno, $3);
                            nerror++;
                        } else if (esConstante(ListaSimbolos, $3)) {
                            printf("Error en linea %d: Variable \"%s\" es constante.\n", yylineno, $3);
                            nerror++;
                        }
                            
                    
                        $$ = creaLC();
                        concatenaLC($$, $1);
            
                        // Creamos operacion 'li $v0, 5'
                        Operacion oper = creaOp("li", "$v0", "5", NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Creamos operacion 'syscall'
                        oper = creaOp("syscall", NULL, NULL, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Creamos operacion 'sw $v0, _x'
                        char * arg;
                        asprintf(&arg, "_%s", $3);  // Añadimos '_' para resolver conflictos
                        oper = creaOp("sw", "$v0", arg, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos
                        liberaLC($1);
                    }
                ;

comparacion     :   expresion "<" expresion 
                    {
                        $$ = creaLC();
                        concatenaLC($$, $3);

                        Operacion oper = creaOp("bge", recuperaResLC($1), recuperaResLC($3), "--");
                        insertaLC($$, finalLC($$), oper);

                        liberaReg(oper.res);
                        liberaReg(oper.arg1);

                        liberaLC($1);
                        liberaLC($3);                         
                    }
                |   expresion ">" expresion   
                    {
                        $$ = creaLC();
                        concatenaLC($$, $3);
                        
                        Operacion oper = creaOp("ble", recuperaResLC($1), recuperaResLC($3), "--");
                        insertaLC($$, finalLC($$), oper);

                        liberaReg(oper.res);
                        liberaReg(oper.arg1);

                        liberaLC($1);
                        liberaLC($3);                        
                    }
                |   expresion "<" "=" expresion     
                    {
                        $$ = creaLC();
                        concatenaLC($$, $4);
                        
                        Operacion oper = creaOp("bgt", recuperaResLC($1), recuperaResLC($4), "--");
                        insertaLC($$, finalLC($$), oper);

                        liberaReg(oper.res);
                        liberaReg(oper.arg1);

                        liberaLC($1);
                        liberaLC($4);                    
                    }
                |   expresion ">" "=" expresion     
                    {
                        $$ = creaLC();
                        concatenaLC($$, $4);
                                    
                        Operacion oper = creaOp("blt", recuperaResLC($1), recuperaResLC($4), "--");
                        insertaLC($$, finalLC($$), oper);

                        liberaReg(oper.res);
                        liberaReg(oper.arg1);

                        liberaLC($1);
                        liberaLC($4);                                  
                    }
                |   expresion "=" "=" expresion     
                    {
        
                        $$ = creaLC();
                        concatenaLC($$, $4);
                                       
                        Operacion oper = creaOp("bne", recuperaResLC($1), recuperaResLC($4), "--");
                        insertaLC($$, finalLC($$), oper);

                        liberaReg(oper.res);
                        liberaReg(oper.arg1);

                        liberaLC($1);
                        liberaLC($4); 
                    }
                |   expresion "!" "=" expresion      
                    {
                        $$ = creaLC();
                        concatenaLC($$, $4);
                        
                        Operacion oper = creaOp("beq", recuperaResLC($1), recuperaResLC($4), "--");
                        insertaLC($$, finalLC($$), oper);

                        liberaReg(oper.res);
                        liberaReg(oper.arg1);

                        liberaLC($1);
                        liberaLC($4); 
                    }
                |   expresion                      
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);

                        Operacion oper = creaOp("beqz", recuperaResLC($1), "--", NULL);
                        insertaLC($$, finalLC($$), oper);

                        liberaReg(oper.res);

                        liberaLC($1);
                    }

expresion       :   expresion "+" expresion                                 
                    {   
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        concatenaLC($$, $3);
        
                        // Creamos la operacion 'add $ti, $ti, $tj'
                        Operacion oper = creaOp("add", recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
                        insertaLC($$, finalLC($$), oper); 
                        guardaResLC($$, oper.res);
                        
                        // Liberamos registro 
                        liberaReg(oper.arg2);

                        // Liberamos
                        liberaLC($1);
                        liberaLC($3);
                    }
                |   expresion "-" expresion                                 
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        concatenaLC($$, $3);

                        // Creamos la operacion 'sub $ti, $ti, $tj'
                        Operacion oper = creaOp("sub", recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
                        insertaLC($$, finalLC($$), oper);
                        guardaResLC($$, oper.res);

                        // Liberamos registro 
                        liberaReg(oper.arg2);

                        // Liberamos
                        liberaLC($1);
                        liberaLC($3);
                    }
                |   expresion "*" expresion                                 
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        concatenaLC($$, $3);

                        // Creamos la operacion 'mul $ti, $ti, $tj'
                        Operacion oper = creaOp("mul", recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
                        insertaLC($$, finalLC($$), oper);
                        guardaResLC($$, oper.res);

                        // Liberamos registro 
                        liberaReg(oper.arg2);

                        // Liberamos
                        liberaLC($1);
                        liberaLC($3);
                    }
                |   expresion "/" expresion                                 
                    {
                        $$ = creaLC();
                        concatenaLC($$, $1);
                        concatenaLC($$, $3);

                        // Creamos la operacion 'div $ti, $ti, $tj'
                        Operacion oper = creaOp("div", recuperaResLC($1), recuperaResLC($1), recuperaResLC($3));
                        insertaLC($$, finalLC($$), oper);
                        guardaResLC($$, oper.res);

                        // Liberamos registro 
                        liberaReg(oper.arg2);

                        // Liberamos
                        liberaLC($1);
                        liberaLC($3);
                    }
                |   "-" expresion %prec UMINUS                              
                    {
                        $$ = creaLC();
                        concatenaLC($$, $2);
            
                        // Creamos la operacion 'neg $ti, $ti'
                        Operacion oper = creaOp("neg", recuperaResLC($2), recuperaResLC($2), NULL);
                        insertaLC($$, finalLC($$), oper);
                        guardaResLC($$, oper.res);

                        // Liberamos
                        liberaLC($2);
                    }
                |   "(" expresion ")"                                       
                    {
                        $$ = creaLC();
                        concatenaLC($$, $2);
                        liberaLC($2);
                    }
                |   "id"                                                    
                    {
                        // Comprobamos que la variable existe y no es constante
                        if (!perteneceTablaS(ListaSimbolos, $1)) {
                            printf("Error en linea %d: Variable \"%s\" no declarada.\n", yylineno, $1);
                            nerror++;
                        } 

                        $$ = creaLC();

                        // Creamos operacion 'lw $ti, _x'
                        char * arg;
                        asprintf(&arg, "_%s", $1);  // Añadimos '_' para resolver conflictos
                        Operacion oper = creaOp("lw", obtenerReg(), arg, NULL);
                        insertaLC($$, finalLC($$), oper);
                        guardaResLC($$, oper.res);
                    }
                |   "int"                                                   
                    {
                     
                        $$ = creaLC();

                        // Creamos la operacion 'li $ti, val'
                        Operacion oper = creaOp("li", obtenerReg(), $1, NULL);
                        insertaLC($$, finalLC($$), oper);
                        guardaResLC($$, oper.res);
                    }
                ;
asignacion_for  :   "id" "=" expresion    
                    {
                        if (!perteneceTablaS(ListaSimbolos, $1)) {
                            printf("Error en linea %d: Variable \"%s\" no declarada.\n", yylineno, $1);
                            nerror++;
                        } else if (esConstante(ListaSimbolos, $1)) {
                            printf("Error en linea %d: Variable \"%s\" es constante.\n", yylineno, $1);
                            nerror++;
                        }

                        $$ = creaLC();
                        concatenaLC($$, $3);

                        // Creamos operacion 'sw $ti, _x'
                        char * arg;
                        asprintf(&arg, "_%s", $1);  // Añadimos '_' para resolver conflictos
                        Operacion oper = creaOp("sw", recuperaResLC($3), arg, NULL);
                        insertaLC($$, finalLC($$), oper);

                        // Liberamos el registro
                        liberaReg(oper.res); 

                        //Liberamos
                        liberaLC($3);
                    }

%%

void yyerror(const char * msg) {
    printf("Error en línea %d: %s\n", yylineno, msg);
    nerror++;
}

/* Función que nos proporciona una etiqueta nueva para usar */
char *obtenerEtiqueta() {
    char aux[32];
    sprintf(aux, "$l%d", contadorEtiqueta++);
    return strdup(aux);
}
