#include "kernel/types.h"
#define EMPTY_SLOT 0xffffffff
#define TRUE 1
#define CREATE_QUEUE(name, type, size) \
                            static queue_t name; \
                            static type elements[size]; \
                            name.elements = elements;     \
                            name.n = size;                \
                            name.tail = 0;                \
                            int i = 0; \
                            while(i < size){\
                                elements[i++] = EMPTY_SLOT;}\

typedef struct queue_t{
    volatile int tail;
    int n;
    int *elements;
}queue_t;

extern uint64 cas(volatile void* addr, int expected, int newval);

int Dequeue(queue_t* q);
void Enqueue(queue_t* q, int e);
void Fill(queue_t* q, int val);
void Remove(queue_t* q, int key);

