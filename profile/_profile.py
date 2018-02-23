import csv
import time
import os

from kerl import conv
from kerl.kerl import Kerl

dir_path = os.path.dirname(__file__)

start = time.time()
file = os.path.join(dir_path, '../tests/test_files/generateTrytesAndHashes')
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

        assert hashes == trytes_out, 'line:' + str(count+2) +' '+ hashes + '!=' + trytes_out

file = os.path.join(dir_path, '../tests/test_files/generateMultiTrytesAndHash')
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

file = os.path.join(dir_path, '../tests/test_files/generateTrytesAndMultiSqueeze')
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

print('Done')
print(f'Time: {time.time() - start}')
