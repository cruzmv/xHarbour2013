/*
 * $Id: dbgthsh.prg 9935 2013-05-07 09:45:53Z zsaulius $
 */

/*
 * Harbour Project source code:
 * The Debugger Hash Inspector
 *
 * Copyright 2006 Francesco Saverio Giudice <info / at / fsgiudice / dot / com>
 * www - http://www.xharbour.org
 * www - http://www.harbour-project.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

 /*
   26/06/2006 - FSG
   Converted dbgtarr.prg to work with hashes.
 */


#include "hbclass.ch"

#include "common.ch"
#include "inkey.ch"
#include "setcurs.ch"

CREATE CLASS HBDbHash

   VAR aWindows   INIT {}
   VAR TheHash
   VAR hashName
   VAR nCurWindow INIT 0
   VAR lEditable

   METHOD New( hHash, cVarName, lEditable )

   METHOD addWindows( hHash, nRow )
   METHOD doGet( oBrowse, pItem, nSet )
   METHOD SetsKeyPressed( nKey, oBrwSets, oWnd, cName, hHash )

ENDCLASS

METHOD New( hHash, cVarName, lEditable ) CLASS HBDbHash

   DEFAULT lEditable TO .T.

   ::hashName := cVarName
   ::TheHash := hHash
   ::lEditable := lEditable
   
   ::addWindows( ::TheHash )

   RETURN Self

METHOD addWindows( hHash, nRow ) CLASS HBDbHash
   LOCAL oBrwSets
   LOCAL nSize := Len( hHash )
   LOCAL oWndSets
   LOCAL nWidth
   LOCAL nColWidth
   LOCAL oCol
   LOCAL nKeyLen

   IF nSize < MaxRow() - 2
      IF nRow != NIL
         oWndSets := HBDbWindow():New( GetTopPos( nRow ), 5, getBottomPos( nRow + nSize + 1 ), MaxCol() - 5, ::hashName + "[1.." + LTrim( Str( nSize, 6 ) ) + "]", "N/W" )
      ELSE
         oWndSets := HBDbWindow():New( 1, 5, 2 + nSize, MaxCol() - 5, ::hashName + "[1.." + LTrim( Str( nSize, 6 ) ) + "]", "N/W" )
      ENDIF
   ELSE
      oWndSets := HBDbWindow():New( 1, 5, MaxRow() - 2, MaxCol() - 5, ::hashName + "[1.." + LTrim( Str( nSize, 6 ) ) + "]", "N/W" )
   ENDIF
   ::nCurWindow++
   oWndSets:lFocused := .T.
   AAdd( ::aWindows, oWndSets )

   nWidth := oWndSets:nRight - oWndSets:nLeft - 1
   oBrwSets := TBrowseNew( oWndSets:nTop + 1, oWndSets:nLeft + 1, oWndSets:nBottom - 1, oWndSets:nRight - 1 )
   oBrwSets:autolite := .F.
   oBrwSets:ColorSpec := __Dbg():ClrModal()
   oBrwSets:Cargo := { 1, {} } // Actual highligthed row
   AAdd( oBrwSets:Cargo[ 2 ], hHash )

   oBrwSets:AddColumn( oCol := TBColumnNew( "", { || ::hashName + "[" + HashKeyString( hHash, oBrwSets:cargo[ 1 ] ) + "]" } ) )

   // calculate max key length
   nKeyLen := 0
   HEval( hHash, {| k, v, p | HB_SYMBOL_UNUSED( k ), HB_SYMBOL_UNUSED( v ), nKeyLen := Max( nKeyLen, Len( ::hashName + "[" + HashKeyString( hHash, p ) + "]" ) ) } )
   oCol:width := nKeyLen
   oCol:DefColor := { 1, 2 }
   nColWidth := oCol:Width

   oBrwSets:AddColumn( oCol := TBColumnNew( "" ,{ || PadR( __dbgValToStr( HGetValueAt( hHash, oBrwSets:cargo[ 1 ] ) ), nWidth - nColWidth - 1 ) } ) )

   /* 09/08/2004 - <maurilio.longo@libero.it>
                   Setting a fixed width like it is done in the next line of code wich I've
                   commented exploits a bug of current tbrowse, that is, if every column is
                   narrower than tbrowse but the sum of them is wider tbrowse paints
                   one above the other if code like the one inside RefreshVarsS() is called.
                   (That code is used to have current row fully highlighted and not only
                   current cell). Reproducing this situation on a smaller sample with
                   clipper causes that only column two is visible after first stabilization.

                   I think tbrowse should trim columns up until the point where at leat
                   two are visible in the same moment, I leave this fix to tbrowse for
                   the reader ;)
   oCol:width := 50
   */

   oCol:DefColor:= { 1, 3 }

   oBrwSets:goTopBlock := { || oBrwSets:cargo[ 1 ] := 1 }
   oBrwSets:goBottomBlock := { || oBrwSets:cargo[ 1 ] := Len( oBrwSets:cargo[ 2 ][ 1 ] ) }
   oBrwSets:skipBlock := { |nPos| ( nPos := HashBrowseSkip(nPos, oBrwSets), oBrwSets:cargo[ 1 ] := ;
                                    oBrwSets:cargo[ 1 ] + nPos, nPos ) }

   ::aWindows[ ::nCurWindow ]:bPainted    := { || ( oBrwSets:forcestable(), RefreshVarsS( oBrwSets ) ) }
   ::aWindows[ ::nCurWindow ]:bKeyPressed := { | nKey | ::SetsKeyPressed( nKey, oBrwSets,;
                           ::aWindows[ ::nCurWindow ],::hashName, hHash ) }

   SetCursor( SC_NONE )
   
   ::aWindows[ ::nCurWindow ]:ShowModal()

   RETURN Self

