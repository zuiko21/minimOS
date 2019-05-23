# miniPET

This is an _accurate *recreation*_ of a **Commodore PET 8032**, albeit
with more modern components. Performance is expected to be the same, save for
somewhat _reduced power consumption_ (and noticeably lower component count).

Since the original PET range include a CRT monitor, adequate compatibility with
current external monitors must be provided. The internal monitor on the 4000/8000
series worked at an unusual **20 kHz** horizontal rate. For compatibility with
current standards, two options are considered:

1) Tweaking the CRTC registers to achieve **~15.7 kHz** horizontal scan, essentialy
by _enlarging porchs_.
2) Speed things up for **VGA** compatibility (at **31.5 kHz** scan rate).

The later option adds much more complexity, but seems quite interesting. That would mean:

- Duplicate scanlines per char (another CRTC tweak). _This means a different arranging
of CRTC raster address lines_.
- Optionally, redesigning PETSCII font in an 8x16 fashion.
- Speeding up CPU up to ~1.57 MHz.



*Last modified: 20190523-1209*
