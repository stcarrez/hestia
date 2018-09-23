-----------------------------------------------------------------------
--  hestia-ports -- Heat port control
--  Copyright (C) 2017, 2018 Stephane Carrez
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

   Zones : Zone_Control_Array
     := (1 => (Mode => H_CONFORT,
               Pos_Control => STM32.Device.PB4,
               Neg_Control => STM32.Device.PA8),
         2 => (Mode => H_CONFORT,
               Pos_Control => STM32.Device.PH6,
               Neg_Control => STM32.Device.PA15),
         3 => (Mode => H_CONFORT,
               Pos_Control => STM32.Device.PI0,
               Neg_Control => STM32.Device.PB15));

   --  ------------------------------
   --  Set the zone.
   --  ------------------------------
   procedure Set_Zone (Zone : in Zone_Type;
                       Mode : in Control_Type) is
   begin
      Zones (Zone).Mode := Mode;
      case Mode is
         when H_CONFORT =>
            Zones (Zone).Pos_Control.Clear;
            Zones (Zone).Neg_Control.Clear;

         when H_ECO =>
            Zones (Zone).Pos_Control.Set;
            Zones (Zone).Neg_Control.Set;

         when H_HORS_GEL =>
            Zones (Zone).Pos_Control.Clear;
            Zones (Zone).Neg_Control.Set;

         when H_STOPPED =>
            Zones (Zone).Pos_Control.Set;
            Zones (Zone).Neg_Control.Clear;

         when others =>
            null;

      end case;
   end Set_Zone;

   --  ------------------------------
   --  Initialize the heat control ports.
   --  ------------------------------
   procedure Initialize is
      Configuration : STM32.GPIO.GPIO_Port_Configuration
        := (Mode => STM32.GPIO.Mode_Out,
            Output_Type => STM32.GPIO.Push_Pull,
            Speed       => STM32.GPIO.Speed_100MHz,
            Resistors   => STM32.GPIO.Floating);
   begin
      STM32.Device.Enable_Clock (All_Zones);

      STM32.GPIO.Configure_IO (All_Zones, Configuration);
   end Initialize;

end Hestia.Ports;
