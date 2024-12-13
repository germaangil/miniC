#include "listaCodigo.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

struct PosicionListaCRep {
  Operacion dato;
  struct PosicionListaCRep *sig;
};

struct ListaCRep {
  PosicionListaC cabecera;
  PosicionListaC ultimo;
  int n;
  char *res;
};

typedef struct PosicionListaCRep *NodoPtr;

ListaC creaLC() {
  ListaC nueva = malloc(sizeof(struct ListaCRep));
  nueva->cabecera = malloc(sizeof(struct PosicionListaCRep));
  nueva->cabecera->sig = NULL;
  nueva->ultimo = nueva->cabecera;
  nueva->n = 0;
  nueva->res = NULL;
  return nueva;
}

void liberaLC(ListaC codigo) {
  while (codigo->cabecera != NULL) {
    NodoPtr borrar = codigo->cabecera;
    codigo->cabecera = borrar->sig;
    free(borrar);
  }
  free(codigo);
}

void insertaLC(ListaC codigo, PosicionListaC p, Operacion o) {
  NodoPtr nuevo = malloc(sizeof(struct PosicionListaCRep));
  nuevo->dato = o;
  nuevo->sig = p->sig;
  p->sig = nuevo;
  if (codigo->ultimo == p) {
    codigo->ultimo = nuevo;
  }
  (codigo->n)++;
}

Operacion recuperaLC(ListaC codigo, PosicionListaC p) {
  assert(p != codigo->ultimo);
  return p->sig->dato;
}

PosicionListaC buscaLC(ListaC codigo, PosicionListaC p, char *clave, Campo campo) {
  NodoPtr aux = p;
  char *info;
  while (aux->sig != NULL) {
    switch (campo) {
      case OPERACION: 
        info = aux->sig->dato.op;
        break;
      case ARGUMENTO1:
        info = aux->sig->dato.arg1;
        break;
      case ARGUMENTO2:
        info = aux->sig->dato.arg2;
        break;
      case RESULTADO:
        info = aux->sig->dato.res;
        break;
    }
    if (info != NULL && !strcmp(info,clave)) break;
	  aux = aux->sig;
  }
  return aux;
}

void asignaLC(ListaC codigo, PosicionListaC p, Operacion o) {
  assert(p != codigo->ultimo);
  p->sig->dato = o;
}

int longitudLC(ListaC codigo) {
  return codigo->n;
}

PosicionListaC inicioLC(ListaC codigo) {
  return codigo->cabecera;
}

PosicionListaC finalLC(ListaC codigo) {
  return codigo->ultimo;
}

void concatenaLC(ListaC codigo1, ListaC codigo2) {
  NodoPtr aux = codigo2->cabecera;
  while (aux->sig != NULL) {
    insertaLC(codigo1,finalLC(codigo1),aux->sig->dato);
    aux = aux->sig;
  }
}

PosicionListaC siguienteLC(ListaC codigo, PosicionListaC p) {
  assert(p != codigo->ultimo);
  return p->sig;
}

void guardaResLC(ListaC codigo, char *res) {
  codigo->res = res;
}

/* Recupera el registro resultado de una lista de codigo */
char * recuperaResLC(ListaC codigo) {
  return codigo->res;
}

// Añadido por nosotros

Operacion creaOp (char *op, char *res, char *arg1, char *arg2) {
  Operacion operacion;
  operacion.op = op;
  operacion.res = res;
  operacion.arg1 = arg1;
  operacion.arg2 = arg2;
  return operacion;
}

// Para saber que registros están siendo usados (1 usado / 0 no usado)
int regTemp[10] = {0};

char * obtenerReg(){
  for(int i = 0; i < 10; i++) {
    if (regTemp[i] == 0) {
      regTemp[i] = 1;
      char reg[4];
      sprintf(reg, "$t%d", i);
      return strdup(reg);
    }
  }

  printf("Error: no hay registros temporales libres. \n");
  exit(1);
}

void liberaReg(char *reg) { 
  int i = atoi(reg+2);
  regTemp[i] = 0;
}

void imprimirCodigo(ListaC codigo) {
    printf("###################\n");
    printf("# Seccion de codigo\n");
    printf("\t.text\n");
    printf("\t.globl main\n");
    printf("main:\n");

    PosicionListaC p = inicioLC(codigo);
    Operacion oper;
    while (p != finalLC(codigo)) {
        oper = recuperaLC(codigo, p);
        if(strcmp(oper.op, "etiq") == 0) {
            printf("%s:", oper.res);
        } else {
            printf("\t%s",oper.op);
            if (oper.res) printf(" %s",oper.res);
            if (oper.arg1) printf(", %s",oper.arg1);
            if (oper.arg2) printf(", %s",oper.arg2);
        }
        printf("\n");
        p = siguienteLC(codigo, p);
    }
    printf("\n###################\n");
    printf("# Fin\n");
    printf("\tli $v0 10\n");
    printf("\tsyscall\n");
}

/* Función encargada de sustituir "--" por la etiqueta que corresponde */
void insertarEtiqueta(ListaC codigo, char *etiq) {
  
  PosicionListaC p = buscaLC(codigo, inicioLC(codigo), "--", ARGUMENTO1);
  if(p == finalLC(codigo))
    p = buscaLC(codigo, inicioLC(codigo), "--", ARGUMENTO2);

  Operacion oper = recuperaLC(codigo, p);

  if(strcmp(oper.res, "--") == 0)
    oper.res = etiq;
  else if(strcmp(oper.arg1, "--") == 0)
    oper.arg1 = etiq;
  else
    oper.arg2 = etiq;

  asignaLC(codigo, p, oper);
}
