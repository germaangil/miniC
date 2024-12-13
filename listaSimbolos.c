#include "listaSimbolos.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

struct PosicionListaRep {
  Simbolo dato;
  struct PosicionListaRep *sig;
};

struct ListaRep {
  PosicionLista cabecera;
  PosicionLista ultimo;
  int n;
};

typedef struct PosicionListaRep *NodoPtr;

Lista creaLS() {
  Lista nueva = malloc(sizeof(struct ListaRep));
  nueva->cabecera = malloc(sizeof(struct PosicionListaRep));
  nueva->cabecera->sig = NULL;
  nueva->ultimo = nueva->cabecera;
  nueva->n = 0;
  return nueva;
}

void liberaLS(Lista lista) {
  while (lista->cabecera != NULL) {
    NodoPtr borrar = lista->cabecera;
    lista->cabecera = borrar->sig;
    free(borrar);
  }
  free(lista);
}

void insertaLS(Lista lista, PosicionLista p, Simbolo s) {
  NodoPtr nuevo = malloc(sizeof(struct PosicionListaRep));
  nuevo->dato = s;
  nuevo->sig = p->sig;
  p->sig = nuevo;
  if (lista->ultimo == p) {
    lista->ultimo = nuevo;
  }
  (lista->n)++;
}

void suprimeLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  NodoPtr borrar = p->sig;
  p->sig = borrar->sig;
  if (lista->ultimo == borrar) {
    lista->ultimo = p;
  }
  free(borrar);
  (lista->n)--;
}

Simbolo recuperaLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig->dato;
}

PosicionLista buscaLS(Lista lista, char *nombre) {
  NodoPtr aux = lista->cabecera;
  while (aux->sig != NULL && strcmp(aux->sig->dato.nombre,nombre) != 0) {
    aux = aux->sig;
  }
  return aux;
}

void asignaLS(Lista lista, PosicionLista p, Simbolo s) {
  assert(p != lista->ultimo);
  p->sig->dato = s;
}

int longitudLS(Lista lista) {
  return lista->n;
}

PosicionLista inicioLS(Lista lista) {
  return lista->cabecera;
}

PosicionLista finalLS(Lista lista) {
  return lista->ultimo;
}

PosicionLista siguienteLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig;
}

// Añadido por nosotros

int perteneceTablaS (Lista lista, char *nombre) {
  PosicionLista p = buscaLS(lista, nombre);
  return (p != finalLS(lista));
}

void añadeEntrada (Lista lista, char *nombre, Tipo tipo) {
  Simbolo s;
  s.nombre = nombre;
  s.tipo = tipo;
  s.valor = 0;
  insertaLS(lista, finalLS(lista), s);
}

int esConstante (Lista lista, char *nombre) {
  PosicionLista pos = buscaLS(lista, nombre);
  if (pos != finalLS(lista)) {
    Simbolo sim = recuperaLS(lista, pos);
    return sim.tipo == CONSTANTE;
  }
  return 0;
}

void imprimirListaS(Lista lista) {
  printf("###################\n");
  printf("# Seccion de datos\n");
  printf("\t.data\n\n");

  /* Imprimir cadenas */
  PosicionLista p = inicioLS(lista);
  int ncadena = 1;
  while (p != finalLS(lista)) {
    Simbolo simbolo = recuperaLS(lista, p);
    if (simbolo.tipo == CADENA) {
      printf("$str%d:\n", ncadena);
      printf("\t.asciiz %s\n", simbolo.nombre);
      ncadena++;
    }
    p = siguienteLS(lista, p);
  }

  /* Imprimir variables globales. */
  p = inicioLS(lista);
  while (p != finalLS(lista)) {
    Simbolo simbolo = recuperaLS(lista, p);
    if (simbolo.tipo == VARIABLE || simbolo.tipo == CONSTANTE) {
      printf("_%s:\n", simbolo.nombre);
      printf("\t.word 0\n");
    }
    p = siguienteLS(lista, p);
  }

  printf("\n");
}