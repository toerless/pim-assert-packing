---
coding: utf-8

title: PIM Assert Message Packing
abbrev: assert-packing
docname: draft-ietf-pim-assert-packing-11
category: std
stream: IETF
wg: PIM
ipr: trust200902

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
    name: Toerless Eckert
    org: Futurewei
    role: editor
    country: USA
    email: tte@cs.fau.de
  -
    name: Mike McBride
    org: Futurewei
    country: USA
    email: michael.mcbride@futurewei.com
  -
    name: Zheng(Sandy) Zhang
    org: ZTE Corporation
    country: China
    email: zhang.zheng@zte.com.cn

normative:
  RFC2119:
  RFC7761:
  RFC8174:
  I-D.ietf-pim-rfc8736bis:

informative:
  RFC2475:
  RFC3973:
  RFC6037:

--- abstract

LANs often have more than one upstream router.
When PIM Sparse Mode (PIM-SM), including PIM Source Specific-Specific Multicast (PIM-SSM), is used, this
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
metric of the route towards the source or PIM Rendezvous Point (RP).

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

The reader is expected to be familiar with the terminology of {{RFC7761}}. The following lists the abbreviations repeated in this document.

AT: Assert Timer

RP: Rendezvous Point

RPF: Reverse Path Forwarding

SPT: Shortest Path Tree

RPT: RP Tree

DR: Designated Router

# Problem Statement 

PIM Asserts occur in many deployments. See {{use-case-examples}}
for explicit examples and explanations of why it is often not possible to avoid.

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

1. The PIM Assert Packing Hello Option.
2. The encoding of PackedAssert messages.
2. How to send and receive PackedAssert messages.

## PIM Assert Packing Hello Option

The PIM Assert Packing Hello Option ({{assert-packing-option}}) is used to announce support
for the assert packing mechanisms specified in this document.
PackedAssert messages ({{assert-packing-formats}}) 
MUST NOT be used unless all PIM routers in the same subnet announce this option.

## Assert Packing Message Formats {#assert-packing-formats}

The PIM Assert message, as defined in Section 4.9.6 of {{RFC7761}},
describes the parameters of a (\*,G) or (S,G) assert through the
following information elements: Rendezvous Point Tree flag (R), Source Address, Group
Address, Metric and Metric Preference. This document calls this
information an assert record.

Assert packing introduces two new PIM Assert message encodings
through the allocation and use of two flags in the PIM Assert
message header {{I-D.ietf-pim-rfc8736bis}}, the Packed (P) and the Aggregated (A)
flags.

If the (P)acked flag is 0, the message is a (non-packed) PIM Assert message
as specified in {{RFC7761}}. See {{rfc7761-assert-message}}. In this case,
the (A) flag MUST be set to 0, and MUST be ignored on receipt.

If the (P) flag is 1, then the message is
called a PackedAssert message and the type and hence
encoding format of the payload is determined by the (A) flag.

If A=0, then the message body is a sequence of assert records. This is called a "Simple PackedAssert" message. See {{simple-packedassert-message}}.

If A=1, then the message body is a sequence of aggregated assert records. This is called an "Aggregated PackedAssert". See {{aggregated-packedassert-message}}.

Two aggregated assert record types are specified.


The "Source Aggregated Assert Record", see {{s-assert-record}},
encodes one (common) Source Address, Metric and Metric Preference as well as a list
of one or more Group Addresses.  Source Aggregated Assert Records provide
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
for (\*,G) flows.  The Source Address is optionally used by {{RFC7761}} assert procedures
to indicate the source(s) that triggered the assert, otherwise the Source Address is set to 0 in the
assert record.

Both Source Aggregated Assert Records and RP Aggregated Assert Records also include the
R flag which maintains its semantic from {{RFC7761}} but also distinguishes
the encodings. Source Aggregated Assert Records have R=0, as (S,G) assert records do in {{RFC7761}}.
RP Aggregated Assert Records have R=1, as (\*,G) assert records do in {{RFC7761}}.

## PackedAssert Mechanism

