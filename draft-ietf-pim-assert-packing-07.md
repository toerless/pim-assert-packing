---

title: PIM Assert Message Packing
abbrev: assert-packing
docname: draft-ietf-pim-assert-packing-07
category: std
stream: IETF
wg: PIM
ipr: trust200902
updates: RFC7761, RFC3973

stand_alone: yes
pi: [ toc, tocdepth: 5, sortrefs, symrefs, comments]

author:
  -
    name: Yisong Liu
    role: editor
    org: China Mobile
    role: editor
    country: China
    email: liuyisong@chinamobile.com
  -
    name: Mike McBride
    org: Futurewei
    country: USA
    email: michael.mcbride@futurewei.com
  -
    name: Toerless Eckert
    org: Futurewei
    role: editor
    country: USA
    email: tte@cs.fau.de
  -
    name: Zheng(Sandy) Zhang
    org: ZTE Corporation
    country: China
    email: zhang.zheng@zte.com.cn

normative:
  RFC2119:
  RFC3973:
  RFC7761:
  RFC8174:
  RFC8736:

informative:
  RFC6037:

--- abstract

LANs often have more than one upstream router.
When PIM Sparse Mode (PIM-SM), including PIM-SSM, is used, this
can lead to duplicate IP multicast packets being forwarded by these
PIM routers.  PIM Assert messages are used to elect a single forwarder for
each IP multicast traffic flow between these routers.

This document defines a mechanism to send
and receive information for multiple IP multicast flows 
in a single PackedAssert message. This optimization reduces the
total number of PIM packets on the LAN and can therefore speed up
the election of the single forwarder, reducing the number of duplicate IP
multicast packets incurred.

--- middle

# Introduction

In PIM-SM shared LAN networks, there is typically more than one
upstream router. When duplicate data packets appear on the LAN, from
different upstream routers, assert packets are sent from these
routers to elect a single forwarder according to {{RFC7761}}. The PIM
assert messages are sent periodically to keep the assert state. The
PIM assert message carries information about a single multicast
source and group, along with the corresponding metric-preference and
metric of the route towards the source or RP.

This document defines a mechanism to encode the information of 
multiple PIM Assert messages into a single PackedAssert message.
This allows to send and receive information for multiple IP multicast flows 
in a single PackedAssert message without changing the PIM Assert state
machinery. It reduces the total number of PIM packets on the LAN and can
therefore speed up the election of the single forwarder, reducing the number
of duplicate IP multicast packets.  This can particularly be helpful when
there is traffic for a large number of multicast groups or SSM channels and
PIM packet processing performance of the routers is slow.

## Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
BCP 14 {{RFC2119}} {{RFC8174}} when, and only when, they appear in all
capitals, as shown here.

## Terminology

The reader is expected to be familiar with the terminoloy of {{RFC7761}}. The following lists the abbreviations repeated in this document.

AT: Assert Timer

RP: Rendezvous Point

RPF: Reverse Path Forwarding

SPT: Shortest Path Tree

RPT: RP Tree

DR: Designated Router

# Problem statement 

PIM Assert occur in many deployments. See {{use-case-examples}}
for some explicit examples.

PIM assert state depends mainly on the network topology.
As long as there is a layer 2 network with more than 2 PIM routers,
there may be multiple upstream routers, which can cause duplicate
multicast traffic to be forwarded and assert process to occur.

As the multicast services become widely deployed, the
number of multicast entries increases, and a large number of assert
messages may be sent in a very short period when multicast data
packets trigger PIM assert processing in the shared LAN networks.
The PIM routers need to process a large number of PIM assert small
packets in a very short time. As a result, the device load is very
large. The assert packet may not be processed in time or even
discarded, thus extending the time of traffic duplication in the
network.

The PIM Assert mechanism can only be avoided by designing the network
to be without transit subnets with multiple upstream routers. For
example, an L2 ring between routers can sometimes be reconfigured to be a ring
of point-to-point subnets connected by the routers. These L2/L3 topology
changes are undesirable though, when they are only done to enable IP multicast
with PIM because they increase the cost of introducing IP multicast with PIM.

