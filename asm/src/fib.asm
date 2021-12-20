    ADDI X16, XZR, 43 // Number of fib iterations
    ADDI X5, XZR, 0 // Calc next fib number
    ADDI X6, XZR, 1
    ADDI X24, XZR, 0
fib:
    ADD  X7, X6, X5
    ADDI X5, X6, 0
    ADDI X6, X7, 0
    SUBI X16, X16, 1 // Dec fib iterator
    ADDI X0, X5, 0

print_start:
    ADDI X9,  X9,  8 // Print fib number
    ADDI X10, X22, 0
print_x:
    STUR X0, [X10, 0]
    SUBI X9,  X9,  1
    ADDI X10, X10, 1
    LSR  X0,  X0,  4
    // CBZ  X0, btn_start
    CBNZ X9, print_x

btn_wait: 
    LDUR X25, [X23, 1]
    CBNZ X25, 3
    ADDI X24, X25, 0
    B btn_wait
    CBZ  X24, 3
    ADDI X24, X25, 0
    B btn_wait

    CBNZ X16, fib
    B 0 // Stop