PackedAsserts do not change the {{RFC7761}} PIM assert state machine specification. Instead,
sending and receiving of PackedAssert messages as specified in the following subsections are logically
new packetization options for assert records in addition to the (not packed) {{RFC7761}} Assert Message. 
There is no change to the assert record information elements transmitted or
their semantic. They are just transmitted in fewer but larger packets and fewer total number of bytes used to encode the information elements. In result, PIM routers should be able to send/receive assert records faster and/or with less processing overhead.

### Sending PackedAssert messages

When using assert packing, the regular {{RFC7761}} Assert message encoding with A=0 and P=0 is
still allowed to be sent.  Routers are free to choose which PackedAssert message format they send. 

- When any PIM routers on the LAN have not signaled support for Assert Packing,
  implementations MUST send only Asserts and MUST NOT send PackedAsserts under
  any condition.

- Implementations SHOULD support sending of PackedAssert messages.
  It is out of scope of this specification for which conditions, such as data-triggered asserts or 
  Assert Timer (AT) expiry based asserts, or under which conditions (such as high load) an implementation
  will send PackedAsserts instead of Asserts.

- Implementations are expected to specify in documentation and/or management interfaces (such as a YANG model),
  which PackedAssert message formats they can send and under which conditions they will send them. 

- Implementations SHOULD be able to indicate to the operator (such as through a YANG model)
  how many Assert and PackedAssert messages were sent/received and how many assert records where sent/received.

- Implementations that introduce support for PackedAsserts after support for Asserts SHOULD support configuration that disables PackedAssert operations.

When a PIM router has an assert record ready to send according to
{{RFC7761}}, it calls one of the following functions:

- send Assert(S,G) / send Assert(\*,G) ({{RFC7761}}, Section 4.2),
- Send Assert(S,G) / SendAssertCancel(S,G) ({{RFC7761}}, Section 4.6.1),
- Send Assert(\*,G) / Send AssertCancel(\*,G) ({{RFC7761}}, Section 4.6.2)
- send Assert(S,G) ({{RFC7761}}, Section 4.8.2). 

When sending of PackedAsserts is possible on the network, any of these calls,
MAY not result in sending of an Assert message with the assert record,
but instead in remembering the assert record, and letting PIM continue with
further processing for other flows that may result in additional assert records. 
PIM MUST then create PackedAssert messages from the remembered assert records
and schedule them for sending according to the considerations of the following
subsections.

#### Handling of reception triggered assert records.

Avoiding additional delay because of assert packing compared to immediate scheduling of
Assert messages is most critical for assert records that are triggered by
reception of data or reception of asserts against which the router
is in the "I am Assert Winner" state.  In these cases the router
SHOULD send out an Assert or PackedAssert message containing this assert record
as soon as possible to minimize the time in which duplicate IP multicast packets can occur.

To avoid additional delay in this case, the router should employ appropriate
assert packing and scheduling mechanisms, as explained here.

Asserts/PackedAsserts in this case are scheduled for serialization with highest priority, such
that they bypass any potentially earlier scheduled other packets.
When there is no such Assert/PackedAssert message scheduled for or being serialized,
the router immediately serializes an Assert or PackedAssert message without further assert packing.

If there are one or more reception triggered Assert/PackedAssert messages already serializing
and/or scheduled to be serialized on the outgoing interface, then the router can use the time
until the last of those messages will have finished serializing for PIM processing of further
conditions that may result in additional reception triggered assert records as well as packing of these assert
records without introducing additional delay.

#### Handling of timer expiry triggered assert records.

Asserts triggered by expiry of the AT on an assert winner are not time-critical because
they can be scheduled in advance and because the Assert_Override_Interval parameter of {{RFC7761}} already
creates a 3 second window in which such assert records can be sent, received, and processed before
an assert loser's state would expire and duplicate IP multicast packets could occur.

An example mechanism to allow packing of AT expiry triggered assert records on assert winners is
to round the AT to an appropriate granularity such as 100msec.  This will cause AT for multiple
(S,G) and/or (\*,G) states to expire at the same time, thus allowing them to be easily packed
without changes to the assert state machinery.

AssertCancel messages have assert records with an infinite metric and can use assert packing
as any other Assert. They are sent on Override Timer (OT) expiry and can be packed for example
with the same considerations as AT expiry triggered assert records.