These designs are also not feasible when specific L2 technologies are needed.
For example various L2 technologies for rings provide sub 50msec failover
mechanisms, something not possible equally with an L3 subnet based ring. 
Likewise, IEEE Time Sensitive Networking mechanisms would require an
L2 topology that can not simply be replaced by an L3 topology.
L2 sub-topologies can also significantly reduce the cost of deployment.

# Specification

This document defines three elements in support of PIM assert packing:

1. The PIM Hello Assert Packing Option.
2. The encoding of PackedAssert messages.
2. How to send and receive PackedAssert messages.

## PIM Hello Assert Packing Option

The PIM Assert Packing Hello Option ({{assert-packing-option}}) is used to announce support
for the assert packing mechanisms specified in this document.
PackedAssert messages ({{assert-packing-formats}}) MUST
only be sent when all PIM routers in the same subnet announce this option.

## Assert Packing Message Formats {#assert-packing-formats}

The message body of an {RFC7761}}, Section 4.9.6, PIM Assert message, except
for its first four bytes of header, describes the parameters of a (\*,G) or
(S,G) assert through the following information elements:
 R(PT), Source Address, Group Address, Metric and Metric Preference.
This document calls this information an assert record.

Assert packing introduces two new PIM Assert message encodings through the allocation
and use of two {{RFC8736}} specified flags in the PIM Assert message header,
the P)acked and the A)ggregated flag.

If the P)acked flag is 0, the message is a (non-packed) PIM Assert message
as specified in {{RFC7761}}. See {{rfc7761-assert-message}}. In this case,
the A)ggregated flag MUST be set to 0. If the P)acked flag
is 1), then the message is called a PackedAssert message and the type and hence
 encoding format of the payload is determined by the A)ggregated flag.

If A=0, then the message body is a sequence of assert records
preceeded by a count. This is called a "Simple PackedAssert" message. See {{simple-packedassert-message}}.

If A=1, then the message body is a sequence of aggregated assert records
preeeded by a count. This is called an "Aggregated PackedAssert". See {{aggregated-packedassert-message}}.

Two aggregated assert record types are specified.


The "Source Aggregated Assert Record", see {{s-assert-record}},
encodes one (common) Source Address, Metric and Metric Preference as well as a list
of one or more Group Addresses with a Count.  Source Aggregated Assert Records provide
a more compact encoding than the Simple PackedAssert message format when multiple (S,G) flows share the same source S. 
A single Source Aggregated Assert Record with n Group Addresses represents the information of
assert records for (S,G1)...(S,Gn). 

The "RP Aggregated Assert Record", see {{rp-assert-record}},
encodes one common Metric and Metric Preference as
well as a list of "Group Records", each of which encodes a Group Address
and a list of zero or more Source Addresses with a count. This is called an
"RP Aggregated Assert Record", because with standard RPF according to ({{RFC7761}}),
all the Group Addresses that use the same RP will have the same Metric and Metric Preference.

RP Aggregation Records provide a more compact encoding than the Simple PackedAssert message format
for (*,G) flows.  The Source Address option is optionally used by {{RFC7761}} assert procedures
to indicate the source(s) that triggered the assert, otherwise it is 0.

Both Source Aggregated Assert Records and RP Aggregated Assert Records also include the
R)PT flag which maintains its semantic from {{RFC7761}} but also distinguishes
the encodings. Source Aggregated Assert Records have R=0, as (S,G) assert records do in {{RFC7761}}.
RP Aggregated Assert Records have R=1, as (*,G) assert records do in {{RFC7761}}.

## PackedAssert Mechanism

PackedAsserts do not change the {{RFC7761}} PIM assert state machine specification. Instead,
sending and receiving of PackedAssert messages as specified in the following subsections is logically
a layer in between sending/receiving of Assert messages and serialization/deserialization of
their respective packets. There is no change in in the information elements of the transmitted
information elements constituting the assert records not their semantics. Only the compactness
of their encoding.

### Sending PackedAssert messages

When using assert packing, the regular {{RFC7761}} Assert message encoding with A=0 and P=0 is
still allowed to be sent.  Router are free to choose which PackedAssert message type they send. If a router chooses
to send PacketAssert messages, then it MUST comply to the requirements in the remainder
of this section. Implementations SHOULD NOT send only Asserts (but no PackedAsserts) in all
cases when all routers on the LAN do support Assert Packing.

