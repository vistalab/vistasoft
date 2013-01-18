/******************************************************************************

File        : utils.hh

Date        : Wednesday 13th September 2000

Author      : Dr Gavin C. Cawley

Description : Various inline utility functions.

History     : 07/07/2000 - v1.00
              13/09/2000 - v1.01 minor changes to comments

Copyright   : (c) Dr Gavin C. Cawley, September 2000.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

******************************************************************************/

double inline min(double a, double b)
{
   return a < b ? a : b;
}

double inline max(double a, double b)
{
   return a > b ? a : b;
}

double inline square(double x)
{
   return x*x;
}

/***************************** That's all Folks! *****************************/

