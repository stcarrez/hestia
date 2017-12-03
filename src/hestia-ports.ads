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
with STM32;
with STM32.GPIO;
with STM32.Device;
with Hestia.Config;
package Hestia.Ports is

   type Zone_Type is new Natural range 1 .. Hestia.Config.MAX_ZONES;

   type Control_Type is (H_CONFORT, H_ECO, H_HORS_GEL, H_STOPPED, H_CONFORT_M1, H_CONFORT_M2);

   subtype Heat_Control_Point is STM32.GPIO.GPIO_Point;

   --  Heat control ports are connected to the available PWM outputs.
   Zone1_Control : Heat_Control_Point renames STM32.Device.PB4;
   Zone2_Control : Heat_Control_Point renames STM32.Device.PA8;
   Zone3_Control : Heat_Control_Point renames STM32.Device.PH6;
   Zone4_Control : Heat_Control_Point renames STM32.Device.PA15;
   Zone5_Control : Heat_Control_Point renames STM32.Device.PI0;
   Zone6_Control : Heat_Control_Point renames STM32.Device.PB15;

   --  Set the zone.
   procedure Set_Zone (Zone : in Zone_Type;
                       Mode : in Control_Type);

   --  Initialize the heat control ports.
   procedure Initialize;

private

   type Zone_Control_Type is limited record
      Mode        : Control_Type;
      Pos_Control : Heat_Control_Point;
      Neg_Control : Heat_Control_Point;
   end record;

   type Zone_Control_Array is array (Zone_Type) of Zone_Control_Type;

end Hestia.Ports;
