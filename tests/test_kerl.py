import random
import csv
import os
import sha3

import pytest

from kerl import conv
from kerl.kerl import Kerl


@pytest.fixture
def profile():
    # The tests that verify the files take an extremely long time to run with
    # line profiling on. Therefore, we run the tests normally without the
    # PROFILE_ON set to ensure validity and then run again with PROFILE_ON
    # to check the coverage.
    return os.getenv('PROFILE_ON')


def test_correct_hash_function():
    k = sha3.keccak_384()
    k.update("Message".encode('utf-8'))

    expected = (
        '0c8d6ff6e6a1cf18a0d55b20f0bca160d0d1c914a5e842f3'
        + '707a25eeb20a279f6b4e83eda8e43a67697832c7f69f53ca'
    )
    assert k.hexdigest() == expected


def test_correct_first():
    inp = 'EMIDYNHBWMBCXVDEFOFWINXTERALUKYYPPHKP9JJFGJEIUY9MUDVNFZHMMWZUYUSWAIOWEVTHNWMHANBH'

    trits = conv.trytes_to_trits(inp)

    kerl = Kerl()
    kerl.absorb(trits)
    trits_out = []
    kerl.squeeze(trits_out)

    trytes_out = conv.trits_to_trytes(trits_out)

    expected = 'EJEAOOZYSAWFPZQESYDHZCGYNSTWXUMVJOVDWUNZJXDGWCLUFGIMZRMGCAZGKNPLBRLGUNYWKLJTYEAQX'
    assert trytes_out == expected


def test_output_greater_243():
    inp = '9MIDYNHBWMBCXVDEFOFWINXTERALUKYYPPHKP9JJFGJEIUY9MUDVNFZHMMWZUYUSWAIOWEVTHNWMHANBH'

    trits = conv.trytes_to_trits(inp)

    kerl = Kerl()
    kerl.absorb(trits)
    trits_out = []
    kerl.squeeze(trits_out, length=486)

    trytes_out = conv.trits_to_trytes(trits_out)

    expected = (
        'G9JYBOMPUXHYHKSNRNMMSSZCSHOFYOYNZRSZMAAYWDYEIMVVOGKPJBVBM9TDPULSFUNMTVXRKFIDOHUXX'
        + 'VYDLFSZYZTWQYTE9SPYYWYTXJYQ9IFGYOLZXWZBKWZN9QOOTBQMWMUBLEWUEEASRHRTNIQWJQNDWRYLCA'
    )

    assert trytes_out == expected


def test_input_greater_243():
    inp = (
        'G9JYBOMPUXHYHKSNRNMMSSZCSHOFYOYNZRSZMAAYWDYEIMVVOGKPJBVBM9TDPULSFUNMTVXRKFIDOHUXX'
        + 'VYDLFSZYZTWQYTE9SPYYWYTXJYQ9IFGYOLZXWZBKWZN9QOOTBQMWMUBLEWUEEASRHRTNIQWJQNDWRYLCA'
    )

    trits = conv.trytes_to_trits(inp)

    kerl = Kerl()
    kerl.absorb(trits)
    trits_out = []
    kerl.squeeze(trits_out, length=486)

    trytes_out = conv.trits_to_trytes(trits_out)

    expected = (
        'LUCKQVACOGBFYSPPVSSOXJEKNSQQRQKPZC9NXFSMQNRQCGGUL9OHVVKBDSKEQEBKXRNUJSRXYVHJTXBPD'
        + 'WQGNSCDCBAIRHAQCOWZEBSNHIJIGPZQITIBJQ9LNTDIBTCQ9EUWKHFLGFUVGGUWJONK9GBCDUIMAYMMQX'
    )

    assert trytes_out == expected


def test_absorb_0_length():
    inp = (
        'G9JYBOMPUXHYHKSNRNMMSSZCSHOFYOYNZRSZMAAYWDYEIMVVOGKPJBVBM9TDPULSFUNMTVXRKFIDOHUXX'
        + 'VYDLFSZYZTWQYTE9SPYYWYTXJYQ9IFGYOLZXWZBKWZN9QOOTBQMWMUBLEWUEEASRHRTNIQWJQNDWRYLCA'
    )

    trits = conv.trytes_to_trits(inp)

    kerl = Kerl()
    with pytest.raises(ValueError) as e:
        kerl.absorb(trits, length=0)
        assert str(e) == 'trits length of 0 must be greater than zero'


