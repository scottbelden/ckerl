# ckerl

Cython implementation of the Kerl hash function

# Install

`pip install ckerl`

# Example

```python
from ckerl import Kerl
from ckerl import trytes_to_trits, trits_to_trytes

k = Kerl()

input = 'EMIDYNHBWMBCXVDEFOFWINXTERALUKYYPPHKP9JJFGJEIUY9MUDVNFZHMMWZUYUSWAIOWEVTHNWMHANBH'
trits = trytes_to_trits(input)

k.absorb(trits)
trits_out = []
k.squeeze(trits_out)

trytes_out = trits_to_trytes(trits_out)

print(trytes_out)
# EJEAOOZYSAWFPZQESYDHZCGYNSTWXUMVJOVDWUNZJXDGWCLUFGIMZRMGCAZGKNPLBRLGUNYWKLJTYEAQX
```
