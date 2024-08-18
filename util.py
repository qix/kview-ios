
from pathlib import Path

videos = Path('/Users/josh/kaleido-video/').expanduser()

def path_codes(path: Path, *, include_secret: bool):
    if path.stem.startswith('.'):
        return []
    parts = path.stem.split('__')[0].split('_')
    codes = [code.upper() for code in parts]

    if include_secret:
        return [code[1:] if code.startswith('!') else code for code in codes]
    return [code for code in codes if not code.startswith('!')]

