-----------------------------------------------------------------------
--  hestia-network -- Hestia Network Manager
--  Copyright (C) 2016, 2017 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------
with System;
with Interfaces;
with Ada.Real_Time;
with Net.Buffers;
with Net.Interfaces.STM32;
with Net.DHCP;
with Net.NTP;
with Net.DNS;
package Hestia.Network is

   use type Interfaces.Unsigned_32;

   --  Reserve 32 network buffers.
   NET_BUFFER_SIZE  : constant Interfaces.Unsigned_32 := Net.Buffers.NET_ALLOC_SIZE * 32;

   --  The Ethernet interface driver.
   Ifnet     : aliased Net.Interfaces.STM32.STM32_Ifnet;

   --  Initialize and start the network stack.
   procedure Initialize;

   --  Do the network housekeeping and return the next deadline.
   procedure Process (Deadline : out Ada.Real_Time.Time);

private

   --  The task that waits for packets.
   task Controller with
     Storage_Size => (16 * 1024),
     Priority => System.Default_Priority;

   type NTP_Client_Type is limited new Net.DNS.Query with record
      --  The TTL deadline for the resolved DNS entry.
      Ttl_Deadline : Ada.Real_Time.Time;

      --  The NTP client connection and port.
      Server       : aliased Net.NTP.Client;
      Port         : Net.Uint16 := Net.NTP.NTP_PORT;
   end record;

   --  Save the answer received from the DNS server.  This operation is called for each answer
   --  found in the DNS response packet.  The Index is incremented at each answer.  For example
   --  a DNS server can return a CNAME_RR answer followed by an A_RR: the operation is called
   --  two times.
   --
   --  This operation can be overriden to implement specific actions when an answer is received.
   overriding
   procedure Answer (Request  : in out NTP_Client_Type;
                     Status   : in Net.DNS.Status_Type;
                     Response : in Net.DNS.Response_Type;
                     Index    : in Natural);

   --  The DHCP client used by Hestia.
   Dhcp      : aliased Net.DHCP.Client;

   --  NTP client based on the NTP server provided by DHCP option (or static).
   Time_Ntp  : aliased NTP_Client_Type;

end Hestia.Network;
