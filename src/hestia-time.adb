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
with Interfaces;
with Hestia.Config;
package body Hestia.Time is

   Secs_In_Day           : constant := 24 * 3600;
   Secs_In_Four_Years    : constant := (3 * 365 + 366) * Secs_In_Day;
   Secs_In_Non_Leap_Year : constant := 365 * Secs_In_Day;

   type Day_Count_Array is array (Month_Name) of Day_Number;
   type Day_Array is array (Boolean) of Day_Count_Array;

   Day_Table : constant Day_Array :=
     (False => (January => 31, February => 28, March => 31, April => 30,
                May => 31, June => 30, July => 31, August => 31,
                September => 30, October => 31, November => 30, December => 31),
      True => (January => 31, February => 29, March => 31, April => 30,
               May => 31, June => 30, July => 31, August => 31,
               September => 30, October => 31, November => 30, December => 31));

   function Is_Leap (Year : in Year_Number) return Boolean;

   function Is_Leap (Year : in Year_Number) return Boolean is
   begin
      return Year mod 400 = 0 or (Year mod 4 = 0 and not (Year mod 100 = 0));
   end Is_Leap;

   --  ------------------------------
   --  Convert the NTP time reference to a date.
   --  ------------------------------
   function Convert (Time : in Net.NTP.NTP_Reference) return Date_Time is
      use type Interfaces.Unsigned_32;

      T              : Net.NTP.NTP_Timestamp;
      S              : Net.Uint32;
      Result         : Date_Time;
      Four_Year_Segs : Natural;
      Rem_Years      : Natural;
      Year_Day       : Natural;
      Is_Leap_Year   : Boolean;
   begin
      T := Net.NTP.Get_Time (Time);
      S := T.Seconds;

      --  Apply the timezone correction.
      S := S + 60 * Hestia.Config.TIME_ZONE_CORRECTION;

      --  Compute year.
      Four_Year_Segs := Natural (S / Secs_In_Four_Years);
      if Four_Year_Segs > 0 then
         S := S - Net.Uint32 (Four_Year_Segs) * Net.Uint32 (Secs_In_Four_Years);
      end if;
      Rem_Years := Natural (S / Secs_In_Non_Leap_Year);
      if Rem_Years > 3 then
         Rem_Years := 3;
      end if;
      S := S - Net.Uint32 (Rem_Years * Secs_In_Non_Leap_Year);
      Result.Year := Natural (4 * Four_Year_Segs + Rem_Years) + 1970;

      --  Compute year day.
      Year_Day := Natural (S / Secs_In_Day);
      Result.Year_Day := Year_Day;

      --  Compute month and day of month.
      Is_Leap_Year := Is_Leap (Result.Year);
      Result.Month := January;
      while Year_Day > Day_Table (Is_Leap_Year) (Result.Month) loop
         Year_Day := Year_Day - Day_Table (Is_Leap_Year) (Result.Month);
         Result.Month := Month_Name'Succ (Result.Month);
      end loop;
      Result.Day := Year_Day;

      --  Compute hours, minutes and remaining seconds.
      S := S mod 86400;
      Result.Hour := Hour_Number (S / 3600);
      S := S mod 3600;
      Result.Minute := Minute_Number (S / 60);
      Result.Second := Second_Number (S mod 60);
      Result.Sub_Seconds := T.Sub_Seconds;
      Result.Week_Day := Monday;
      return Result;
   end Convert;

end Hestia.Time;
