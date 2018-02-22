# cython: linetrace=True

from sha3 import keccak_384

from . import conv

__all__ = [
    'Kerl',
]

BYTE_HASH_LENGTH = 48
TRIT_HASH_LENGTH = 243

class Kerl:

    def __init__(self):
        self.k = keccak_384()

    def absorb(self, trits, offset=0, length=None):
        """
        Absorb trits into the sponge from a buffer.

        :param trits:
          Buffer that contains the trits to absorb.

        :param offset:
          Starting offset in ``trits``.

        :param length:
          Number of trits to absorb.  Defaults to ``len(trits)``.
        """
        # Pad input if necessary, so that it can be divided evenly into
        # hashes.
        # Note that this operation creates a COPY of ``trits``; the
        # incoming buffer is not modified!
        pad = ((len(trits) % TRIT_HASH_LENGTH) or TRIT_HASH_LENGTH)
        trits += [0] * (TRIT_HASH_LENGTH - pad)

        if length is None:
            length = len(trits)

        if length < 1:
            raise ValueError(f'trits length of {length} must be greater than zero')

        while offset < length:
            stop = min(offset + TRIT_HASH_LENGTH, length)

            # If we're copying over a full chunk, zero last trit
            if stop - offset == TRIT_HASH_LENGTH:
                trits[stop - 1] = 0

            signed_nums = conv.convertToBytes(trits[offset:stop])

            # Convert signed bytes into their equivalent unsigned representation
            # In order to use Python's built-in bytes type
            unsigned_bytes = bytearray(conv.convert_sign(b) for b in signed_nums)

            self.k.update(unsigned_bytes)

            offset += TRIT_HASH_LENGTH

    def squeeze(self, trits, offset=0, length=None):
        """
        Squeeze trits from the sponge into a buffer.

        :param trits:
            Buffer that will hold the squeezed trits.

            IMPORTANT:  If ``trits`` is too small, it will be extended!

        :param offset:
            Starting offset in ``trits``.

        :param length:
            Number of trits to squeeze from the sponge.

            If not specified, defaults to :py:data:`TRIT_HASH_LENGTH` (i.e.,
            by default, we will try to squeeze exactly 1 hash).
        """
        # Pad input if necessary, so that it can be divided evenly into
        # hashes.
        pad = ((len(trits) % TRIT_HASH_LENGTH) or TRIT_HASH_LENGTH)
        trits += [0] * (TRIT_HASH_LENGTH - pad)

        if length is None:
            # By default, we will try to squeeze one hash.
            # Note that this is different than ``absorb``.
            length = len(trits) or TRIT_HASH_LENGTH

        if length < 1:
            raise ValueError(f'trits length of {length} must be greater than zero')

        while offset < length:
            unsigned_hash = self.k.digest()

            signed_hash = [conv.convert_sign(b) for b in unsigned_hash]

            trits_from_hash = conv.convertToTrits(signed_hash)
            trits_from_hash[TRIT_HASH_LENGTH - 1] = 0

            stop = min(TRIT_HASH_LENGTH, length-offset)
            trits[offset:offset+stop] = trits_from_hash[0:stop]

            flipped_bytes = bytearray(conv.convert_sign(~b) for b in unsigned_hash)

            # Reset internal state before feeding back in
            self.reset()
            self.k.update(flipped_bytes)

            offset += TRIT_HASH_LENGTH

    def reset(self):
        self.k = keccak_384()
