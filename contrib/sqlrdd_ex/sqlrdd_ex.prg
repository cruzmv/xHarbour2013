#include "fileio.ch"
#include "Setcurs.ch"
#include "Directry.ch"
#include "common.ch"
#include 'inkey.ch'
#include 'dbinfo.ch'
#include "hbclass.ch"

#include "sqlrdd.ch"
#include "pgs.ch"        // PARA POSTGRESQL

******************************
FUNCTION AJUSTA_CONEXAO_SQLRDD
******************************

OVERRIDE METHOD CONNECTRAW IN CLASS SR_PGS WITH SYG_CONNECTRAW
//ESSE COMANDO ACIMA FAZ COM QUE A FUNÇÃO: MYCONNECTRAW() SUBISTITUA A FUNÇÃO: CONNECTRAW DENTRO DA CLASSE SR_PGS(SQLRDD)

RETURN


STATIC FUNCTION SYG_CONNECTRAW( cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace,;
            cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit )
/*
ESSA FUNÇÃO É USADA PARA FAZER A CONEXÃO COM O BANCO DE DADOS NO POSTGRESQL COM O SQLRDD
*/
   local hEnv := 0, hDbc := 0
   local nret, cVersion := "", cSystemVers := "", cBuff := ""
   Local aRet := {}
   LOCAl Self := HB_QSelf()

   (cDSN)
   (cUser)
   (cPassword)
   (nVersion)
   (cOwner)
   (nSizeMaxBuff)
   (lTrace)
   (nPrefetch)
   (nSelMeth)
   (nEmptyMode)
   (nDateMode)
   (lCounter)
   (lAutoCommit)

   //DEFAULT ::cPort := 5432
   IF EMPTY(::cPort)
      ::cPort := 5432
   ENDIF
   cConnect := "host=" + ::cHost + " user=" + ::cUser + " password=" + ::cPassword + " dbname=" + ::cDTB + " port=" + str(::cPort,6)

*   IF !Empty( ::sslcert )
*      cConnect += " sslmode=prefer sslcert="+::sslcert +" sslkey="+::sslkey +" sslrootcert="+ ::sslrootcert +" sslcrl="+ ::sslcrl
*   ENDIF

   hDbc := PGSConnect( cConnect )
   nRet := PGSStatus( hDbc )

   if nRet != SQL_SUCCESS .and. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode = nRet
      SR_MsgLogFile( "Connection Error: " + alltrim(str(PGSStatus2( hDbc ))) + " (see pgs.ch)" )
      Return Self
   else
      ::cConnect = cConnect
      ::hStmt    = NIL
      ::hDbc     = hDbc
      cTargetDB  = "PostgreSQL Native"
      ::exec( "select version()",.t.,.t.,@aRet )
      If len (aRet) > 0
         cSystemVers := aRet[1,1]
      Else
         cSystemVers= "??"
      EndIf
   EndIf

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers
   ::nSystemID   := SYSTEMID_POSTGR
   ::cTargetDB   := Upper( cTargetDB )

   // na linha abaixo acresenta as versões suportadas pelo SQLRDD
   If ! ("7.3" $ cSystemVers .or. "7.4" $ cSystemVers .or. "8.0" $ cSystemVers .or. "8.1" $ cSystemVers .or. "8.2" $ cSystemVers .or. "8.3" $ cSystemVers .or. "8.4" $ cSystemVers .or. "9.0" $ cSystemVers .or. "9.1" $ cSystemVers)
      ::End()
      ::nRetCode  := SQL_ERROR
      ::nSystemID := NIL
      SR_MsgLogFile( "Unsupported Postgres version: " + cSystemVers )
   EndIf

   ::exec( "select pg_backend_pid()", .T., .T., @aRet )

   If len( aRet ) > 0
      ::uSid := val(str(aRet[1,1],8,0))
   EndIf

return Self

