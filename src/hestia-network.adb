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
with Ada.Real_Time;
with Ada.Synchronous_Task_Control;
with Net.Interfaces;
with Net.Headers;
with Net.Protos.Arp;
with Net.Protos.Dispatchers;
with HAL;
with STM32.RNG.Interrupts;
with STM32.Eth;
with STM32.SDRAM;

package body Hestia.Network is

   Ready  : Ada.Synchronous_Task_Control.Suspension_Object;

   --  ------------------------------
   --  Initialize and start the network stack.
   --  ------------------------------
   procedure Initialize is
   begin
      STM32.RNG.Interrupts.Initialize_RNG;

      --  STMicroelectronics OUI = 00 81 E1
      Ifnet.Mac := (0, 16#81#, 16#E1#, 15, 5, 1);

      --  Setup some receive buffers and initialize the Ethernet driver.
      Net.Buffers.Add_Region (STM32.SDRAM.Reserve (Amount => HAL.UInt32 (NET_BUFFER_SIZE)),
                              NET_BUFFER_SIZE);

      --  Initialize the Ethernet driver.
      STM32.Eth.Initialize_RMII;

      Ifnet.Initialize;

      Ada.Synchronous_Task_Control.Set_True (Ready);

      --  Initialize the DHCP client.
      Dhcp.Initialize (Ifnet'Access);

   end Initialize;

   --  ------------------------------
   --  Save the answer received from the DNS server.  This operation is called for each answer
   --  found in the DNS response packet.  The Index is incremented at each answer.  For example
   --  a DNS server can return a CNAME_RR answer followed by an A_RR: the operation is called
   --  two times.
   --
   --  This operation can be overriden to implement specific actions when an answer is received.
   --  ------------------------------
   overriding
   procedure Answer (Request  : in out NTP_Client_Type;
                     Status   : in Net.DNS.Status_Type;
                     Response : in Net.DNS.Response_Type;
                     Index    : in Natural) is
      pragma Unreferenced (Index);
      use type Net.DNS.Status_Type;
      use type Net.DNS.RR_Type;
      use type Net.Uint16;
   begin
      if Status = Net.DNS.NOERROR and then Response.Of_Type = Net.DNS.A_RR then
         Request.Server.Initialize (Ifnet'Access, Response.Ip, Request.Port);
      end if;
   end Answer;

   --  ------------------------------
   --  The task that waits for packets.
   --  ------------------------------
   task body Controller is
      use type Ada.Real_Time.Time;
      use type Net.Uint16;

      Packet  : Net.Buffers.Buffer_Type;
      Ether   : Net.Headers.Ether_Header_Access;
   begin
      --  Wait until the Ethernet driver is ready.
      Ada.Synchronous_Task_Control.Suspend_Until_True (Ready);

      loop
         if Packet.Is_Null then
            Net.Buffers.Allocate (Packet);
         end if;
         if not Packet.Is_Null then
            Ifnet.Receive (Packet);
            Ether := Packet.Ethernet;
            if Ether.Ether_Type = Net.Headers.To_Network (Net.Protos.ETHERTYPE_ARP) then
               Net.Protos.Arp.Receive (Ifnet, Packet);
            elsif Ether.Ether_Type = Net.Headers.To_Network (Net.Protos.ETHERTYPE_IP) then
               Net.Protos.Dispatchers.Receive (Ifnet, Packet);
            end if;
         else
            delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (100);
         end if;
      end loop;
   end Controller;

end Hestia.Network;
