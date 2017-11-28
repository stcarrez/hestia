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
package Hestia.Ports is

   subtype Heat_Control_Point is STM32.GPIO.GPIO_Point;

   --  Heat control ports are connected to the available PWM outputs.
   Zone1_Control : Heat_Control_Point renames STM32.Device.PB4;
   Zone2_Control : Heat_Control_Point renames STM32.Device.PA8;
   Zone3_Control : Heat_Control_Point renames STM32.Device.PH6;
   Zone4_Control : Heat_Control_Point renames STM32.Device.PA15;
   Zone5_Control : Heat_Control_Point renames STM32.Device.PI0;
   Zone6_Control : Heat_Control_Point renames STM32.Device.PB15;

end Hestia.Ports;
