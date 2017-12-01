-----------------------------------------------------------------------
--  hestia-time -- Date and time information
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
with Net.NTP;
package Hestia.Time is

   type Month_Name is (January, February, March, April, May, June, July, August,
                       September, October, November, December);
   type Day_Name is (Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday);
   subtype Day_Number      is Natural range 1 .. 31;
   subtype Hour_Number     is Natural range 0 .. 23;
   subtype Minute_Number   is Natural range 0 .. 59;
   subtype Second_Number   is Natural range 0 .. 59;
   subtype Year_Number     is Natural range 1901 .. 2399;

   type Time_Offset is range -(28 * 60) .. 28 * 60;

   type Date_Time is record
      Hour     : Hour_Number;
      Minute   : Minute_Number;
      Second   : Second_Number;
      Sub_Seconds : Net.Uint32 := 0;
      Week_Day : Day_Name;
      Year_Day : Natural;
      Day      : Day_Number;
      Month    : Month_Name;
      Year     : Year_Number;
   end record;

   --  Convert the NTP time reference to a date.
   function Convert (Time : in Net.NTP.NTP_Reference) return Date_Time with
     Pre => Time.Status in Net.NTP.SYNCED | Net.NTP.RESYNC;

end Hestia.Time;
