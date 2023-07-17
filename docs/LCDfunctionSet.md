Selecting 4-bit or 8-bit mode requires careful selection of commands. There are two primary considerations. First, with D3–D0 unconnected, these lines will always appear high (binary 1111) to the HD44780 since there are internal pull-up MOSFETs.[3] Second, the LCD may initially be in one of three states:

State 1: 8-bit mode
State 2: 4-bit mode, waiting for the first set of 4 bits
State 3: 4-bit mode, waiting for the second set of 4 bits
State 3 may occur, for example, if a prior control was aborted after sending only the first 4 bits of a command while the HD44780 was in 4-bit mode.

The following algorithm ensures that the LCD is in the desired mode:

The same command is sent three times, Function Set with 8-bit interface D7–D4 = binary 0011, the lower four bits are "don't care", using single enable pulses. If the controller is in 4-bit mode, the lower four bits are ignored so they cannot be sent until the interface is in a known size configuration.

Starting in state 1 (8-bit configuration):

Send Function Set command. Command will be executed, set 8-bit mode.
Send Function Set command. Command will be executed, set 8-bit mode.
Send Function Set command. Command will be executed, set 8-bit mode.
Starting in state 2 (4-bit configuration, waiting for first 4-bit transfer):

Send Function Set command. First 4 bits received.
Send Function Set command. Last 4 bits, command accepted, set 8-bit mode.
Send Function Set command. Command will be executed, set 8-bit mode.
Starting in state 3 (4-bit configuration, waiting for last 4-bit transfer):

Send Function Set command. Last 4 bits, unknown command executed.
Send Function Set command. In 8-bit mode command will be executed, otherwise first 4 bits received.
Send Function Set command. 8-bit command will be executed or last 4 bits of previous command; set 8-bit mode.
In all three starting cases, the bus interface is now in 8-bit mode, 1 line, 5×8 characters. If a different configuration 8-bit mode is desired, an 8-bit bus Function Set command should be sent to set the full parameters. If 4-bit mode is desired, binary 0010 should be sent on D7–D4 with a single enable pulse. Now the controller will be in 4-bit mode and a full 4-bit bus Function Set command sequence (two enables with command bits 7–4 and 3–0 on subsequent cycles) will complete the configuration of the Function Set register.