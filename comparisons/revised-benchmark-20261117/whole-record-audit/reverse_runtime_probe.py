"""A finite discriminator for the proposed runtime-extent premise, independent of XLA."""
import json
from itertools import permutations


def observation(input_shape, output_shape):
    # Stored bounds (2, 2) and (1, 2, 2), inserted axis 0.
    # Requested output axis 1 maps to input axis 0.
    rows, cols = input_shape
    unit, out_rows, out_cols = output_shape
    data = [11, 29]
    assert unit == 1 and rows * cols == out_rows * out_cols == len(data)
    assert all(1 <= x <= 2 for x in (*input_shape, out_rows, out_cols))
    original = [data[(out_rows - 1 - r) * out_cols + c]
                for r in range(out_rows) for c in range(out_cols)]
    replacement = [data[(rows - 1 - r) * cols + c]
                   for r in range(rows) for c in range(cols)]
    return {'input': input_shape, 'output': output_shape, 'original': original,
            'replacement': replacement, 'retained_extents_match': input_shape == output_shape[1:]}


if __name__ == '__main__':
    cases = [observation(s, (1, *t)) for s in permutations((1, 2))
             for t in permutations((1, 2))]
    assert all((c['original'] == c['replacement']) == c['retained_extents_match'] for c in cases)
    print(json.dumps(cases, indent=2))
