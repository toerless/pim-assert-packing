---

title: PIM Assert Message Packing
abbrev: assert-packing
docname: draft-ietf-pim-assert-packing-08
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

The reader is expected to be familiar with the terminology of {{RFC7761}}. The following lists the abbreviations repeated in this document.

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
PackedAssert messages ({{assert-packing-formats}}) 
MUST NOT be used unless all PIM routers in the same subnet announce this option.

## Assert Packing Message Formats {#assert-packing-formats}

The PIM Assert message, as defined in Section 4.9.6 of {{RFC7761}},
describes the parameters of a (*,G) or (S,G) assert through the
following information elements: Rendezvous Point Tree flag (R), Source Address, Group
Address, Metric and Metric Preference. This document calls this
information an assert record.

Assert packing introduces two new PIM Assert message encodings
through the allocation and use of two flags in the PIM Assert
message header {{RFC8736}}, the Packed (P) and the Aggregated (A)
flags.

If the P)acked flag is 0, the message is a (non-packed) PIM Assert message
as specified in {{RFC7761}}. See {{rfc7761-assert-message}}. In this case,
the (A) flag MUST be set to 0, and MUST be ignored on receipt.
If the (P) flag is 2, then the message is
called a PackedAssert message and the type and hence
encoding format of the payload is determined by the (A) flag.

If A=0, then the message body is a sequence of assert records
preceeded by a count. This is called a "Simple PackedAssert" message. See {{simple-packedassert-message}}.

If A=1, then the message body is a sequence of aggregated assert records
preceeded by a count. This is called an "Aggregated PackedAssert". See {{aggregated-packedassert-message}}.

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
for (*,G) flows.  The Source Address is optionally used by {{RFC7761}} assert procedures
to indicate the source(s) that triggered the assert, otherwise it is 0.

Both Source Aggregated Assert Records and RP Aggregated Assert Records also include the
R flag which maintains its semantic from {{RFC7761}} but also distinguishes
the encodings. Source Aggregated Assert Records have R=0, as (S,G) assert records do in {{RFC7761}}.
RP Aggregated Assert Records have R=1, as (*,G) assert records do in {{RFC7761}}.

## PackedAssert Mechanism

PackedAsserts do not change the {{RFC7761}} PIM assert state machine specification. Instead,
sending and receiving of PackedAssert messages as specified in the following subsections is logically
a layer in between sending/receiving of Assert messages and serialization/deserialization of
their respective packets. There is no change in the information elements of the transmitted
information elements constituting the assert records nor their semantics. Only the compactness
of their encoding.

### Sending PackedAssert messages

When using assert packing, the regular {{RFC7761}} Assert message encoding with A=0 and P=0 is
still allowed to be sent.  Routers are free to choose which PackedAssert message type they send. 

It is out of scope of this specification for which conditions, such as data-triggered asserts or 
Assert Timer (AT) expiry based asserts, an implementation should generate PackedAsserts instead of Asserts.
Instead,

- Implementations are expected to specify in documentation and/or management interfaces (such as a YANG model),
which PackedAssert message types they can send and under which conditions they will. 
- Implementation SHOULD NOT send only Asserts, but no PackedAsserts under all conditions, 
when all routers on the LAN do support Assert Packing.

When a PIM router has an assert record ready to send according to
{{RFC7761}}, it calls send Assert(S,G) / send Assert(*,G) (Section 4.2),
Send Assert(S,G) / SendAssertCancel(S,G) (Section 4.6.1),
Send Assert(*,G) / Send AssertCancel(*,G) (Section 4.6.2) and
send Assert(S,G) (Section 4.8.2). Each of these calls will send
an Assert message. When sending of PackedAsserts is possible on the
network, any of these calls is permitted to not send an Assert message, but only
remember the assert record, and let PIM continue with further processing
for other flows that may result in additional assert records - to finally
packe PackedAssert messages from the remembered assert records and send them.

The following text discusses several conditions to be taken into account
for this further processing and how to create and schedule PackedAssert messages.

Avoiding possible additional and relevant delay because of further processing
is most critical for assert records that are triggered by
reception of data or reception of asserts against which the router
is in the "I am Assert Winner" state.  In these cases the router
SHOULD send out an Assert or PackedAssert message containing this assert record
as soon as possible to minimize the time in which duplicate IP multicast packets can occur.

To avoid additional delay in this case, the router should employ appropriate
assert packing and scheduling mechanisms, such as for example the following.

Asserts/PackedAsserts in this case are scheduled for serialization with highest priority, such
that they bypass any potentially earlier scheduled other packets.
When there is no such Assert/PacketAssert message scheduled for or being serialized,
the router immediately serializes an Assert or PackedAssert message without further assert packing.
If there are one or more Assert/PackedAssert messages serialized and/or scheduled to be serialized,
then the router can pack assert records into new PackedAssert messages until shortly before the
last of those Assert/PackedAssert packets has finished serializing. 

