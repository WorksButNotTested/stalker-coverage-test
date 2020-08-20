#include <stdio.h>
#include <stdlib.h>

long square(long x)
{
    return x * x;
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Give me an argument!\n");
        return 1;
    }

    long x = strtol(argv[1], NULL, 0);
    long sq_x = square(x);
    printf("%ld squared is %ld\n", x, sq_x);
    return 0;
}