METHOD doGet( oBrowse, pItem, nSet ) CLASS HBDbHash

#ifndef HB_NO_READDBG

   LOCAL nKey
   LOCAL GetList := {}
   LOCAL lScoreSave := Set( _SET_SCOREBOARD, .F. )
   LOCAL lExitSave  := Set( _SET_EXIT, .T. )
   LOCAL bInsSave   := SetKey( K_INS )
   LOCAL oErr, bErrorBlock
   LOCAL cValue := PadR( __dbgValToStr( HGetValueAt( pItem, nSet ) ),;
                         oBrowse:nRight - oBrowse:nLeft - oBrowse:GetColumn( 1 ):width )

   // make sure browse is stable
   oBrowse:forceStable()
   // if confirming new record, append blank

   // set insert key to toggle insert mode and cursor
   SetKey( K_INS, { || SetCursor( iif( ReadInsert( ! ReadInsert() ),;
           SC_NORMAL, SC_INSERT ) ) } )

   // initial cursor setting
   SetCursor( iif( ReadInsert(), SC_INSERT, SC_NORMAL ) )

   // create a corresponding GET
   @ Row(), oBrowse:nLeft + oBrowse:GetColumn( 1 ):width + 1 GET cValue ;
      VALID iif( Type( cValue ) == "UE", ( __dbgAlert( "Expression error" ), .F. ), .T. )

   READ SAVE

   IF LastKey() == K_ENTER
      bErrorBlock := ErrorBlock( {|oErr| break( oErr ) } )
      BEGIN SEQUENCE
         HSetValueAt( pItem, nSet, &cValue )
      RECOVER USING oErr
         __dbgAlert( oErr:description )
      END SEQUENCE
      ErrorBlock( bErrorBlock )
   ENDIF

   SetCursor( SC_NONE )
   Set( _SET_SCOREBOARD, lScoreSave )
   Set( _SET_EXIT, lExitSave )
   SetKey( K_INS, bInsSave )

   // check exit key from get
   nKey := LastKey()
   IF nKey == K_UP .OR. nKey == K_DOWN .OR. nKey == K_PGUP .OR. nKey == K_PGDN
      KEYBOARD Chr( nKey )
   ENDIF

#endif

   RETURN NIL

