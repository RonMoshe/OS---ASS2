#include "kernel/types.h"
#include "user.h"

#define NFORKS 50
int main(int argc, char* argv[])
{
    int new_cpu = 2;
    printf("cpu before calling to set_cpu(2): %d\n", get_cpu());
    set_cpu(new_cpu);
    printf("cpu after calling to set_cpu(2): %d\n", get_cpu());
    exit(0);
}