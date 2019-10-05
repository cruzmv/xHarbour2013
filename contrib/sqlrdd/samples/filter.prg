/*
* SQLRDD Test
* Copyright (c) 2008 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"

#define RECORDS_IN_TEST                   1000
#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

/*------------------------------------------------------------------------*/

Function Main( cDSN, lLog )

   local aStruct := {{"CODE_ID","C",8,0 },;
                     {"CARDID","C",1,0},;
                     {"DESCR","C",50,0},;
                     {"PERCENT","N",10,2},;
                     {"DAYS","N",8,0},;
                     {"DATE_LIM","D",8,0},;
                     {"ENABLE","L",1,0},;
                     {"OBS","M",10,0},;
                     {"VALUE","N",18,6}}
   local nCnn, i

   ? ""
   ? "filter.exe"
   ? ""
   ? "Smart SET FILTER demo"
   ? "(c) 2008 - Marcelo Lombardo"
   ? ""

   ? "Connecting to database..."

   Connect( cDSN )    // see connect.prg

   ? "Connected to        :", SR_GetConnectionInfo(, SQL_DBMS_NAME ), SR_GetConnectionInfo(, SQL_DBMS_VER )
   ? "Creating table      :", dbCreate( "TEST_FILTER", aStruct, "SQLRDD" )

   USE "TEST_FILTER" EXCLUSIVE VIA "SQLRDD"

   ? "Creating 02 indexes..."

   Index on CODE_ID+DESCR            to TEST_FILTER_IND01
   Index on str(DAYS)+dtos(DATE_LIM) to TEST_FILTER_IND02

   ? "Appending " + alltrim(str(RECORDS_IN_TEST)) + " records.."

   s := seconds()

   For i = 1 to RECORDS_IN_TEST
      Append Blank
      Replace CODE_ID  with strZero( i, 5 )
      Replace DESCR    with dtoc( date() ) + " - " + time()
      Replace DAYS     with (RECORDS_IN_TEST - i)
      Replace DATE_LIM with date()
      Replace ENABLE   with .T.
      Replace OBS      with "This is a memo field. Seconds since midnight : " + alltrim(str(seconds()))
   Next

   ? "dbCloseArea()       :", dbCloseArea()

   USE "TEST_FILTER" SHARED VIA "SQLRDD"

   ? "Opening Indexes"
   SET INDEX TO TEST_FILTER_IND01
   SET INDEX TO TEST_FILTER_IND02 ADDITIVE

   SET FILTER TO DAYS < 10    // Very fast and optimized back end filter

   ? "Set Filter DAYS < 10:", dbFilter()     // Returning filter expression is translated to SQL
   ? " "
   ? "Press any key to browse()"

   inkey(0)
   clear

   browse(row()+1,1,row()+20,80)

   clear

   SET FILTER TO

   ? "Removing filter    :", dbFilter()
   ? "Press any key to browse()"

   inkey(0)
   clear

   dbGoTop()
   browse(row()+1,1,row()+20,80)

   clear

   SET FILTER TO MyFunc()    // Slow and non optimized filter

   ? "Set Filter MyFunc()  ", dbFilter()     // Returning filter expression is translated to SQL
   ? " "
   ? "Note this is pretty slower!"
   ? " "
   ? "Press any key to browse()"

   inkey(0)
   clear

   browse(row()+1,1,row()+20,80)

Return NIL

/*------------------------------------------------------------------------*/

Function MyFunc()

Return DAYS < 10

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
