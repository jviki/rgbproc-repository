Repository rgbproc
==================

Repository is intended for use with Xilinx EDK tools. It is
divided (as required) to _boards_ and _pcores_ directories.
First one contains board definitions and the following one
libraries and hardware units that can be used to build a
design (typically using Xilinx XPS tool).


Boards
------

Currently there is only one board description available because
it was the target of the _rgbproc_ repository development.

### Xilinx ML506 with video

The board is derived from original Xilinx board description for
ML506 board. It is extended by connections to AD9980 and CH7301C
codecs. For both of them an IO_TYPE is defined as VGA_IN and
DVI_OUT (but CH7301C is capable of output VGA as well).


Processing cores (pcores)
-------------------------

The repository consists of many units that can be used to
build a design for image/video processing. The backbone
is the data bus called simply _RGB_ that is used to pass
data (typically) from VGA input to VGA/DVI output.

The most common units are described in the following text.


### Unit `rgb_in`

Unit is intended to transform incoming VGA (coming from AD9980 codec
in digital form) signal to the internal data bus called _RGB_. It
assumes (hardcoded) resolution 640x480 and the system is preset to
process data at 25 MHz. After several modifications (updating
constraints, changing internal constants of `rgb_in`) it should be
able to process even greater resolutions at faster clock.

The major computation done in `rgb_in` is determining of valid pixel
data. Thus it generates DE signal of _RGB_ bus. All other signals
are simply passed through the unit.


### Unit `rgb_out`

Unit is intended to transform incoming _RGB_ bus data to protocol
used by CH7301C codec. The most important signal is DE flag that
is passed to the codec unchanged.

The unit transforms the channels (R, G, B) to IDF0 encoding defined
in CH7301C specification. The resulting data are then send to the
codec in double data rate (DDR).


### Unit `rgb_shreg`

Unit can be used to introduce a delay in the pipeline or as an example
unit. Eg. after few modifications it could be used as a simple buffer.


### Unit `rgb_split`

Unit splits the _RGB_ bus to two independed _RGB_ buses which can be
processed in parallel.


### Unit `rgb_mux`

Multiplexor on _RGB_ bus. Selects one from two source lines that is
passed to the output. The multiplexor control can be done over IPIF
interface which can be connected to some PLBv46 endpoint provided by
Xilinx.

When a request to changed to source line is made the multiplexor does
not perform it immediately. Instead it waits for vertical synchronization
to do it. So it should never damage any frame.


### Unit `rgb_line_buff`

Buffer of one line of an _RGB_ frame. It provides direct access to any number
of its elements. It is intended to support filtering.


### Unit `rgb_win`

Constructs a sliding window that can be used by filters (currently supports
only 3x3 window size). It is connected to a number of `rgb_line_buff` units to
get few pixels of every line. Output from the unit is _k_-dimensional _RGB_ bus
where _k_ is the size of window (3x3 = 9).


### Unit `design_id`

Unit that provides meta information to software over IPIF interface which
can be connected to PLB bus and thus to MicroBlaze. Serves _design id_,
_design version_, _design name_ (four characters) and _negation_ register
to test the communication.
