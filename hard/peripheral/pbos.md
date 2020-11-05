# PBOS: _Port-"B"_ Output Stream

A simple, default output device intended for limited computers, particularly those
VIA-equipped (like most 65xx devices), much like the
[PASK](pask.md) basic keyboard interface.

## Principle of operation

Pretty much like the **PASK** interface -- in an opposite way. Set in
_pulse handshake_ mode, every time a character is sent via `PB` a brief
pulse is generated from `CB2` as a **`STROBE`** indication.

### Handshake option

Note that _no flow control is specified_, although could be implemented
when needed via `CB1` input -- but usually without enabling the interrupt.
Output routine could just wait for the corresponding bit (4) to appear in `IFR`
or return an error in case of timeout. Writing to the `IORB` will clear that
flag, so data can be put quickly on the port, in any case.

### Interoperation with PASK

PBOS might send characters to another computer just equipped with PASK support,
as the interface is comparable. Connect as follows:

Sender (PBOS)|Receiver (PASK)
-----|-----
`CB2`|`CA1`
`PB0-7`|`PA0-7`
`CB1`|`CA2` \*

\*) Handshake is **not** usually implemented in PASK, but could be set if needed.

Unless full handshake is implemented, is the responsibility of the _sender_ to put
data in an appropriate rate -- don't forget PASK is intended for a _keyboard_, thus
not expected to have great throughput!

## Software support

Mostly inteded for **firmware**, a very simple driver could be installed as well.
This should have the least priority into the _Kernel driver list_, as any other I/O
driver should be se set as default device instead.

_Last modified: 2020-10-16 9:57_
