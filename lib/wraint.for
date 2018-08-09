      SUBROUTINE WRAINT (XNAME,X,ILDEC,IFND)
      IMPLICIT NONE

*     FORMAL_PARAMETERS:
      CHARACTER*(*) XNAME
      INTEGER ILDEC,IFND
      INTEGER X(ILDEC)

**    local variables ; dummy set
      INCLUDE 'wr_sys.inc'
      INTEGER XNAME_L, I1, I2
      INTEGER NCOL
      PARAMETER (NCOL=3)
      SAVE

      IF (.NOT.INIT) CALL FATALERR ('WRAINT','system not initialized')
      IF (IFND.GT.ILDEC) CALL FATALERR ('WRAINT','error')

      XNAME_L = LEN_TRIM (XNAME)

      IF (IFND.EQ.1) THEN
         WRITE (UNIT,'(1X,2A,I11)')
     &         XNAME(1:XNAME_L),' = 1*',X(1)
      ELSE
         WRITE (UNIT,'(1X,2A,I11,10(A,I11))')
     &      XNAME(1:XNAME_L),' = ',X(1),
     &      (',',X(I1),I1=2,MIN (NCOL, IFND))

         IF (IFND.GT.NCOL) THEN
*           remaining data have to be written
            DO I1=NCOL+1,IFND,NCOL
               WRITE (UNIT,'(1X,2A,I11,10(A,I11))')
     &            SPACE(1:XNAME_L),'   ',
     &            X(I1),(',',X(I2),I2=I1+1,MIN (NCOL+I1-1, IFND))
            END DO
         END IF
      END IF

      RETURN
      END
