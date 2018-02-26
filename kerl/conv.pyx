cimport cython
from libc.stdlib cimport malloc, free

DEF BYTE_HASH_LENGTH = 48
DEF TRIT_HASH_LENGTH = 243
DEF BASE3 = 3

tryte_table = {
        '9': [ 0,  0,  0],  #   0
        'A': [ 1,  0,  0],  #   1
        'B': [-1,  1,  0],  #   2
        'C': [ 0,  1,  0],  #   3
        'D': [ 1,  1,  0],  #   4
        'E': [-1, -1,  1],  #   5
        'F': [ 0, -1,  1],  #   6
        'G': [ 1, -1,  1],  #   7
        'H': [-1,  0,  1],  #   8
        'I': [ 0,  0,  1],  #   9
        'J': [ 1,  0,  1],  #  10
        'K': [-1,  1,  1],  #  11
        'L': [ 0,  1,  1],  #  12
        'M': [ 1,  1,  1],  #  13
        'N': [-1, -1, -1],  # -13
        'O': [ 0, -1, -1],  # -12
        'P': [ 1, -1, -1],  # -11
        'Q': [-1,  0, -1],  # -10
        'R': [ 0,  0, -1],  #  -9
        'S': [ 1,  0, -1],  #  -8
        'T': [-1,  1, -1],  #  -7
        'U': [ 0,  1, -1],  #  -6
        'V': [ 1,  1, -1],  #  -5
        'W': [-1, -1,  0],  #  -4
        'X': [ 0, -1,  0],  #  -3
        'Y': [ 1, -1,  0],  #  -2
        'Z': [-1,  0,  0],  #  -1
        }

# Invert for trit -> tryte lookup
trit_table = {tuple(v): k for k, v in tryte_table.items()}

def trytes_to_trits(trytes):
    trits = []
    for tryte in trytes:
        trits.extend(tryte_table[tryte])

    return trits

def trits_to_trytes(trits):
    trytes = []
    trits_chunks = [trits[i:i + 3] for i in range(0, len(trits), 3)]

    for trit in trits_chunks:
        trytes.extend(trit_table[tuple(trit)])

    return ''.join(trytes)

@cython.boundscheck(False)
def bytes_to_trits(bytes_k):
    cdef int i

    cdef int bytesArray[BYTE_HASH_LENGTH]
    for i in range(BYTE_HASH_LENGTH):
        bytesArray[i] = bytes_k[i]

    # number sign in MSB
    cdef int is_negative = (1 if bytesArray[0] < 0 else 0)

    cdef int sub
    if is_negative:
        # sub1
        for i in range((BYTE_HASH_LENGTH - 1), -1, -1):
            sub = (bytesArray[i] & 0xFF) - 1
            bytesArray[i] = (sub if sub <= 0x7F else sub - 0x100)
            if bytesArray[i] != -1:
                break

        # 1-complement
        for i in range(BYTE_HASH_LENGTH):
            bytesArray[i] = ~bytesArray[i]

    # This structure will hold the resulting trits
    cdef int trits[TRIT_HASH_LENGTH]
    trits[:] = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ]

    # The padded_trits is five trits longer than the actual trits buffer and
    # is used to help with multiplication. In the algorithm below we will need
    # multiply our current trit value by 256. To do this, we convert 256 into
    # balanced ternary and get [1, 0, 0, 1, 1, 1] and then multiply like so:
    # https://en.wikipedia.org/wiki/Balanced_ternary#Multi-trit_multiplication
    #
    # This multiplication is the same as taking our original array, copying it
    # four times, and shifting it the appropriate number of trits. Using the
    # padded trits array and the memory views makes this fairly easy.
    cdef int padding = 5
    cdef int padded_trits[248]
    padded_trits[:] = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

        0, 0, 0, 0, 0,
    ]

    cdef int[:] padded_trits_view = padded_trits
    cdef int[:] temp0 = padded_trits_view[padding:]
    cdef int[:] temp1 = padded_trits_view[padding-1:-1]
    cdef int[:] temp2 = padded_trits_view[padding-2:-2]
    cdef int[:] temp3 = padded_trits_view[padding-5:-5]

    cdef int byte_index, remainder, value, carry
    cdef int max_trit_index = padding

    for byte_index in range(BYTE_HASH_LENGTH):

        for i in range(min(TRIT_HASH_LENGTH, max_trit_index)):
            trits[i] = temp0[i] + temp1[i] + temp2[i] + temp3[i]

        max_trit_index += padding + 1

        trits[0] += bytesArray[byte_index] & 0xFF

        # Every 8 iterations go through and fix up the trit array. We need to
        # make sure that we do this frequently enough so that the values in the
        # trit array don't reach the max value for an int. At the same time, we
        # don't do this every iteration because it is fairly expensive.
        if ((byte_index + 1) % 8 == 0):
            carry = 0
            for i in range(min(TRIT_HASH_LENGTH, max_trit_index)):
                value = trits[i] + carry

                if (value > 1) or (value < -1):
                    remainder = value % 3
                    carry = value // 3

                    if remainder > 1:
                        remainder = -1
                        carry += 1

                    padded_trits[i+padding] = remainder

                else:
                    padded_trits[i+padding] = value
                    carry = 0
        else:
            for i in range(min(TRIT_HASH_LENGTH, max_trit_index)):
                padded_trits[i+padding] = trits[i]

    if is_negative:
        for i in range(TRIT_HASH_LENGTH):
            trits[i] = padded_trits[i+padding] * -1
    else:
        for i in range(TRIT_HASH_LENGTH):
            trits[i] = padded_trits[i+padding]

    return trits

