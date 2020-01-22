--------------------------------------------------------------------------------
-- Copyright (C) 1999-2008 Easics NV.
-- This source file may be used and distributed without restriction
-- provided that this copyright statement is not removed from the file
-- and that any derivative work contains the original copyright notice
-- and the associated disclaimer.
--
-- THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
--
-- Purpose : synthesizable CRC function
--   * polynomial: x^20 + x^19 + x^13 + x^12 + x^10 + x^8 + x^7 + x^4 + x^3 + x^2 + x^1 + 1
--   * data width: 64
--
-- Info : tools@easics.be
--        http://www.easics.com
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package PCK_CRC20_D64 is
  -- polynomial: x^20 + x^19 + x^13 + x^12 + x^10 + x^8 + x^7 + x^4 + x^3 + x^2 + x^1 + 1
  -- data width: 64
  -- convention: the first serial bit is D[63]
  function nextCRC20_D64
    (Data: std_logic_vector(63 downto 0);
     crc:  std_logic_vector(19 downto 0))
    return std_logic_vector;
end PCK_CRC20_D64;


package body PCK_CRC20_D64 is

  -- polynomial: x^20 + x^19 + x^13 + x^12 + x^10 + x^8 + x^7 + x^4 + x^3 + x^2 + x^1 + 1
  -- data width: 64
  -- convention: the first serial bit is D[63]
  function nextCRC20_D64
    (Data: std_logic_vector(63 downto 0);
     crc:  std_logic_vector(19 downto 0))
    return std_logic_vector is

    variable d:      std_logic_vector(63 downto 0);
    variable c:      std_logic_vector(19 downto 0);
    variable newcrc: std_logic_vector(19 downto 0);

  begin
    d := Data;
    c := crc;

    newcrc(0) := d(63) xor d(59) xor d(56) xor d(55) xor d(51) xor d(50) xor d(49) xor d(48) xor d(46) xor d(45) xor d(44) xor d(41) xor d(40) xor d(38) xor d(31) xor d(30) xor d(29) xor d(28) xor d(25) xor d(23) xor d(22) xor d(20) xor d(18) xor d(17) xor d(14) xor d(13) xor d(10) xor d(6) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor d(0) xor c(0) xor c(1) xor c(2) xor c(4) xor c(5) xor c(6) xor c(7) xor c(11) xor c(12) xor c(15) xor c(19);
    newcrc(1) := d(63) xor d(60) xor d(59) xor d(57) xor d(55) xor d(52) xor d(48) xor d(47) xor d(44) xor d(42) xor d(40) xor d(39) xor d(38) xor d(32) xor d(28) xor d(26) xor d(25) xor d(24) xor d(22) xor d(21) xor d(20) xor d(19) xor d(17) xor d(15) xor d(13) xor d(11) xor d(10) xor d(7) xor d(0) xor c(0) xor c(3) xor c(4) xor c(8) xor c(11) xor c(13) xor c(15) xor c(16) xor c(19);
    newcrc(2) := d(63) xor d(61) xor d(60) xor d(59) xor d(58) xor d(55) xor d(53) xor d(51) xor d(50) xor d(46) xor d(44) xor d(43) xor d(39) xor d(38) xor d(33) xor d(31) xor d(30) xor d(28) xor d(27) xor d(26) xor d(21) xor d(17) xor d(16) xor d(13) xor d(12) xor d(11) xor d(10) xor d(8) xor d(6) xor d(5) xor d(4) xor d(3) xor d(2) xor d(0) xor c(0) xor c(2) xor c(6) xor c(7) xor c(9) xor c(11) xor c(14) xor c(15) xor c(16) xor c(17) xor c(19);
    newcrc(3) := d(63) xor d(62) xor d(61) xor d(60) xor d(55) xor d(54) xor d(52) xor d(50) xor d(49) xor d(48) xor d(47) xor d(46) xor d(41) xor d(39) xor d(38) xor d(34) xor d(32) xor d(30) xor d(27) xor d(25) xor d(23) xor d(20) xor d(12) xor d(11) xor d(10) xor d(9) xor d(7) xor d(2) xor d(0) xor c(2) xor c(3) xor c(4) xor c(5) xor c(6) xor c(8) xor c(10) xor c(11) xor c(16) xor c(17) xor c(18) xor c(19);
    newcrc(4) := d(62) xor d(61) xor d(59) xor d(53) xor d(47) xor d(46) xor d(45) xor d(44) xor d(42) xor d(41) xor d(39) xor d(38) xor d(35) xor d(33) xor d(30) xor d(29) xor d(26) xor d(25) xor d(24) xor d(23) xor d(22) xor d(21) xor d(20) xor d(18) xor d(17) xor d(14) xor d(12) xor d(11) xor d(8) xor d(6) xor d(5) xor d(4) xor d(2) xor d(0) xor c(0) xor c(1) xor c(2) xor c(3) xor c(9) xor c(15) xor c(17) xor c(18);
    newcrc(5) := d(63) xor d(62) xor d(60) xor d(54) xor d(48) xor d(47) xor d(46) xor d(45) xor d(43) xor d(42) xor d(40) xor d(39) xor d(36) xor d(34) xor d(31) xor d(30) xor d(27) xor d(26) xor d(25) xor d(24) xor d(23) xor d(22) xor d(21) xor d(19) xor d(18) xor d(15) xor d(13) xor d(12) xor d(9) xor d(7) xor d(6) xor d(5) xor d(3) xor d(1) xor c(1) xor c(2) xor c(3) xor c(4) xor c(10) xor c(16) xor c(18) xor c(19);
    newcrc(6) := d(63) xor d(61) xor d(55) xor d(49) xor d(48) xor d(47) xor d(46) xor d(44) xor d(43) xor d(41) xor d(40) xor d(37) xor d(35) xor d(32) xor d(31) xor d(28) xor d(27) xor d(26) xor d(25) xor d(24) xor d(23) xor d(22) xor d(20) xor d(19) xor d(16) xor d(14) xor d(13) xor d(10) xor d(8) xor d(7) xor d(6) xor d(4) xor d(2) xor c(0) xor c(2) xor c(3) xor c(4) xor c(5) xor c(11) xor c(17) xor c(19);
    newcrc(7) := d(63) xor d(62) xor d(59) xor d(55) xor d(51) xor d(47) xor d(46) xor d(42) xor d(40) xor d(36) xor d(33) xor d(32) xor d(31) xor d(30) xor d(27) xor d(26) xor d(24) xor d(22) xor d(21) xor d(18) xor d(15) xor d(13) xor d(11) xor d(10) xor d(9) xor d(8) xor d(7) xor d(6) xor d(4) xor d(2) xor d(1) xor d(0) xor c(2) xor c(3) xor c(7) xor c(11) xor c(15) xor c(18) xor c(19);
    newcrc(8) := d(60) xor d(59) xor d(55) xor d(52) xor d(51) xor d(50) xor d(49) xor d(47) xor d(46) xor d(45) xor d(44) xor d(43) xor d(40) xor d(38) xor d(37) xor d(34) xor d(33) xor d(32) xor d(30) xor d(29) xor d(27) xor d(20) xor d(19) xor d(18) xor d(17) xor d(16) xor d(13) xor d(12) xor d(11) xor d(9) xor d(8) xor d(7) xor d(6) xor d(4) xor d(0) xor c(0) xor c(1) xor c(2) xor c(3) xor c(5) xor c(6) xor c(7) xor c(8) xor c(11) xor c(15) xor c(16);
    newcrc(9) := d(61) xor d(60) xor d(56) xor d(53) xor d(52) xor d(51) xor d(50) xor d(48) xor d(47) xor d(46) xor d(45) xor d(44) xor d(41) xor d(39) xor d(38) xor d(35) xor d(34) xor d(33) xor d(31) xor d(30) xor d(28) xor d(21) xor d(20) xor d(19) xor d(18) xor d(17) xor d(14) xor d(13) xor d(12) xor d(10) xor d(9) xor d(8) xor d(7) xor d(5) xor d(1) xor c(0) xor c(1) xor c(2) xor c(3) xor c(4) xor c(6) xor c(7) xor c(8) xor c(9) xor c(12) xor c(16) xor c(17);
    newcrc(10) := d(63) xor d(62) xor d(61) xor d(59) xor d(57) xor d(56) xor d(55) xor d(54) xor d(53) xor d(52) xor d(50) xor d(47) xor d(44) xor d(42) xor d(41) xor d(39) xor d(38) xor d(36) xor d(35) xor d(34) xor d(32) xor d(30) xor d(28) xor d(25) xor d(23) xor d(21) xor d(19) xor d(17) xor d(15) xor d(11) xor d(9) xor d(8) xor d(5) xor d(4) xor d(3) xor d(1) xor d(0) xor c(0) xor c(3) xor c(6) xor c(8) xor c(9) xor c(10) xor c(11) xor c(12) xor c(13) xor c(15) xor c(17) xor c(18) xor c(19);
    newcrc(11) := d(63) xor d(62) xor d(60) xor d(58) xor d(57) xor d(56) xor d(55) xor d(54) xor d(53) xor d(51) xor d(48) xor d(45) xor d(43) xor d(42) xor d(40) xor d(39) xor d(37) xor d(36) xor d(35) xor d(33) xor d(31) xor d(29) xor d(26) xor d(24) xor d(22) xor d(20) xor d(18) xor d(16) xor d(12) xor d(10) xor d(9) xor d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor c(1) xor c(4) xor c(7) xor c(9) xor c(10) xor c(11) xor c(12) xor c(13) xor c(14) xor c(16) xor c(18) xor c(19);
    newcrc(12) := d(61) xor d(58) xor d(57) xor d(54) xor d(52) xor d(51) xor d(50) xor d(48) xor d(45) xor d(43) xor d(37) xor d(36) xor d(34) xor d(32) xor d(31) xor d(29) xor d(28) xor d(27) xor d(22) xor d(21) xor d(20) xor d(19) xor d(18) xor d(14) xor d(11) xor d(7) xor d(4) xor d(1) xor d(0) xor c(1) xor c(4) xor c(6) xor c(7) xor c(8) xor c(10) xor c(13) xor c(14) xor c(17);
    newcrc(13) := d(63) xor d(62) xor d(58) xor d(56) xor d(53) xor d(52) xor d(50) xor d(48) xor d(45) xor d(41) xor d(40) xor d(37) xor d(35) xor d(33) xor d(32) xor d(31) xor d(25) xor d(21) xor d(19) xor d(18) xor d(17) xor d(15) xor d(14) xor d(13) xor d(12) xor d(10) xor d(8) xor d(6) xor d(4) xor d(3) xor d(0) xor c(1) xor c(4) xor c(6) xor c(8) xor c(9) xor c(12) xor c(14) xor c(18) xor c(19);
    newcrc(14) := d(63) xor d(59) xor d(57) xor d(54) xor d(53) xor d(51) xor d(49) xor d(46) xor d(42) xor d(41) xor d(38) xor d(36) xor d(34) xor d(33) xor d(32) xor d(26) xor d(22) xor d(20) xor d(19) xor d(18) xor d(16) xor d(15) xor d(14) xor d(13) xor d(11) xor d(9) xor d(7) xor d(5) xor d(4) xor d(1) xor c(2) xor c(5) xor c(7) xor c(9) xor c(10) xor c(13) xor c(15) xor c(19);
    newcrc(15) := d(60) xor d(58) xor d(55) xor d(54) xor d(52) xor d(50) xor d(47) xor d(43) xor d(42) xor d(39) xor d(37) xor d(35) xor d(34) xor d(33) xor d(27) xor d(23) xor d(21) xor d(20) xor d(19) xor d(17) xor d(16) xor d(15) xor d(14) xor d(12) xor d(10) xor d(8) xor d(6) xor d(5) xor d(2) xor c(3) xor c(6) xor c(8) xor c(10) xor c(11) xor c(14) xor c(16);
    newcrc(16) := d(61) xor d(59) xor d(56) xor d(55) xor d(53) xor d(51) xor d(48) xor d(44) xor d(43) xor d(40) xor d(38) xor d(36) xor d(35) xor d(34) xor d(28) xor d(24) xor d(22) xor d(21) xor d(20) xor d(18) xor d(17) xor d(16) xor d(15) xor d(13) xor d(11) xor d(9) xor d(7) xor d(6) xor d(3) xor c(0) xor c(4) xor c(7) xor c(9) xor c(11) xor c(12) xor c(15) xor c(17);
    newcrc(17) := d(62) xor d(60) xor d(57) xor d(56) xor d(54) xor d(52) xor d(49) xor d(45) xor d(44) xor d(41) xor d(39) xor d(37) xor d(36) xor d(35) xor d(29) xor d(25) xor d(23) xor d(22) xor d(21) xor d(19) xor d(18) xor d(17) xor d(16) xor d(14) xor d(12) xor d(10) xor d(8) xor d(7) xor d(4) xor c(0) xor c(1) xor c(5) xor c(8) xor c(10) xor c(12) xor c(13) xor c(16) xor c(18);
    newcrc(18) := d(63) xor d(61) xor d(58) xor d(57) xor d(55) xor d(53) xor d(50) xor d(46) xor d(45) xor d(42) xor d(40) xor d(38) xor d(37) xor d(36) xor d(30) xor d(26) xor d(24) xor d(23) xor d(22) xor d(20) xor d(19) xor d(18) xor d(17) xor d(15) xor d(13) xor d(11) xor d(9) xor d(8) xor d(5) xor c(1) xor c(2) xor c(6) xor c(9) xor c(11) xor c(13) xor c(14) xor c(17) xor c(19);
    newcrc(19) := d(63) xor d(62) xor d(58) xor d(55) xor d(54) xor d(50) xor d(49) xor d(48) xor d(47) xor d(45) xor d(44) xor d(43) xor d(40) xor d(39) xor d(37) xor d(30) xor d(29) xor d(28) xor d(27) xor d(24) xor d(22) xor d(21) xor d(19) xor d(17) xor d(16) xor d(13) xor d(12) xor d(9) xor d(5) xor d(4) xor d(3) xor d(2) xor d(1) xor d(0) xor c(0) xor c(1) xor c(3) xor c(4) xor c(5) xor c(6) xor c(10) xor c(11) xor c(14) xor c(18) xor c(19);
    return newcrc;
  end nextCRC20_D64;

end PCK_CRC20_D64;