Routers SHOULD specify in documentation and/or management interfaces (such as a YANG model),
which PackedAssert message types they can send and under which conditions they do - such
as for data-triggered asserts or Assert Timer (AT) expiry based asserts. 

To send a PackedAssert message, when a PIM router has an assert record ready to sent according to the
pseudocode "send Assert(...)" in {{RFC7761}}, it will not immediately proceed
in generating a PIM Assert message from it. Instead, it will remember it
for assert packing and proceed with PIM assert processing for other (S,G) and (\*,G) flows that will
result in further (S,G) or (\*,G) assert records until one or more of the following conditions
is met and only then send the PackedAssert message(s).

1. RECOMMENDED: Further processing would cause additional delay for sending the PackedAssert message.
2. OPTIONAL: Further processing would cause "relevant"(\*) delay for sending the PackedAssert message.
2. OPTIONAL: The router has packed a "sufficient"(\*) number of assert records for a PackedAssert message.
3. There is no further space left in a possible PackedAssert message or the implementation does not want to pack further assert records.

(\*) "relevant" and "sufficient" are defined in this section below.

Avoiding additional relevant delay is most criticial for asserts that are triggered by reception
of data or reception of asserts against which this router is the assert winner, because it needs to
send out an assert to the (potential) assert looser(s) as soon as possible to minimize the time in
which duplicate IP multicast packets can occur.

To avoid additional delay in this case, the router SHOULD employ appropriate
assert packing and scheduling mechanisms, such as for example the following.

Asserts/PackedAsserts in this case are scheduled for serialization with highest priority, such
that they bypass any potentially earlier scheduled other packets.
When there is no such Assert/PacketAssert message scheduled for or being serialised,
the router immediately serializes an Assert or PackedAssert message without further assert packing.
If there are one or more Assert/PackedAssert messages serialized and/or scheduled to be serialized,
then the router can pack assert records into new PackedAssert messages until shortly before the
last of those Assert/PackedAssert packets has finished serializing. 

Asserts triggered by expiry of the AT on an assert winner are not time-critical because
they can be scheduled in advance and because the Assert_Override_Interval parameter of {{RFC7761}} already
creates a 3 second window in which such assert records can be sent, received, and processed before
an assert loosers state would expire and duplicate IP multicast packets could occur.

An example mechanism to allows packing of AT expiry triggered assert records on assert winners is
to round the AT to an appropriate granularity such as 100msec.  This will cause AT for multiple
(S,G) and/or (\*,G) states to expire at the same time, thus allowing them to be easily packed
without changes to the assert state machinery.

AssertCancel messages have assert records with an infinite metric and can use assert packing
as any other Assert. They are sent on Override Timer (OT) expiry and can be packed for example
with the same considerations as AT expiry triggered assert records.

Additional delay is not "relevant" when it still causes the overall amount of (possible) duplicate
IP multicast packets to decrease in a condition with large number of (S,G) and/or (\*,G), compared
to the situation in which no delay is added by the implementation.

This can simply be the case because the implementation can not afford to implement the (more advanced)
mechanisms described above, and some simpler mechanism that does introduce some additional delay
still causes more overall reduction in duplicate IP multicast packets than not sending PackedAsserts at all,
but only Asserts. 

"Relevant" is a highly implementation dependent metric and can typically only be measured 
against routers of the same type as receivers, and performance results with other routers will likely
differ. Therefore it is optional.

When Asserts are sent, a single packet loss will result only in continued or new
duplicates from a single IP multicast flow.  Loss of (non AssertCancel) PackedAssert impacts
duplicates for all flows packed into the PackedAssert and may result in the need
for re-sending more than one Assert/PacketAssert, because of the possible inability to pack them.
Routers SHOULD therefore support mechanisms allowing for PackedAsserts and Asserts to
be sent with an apropriate DSCP, such as Expedited Forwarding  (EF), to minimize their loss, especially
when duplicate IP multicast packets could cause congestion and loss.

Routers MAY support a configurable option for sending PackedAssert messages twice in short order
(such as 50msec apart), to overcome possible loss, but only a) if the total size of the two PackedAsserts
is less than the total size of equivalent Assert messages, and b) if the {{RFC7761}} conditions that caused
the assert records in the PackedAssert message make the router believe that reception of either copies
of the PackedAssert message will not trigger sending of Assert/PackedAssert.

