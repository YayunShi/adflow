   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
   !
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          setPointers_offTSInstance.f90                   *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE SETPOINTERSOFFTSINSTANCE_SPATIAL_D(nn, sps, sps2)
   USE BLOCKPOINTERS_D
   IMPLICIT NONE
   !write(14, *),flowDoms(nn,1,sps2)%w,flowDoms(nn,1,sps2)%vol
   !
   !      ******************************************************************
   !      *                                                                *
   !      * setPointers_offTSInstance calls the normal setPointers but also*
   !      * sets w_offTimeInstance and vol_offTimeInstance which are       *
   !      * required for the forward mode AD calculations                  *
   !      *                                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   !
   !      Subroutine arguments
   !
   INTEGER(kind=inttype), INTENT(IN) :: nn, sps, sps2
   EXTERNAL SETPOINTERS
   EXTERNAL FLOWDOMS
   TYPE(#UNKNOWNDERIVEDTYPE0#) :: FLOWDOMS
   TYPE(#UNKNOWNDERIVEDTYPE0#) :: result1
   TYPE(UNKNOWNDERIVEDTYPE0) :: result1d
   CALL SETPOINTERS(nn, 1, sps)
   result1 = FLOWDOMS(nn, 1, sps2)
   w_offtimeinstanced => result1d%w
   w_offtimeinstance => result1%w
   result1 = FLOWDOMS(nn, 1, sps2)
   vol_offtimeinstanced => result1d%vol
   vol_offtimeinstance => result1%vol
   END SUBROUTINE SETPOINTERSOFFTSINSTANCE_SPATIAL_D