METHOD SetsKeyPressed( nKey, oBrwSets, oWnd, cName, hHash ) CLASS HBDbHash

   LOCAL nSet := oBrwSets:cargo[ 1 ]
   LOCAL cOldname := ::hashName
   LOCAL uValue

   DO CASE
   CASE nKey == K_UP
      oBrwSets:Up()

   CASE nKey == K_DOWN
      oBrwSets:Down()

   CASE nKey == K_HOME .OR. nKey == K_CTRL_PGUP .OR. nKey == K_CTRL_HOME
      oBrwSets:GoTop()

   CASE nKey == K_END .OR. nKey == K_CTRL_PGDN .OR. nKey == K_CTRL_END
      oBrwSets:GoBottom()

   CASE nKey == K_PGDN
      oBrwSets:pageDown()

   CASE nKey == K_PGUP
      oBrwSets:PageUp()

   CASE nKey == K_ENTER

      uValue := HGetValueAt( hHash, nSet )

      IF hb_isHash( uValue )

         IF Len( uValue ) == 0
            __dbgAlert( "Hash is empty" )
         ELSE
            SetPos( ownd:nBottom, ownd:nLeft )
            ::aWindows[ ::nCurwindow ]:lFocused := .F.

            ::hashName:= ::hashName + "[" + HashKeyString( hHash, nSet ) + "]"
            ::AddWindows( HGetValueAt( hHash, nSet ), oBrwSets:RowPos + oBrwSets:nTop )
            ::hashName := cOldName

            ADel( ::aWindows, ::nCurWindow )
            ASize( ::awindows, Len( ::awindows ) - 1 )
            IF ::nCurwindow == 0
               ::nCurwindow := 1
            ELSE
               ::nCurwindow--
            ENDIF
         ENDIF
      ELSEIF ISBLOCK( uValue ) .OR. hb_isPointer( uValue )
         __dbgAlert( "Value cannot be edited" )
      ELSE
         IF ::lEditable
            oBrwSets:RefreshCurrent()
            IF ISOBJECT( uValue )
               __DbgObject( uValue, cName + "[" + HashKeyString( hHash, nSet ) + "]" )
            ELSEIF ISARRAY( uValue )
               __DbgArrays( uValue, cName + "[" + HashKeyString( hHash, nSet ) + "]" )
            ELSE
               ::doGet( oBrwSets, hHash, nSet )
            ENDIF
            oBrwSets:RefreshCurrent()
            oBrwSets:ForceStable()
         ELSE
            __dbgAlert( "Value cannot be edited" )
         ENDIF
      ENDIF

   ENDCASE

   RefreshVarsS( oBrwSets )

   ::aWindows[ ::nCurwindow ]:SetCaption( cName + "[" + hb_NToS( oBrwSets:cargo[ 1 ] ) + ".." + ;
                                          hb_NToS( Len( hHash ) ) + "]" )

   RETURN self

FUNCTION __dbgHashes( hHash, cVarName, lEditable )
   RETURN HBDbHash():New( hHash, cVarName, lEditable )

STATIC FUNCTION GetTopPos( nPos )
   RETURN iif( ( MaxRow() - nPos ) < 5, MaxRow() - nPos, nPos )

STATIC FUNCTION GetBottomPos( nPos )
   RETURN iif( nPos < MaxRow() - 2, nPos, MaxRow()-2 )

STATIC PROCEDURE RefreshVarsS( oBrowse )

   LOCAL nLen := oBrowse:colCount

   IF nLen == 2
      oBrowse:deHilite():colPos := 2
   ENDIF
   oBrowse:deHilite():forceStable()

   IF nLen == 2
      oBrowse:hilite():colPos := 1
   ENDIF
   oBrowse:hilite()

   RETURN

STATIC FUNCTION HashBrowseSkip( nPos, oBrwSets )
   RETURN iif( oBrwSets:cargo[ 1 ] + nPos < 1, 0 - oBrwSets:cargo[ 1 ] + 1 , ;
             iif( oBrwSets:cargo[ 1 ] + nPos > Len( oBrwSets:cargo[ 2 ][ 1 ] ), ;
                Len( oBrwSets:cargo[ 2 ][ 1 ] ) - oBrwSets:cargo[ 1 ], nPos ) )

STATIC FUNCTION HashKeyString( hHash, nAt )

   LOCAL xVal  := HGetKeyAt( hHash, nAt )
   LOCAL cType := ValType( xVal )

   DO CASE
   CASE cType == "C" ; RETURN '"' + xVal + '"'
   CASE cType == "D" ; RETURN '"' + DToC( xVal ) + '"'
   CASE cType == "N" ; RETURN hb_NToS( xVal )
   ENDCASE
  
   RETURN AllTrim( CStr( xVal ) )
