#include <stdio.h>

int main(int argc, char **argv) {
    if (argc != 3) {
        return 2;
    }
    if (renamex_np(argv[1], argv[2], RENAME_SWAP) != 0) {
        perror("renamex_np");
        return 1;
    }
    return 0;
}