Asserts triggered by expiry of the AT on an assert winner are not time-critical because
they can be scheduled in advance and because the Assert_Override_Interval parameter of {{RFC7761}} already
creates a 3 second window in which such assert records can be sent, received, and processed before
an assert losers state would expire and duplicate IP multicast packets could occur.

An example mechanism to allow packing of AT expiry triggered assert records on assert winners is
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
for re-sending more than one Assert/PacketAssert, because of the possible inability to pack the assert records in this condition.  Threrefore, routers SHOULD support mechanisms allowing for PackedAsserts and Asserts to
be sent with an appropriate DSCP, such as Expedited Forwarding  (EF), to minimize their loss, especially
when duplicate IP multicast packets could cause congestion and loss.

Routers MAY support a configurable option for sending PackedAssert messages twice in short order
(such as 50msec apart), to overcome possible loss, but only when the following two conditions
are met.

1. The total size of the two PackedAsserts is less than the total size of equivalent Assert messages,

2. The condition of the assert records flows in the PackedAssert is such that the router
   can expect that their reception by PIM routers will not trigger Assert/PackedAsserts replies.
   This condition is true for example when sending an assert record while becoming or being Assert Winner (Action A1/A3 in {{RFC7761}}). 


It is "sufficient" that assert records are not packed up to MTU size, but to a size that
allows the router to achieve the required operating scale of (S,G) and (\*,G) flows with minimum duplicates.
This packing size may be larger when the network is operating with the maximum number of supported multicast
 flows, and it can be a smaller packing size when operating with fewer multicast flows. Larger than "sufficient"
packets may then not provide additional benefits, because they only reduce the performance requirements for
packet sending and reception, and other performance limiting factors may take over once
a "sufficient" size is reached. And larger packets can incur more duplicates on loss.
Routers MAY support a "sufficient" amount of packing to minimize the negative impacts of loss of PackedAssert packets
without loss of performance of minimizing IP multicast packet duplication.

### Receiving PackedAssert messages

Upon reception of a PackedAssert message, the PIM router logically
converts its payload into a sequence of assert records that are then processed
as if an equivalent sequence of Assert messages where received according to {{RFC7761}}.

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
{: #FIG-MESSAGE-ASSERT title="Assert"}

{{FIG-MESSAGE-ASSERT}} shows a PIM Assert message as specified in Section 4.9.6 of
{{RFC7761}} with the common header showing the Flag Bits defined in {{RFC8736}} and
the location of the P and A flags.  As specified in {{assert-packing-formats}}, both
flags in a (non-packed) PIM Assert message are required to be set to 0.

## Simple PackedAssert Message Format {#simple-packedassert-message}

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |PIM Ver| Type  |7 6 5 4 3 2|A|P|           Checksum            |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |      Count                    |  Reserved                     |
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

- PIM Version, Type, Checksum:

    As specified in Section 4.9.6 of {{RFC7761}}.

- 7 6 5 4 3 2: Flag bits according to Section 4 of {{RFC8736}}.


- Reserved:
     Set to zero on transmission.  Ignored upon receipt.

- P: packed flag. MUST be 1.

- A: aggregated flag. MUST be 0.

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
    |PIM Ver| Type  |7 6 5 4 3 2|A|P|           Checksum            |
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

- PIM Version, Type, Reserved, Checksum:

    As specified in Section 4.9.6 of {{RFC7761}}.

- 7 6 5 4 3 2: Flag bits according to Section 4 of {{RFC8736}}.


- P: packed flag. MUST be 1.

- A aggregated flag. MUST be 1.

- Count:

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

# IANA Considerations

IANA is requested to assign a new code point from the "PIM-Hello
Options" registry for the Packed Assert Capability as follows:

    +=======+========+=========================+================+
    | Value | Length |          Name           | Reference      |
    +=======+========+=========================+================+
    | TBD   |      0 | Packed Assert Capability| [This Document]|
    +=======+========+=========================+================+
{: #FIG-IANA-ASK }

IANA is requested to assign two Flag Bits in the Assert message
from the "PIM Message Types" registry as follows:

    +======+========+=================+====================+
    | Type | Name   | Flag Bits       | Reference          |
    +======+========+=================+====================+
    |   5  | Assert | 2-7: Reserved   | [RFC3973][RFC7761] |
    |      |        |   1: Aggregated | [This Document]    |
    |      |        |   0: Packed     | [This Document]    |
    +======+========+=================+====================+
{: #FIG-IANA-ASK2 }

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

