#Driver architecture in minimOS·65
Generically speaking, a driver is a pack of **I/O routines** and/or some **interrupt tasks**. This architecture has a **binary header** in front of each package, describing driver's features and pointing to the particular routines, rendering an uniform interface for easy installation and access.

Current format (as of 0.5a) is as follows:
* `D_ID` holds an ID number for each driver. *This is still TBD* but will be usually a *negative* (128-255) number for **physical** devices. Numbers 128-130 and 255 *might* be reserved.
* `D_AUTH` is a byte with flags indicating present features of this driver. This is important for establishing interrupt queues as needed without useless overhead. See format below (hopefully will no longer change).
* `D_INIT` points to the **initialisation** routine, **always called by the kernel** during boot. Should end in `CLC:RTS` if all OK (or no initialisation procedure is needed), otherwise ending in `SEC:RTS` will throw an error and the driver will *not* be registered, and thus not available for I/O or interrupt tasks.
* `D_POLL`
* `D_REQ`
* `D_CIN`
* `D_COUT`
* `D_SEC`
* `D_SIN`
* `D_SOUT`
* `D_BYE` points to the **shutdown** routine, **always called by the kernel** before poweroff. Ending in `RTS` is OK, as any error would be ignored anyway.
* `D_INFO`
* `D_MEM`

