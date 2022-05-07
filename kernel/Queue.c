#include "kernel/Queue.h"

int Dequeue(queue_t* q)
{
    int i, n, e;
    while(TRUE)
    {
        n = q->tail;
        for(i = 0; i<n; i++)
        {
            /* Try to capture element i, different from EMPTY_SLOT */
            e = q->elements[i];
            if(cas(&q->elements[i], e, EMPTY_SLOT) == 0)
            {
                if (e != EMPTY_SLOT)
                    return e;
            }
        }
    }
}

void Enqueue(queue_t* q, int e)
{
    int n = q->n, tail;

    do {
        tail = q->tail;
    }while(cas(&q->tail, tail, (tail + 1) % n));

    q->elements[tail] = e;
}

void Fill(queue_t* q, int val)
{
    int i = 0, n = q->n;
    while(i<n)
        q->elements[i++] = val;
}

void Remove(queue_t* q, int key)
{
    int i, n, e;

    n = q->tail;
    for(i = 0; i<n; i++)
    {
        /* Capture element i, mark its cell as EMPTY_SLOT */
        if(cas(&q->elements[i], key, EMPTY_SLOT) == 0)
        {
            return;
        }
    }
}
