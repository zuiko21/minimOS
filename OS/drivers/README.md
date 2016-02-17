#Driver architecture in minimOS·65
Generically speaking, a driver is a pack of **I/O routines** and/or some **interrupt tasks**. This architecture uses a **binary header** in front of each package, describing driver's features and pointing to the particular routines, rendering an uniform interface for easy installation and access.

Current header format (as of 0.5a) is as follows:
* `D_ID` is a byte holding an ID number for each driver. *This is still TBD* but will be usually a *negative* (128-255) number for **physical** devices. Numbers 128-130 and 255 *might* be reserved.
* `D_AUTH` is a byte with flags indicating present features of this driver. This is important for establishing interrupt queues as needed without useless overhead. See format below (hopefully will no longer change).
* `D_INIT` points to the **initialisation** routine, **always called by the kernel** during boot. Should end in `CLC:RTS` (the `_EXIT_OK` macro) if all was OK (or no initialisation procedure is needed), otherwise ending in `SEC:RTS` will throw an error and the driver will *not* be registered, and thus not available for I/O or interrupt tasks.
* `D_POLL` points to the** *jiffy* interrupt task** for this device, typically done about 200 times per second. *This routine will be included into the interrupt queue ONLY if enabled via the corresponding bit at* `D_AUTH`.
* `D_REQ` points to the** *asynchronous* interrupt task**, directly requested by the device. If the source of interrupt is **acknowledged**, should end in `CLC:RTS` (or `_EXIT_OK`) which *may* stop checking the remaining drivers, lowering latency; but if it wasn't, should end via `SEC:RTS` (AKA `_NEXT_ISR`) in order to continue checking. *This routine will be included into the interrupt queue ONLY if enabled via the corresponding bit at* `D_AUTH`.
* `D_CIN` points to the standard **character input**, as called by `CIN` kernel function. *Its availability is reflected on* `D_AUTH`.
* `D_COUT` points to the standard **character output**, as called by `COUT` kernel function. *Its availability is reflected on* `D_AUTH`.
* `D_SEC` points to the** *slow* interrupt task**, typically done about once per second, although accuracy is NOT guaranteed. *This routine will be included into the interrupt queue ONLY if enabled via the corresponding bit at* `D_AUTH`.
* `D_BLIN` points to the *block transfer input* routine, availability as stated in `D_AUTH`. **Not yet used** but might equally serve as a **device control** interface (TBD).
* `D_BLOUT` points to the *block transfer output* routine, availability as stated in `D_AUTH`. **Not yet used** but might equally serve as a **device control** interface (TBD).
* `D_BYE` points to the **shutdown** routine, **always called by the kernel** before poweroff. Ending in `RTS` is OK, as any error would be ignored anyway.
* `D_INFO` points to a *NULL-terminated* string, identifying the driver in a human-readable form.
* `D_MEM` is a byte indicating how many *dinamically allocated* RAM bytes takes this driver. This is intended for on-the-fly loading drivers and thus **not yet supported**, current kernel (with ROM-integrated drivers) should expect a value of **0** here.

As mentioned, currently these drivers must be integrated into the kernel ROM, via an `#include` directive into `drivers.s`, itself included into `rom.s`. **Global** driver variables are *statically* allocated into an appropriate `.h` file (usually with the same name as the driver) included into `drivers.h`.

Future plans include the ability of loading drivers *in-the-fly*, stating a non-zero `D_MEM` value and possibly stating pointers from a base address of zero, to be relocated upon loading.