It is "sufficient" that assert records are not packed up to MTU size, but to a size that
allows the router to achieve the required operating scale of (S,G) and (\*,G) flows with minimum duplicates.
This packing size may be larger when the network is operating with the maximum number of supported multicast
 flows, and it can be a smaller packing size when operating with fewer multicast flows. Larger than "sufficient"
packets may then not provide additional benefits, because they only reduce the performance requirements for
packet sending and reception, and other performance limiting factors may take over once
a "sufficient" size is reached. And larger packets can incur more duplicates on loss.
Considering a "suggifient" amount of packing minimizes the negative impacts of loss of PackedAssert packets
without loss of (minimum packet duplication) performance.

Like "relevant", "sufficient" is highly implementation dependent and hence only optional.

### Receiving PackedAssert messages

Upon reception of a PackedAssert message, the PIM router logically
converts its payload into a sequence of assert records that are then processed
as if an equivalent sequence of Assert messages where received according to {{RFC7761}}.

# Packet Formats

This section describes the format of new PIM messages introduced by
this document.

## PIM Assert Packing Hello Option {#assert-packing-option}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |      OptionType = TBD         |      OptionLength = 0         |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-HELLO-OPTION title="PIM Assert Packing Hello Option"}

- TBD
    PIM Packed Assert Capability Hello Option

Including the PIM OptionType TBD indicates support for the ability to
receive and process all the PackedAssert encodings defined in this document.

## Assert Message Format {#rfc7761-assert-message}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |PIM Ver| Type  | Reserved  |A|P|           Checksum            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Group Address (Encoded-Group format)             |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |            Source Address (Encoded-Unicast format)            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                      Metric Preference                      |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                             Metric                            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-MESSAGE-ASSERT title="Assert"}

When assert packing is used on a subnet, routers MUST send Assert messages
according to above format. This is exactly the same format as the one defined
in {{RFC7761}} but the A and P flags are not reserved, but distinguish
this Assert Message Format from those newly defined in this document.

- P)acked: MUST be 0.

- A)ggregated: MUST be 0.

All other field according to {{RFC7761}}, Section 4.9.6.

## Simple PackedAssert Message Format {#simple-packedassert-message}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |PIM Ver| Type  | Reserved  |A|P|           Checksum            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |      Count                    |  Reserved(2)                  |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                        Assert Record [1]                      .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                        Assert Record [2]                      .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                               .                               |
    .                               .                               .
    |                               .                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                        Assert Record [M]                      .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-MESSAGE-SIMPLE title="Simple PackedAssert"}

- PIM Version, Type, Checksum, Reserved

    As specified in Section 4.9.6 of {{RFC7761}}.

- Reserved(2)
     Set to zero on transmission.  Ignored upon receipt.

- P)acked: MUST be 1.

- A)ggregated: MUST be 0.

- Count

    The number of packed Assert Records in the message.

The format of each Assert Record is the same as the PIM assert message body as specified in Section 4.9.6 of {{RFC7761}}.

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Group Address (Encoded-Group format)             |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |            Source Address (Encoded-Unicast format)            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                      Metric Preference                      |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                             Metric                            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-ASSERT-RECORD-FORMAT title="Assert Record"}

## Aggregated PackedAssert Message Format {#aggregated-packedassert-message}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |PIM Ver| Type  | Reserved  |A|P|           Checksum            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Count  (M)       |  Reserved                     |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                     Aggregated Assert Record [1]              .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                     Aggregated Assert Record [2]              .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                               .                               |
    .                               .                               .
    |                               .                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                     Aggregated Assert Record [M]              .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-PACKET-FORMAT-SG title="Aggregated PackedAssert"}

- PIM Version, Type, Reserved, Checksum

    As specified in Section 4.9.6 of {{RFC7761}}.

- P)acked: MUST be 1.

- A)ggregated: MUST be 1.

- Count

    The number of Aggregated Assert Records following in the message.
    Each of these records can either be a Source Aggregated or RP aggregated Assert Record.