def trits_to_bytes(trits):
    cdef int *trits_array
    cdef int len_trits = len(trits)
    cdef int i

    # Allocate a new array for the trits
    trits_array = <int *>malloc(len_trits*cython.sizeof(int))

    if trits_array is NULL:
        raise MemoryError()

    # trits originally come least significant trit first, but for the loop
    # below we want to work with the most significant trit first so we fill the
    # array in reverse order
    for i in range(len_trits):
        trits_array[i] = trits[len_trits - 1 - i]

    # trits will first be converted to bytes in little endian format
    cdef int little_endian_bytes[BYTE_HASH_LENGTH]
    little_endian_bytes[:] = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ]

    cdef int max_byte_index = 0
    cdef int sign = 0
    cdef int carry = 0
    cdef int value, j

    # Loop over the trits and convert them to bytes. The method being used is
    # the following:
    #
    # "Building" the number from left to right using only the base
    #
    # With this method, you start from the left in the number; for each
    # digit, you add that digit and then multiply by the base:
    #
    # For example, to convert the trits [1, 0, -1, 0, 1, 0, 1] to base 256, we
    # do it like this:
    #
    #  1                                        ["add" the next (first) digit]
    #  1 * 3 = 3                                [multiply by the base]
    #  3 + 0 = 3                                [add the next digit]
    #  3 * 3 = 9                                [multiply by the base]
    #  9 - 1 = 8                                [add the next digit]
    #  8 * 3 = 24                               [multiply by the base]
    #  24 + 0 = 24                              [add the next digit]
    #  24 * 3 = 72                              [multiply by the base]
    #  72 + 1 = 73                              [add the next digit]
    #  73 * 3 = 219                             [multiply by the base]
    #  219 + 0 = 219                            [add the next digit]
    #  219 * 3 = 657 -> 2^256 + 145 -> [145, 2] [remember the byte array is little endian]
    #  [145, 2] + 1 = [146, 2]                  [add the next digit]
    #
    # Source: http://mathforum.org/library/drmath/view/64867.html

    for i in range(len_trits):

        # The first non-zero trit will determine the sign of the number. A trit
        # of -1 means a negative number. A trit of 1 means a positive number
        if sign == 0 and trits_array[i] != 0:
            sign = trits_array[i]
        elif sign == 0 and trits_array[i] == 0:
            continue

        # When converting to bytes we'll convert the absolute value of the
        # number to bytes and then fix up the bytes later if the original
        # number was negative. The abs(trits) is just a matter of multiplying
        # all the trits by the sign so we do that here as we process each trit
        trits_array[i] = trits_array[i] * sign

        # Loop over the byte array and multiply each byte by 3. The
        # max_byte_index keeps track of the highest index in the array that we
        # should iterate to. For example, on the first loop through we will
        # only have a value for the first byte in the array, so there's no need
        # to multiply all the other 0 value bytes by 3.
        carry = 0
        for j in range(BYTE_HASH_LENGTH):
            if j > max_byte_index:
                break

            value = (little_endian_bytes[j] * 3) + carry

            if value > 255:
                max_byte_index = max(max_byte_index, j + 1)
                carry = value // 256
                value = value % 256
            else:
                carry = 0

            little_endian_bytes[j] = value

        little_endian_bytes[0] += trits_array[i]

        # Handle any overflows or underflows from the previous addition.
        for j in range(max_byte_index):
            if trits_array[i] == 1 and little_endian_bytes[j] == 256:
                little_endian_bytes[j] = 0
                little_endian_bytes[j+1] += 1
            elif trits_array[i] == -1 and little_endian_bytes[j] == -1:
                little_endian_bytes[j] = 255
                little_endian_bytes[j+1] -= 1
            else:
                break

    free(trits_array)

    cdef int bytesArray[BYTE_HASH_LENGTH]

    # Change the array to big endian and balanced
    for i in range(BYTE_HASH_LENGTH):
        if little_endian_bytes[i] <= 0x7F:
            bytesArray[BYTE_HASH_LENGTH - 1 - i] = little_endian_bytes[i]
        else:
            bytesArray[BYTE_HASH_LENGTH - 1 - i] = little_endian_bytes[i] - 0x100

    # If we had a negative number now we fix the byte array by doing
    # 1s complement and adding one
    cdef int add
    if sign < 0:
        # 1s complement
        for i in range(BYTE_HASH_LENGTH):
            bytesArray[i] = ~bytesArray[i]

        # add 1
        for i in range((BYTE_HASH_LENGTH - 1), -1, -1):
            add = (bytesArray[i] & 0xFF) + 1
            if add <= 0x7F:
                bytesArray[i] = add
            else:
                bytesArray[i] = add - 0x100
            if bytesArray[i] != 0:
                break

    return bytesArray

cdef int convert_sign(int byte):
    """
    Convert between signed and unsigned bytes
    """
    if byte < 0:
        return 256 + byte
    elif byte > 127:
        return -256 + byte
    return byte
