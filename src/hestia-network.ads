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
with Net.Buffers;
with Net.Interfaces.STM32;
with Net.DHCP;
package Hestia.Network is

   use type Interfaces.Unsigned_32;

   --  Reserve 32 network buffers.
   NET_BUFFER_SIZE  : constant Interfaces.Unsigned_32 := Net.Buffers.NET_ALLOC_SIZE * 32;

   --  The Ethernet interface driver.
   Ifnet     : aliased Net.Interfaces.STM32.STM32_Ifnet;

   --  The DHCP client used by Hestia.
   Dhcp      : aliased Net.DHCP.Client;

   --  Initialize and start the network stack.
   procedure Initialize;

   --  The task that waits for packets.
   task Controller with
     Storage_Size => (16 * 1024),
     Priority => System.Default_Priority;

end Hestia.Network;