### Source Aggregated Assert Record {#s-assert-record}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                      Metric Preference                      |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                             Metric                            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |            Source Address (Encoded-Unicast format)            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |        Number of Groups (N)   |           Reserved            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                 Group Address 1 (Encoded-Group format)        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                 Group Address 2 (Encoded-Group format)        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                             .                                 |
    |                             .                                 |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                 Group Address N (Encoded-Group format)        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-RECORD-FORMAT-SG title="Source Aggregated Assert Record"}

- Reserved
     Set to zero on transmission.  Ignored upon receipt.

- R: MUST be 0.

    R indicates both that the encoding format of the record is that of a Source Aggregated Assert Record,
    but also that all assert records represented by the Source Aggregated Assert Record have R=0 and are therefore
    (S,G) assert records according to the definition of R in {{RFC7761}}, Section 4.9.6.

- Source Address, Metric Preference, Metric 

    As specified in Section 4.9.6 of {{RFC7761}}.  Source Address MUST NOT be zero.

- Number of Groups

    The number of Group Address fields.

- Group Address

    As specified in Section 4.9.6 of {{RFC7761}}.

### RP Aggregated Assert Record {#rp-assert-record}

An RP Aggregation Assert record aggregates (\*,G) assert records with
the same Metric Preference and Metric. Typically this is the case
for all (\*,G) using the same RP, but the encoding is not limited
to only (\*,G) using the same RP because the RP address is not
encoded as it is also not present in {{RFC7761}} assert records.

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                      Metric Preference                      |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                             Metric                            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |   Number of Group Records (K) |           Reserved            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                        Group Record [1]                       .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                        Group Record [2]                       .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                               .                               |
    .                               .                               .
    |                               .                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                                                               |
    .                                                               .
    .                        Group Record [K]                       .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-RECORD-FORMAT-RP title="RP Aggregated Assert Record"}

- R: MUST be 1.

    R indicates both that the encoding format of the record is that of an RP Aggregated Assert Record,
    and that all assert records represented by the RP Aggregated Assert Record have R=1 and are therefore
    (\*,G) assert records according to the definition of R in {{RFC7761}}, Section 4.9.6.

- Metric Preference, Metric

    As specified in Section 4.9.6 of {{RFC7761}}.

- Reserved
    Set to zero on transmission.  Ignored upon receipt.

- Number of Group Records

    The number of packed Group Gecords. A record consists of a Group
    Address and a Source Address list with a number of sources.

The format of each Group Record is:

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Group Address (Encoded-Group format)             |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |        Number of Sources (P)  |           Reserved            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Source Address 1 (Encoded-Unicast format)        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Source Address 2 (Encoded-Unicast format)        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                             .                                 |
    |                             .                                 |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Source Address P (Encoded-Unicast format)        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-GROUP-RECORD title="Group Record"}

- Group Address and Reserved

    As specified in Section 4.9.6 of {{RFC7761}}.

- Reserved
     Set to zero on transmission.  Ignored upon receipt.

- Number of Sources

    The Number of Sources is corresponding to the number of Source Address fields in the Group Record.
    If this number is 0, the Group Record indicates one assert record with a Source Address of 0.
    If this number is not 0 and one of the (\*,G) assert records to be encoded should have
    the Source Address 0, then 0 needs to be encoded as one of the Source Address fields.

- Source Address

    As specified in Section 4.9.6 of {{RFC7761}}.
    But there can be multiple Source Address fields in the Group Record.

# Updates from RFC3973 and RFC7761

This document introduces two new flag bits to the PIM Assert message type,
as defined in {{assert-packing-formats}}, the P)acked and A)aggregated bits.
When both bits are zero, the packet is an otherwise encoding and semantically
unchanged PIM Assert message.

Requirements for the use of P and A flag with other values than zero 
are specified in this document only for use with {{RFC7761}}. These
requirements do not apply to {{RFC3973}} solely because of lack of
interest in the use of the mechanisms specified in this document together with {{RFC3973}}.

\[RFC-Editor: pls. remove this sentence: RFC3973 should be historic by now, and it is only mentioned at all because of the fact that the "PIM Message Type Registry" mentions it, and this document mentions that registry. Depending on IETF/IESG review, the authors would prefer if we could remove all mentioning of RFC3973 in this document, because it may just confuse readers.]