#### Beneficial delay in sending PackedAssert messages {#beneficial}

Delay in sending PackedAsserts beyond what was discussed in prior subsectons can still be beneficial when
it causes the overall amount of (possible) duplicate IP multicast packets to decrease in a condition with
large number of (S,G) and/or (\*,G), compared to the situation in which an implementation only
sends Assert messages.

This delay can simply be used in implementations because it can not support the (more advanced)
mechanisms described above, and this longer delay can be achieve by some simpler mechanism 
(such as only periodic generation of PackedAsserts) and still achieves an overall reduction
in duplicate IP multicast packets compared to sending only Asserts.

#### Handling Assert/PackedAssert message loss

When Asserts are sent, a single packet loss will result only in continued or new
duplicates from a single IP multicast flow.  Loss of (non AssertCancel) PackedAssert impacts
duplicates for all flows packed into the PackedAssert and may result in the need
for re-sending more than one Assert/PackedAssert, because of the possible inability to pack the assert records in this condition.  Therefore, routers SHOULD support mechanisms allowing for PackedAsserts and Asserts to
be sent with an appropriate Differentiated Services Code Point (DSCP, {{RFC2475}}), such as Expedited Forwarding  (EF), to minimize their loss, especially
when duplicate IP multicast packets could cause congestion and loss.

Routers MAY support a configurable option for sending PackedAssert messages twice in short order
(such as 50msec apart), to overcome possible loss, but only when the following two conditions
are met.

1. The total size of the two PackedAsserts is less than the total size of equivalent Assert messages,

2. The condition of the assert records flows in the PackedAssert is such that the router
   can expect that their reception by PIM routers will not trigger Assert/PackedAsserts replies.
   This condition is true for example when sending an assert record while becoming or being Assert Winner (Action A1/A3 in {{RFC7761}}). 

#### Optimal degree of assert record packing

The optimal target packing size will vary depending on factors
including implementation characteristics and the required operating
scale. At some point, as the target packing size is varied from the
size of a single non-packed Assert, to the MTU size, a size can be
expected to be found where the router can achieve the required
operating scale of (S,G) and (\*,G) flows with minimum duplicates.
Beyond this size, a further increase in the target packing size would
not produce further benefits, but might introduce possible negative
effects such as the incurrence of more duplicates on loss.

For example, in some router implementations, the total number of
packets that a control plane function such as PIM can send/receive
per unit of time is a more limiting factor than the total amount
of data across these packets. As soon as the packet size is large
enough for the maximum possible payload througput, increasing the
packet size any further may still reduce the processing overhead
of the router, but may increase latency incurred in creating the
packet in a way that may increase duplicates compared to smaller
packets.

### Receiving PackedAssert messages

Upon reception of a PackedAssert message, the PIM router logically
converts its payload into a sequence of assert records that are then processed
as if an equivalent sequence of Assert messages were received according to {{RFC7761}}.

# Packet Formats

This section describes the format of new PIM extensions introduced by
this document.

## PIM Assert Packing Hello Option {#assert-packing-option}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |      OptionType = TBD         |      OptionLength = 0         |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-HELLO-OPTION title="PIM Assert Packing Hello Option"}

The PIM Assert Packing Hello Option is a new option for PIM Hello Messages according to Section 4.9.2 of {{RFC7761}}.

- OptionType TBD: 
    PIM Packed Assert Capability Hello Option

Including the PIM OptionType TBD indicates support for the ability to
receive and process all the PackedAssert encodings defined in this document.

