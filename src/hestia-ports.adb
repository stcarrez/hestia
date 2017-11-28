-----------------------------------------------------------------------
--  hestia-ports -- Heat port control
--  Copyright (C) 2017 Stephane Carrez
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

package body Hestia.Ports is

   All_Zones : constant STM32.GPIO.GPIO_Points
     := (Zone1_Control, Zone2_Control, Zone3_Control, Zone4_Control, Zone5_Control, Zone6_Control);

   --  ------------------------------
   --  Initialize the heat control ports.
   --  ------------------------------
   procedure Initialize is
      Configuration : STM32.GPIO.GPIO_Port_Configuration;
   begin
      STM32.Device.Enable_Clock (All_Zones);

      Configuration.Mode        := STM32.GPIO.Mode_Out;
      Configuration.Output_Type := STM32.GPIO.Push_Pull;
      Configuration.Speed       := STM32.GPIO.Speed_100MHz;
      Configuration.Resistors   := STM32.GPIO.Floating;
      STM32.GPIO.Configure_IO (All_Zones, Configuration);
   end Initialize;

end Hestia.Ports;