# IANA Considerations


    +======+========================+===============+
    | Type |     Description        | Reference     |
    +======+========================+===============+
    | TBD  |Packed Assert Capability| This Document |
    +======+========================+===============+
{: #FIG-IANA-ASK }

IANA is requested to allocate a new code points from the "PIM-Hello
Options" registry for TBD.

    +======+========+=================+====================+
    | Type | Name   | Flag Bits       | Reference          |
    +======+========+=================+====================+
    |   5  | Assert | 2-7: Reserved   | [RFC3973][RFC7761] |
    |      |        |   1: Aggregated | [This Document]    |
    |      |        |   0: Packed     | [This Document]    |
    +======+========+=================+====================+
{: #FIG-IANA-ASK2 }

IANA is asked to add the definition of the Aggregated and Packed
Flags Bits for the PIM Assert Message Type to the
"PIM Message Types" registry according to {{RFC8736}} IANA considerations,
and as shown in {{FIG-IANA-ASK}}.

#  Security Considerations

The security considerations of {{RFC7761}} apply to the extensions
defined in this document.

This document packs multiple assert records in a single message. As
described in Section 6.1 of {{RFC7761}}, a forged Assert message could
cause the legitimate designated forwarder to stop forwarding traffic
to the LAN. The effect may be amplified when using a PackedAssert message.

# Acknowledgments

The authors would like to thank: Stig Venaas for the valuable
contributions of this document, Alvaro Retana for his thorough
and constructive RTG AD review.

# Working Group considerations

\[RFC-Editor: please remove this section].

## Open Issues

## Changelog

This document is hosted starting with -06 on https://github.com/toerless/pim-assert-packing.

### draft-ietf-pim-assert-packing-07

Included changes from review of Alvaro Retana (https://mailarchive.ietf.org/arch/msg/pim/Cp4o5glUFge2b84X9CQMwCWZjAk/)

Please see emails in https://github.com/toerless/pim-assert-packing/emails for descriptions of the changes made from -05.

### draft-ietf-pim-assert-packing-06

This version was converted from txt format into markdown for better editing later, but is otherwise text identical to -05. It was posted to DataTracker to make diffs easier.

Functional changes:

--- back

# Use case examples {#use-case-examples}

## Enterprise network

When an Enterprise network is connected through a layer-2 network,
the intra-enterprise runs layer-3 PIM multicast. The different sites
of the enterprise are equivalent to the PIM connection through the
shared LAN network. Depending upon the locations and amount of
groups there could be many asserts on the first-hop routers.

## Video surveillance

Video surveillance deployments have migrated from analog based
systems to IP-based systems oftentimes using multicast. In the
shared LAN network deployments, when there are many cameras
streaming to many groups there may be issues with many asserts on
first-hop routers.

## Financial Services

Financial services extensively rely on IP Multicast to deliver stock
market data and its derivatives, and current multicast solution PIM
is usually deployed. As the number of multicast flows grow, there
are many stock data with many groups may result in many PIM asserts
on a shared LAN network from publisher to the subscribers.

## IPTV broadcast Video

PIM DR deployments are often used in host-side network for
IPTV broadcast video services. Host-side access network failure
scenario may be benefitted by assert packing when many groups are
being used. According to {{RFC7761}} the DR will be elected to forward
multicast traffic in the shared access network. When the DR recovers
from a failure, the original DR starts to send traffic, and the
current DR is still forwarding traffic. In the situation multicast
traffic duplication maybe happen in the shared access network and
can trigger the assert progress.

## MVPN MDT

As described in {{RFC6037}}, MDT (Multicast Distribution Tree) is used
as tunnels for MVPN. The configuration of multicast-enabled VRF (VPN
routing and forwarding) or interface that is in a VRF changing may
cause many assert packets to be sent in a same time.

## Special L2 services

Additionally, future backhaul, or fronthaul, networks may want to
connect L3 across an L2 underlay supporting Time Sensitive Networks
(TSN). The infrastructure may run DetNet over TSN. These transit L2
LANs would have multiple upstreams and downstreams. This document is
taking a proactive approach to prevention of possible future assert
issues in these types of environments.

