-----------------------------------------------------------------------
--  hestia-display-main -- Main display view manager
--  Copyright (C) 2018 Stephane Carrez
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

with Hestia.Display.Main;
with Hestia.Display.Info;
package Hestia.Display.Instances is

   Display      : aliased Main.Display_Type;
   Info_Display : aliased Info.Display_Type;

end Hestia.Display.Instances;