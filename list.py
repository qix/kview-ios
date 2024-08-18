from collections import defaultdict
import random
from pathlib import Path
from .util import path_codes

videos = Path('/Users/josh/kaleido-video/').expanduser()
all_codes = set()
for path in videos.glob('*'):
    all_codes.update(path_codes(path, include_secret=True))

secret_codes = set([code for code in all_codes if len(code) != 1])

def map_char(letter: str):
    if letter.lower() in ("0",):
        return "0"
    elif letter.lower() in ("1",):
        return "1"
    elif letter.lower() in ("2", "a", "b", "c"):
        return "2"
    elif letter.lower() in ("3","d", "e", "f"):
        return "3"
    elif letter.lower() in ("4","g", "h", "i"):
        return "4"
    elif letter.lower() in ("5","j", "k", "l"):
        return "5"
    elif letter.lower() in ("6","m", "n", "o"):
        return "6"
    elif letter.lower() in ("7","p", "q", "r", "s"):
        return "7"
    elif letter.lower() in ("8","t", "u", "v"):
        return "8"
    elif letter.lower() in ("9","w", "x", "y", "z"):
        return "9"
    return "?"

def map_code(code: str):
    return ''.join([map_char(char) for char in code])

all_numbers = defaultdict(list)
for code in all_codes:
    all_numbers[map_code(code)].append(code)

def print_codes(codes):
    for code in sorted(codes, key=lambda code: (len(code) if code.isdigit() else 999, code)):
        print(code)


print('=== ALL ===')
print_codes(all_codes)
print()

print('=== SUBSET (10) ===')
print_codes(random.sample(list(secret_codes), k=10))
print()

print('=== COLLISIONS ===')
collisions = {number: codes for number, codes in all_numbers.items() if len(codes) > 1}
if collisions:
    for number, codes in collisions.items():
        print(f'{number}: ' + ', '.join(codes))
else:
    print('-- none --')
print()
