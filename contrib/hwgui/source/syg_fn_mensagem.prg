/*
 *   $Id: syg_fn_mensagem.prg 2818 2012-09-02 06:17:51Z leonardo $
 */

*===============================================================================
* syg_fn_mensagem
*-------------------------------------------------------------------------------
* funções de mensagens e diálogos de decisão com usuários
*-------------------------------------------------------------------------------
*
*
*
*-------------------------------------------------------------------------------
* 2012.03.01 amb  Re-estruturação e testes
* 2011.10.19 amb  Adaptações do novo modelo
* 2010.01.10 mac  Atualizações
* 2005.01.10 leo  1ª versão
*===============================================================================
#pragma /w2
#pragma /es2

#include "windows.ch"
#include "guilib.ch"

*===============================================================================
* sygDialogo
*-------------------------------------------------------------------------------
* Mostra mensagem de diálogo para o usuario
*===============================================================================

function sygDialogo(;
  cMsg,; // Mensagem a ser apresentada
  bBlc ) // Bloco ... em construçao versão posterior

static oDlgHab

  IF cMsg=nil
     cMsg=''
  ENDIF

* Destrói o objeto da memória
*______________________________________
  if Empty(cMsg)
    if oDlgHab <> nil
       oDlgHab:Close()
       oDlgHab:= nil
    endif
    return nil
  endif

  if oDlgHab == nil
    oDlgHab:= CriaObjDialogo()
  endif

  AtualizaDialogo(cMsg, @oDlgHab)

  IF bBlc#NIL
     IF ValType(bBlc) = 'B'
        EVAL( bBlc )
        if oDlgHab <> nil
           oDlgHab:Close()
           oDlgHab:= nil
        endif
     ENDIF
  ENDIF
return nil

*===============================================================================
* sygCriaObjDialogo(cMsg, oDlg )
*===============================================================================
static function CriaObjDialogo()
  local oBox
  local oAnime, oTimHabla

  INIT DIALOG oBox TITLE "Processando..." NOEXIT NOEXITESC ;//NOCLOSABLE;
  AT 0,0 SIZE 485,60 ;
  ON EXIT {|| HWG_NOSAIDAF4() };
  STYLE WS_POPUP+WS_SYSMENU+WS_SIZEBOX+DS_CENTER;
  COLOR Rgb(255, 255, 255)

  @ 45,26 SAY oTimHabla CAPTION "Aguarde, em processamento." SIZE 465,20;
              FONT HFont():Add( '',0,-11,400,,,);
              BACKCOLOR Rgb(255, 255, 255)

  @  5,20 ANIMATION oAnime ;
          OF oBox ;
          Size 32,32;
          File "res\processando.avi";
          AUTOPLAY

  oAnime:Play()

  ACTIVATE DIALOG oBox NOMODAL

return oBox

*===============================================================================
*
*-------------------------------------------------------------------------------
*
*===============================================================================
static function AtualizaDialogo(cMsg, oDlg)
  local E
  IF EMPTY(cMsg) .or. VALTYPE(cMsg)#'C'
     cMsg:="Aguarde, em processamento..."
  ENDIF

  try
    oDlg:ACONTROLS[1]:SETTEXT(cMsg)
    // oDlgHabla:ACONTROLS[1]:REFRESH()
  catch E
    // HWG_DOEVENTS()
  end
return nil

*****************************
STATIC FUNCTION HWG_NOSAIDAF4
*****************************
if getkeystate(VK_F4,.F.,.T.) < 0
   RETURN .F.
ENDIF
RETURN .T.
