"""Expected native well-formedness outcomes, not tensor-value evaluation."""


def expected_rows():
    return [(name,mode,'checked_fatal' if name in ('empty_inserted','constant_indices') and mode!='control' else 'valid',
             'unreturned' if name in ('empty_inserted','constant_indices') and mode!='control' else
             '1' if mode!='control' and (name!='layout_sensitive' or mode=='pass') else '0')
            for name in ('empty_inserted','nonempty','empty_retained','both_empty',
                         'layout_sensitive','constant_indices','constant_conversion')
            for mode in ('control','handler','pass')]