## Assert Message Format {#rfc7761-assert-message}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |PIM Ver| Type  |7 6 5 4 3 2|A|P|           Checksum            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Group Address (Encoded-Group format)             |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |            Source Address (Encoded-Unicast format)            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                      Metric Preference                      |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                             Metric                            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
{: #FIG-MESSAGE-ASSERT title="Assert Message Format"}

{{FIG-MESSAGE-ASSERT}} shows a PIM Assert message as specified in Section 4.9.6 of
{{RFC7761}} with the common header showing the "7 6 5 4 3 2" Flag Bits as defined
in Section 4 of {{I-D.ietf-pim-rfc8736bis}} and the location of the P and A flags,
see {{IANA}}.
 As specified in {{assert-packing-formats}}, both
flags in a (non-packed) PIM Assert message are required to be set to 0.

## Simple PackedAssert Message Format {#simple-packedassert-message}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |PIM Ver| Type  |7 6 5 4 3 2|A|P|           Checksum            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |    Zero       |                     Reserved                  |
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
{: #FIG-MESSAGE-SIMPLE title="Simple PackedAssert Message Format"}

- PIM Version, Type, Checksum:

    As specified in Section 4.9.6 of {{RFC7761}}.

- "7 6 5 4 3 2": IANA registry handled bits according to Section 4 of {{I-D.ietf-pim-rfc8736bis}}.

- Zero:
     Set to zero on transmission. Serves to make non assert packing capable PIM routers fail in parsing the message instead of possible mis-parsing if this field was used.

- Reserved:
     Set to zero on transmission.  Ignored upon receipt.

- P: packed flag. MUST be 1.

- A: aggregated flag. MUST be 0.

- M: The number of Assert Records in the message. Derived from the length of the packet carrying the message.

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
    |PIM Ver| Type  |7 6 5 4 3 2|A|P|           Checksum            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |    Zero       |                     Reserved                  |
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
{: #FIG-PACKET-FORMAT-SG title="Aggregated PackedAssert Message Format"}

- PIM Version, Type, Reserved, Checksum:

    As specified in Section 4.9.6 of {{RFC7761}}.

- "7 6 5 4 3 2": IANA registry handled bits according to Section 4 of {{I-D.ietf-pim-rfc8736bis}}.

- P: packed flag. MUST be 1.

- A: aggregated flag. MUST be 1.

- Zero:
     Set to zero on transmission. Serves to make non assert packing capable PIM routers fail in parsing the message instead of possible mis-parsing if this field was used.

- M: The number of Aggregated Assert Records in the message. Derived from the length of the packet carrying the message.

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

- Reserved:
     Set to zero on transmission.  Ignored upon receipt.

- R: MUST be 0.

    R indicates both that the encoding format of the record is that of a Source Aggregated Assert Record,
    but also that all assert records represented by the Source Aggregated Assert Record have R=0 and are therefore
    (S,G) assert records according to the definition of R in {{RFC7761}}, Section 4.9.6.

- Source Address, Metric Preference, Metric:

    As specified in Section 4.9.6 of {{RFC7761}}.  Source Address MUST NOT be zero.

- Number of Groups:

    The number of Group Address fields.

- Group Address:

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

- Metric Preference, Metric:

    As specified in Section 4.9.6 of {{RFC7761}}.

- Reserved:
    Set to zero on transmission.  Ignored upon receipt.

- Number of Group Records:

    The number of packed Group Records. A record consists of a Group
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

- Group Address and Reserved:

    As specified in Section 4.9.6 of {{RFC7761}}.

- Reserved:
     Set to zero on transmission.  Ignored upon receipt.

- Number of Sources:

    The Number of Sources is corresponding to the number of Source Address fields in the Group Record.
    If this number is 0, the Group Record indicates one assert record with a Source Address of 0.
    If this number is not 0 and one of the (\*,G) assert records to be encoded should have
    the Source Address 0, then 0 needs to be encoded as one of the Source Address fields.

- Source Address:

    As specified in Section 4.9.6 of {{RFC7761}}.
    But there can be multiple Source Address fields in the Group Record.

# IANA Considerations {#IANA}

IANA is requested to assign a new code point from the "PIM-Hello
Options" registry for the Packed Assert Capability as follows:

    +=======+========+=========================+================+
    | Value | Length |          Name           | Reference      |
    +=======+========+=========================+================+
    | TBD   |      0 | Packed Assert Capability| [This Document]|
    +=======+========+=========================+================+
{: #FIG-IANA-ASK title="IANA PIM-Hello Options ask"}

IANA is requested to assign two Flag Bits in the Assert message
from the "PIM Message Types" registry as follows:

    +======+========+=================+====================+
    | Type | Name   | Flag Bits       | Reference          |
    +======+========+=================+====================+
    |   5  | Assert | 2-7: Unassigned | [RFC3973][RFC7761] |
    |      |        |   1: Aggregated | [This Document]    |
    |      |        |   0: Packed     | [This Document]    |
    +======+========+=================+====================+
{: #FIG-IANA-ASK2 title="IANA PIM Message Types ask"}

\[RFC-Editor note: If IANA can not assign the requested two bits 0 and 1, then the figures showing those two bits need to be fixed to show P and A in the actual locations IANA assigns - aka: the bits shown are "placeholders" according to the requested bits in this section.]

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
and constructive RTG AD review, Ines Robles for her Gen-ART review,
Tommy Pauly for his transport area review, Robert Sparks for his
SecDir review, Shuping Peng for her RtgDir review, John Scudder
for his RTG AD review.

# Working Group considerations

\[RFC-Editor: please remove this section].

## Open Issues

## Changelog

This document is hosted starting with -06 on https://github.com/toerless/pim-assert-packing.

### draft-ietf-pim-assert-packing-11

Thorough AD review by John Scudder.

Functional enhancement: add requirement for existing implementation to be able to disable assert packing so that any possible compatibility issues introduced (which we think will not happen) can be avoided when upgrading to a packedassert version of the software. Also to allow performance comparison. No making a requirement for day 0 implementations because they may want to save the work of having a non-packed-assert code path.

Some rewrite to increase readibility, subdivided 3.3.1 into multiple subsections to better structure it.

Some nits.

### draft-ietf-pim-assert-packing-10

Fixed up Reserved field of PackedAsserts to get back to 32 bit alignment
of the following fields (was down to 16 bits). Sorry, had a misinterpretation
reading rfc7761, though there ws something that had only made it 16 bit
aligned. Anyhow. Only this one change, 8 -> 24 bit for this field.

### draft-ietf-pim-assert-packing-09

For details of review discussion/replies, see review reply emails in (https://github.com/toerless/pim-assert-packing/tree/main/emails)j

review Alvaro Retana:
Reintroduced ref to PIM-DM, fixed typos, downgraded MAY->may for "sufficient".

IANA Expert Review / Stig Venaas:

Removed Count field from message headers as it complicates parsing and is unnecessary. Added "Zero" field to make packed asserts received by a non-packed-assert-capable-router guaranteed to fail ("Reserved" address family type).

Changed from RFC8736 to RFC8736bis so that we can use the word "Unassigned" in the IANA table.

Review Shuping Peng

Changed explanation of how assert packing works from "layer" to "alternative to
packetization via PIM Assert Message.
Fixed various typos, expanded term etc..

Review Robert Sparks:

Moved Intro explanations of how one could avoid asserts (but how its problematic) to appendix.
Applied textual nits found. Removed quotes around term "sufficient" for easier readbility.

Review Tommy Paul:

 Transport related concern explained in reply, but
no additional explanations in text because the question referred to
basic PIM behavior expected to be understood by readers: No discovery
of loss/trigger for retransmission, just restransmission of same
message element after discover of ongoing duplicates and/or expiry
of timers.

### draft-ietf-pim-assert-packing-08

Included changes from review of Alvaro Retana (https://mailarchive.ietf.org/arch/msg/pim/GsKq9bB2a6yDdM9DvAUGCWthdEI)

Please see the following emails discussing the changes:

https://raw.githubusercontent.com/toerless/pim-assert-packing/main/emails/07-alvaro-review-reply.txt

### draft-ietf-pim-assert-packing-07

Included changes from review of Alvaro Retana (https://mailarchive.ietf.org/arch/msg/pim/Cp4o5glUFge2b84X9CQMwCWZjAk/)

Please see the following emails discussing the changes:

https://raw.githubusercontent.com/toerless/pim-assert-packing/main/emails/05-alvaro-review-reply.txt

https://raw.githubusercontent.com/toerless/pim-assert-packing/main/emails/07-pim-wg-announce.txt

### draft-ietf-pim-assert-packing-06

This version was converted from txt format into markdown for better editing later, but is otherwise text identical to -05. It was posted to DataTracker to make diffs easier.

Functional changes:

--- back

# Use case examples {#use-case-examples}

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

The following subsections give examples of the type of network and use-cases
in which subnets with asserts have been observerd or are expected to require
scaling as provided by this specification.

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