def test_squeeze_invalid_length():
    inp = (
        'G9JYBOMPUXHYHKSNRNMMSSZCSHOFYOYNZRSZMAAYWDYEIMVVOGKPJBVBM9TDPULSFUNMTVXRKFIDOHUXX'
        + 'VYDLFSZYZTWQYTE9SPYYWYTXJYQ9IFGYOLZXWZBKWZN9QOOTBQMWMUBLEWUEEASRHRTNIQWJQNDWRYLCA'
    )

    trits = conv.trytes_to_trits(inp)

    kerl = Kerl()
    kerl.absorb(trits)
    trits_out = []
    with pytest.raises(ValueError) as e:
        kerl.squeeze(trits_out, length=-1)
        assert str(e) == 'trits length of 0 must be greater than zero'


def test_all_bytes():
    for i in range(-128, 128):
        in_bytes = [i] * 48
        trits = conv.convertToTrits(in_bytes)
        out_bytes = conv.trits_to_bytes(trits)

        assert in_bytes == out_bytes


def test_random_trits():
    in_trits = [random.randrange(-1, 2) for _ in range(243)]
    in_trits[242] = 0
    in_bytes = conv.trits_to_bytes(in_trits)
    out_trits = conv.convertToTrits(in_bytes)

    assert in_trits == out_trits


def test_generate_trytes_hash(profile):
    file = 'tests/test_files/generateTrytesAndHashes'
    with open(file, 'r') as f:
        reader = csv.DictReader(f)
        for count, line in enumerate(reader):
            trytes = line['trytes']
            hashes = line['Kerl_hash']

            trits = conv.trytes_to_trits(trytes)

            kerl = Kerl()
            kerl.absorb(trits)
            trits_out = []
            kerl.squeeze(trits_out)

            trytes_out = conv.trits_to_trytes(trits_out)

            assert hashes == trytes_out, f'line:{count + 2} {hashes}!={trytes_out}'

            if profile:
                break


def test_generate_multitrytes_and_hash(profile):
    file = 'tests/test_files/generateMultiTrytesAndHash'
    with open(file, 'r') as f:
        reader = csv.DictReader(f)
        for count, line in enumerate(reader):
            trytes = line['multiTrytes']
            hashes = line['Kerl_hash']

            trits = conv.trytes_to_trits(trytes)

            kerl = Kerl()
            kerl.absorb(trits)
            trits_out = []
            kerl.squeeze(trits_out)

            trytes_out = conv.trits_to_trytes(trits_out)

            assert hashes == trytes_out, f'line:{count + 2} {hashes}!={trytes_out}'

            if profile:
                break


def test_generate_trytes_and_multisqueeze(profile):
    file = 'tests/test_files/generateTrytesAndMultiSqueeze'
    with open(file, 'r') as f:
        reader = csv.DictReader(f)
        for count, line in enumerate(reader):
            trytes = line['trytes']
            hashes1 = line['Kerl_squeeze1']
            hashes2 = line['Kerl_squeeze2']
            hashes3 = line['Kerl_squeeze3']

            trits = conv.trytes_to_trits(trytes)

            kerl = Kerl()
            kerl.absorb(trits)

            trits_out = []
            kerl.squeeze(trits_out)
            trytes_out = conv.trits_to_trytes(trits_out)
            assert hashes1 == trytes_out, f'line:{count + 2} {hashes1}!={trytes_out}'

            trits_out = []
            kerl.squeeze(trits_out)
            trytes_out = conv.trits_to_trytes(trits_out)
            assert hashes2 == trytes_out, f'line:{count + 2} {hashes2}!={trytes_out}'

            trits_out = []
            kerl.squeeze(trits_out)
            trytes_out = conv.trits_to_trytes(trits_out)
            assert hashes3 == trytes_out, f'line:{count + 2} {hashes3}!={trytes_out}'

            if profile:
                break
