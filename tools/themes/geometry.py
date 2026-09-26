"""Theme geometry dispatcher; defaults and earlier cosmetics are never edited."""
def detail(mesh,key):
    if key in ('abyssal','crystalborn'):
        from .wild import detail as build
    elif key in ('corsair','overgrown'):
        from .heritage import detail as build
    elif key=='toybox':
        from .toybox import detail as build
    else:raise ValueError(key)
    return build(mesh,key)
