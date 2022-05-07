
#include "kernel/types.h"
#include "user/user.h"


void TestCasImpl(unsigned nforks)
{
    while(nforks--)
        fork();
    while(1){}
}

void TestEnqueue(unsigned nforks)
{
    while(nforks--)
        fork();
    test_enqueue();
}

void TestDequeue(void)
{
    while(1)
        test_dequeue();
}

int main(int argc, char** argv)
{
    const unsigned int nforks = 5;
    /* Test cas implementation 
    if(fork())
        sleep(5);
    else
        TestCasImpl(nforks);
    procdump();
    */
    if(fork())
        TestDequeue();
    else
        TestEnqueue(5);
    exit(0);
}