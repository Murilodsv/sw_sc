! File VersionID:
!   $Id: MacroPore.for 176 2010-03-13 11:36:14Z kroes006 $
! ----------------------------------------------------------------------
!
!
!************************************************************************
      SUBROUTINE MACROPORE(ITask)
! ----------------------------------------------------------------------
!     Date               : 22/08/02                                        
!     Purpose            : Calculation of macropore volume, vertical flow into 
!                          and through macropores, lateral exchange of water 
!                          between macropores and soil matrix, and 
!                          rapid drainage via macropore (crack) system 
!     Subroutines called : MACROGEOM, MACROINIT, MACROSTATE                            
!     Functions called   : -
!     File usage         : -           
! ----------------------------------------------------------------------
      use Variables
      implicit NONE

! ----------------------------------------------------------------------
! --- local
      integer ICpBtDm(MaDm), ICpBtPerZon, ICpSatGWl
      integer ICpSatPeGWl, ICpTpPerZon, ICpTpSatZon, ICpTpWaSrDm(MaDm)
      integer ITask, NnCrAr
      real*8  ArMpSsDm(MaDm), AwlCorFac(MaCp),FrMpWalWet(MaDm,MaCp) 
      real*8  KDCrRlRef(MaDr), QExcMtxDmCp(MaDm,MaCp) 
      real*8  QInIntSatDmCp(MaDm,MaCp), QInMtxSatDmCp(MaDm,MaCp)
      real*8  QInTopLatDm(MaDm), QInTopPreDm(MaDm), QOutDrRapCp(MaCp)
      real*8  QOutMtxSatDmCp(MaDm,MaCp), QOutMtxUnsDmCp(MaDm,MaCp)
      real*8  SorpDmCp(MaDm,MaCp), ThtSrpRefDmCp(MaDm,MaCp)
      real*8  TimAbsCumDmCp(MaDm,MaCp), VlMpDm(MaDm), VlMpDyCp(MaCp)
      real*8  VlMpDmCp(MaDm,MaCp), WaSrMpDm(MaDm)
      real*8  WaSrMpDmCp(MaDm,MaCp),WaSrMp, ZBtDm(MaDm), ZWaLevDm(MaDm)
      logical flBegin,flDraTub(Madr), FlEndSrpEvt(MaDm,MaCp)

!      integer itel

!      character comma*1
!      comma= ','

! ----------------------------------------------------------------------
      goto(1000,2000,3000,4000,5000,6000) ITASK
!
!- A. INITIAL CALCULATIONS
1000  continue
!  -- Determine macropore geometry (incl. static macropore volume)
      call MACROGEOM

!  -- Initialisation of flag for drain tube flDraTub and drainage basis ZDraBas
      if (SwDrRap.Eq.1 .and. SwDra.gt.0) then
         if (SwDra.eq.1 .and. flInitDraBas) call drainage
!   - Flag indicating whether drainage system is tube or open drain
         flDraTub(1) = .false.
         if (SwDTyp(NumLevRapDra).eq.1) flDraTub(1) = .true.
      endif

!  -- Initialisation of flag to indicate beginning of simulation period for 
!     subroutine MACROINTEGRAL
      flBegin = .true.

!  -- Initial calculations
      call MACROINIT(ICpBtDm,ICpTpWaSrDm,NnCrAr,flDraTub,FlEndSrpEvt,       
     &        AwlCorFac,KDCrRlRef,QExcMtxDmCp,QInTopLatDm,QInTopPreDm,
     &        QOutDrRapCp,SorpDmCp,ThtSrpRefDmCp,TimAbsCumDmCp,VlMpDmCp,
     &        VlMpDyCp,WaSrMpDm)

!  -- Calculate INITIAL dynamic macropore (crack) volume, total macropore volume
!     per domain and per compartment, and area of macropores at soil surface
      ICpTpSatZon= NodGwL + 1
      call MACROSTATE(NnCrAr,FlEndSrpEvt,QExcMtxDmCp,
     &        QInTopLatDm,QInTopPreDm,QOutDrRapCp,WaSrMpDm,
     &        ICpBtDm,ICpBtPerZon,ICpSatGWl,ICpSatPeGWl,ICpTpPerZon,
     &        ICpTpSatZon,ICpTpWaSrDm,ArMpSsDm, AwlCorFac,FrMpWalWet,
     &        SorpDmCp,ThtSrpRefDmCp, TimAbsCumDmCp,VlMpDm,VlMpDmCp,
     &        VlMpDyCp,WaSrMp,WaSrMpDmCp,ZBtDm,ZWaLevDm)

!  -- Calculate initial waterstorage in matrix on basis FrArMtrx 
      volact = 0.0d0
      call watstor (volm1,volact,numnod,theta,dz,FrArMtrx)
      volini = volact

!  -- Initialisation of intermediate and cumulative values
      call MACRORESET(0)

      return

!- B. DYNAMICAL CALCULATIONS (within TIME STEP LOOP)
2000  continue
!  -- Calculations of Rates: 
      call MACRORATE(1,ICpBtDm,ICpBtPerZon,ICpSatGWl,ICpSatPeGWl,
     &        ICpTpPerZon,ICpTpSatZon,ICpTpWaSrDm,ArMpSsDm,AwlCorFac,
     &        FrMpWalWet,KDCrRlRef,SorpDmCp,ThtSrpRefDmCp,TimAbsCumDmCp,
     &        VlMpDm,VlMpDmCp,WaSrMp,WaSrMpDm,ZBtDm,ZWaLevDm,
     &        flDraTub,FlEndSrpEvt,
     &        QExcMtxDmCp,QInIntSatDmCp,QInMtxSatDmCp,QInTopLatDm,
     &        QInTopPreDm,QOutDrRapCp,QOutMtxSatDmCp,QOutMtxUnsDmCp)
      return

3000  continue
!  -- Calculations of derivatives dFdhMp:
      call MACRORATE(2,ICpBtDm,ICpBtPerZon,ICpSatGWl,ICpSatPeGWl,
     &        ICpTpPerZon,ICpTpSatZon,ICpTpWaSrDm,ArMpSsDm,AwlCorFac,
     &        FrMpWalWet,KDCrRlRef,SorpDmCp,ThtSrpRefDmCp,TimAbsCumDmCp,
     &        VlMpDm,VlMpDmCp,WaSrMp,WaSrMpDm,ZBtDm,ZWaLevDm,          
     &        flDraTub,FlEndSrpEvt,
     &        QExcMtxDmCp,QInIntSatDmCp,QInMtxSatDmCp,QInTopLatDm,
     &        QInTopPreDm,QOutDrRapCp,QOutMtxSatDmCp,QOutMtxUnsDmCp)
      return

4000  continue
!  -- Calculation of States
!     Calculate dynamic macropore (crack) volume, total macropore volume
!     per domain and per compartment, and area of macropores at soil surface, etc.
      call MACROSTATE(NnCrAr,FlEndSrpEvt,QExcMtxDmCp,
     &        QInTopLatDm,QInTopPreDm,QOutDrRapCp,WaSrMpDm,
     &        ICpBtDm,ICpBtPerZon,ICpSatGWl,ICpSatPeGWl,ICpTpPerZon,
     &        ICpTpSatZon,ICpTpWaSrDm,ArMpSsDm, AwlCorFac,FrMpWalWet,
     &        SorpDmCp,ThtSrpRefDmCp, TimAbsCumDmCp,VlMpDm,VlMpDmCp,
     &        VlMpDyCp,WaSrMp,WaSrMpDmCp,ZBtDm,ZWaLevDm)

!  -- integration of Cumulative and Intermediate values
      call MACROINTEGRAL(flBegin,FrMpWalWet,
     &         QInIntSatDmCp,QInMtxSatDmCp,QInTopLatDm,QInTopPreDm,
     &         QOutDrRapCp,QOutMtxSatDmCp,QOutMtxUnsDmCp) 
      return

5000  continue
!  -- reset intermediate soil water fluxes
      call MACRORESET(1)
      return

6000  continue
!  -- reset cumulative soil water fluxes
      call MACRORESET(2)
      return

      end

!=======================================================================
      SUBROUTINE MACROGEOM               
! ----------------------------------------------------------------------
!     Date               : 26/06/02                                        
!     Purpose            : Geometry of macropore volume. 
!                          Calculation per compartment of:
!                          1. Proportion PpDmCp of macropore volume in Main 
!                             Bypass flow domain and Internal Catchment domains
!                          2. Static macropore volume VlMpStCp
!     Subroutines called : DEFINECOMPART                              
!     Functions called   : -
!     File usage         : -           
! ----------------------------------------------------------------------
      use Variables
      implicit NONE

! ----------------------------------------------------------------------
! --- local
      integer ic, id, IdNx(MaCp+4), jd, NumCpXtr, NumHlp, NumSbDmCp
      real*8  Alfa, AlfaSt, Beta, BetaSt, DiamPolyg, DzAhIc, DzCp,NmZbot
      real*8  NmZtop, Pm, PpIcCp(MaCp), PpMbSs, Sm, RelVlIc(MaCp)
      real*8  RelVlIcSt(MaCp), RelVlIcTo, RelVlMb(MaCp), RelVlMbSt(MaCp) 
      real*8  UnPpIc, Zbot(MaCp+4), Zmid
      real*8  Ztop(MaCp+4), Z_Sp, ZzTpBt

! ----------------------------------------------------------------------
!
!--- Mb =  Main Bypass flow; Ic = Internal Catchment
!
!- A. INITIAL CALCULATIONS:
!   - limit the value of Rzah (R-value at bottom of A-horizon)
      if (Rzah.gt.0.99d0) Rzah= 1.d0
      if (Rzah.lt.1.d-2) Rzah= 0.d0
!   - SPoint = (nearly) 0 has same function as = 1 and gets value 1 for calculations  
      if (SPoint.lt.1.0d-2) SPoint= 1.d0

!   - depth Z of top and bottom of each compartment (z = negative; dz= positive)
      Ztop(1)= 0.d0
      Zbot(1)= -DZ(1)
      do 10 ic= 2, NumNod
         Ztop(ic)= Zbot(ic-1)
         Zbot(ic)= Ztop(ic) - Dz(ic)
  10  continue

!   - define temporary compartments for calculation of macropore geometry
      call DEFINECOMPART(Zbot,Ztop,NumCpXtr,IdNx,Z_Sp)

!- B. CALCULATION OF PpIcCp AND VlMpStCp 
!     PpIcCp= ProPortion of Ic domain; VlMpStCp= STatic VoLume MacroPores                         
!  -- initialize RELative VoLumes
      do 20 ic= 1, NumNod
         RelVlMb(ic)  = 0.d0
         RelVlMbSt(ic)= 0.d0
         RelVlIc(ic)  = 0.d0
         RelVlIcSt(ic)= 0.d0
  20  continue

!  -- integration of the relative volume curves over the NEW compartm. thickness
      do 30 ic= 1, NumNod+NumCpXtr

!   - define help Z's for integration(Z= negative!): 
         Zmid= (Ztop(ic)+Zbot(ic))/2.d0
         DzCp= Ztop(ic) - Zbot(ic)
         if (Zmid.lt.Z_Ah .and. Zmid.gt.Z_Ic) then
            DzAhIc= Z_Ah - Z_Ic
!   - NorMalised Ztop and Zbot
            NmZtop= dmax1(0.d0,(Z_Ah - Ztop(ic)))/DzAhIc
            NmZbot= (Z_Ah - Zbot(ic))/DzAhIc
         endif
         ZzTpBt= Ztop(ic) + Zbot(ic)

!   - integrate relative volume curves of Mb domain over compartment thickness: 
!     Alfa for calculation of PpIcCp, and AlfaSt for Mb domain part of VlMpStCp
         if (Zmid.gt.Z_Ic) then
            Alfa= DzCp
         elseif (Zmid.gt.Z_St) then
            Alfa= DzCp * (ZzTpBt - 2.d0*Z_St)/(2.d0*(Z_Ic-Z_St))
         else
            Alfa= 0.d0
         endif
         AlfaSt= Alfa
!   - no static volume below Z_St (also if Z_St > Z_Ic)
!     (criterium: depth Z of ORIGINAL node deeper than Z_St)
         if (Z(IdNx(ic)).lt.Z_St) AlfaSt= 0.d0

!   - integrate relative volume curves of Ic domain over compartment thickness: 
!     Beta for calculation of PpIcCp, and BetaSt for Ic domain part of VlMpStCp
         if (Zmid.gt.Z_Ah) then
            Beta= DzCp * (1.d0 - ZzTpBt*Rzah/(2.d0*Z_Ah))
         elseif (Zmid.gt.Z_Ic) then
            if (Zmid.gt.Z_Sp) then
               Sm= (Spoint**(1.d0-PowM))/(PowM+1.d0)
               Beta= (1.d0-Rzah) * (DzCp + DzAhIc*Sm*
     &               (NmZtop**(PowM+1.d0) - NmZbot**(PowM+1.d0)))
            else 
               Pm= PowM
               if (SwPowM.eq.1) Pm= 1.d0/PowM
               Sm= ((1.d0-Spoint)**(1.d0-Pm))/(Pm+1.d0)
               Beta= (1.d0-Rzah) * (DzAhIc*Sm* 
     &         ((1.d0-NmZtop)**(Pm+1.d0) -(1.d0-NmZbot)**(Pm+1.d0)))
            endif
         else
            Beta= 0.d0
         endif
!   - no IC volume below Z_Ic (criterium: depth Z of ORIGINAL node below Z_Ic)
        if (Z(IdNx(ic)).lt.Z_Ic) Beta  = 0.d0
         BetaSt= Beta
!   - no static volume below Z_St (also if Z_St > Z_Ic) (crit: ORIG Z below Z_St)
         if (Z(IdNx(ic)).lt.Z_St) BetaSt= 0.d0

!   - calculate for ORIGINAL compartments RELative VoLume of macropores
!     (cm3 per cm2 of unit horizontal area; because of integration over Dz)
!     - Mb domain (PpIcSs= PpIcCp at Soil Surface)
         PpMbSs= 1.d0 - PpIcSs
         RelVlMb(IdNx(ic))  = RelVlMb(IdNx(ic))   + Alfa  *PpMbSs
         RelVlMbSt(IdNx(ic))= RelVlMbSt(IdNx(ic)) + AlfaSt*PpMbSs
!     - Ic domain
         RelVlIc(IdNx(ic))  = RelVlIc(IdNx(ic))   + Beta  *PpIcSs
         RelVlIcSt(IdNx(ic))= RelVlIcSt(IdNx(ic)) + BetaSt*PpIcSs
  30  continue

!  -- calculation PpIcCp and VlMpStCp for the ORIGINAL compartments
      do 40 ic= 1, NumNod
!   - propotion PpIcCp of Ic domain
         if (RelVlIc(ic).gt.0.d0) then
            PpIcCp(ic)= RelVlIc(ic) / (RelVlMb(ic) + RelVlIc(ic))
         else
            PpIcCp(ic)= 0.d0
         endif
!   - static macropore volume VlMpStCp (VlMpStSs= VlMpStCp at Soil Surface)
!     in cm3 per cm2 of unit horizontal area
         VlMpStCp(ic)= VlMpStSs * (RelVlMbSt(ic) + RelVlIcSt(ic)) 
!   - fraction of unit of horizontal area that is left for soil matrix after 
!     substraction of static macropores
         FrArMtrx(ic)= 1.d0 - VlMpStCp(ic)/Dz(ic)
  40  continue

!- C. CALCULATION OF VOLUMETRIC PROPORTIONS PER COMPARTMENT FOR THE MP DOMAINS 
      if (PpIcSs.gt.0.d0) then 
         if (Rzah.lt.0.991d0) then
!   - NumDm (number of domains) = 1 Mb domain + NumSbDm Ic subdom. (+ 1 Ah dom.) 
            NumDm= NumSbDm + 1
            if (Rzah.gt.1.d-3) NumDm= NumDm + 1
            UnPpIc= PpIcSs*(1.d0-Rzah) / float(NumSbDm)
            do 50 ic= 1, NumNod
               if (PpIcCp(ic).gt.1.0d-3) then
                  NumSbDmCp= idint(RelVlIc(ic)/(UnPpIc*Dz(ic)))
                  NumSbDmCp= min0(NumSbDm,NumSbDmCp)
!   - PpDmCp: ProPortion per compartment per DoMain ; index 1 = Mb domain 
                  PpDmCp(1,ic)= 1.d0 - PpIcCp(ic) 
                  do 47 id= 2, NumSbDmCp+1
                     PpDmCp(id,ic)= PpIcCp(ic)*UnPpIc*Dz(ic)/RelVlIc(ic)
  47              continue
                  RelVlIcTo= float(NumSbDmCp)*UnPpIc*Dz(ic)
                  PpDmCp(NumSbDmCp+2,ic)= PpIcCp(ic) * 
     &                                    (1.d0-RelVlIcTo/RelVlIc(ic))
                  do 48 id= NumSbDmCp+3, NumDm
                     PpDmCp(id,ic)= 0.d0
  48              continue
               else
!   - no IC-domain, no SUBdomains
                  PpDmCp(1,ic)= 1.d0
                  do 49 id= 2, NumDm
                     PpDmCp(id,ic)= 0.d0
  49              continue
                  if (ic.eq.1) NumDm = 1
               endif
  50        continue
         else
!   - only one SUBdomain within the IC-domain: the Ah domain
            NumDm= 2
            do 60 ic= 1, NumNod
               PpDmCp(1,ic)= 1.d0 - PpIcCp(ic)
               PpDmCp(2,ic)= PpIcCp(ic)
  60        continue
         endif
      else
!   - no IC-domain
         NumDm= 1
         NumSbDm= 0
         do 70 ic= 1, NumNod
            PpDmCp(1,ic)= 1.d0
  70     continue
      endif

!- D. LUMPING OF IC SUBDOMAINS THAT END IN THE SAME COMPARTMENT
!  -- determine for each domain: POTential bottom (= deepest) compartment number 
!     with macropore volume(ICpBtDmPot) 
      ICpBtDmPot(1)= NumNod
      do 80 id= 2, NumDm
         ic= 1
         do 79 while(PpDmCp(id,ic).gt.0.d0 .and. ic.le.NumNod)
            ic= ic + 1
  79     continue
         ICpBtDmPot(id)= ic - 1
  80  continue

!  -- lumping of PpDmCp
      NumHlp= NumDm
      if (Rzah.gt.1.d-3) NumHlp= NumHlp - 1
      do 90 id= NumHlp, 3, -1
         if (ICpBtDmPot(id).eq.ICpBtDmPot(id-1)) then
            do 87 ic= 1, ICpBtDmPot(id)
               PpDmCp(id-1,ic)= PpDmCp(id-1,ic) + PpDmCp(id,ic) 
  87        continue
            do 89 jd= id, NumDm-1
               do 88 ic= 1, ICpBtDmPot(jd)
                  PpDmCp(jd,ic)= PpDmCp(jd+1,ic)
                  PpDmCp(jd+1,ic)= 0.d0
  88           continue
               ICpBtDmPot(jd)= ICpBtDmPot(jd+1)
  89        continue 
            NumDm= NumDm - 1
         endif
  90  continue

!  -- lump Ah domain only when neighbour domain < 0.5 Ah domain
      if (NumDm.gt.1 .and. Rzah.gt.1.d-3 .and. 
     &    PpDmCp(NumDm,1).gt.2.d0*PpDmCp(NumDm-1,1)) then
         if (ICpBtDmPot(NumDm).eq.ICpBtDmPot(NumDm-1)) then
            do 100 ic= 1, ICpBtDmPot(NumDm)
               PpDmCp(NumDm-1,ic)= PpDmCp(NumDm-1,ic) + PpDmCp(NumDm,ic)
               PpDmCp(NumDm,ic)= 0.d0
 100        continue
            NumDm= NumDm - 1
         endif
      endif
      do 105 id= NumDm+1, NumSbDm+1
         ICpBtDmPot(id)= 0
 105  continue


!- E. DETERMINE DiPoCp, first calculation: DIameter of soil matrix POlygon per  
!     ComPartment as a function of macropore density MpDs with depth
      do 110 ic= 1, NumNod
         DiPoCp(ic)= DiamPolyg(DiPoMa,DiPoMi,Dz(ic),PpIcCp(ic),PpIcSs,
     &                         VlMpStCp(ic),VlMpStSs,Z(1),Z(ic),ZDiPoMa)
 110  continue

!- F. DETERMINE DiPoCp, final calculation for macropores below Z_ic
      do 120 ic= ICpBtDmPot(2)+1, NumNod
         DiPoCp(ic)= DiamPolyg(DiPoMa,DiPoMi,Dz(ic),PpIcCp(ic),PpIcSs,
     &                         VlMpStCp(ic),VlMpStSs,Z(1),Z(ic),ZDiPoMa)
 120  continue

!- G. DETERMINE VlMpStDm1(ic) and -Dm2(ic): VoLume of STatic MacroPores per
!     compartment for DoMain 1 (Main Bypass) and 2 (Internal Catchment)
      do 130 ic= 1, NumNod
         VlMpStDm1(ic)= PpDmCp(1,ic) * VlMpStCp(ic)
         VlMpStDm2(ic)= 0.d0
         do 129 id= 2, NumDm
            VlMpStDm2(ic)= VlMpStDm2(ic) + PpDmCp(id,ic) * VlMpStCp(ic)
 129     continue
 130  continue


!!!!!!!!!!!!!!!!!!!!!
!      open(unit=89,file='MacropDom.wid',status='unknown')
!      write(89,1)  (' PpDm',id,id=1,NumDm)
!
!      do 130 ic= 1, NumNod
!         do 129 id= 1, NumDm
!            VlHlp = PpDmCp(id,ic) * VlMpStCp(ic)
!            WthMp(id) = DiPoCp(ic) * (1.d0 - sqrt(1.d0-  VlHlp/DZ(ic))) ! in cm
! 129     continue
!         write(89,'(I4,23F7.0)') ic, (1.0d0+4*WthMp(id),id=1,NumDm) ! in um
! 130  continue
!      close(1)
!   1  format('Width of Static macropores per domain in um (micro m)'/
!     &'Note: Domain width < 55 um at soil surface is NO macropore'/
!     &'      Domain width < 30 um below soil surface is NO macropore'/
!     &'Comp',20(a,i2.2))

! ---- 
      return
      end

!.......................................................................
      SUBROUTINE DEFINECOMPART(Zbot,Ztop,NumCpXtr,IdNx,Z_Sp)
!     Date               : 15/05/02                                        
!     Purpose            : Defining of temporary extra compartments based on the 
!                          depths of Z_Ah, Z_Ic, Z_St and Z_Sp, and temporary
!                          renumbering of the total of compartments            
!     Subroutines called : -                             
!     Functions called   : -
!     File usage         : -                                           
! ----------------------------------------------------------------------
      use Variables
      implicit NONE

! --- global                                                         In
      real*8 Zbot(MaCp+4), Ztop(MaCp+4)

!     -                                                              Out
      integer IdNx(MaCp+4), NumCpXtr
      real*8  Z_Sp
! ----------------------------------------------------------------------
! --- local
      integer ic, ix, jx
      real*8 Zhlp, Zz(4)
      logical FlagCpXtr(4)
! ----------------------------------------------------------------------
! --- Initialize. NumCpXtr= NUMber of temporary eXTRa ComPartments (nodes)
      NumCpXtr= 4
      do 10 ix= 1, 4
         FlagCpXtr(ix)= .false.
  10  continue

! --- Set minimal depth of Z_Ah, Z_Ic, Z_St
      Z_Ah= dmin1(Z_Ah,Zbot(1))
      Z_Ic= dmin1(Z_Ah,Z_Ic)
      Z_St= dmin1(Z_Ah,Z_St)

! --- Depth Z_Sp of Spoint
      Z_Sp= Z_Ah - Spoint*(Z_Ah-Z_Ic) 

! --- Merge Z_Ah, Z_Ic and/or Z_Sp if difference in depth < 0.1 cm.
!     if Z is merged: NumCpXtr is decreased
      if (abs(Z_Ah-Z_Ic).lt.0.1d0) then
         Z_Ic= Z_Ah
         Z_Sp= Z_Ah
         NumCpXtr= 2
         FlagCpXtr(2)= .true.
         FlagCpXtr(3)= .true.
      elseif (abs(Z_Ah-Z_Sp).lt.0.1d0) then
         Z_Sp= Z_Ah
         NumCpXtr= 3
         FlagCpXtr(2)= .true.
      elseif (abs(Z_Ic-Z_Sp).lt.0.1d0) then
         Z_Sp= Z_Ic
         NumCpXtr= 3
         FlagCpXtr(2)= .true.
      endif

! --- Merge Z_St and Z_Ah, Z_Ic and/or Z_Sp if difference in depth < 0.1 cm
!     if Z_St is merged: NumCpXtr is decreased
      if (abs(Z_St-Z_Ah).lt.0.1d0 .or. abs(Z_St-Z_Sp).lt.0.1d0 .or. 
     &    abs(Z_St-Z_Ic).lt.0.1d0) then
         if (abs(Z_St-Z_Ah).lt.0.1d0) Z_St= Z_Ah
         if (abs(Z_St-Z_Sp).lt.0.1d0) Z_St= Z_Sp
         if (abs(Z_St-Z_Ic).lt.0.1d0) Z_St= Z_Ic
         NumCpXtr= NumCpXtr - 1
         FlagCpXtr(4)= .true.
      endif

! --- Initialize help array Zz
      Zz(1)= Z_Ah
      Zz(2)= Z_Sp
      Zz(3)= Z_Ic
      Zz(4)= Z_St

! --- Adjust Z_Ah, Z_Ic, Z_Sp and Z_St to Zbot, depth of bottom of existing 
!     compartment, if difference in depth < 0.1 cm.
!     If Z is adjusted: NumCpXtr is decreased (only when Z is not merged before)
!     If Z is adjusted: corresp. Zz is set to extreme value out of normal range
      ic= 1
      Zhlp= dmin1(Z_Ic,Z_St)
      do 20 while (Ztop(ic)-1.d-6.gt.Zhlp .and. ic.le.NumNod)
         do 19 ix= 1, 4
            if (abs(Zbot(ic)-Zz(ix)).lt.0.1d0) then
               if (ix.eq.1) Z_Ah= Zbot(ic)
               if (ix.eq.2) Z_Sp= Zbot(ic)
               if (ix.eq.3) Z_Ic= Zbot(ic)
               if (ix.eq.4) Z_St= Zbot(ic)
               Zz(ix)= -1.d6
               if (.not.FlagCpXtr(ix)) NumCpXtr= NumCpXtr - 1
            endif
  19     continue
         ic= ic + 1
  20  continue

! --- Put Zz(1) to Zz(4) in decreasing order, so that after ordening
!     only the first NumCpXtr values are relevant and unic values 
      do 30 ix= 1, 3
         do 29 jx= ix+1, 4
            if (Zz(ix).lt.Zz(jx)) then
               Zhlp= Zz(ix)
               Zz(ix)= Zz(jx)
               Zz(jx)= Zhlp
            elseif (abs(Zz(ix)-Zz(jx)).lt.1.d-1) then
               Zz(jx)= -1.d6
            endif
  29     continue
  30  continue            

! --- Insert NumCpXtr number of temporary extra compartments, shift compartments 
!     and adjust Ztop and Zbot of relevant compartments. Set IdNx= index for all 
!     shifted/adjusted compartments, that represents the corresponding ID-number  
!     of the original compartment
      ic= NumNod
      do 40 ix= NumCpXtr, 1, -1
         do 39 while (Ztop(ic).lt.Zz(ix))
            Zbot(ic+ix)= Zbot(ic)
            Ztop(ic+ix)= Ztop(ic)
            IdNx(ic+ix)= ic
            ic= ic - 1
  39     continue
         Zbot(ic+ix)= Zbot(ic)
         Ztop(ic+ix)= Zz(ix)
         Zbot(ic)   = Zz(ix)
         IdNx(ic+ix)= ic
  40  continue

! --- Set IdNx for all remaining compartments that are not adjusted
      do 50 ix= 1, ic
         IdNx(ix)= ix
  50  continue  

! --- Recalculate Spoint 
      if ((Z_Ah-Z_Ic).gt.1.d0) then
         Spoint= (Z_Ah-Z_Sp) / (Z_Ah-Z_Ic)
      else
         Spoint= 1.d0
      endif       

      return
      end

!=======================================================================
      real*8 FUNCTION DiamPolyg(DiPoMa,DiPoMi,Dz,PpIcCp,PpIcSs,
     &                          VlMpStCp,VlMpStSs,Z1,Z,ZDiPoMa)
! ----------------------------------------------------------------------
!     Date               : 15/10/08
!     Purpose            : calculate matrix polygon diameter
! ----------------------------------------------------------------------
      implicit NONE

! --- global
      real*8 DiPoMa,DiPoMi,Dz,PpIcCp,PpIcSs,VlMpStCp,VlMpStSs
      real*8 Z1,Z,ZDiPoMa 
! ----------------------------------------------------------------------
! --- local
      real*8 MpDs
! ----------------------------------------------------------------------
!
!     DIameter of soil matrix POlygon per ComPartment as a function of 
!     macropore density MpDs with depth
      if ((DiPoMa-DiPoMi).gt.1.d-3) then
         if (VlMpStSs.gt.1.d-6) then
            MpDs= VlMpStCp / Dz / VlMpStSs
         elseif (PpIcSs.gt.1.d-6) then
            MpDs= PpIcCp / PpIcSs
         else
            MpDs= dmax1(0.d0,1.d0-((Z1-Z)/(Z1-ZDiPoMa))) 
         endif
!
         DiamPolyg = DiPoMi + (DiPoMa-DiPoMi) * (1.0d0-MpDs)
      else
         DiamPolyg = DiPoMi
      endif

      return
      end

!=======================================================================
      SUBROUTINE MACROINIT(ICpBtDm,ICpTpWaSrDm,NnCrAr,
     &           flDraTub,FlEndSrpEvt,AwlCorFac,KDCrRlRef,QExcMtxDmCp,
     &           QInTopLatDm,QInTopPreDm,QOutDrRapCp,SorpDmCp,
     &           ThtSrpRefDmCp,TimAbsCumDmCp,VlMpDmCp,VlMpDyCp,WaSrMpDm)
! ----------------------------------------------------------------------
!     Date               : 20/08/02                                        
!     Purpose            : Initialization of parameters for macropore 
!                          calculations 
!     Subroutines called : SHRINKPAR                              
!     Functions called   : watcon, SHRINK
!     File usage         : -           
! ----------------------------------------------------------------------
      use Variables
      implicit NONE

! --- global                                                       
      integer ICpBtDm(MaDm), ICpTpWaSrDm(MaDm), NnCrAr 
      real*8  AwlCorFac(Macp),KDCrRlRef(MaDr), QExcMtxDmCp(MaDm,MaCp)
      real*8  QInTopLatDm(MaDm), QInTopPreDm(MaDm), QOutDrRapCp(MaCp)
      real*8  SorpDmCp(MaDm,MaCp), ThtSrpRefDmCp(MaDm,MaCp)
      real*8  TimAbsCumDmCp(MaDm,MaCp), VlMpDmCp(MaDm,MaCp) 
      real*8  VlMpDyCp(MaCp), WaSrMpDm(MaDm)
      logical flDraTub(Madr),FlEndSrpEvt(MaDm,MaCp)

! ----------------------------------------------------------------------
! --- local
      integer ic, ICpBot, ICpBtMB, ICpHRef, id, il, ir, Itask
      real*8  DZTot, FrW, FrWet, HHydrStat, KCrRlRef, ThethydrStat
      real*8  VlMpDyRl, VlMpRl, VlShriRl, WdthCr, Zhlp
      real*8  SHRINK, watcon, Z_Bot, Zref
      logical flRigid

! ----------------------------------------------------------------------
!
!- A. INITIALIZING VOLUMES OF MACROPORES AND WATER STORAGE IN MACROPORES
!     of lezen uit file met toestandsvariabelen...................
      do 10 ic= 1, NumNod
         VlMpDyCp(ic)   = 0.d0
         QOutDrRapCp(ic)= 0.d0
         AwlCorFac(ic)  = 1.d0
  10  continue
      do 20 id= 1, NumDm
         ICpBtDm(id)    = NumNod
         ICpTpWaSrDm(id)= NumNod + 1
         QInTopLatDm(id)= 0.d0 
         QInTopPreDm(id)= 0.d0
         WaSrMpDm(id)   = 0.d0
         do 19 ic= 1, NumNod
            VlMpDmCp(id,ic)     = 0.d0
            ThtSrpRefDmCp(id,ic)= 0.d0 
            TimAbsCumDmCp(id,ic)= 0.d0
            SorpDmCp(id,ic)     = 0.d0
            QExcMtxDmCp(id,ic)  = 0.d0
            FlEndSrpEvt(id,ic)  = .true.
  19     continue
  20  continue

! --- water volume in macropores in case of static macroprs below groundw level
      if (VlMpStCp(NodGwl).ge.1.d-7) then
         Zhlp= 0.d0
         do 30 ic= 1, NodGwl
            Zhlp= Zhlp - DZ(ic)
  30     continue
         FrWet= dmax1(0.d0,(GWl-Zhlp)/DZ(NodGwl))
         do 40 id= 1, NumDm
            do 39 ic= ICpBtDmPot(id), NodGwl, -1
               FrW= 1.d0
               if (ic.eq.NodGwl) FrW= FrWet
               WaSrMpDm(id)= WaSrMpDm(id)+FrW*VlMpStCp(ic)*PpDmCp(id,ic)
  39        continue
  40     continue
      endif

!- B. DETERMINING NnCrAr (compartm. number for calcul. crack area at soil surf.)
      ic= 1
      do 50 while ((Z(ic)-0.5d0*Dz(ic)+1.d-2).gt.ZnCrAr)
         ic= ic + 1
  50  continue
      NnCrAr= ic

!- C. CALCULATION OF SHRINKAGE PARAMETERS
      do 60 il= 1, NumLay
         if (SwSoilShr(il).ne.0) then      ! Non rigid soils: clay and peat
            Itask= 2*(SwSoilShr(il)-1) + SwShrInp(il)
         else                              ! Rigid soils
            Itask= 6
         endif

         call SHRINKPAR(Itask,ShrParA(il),ShrParB(il),ShrParC(il),
     &                  ShrParD(il),ShrParE(il),ThetSL(il))
  60  continue

!- D. CALCULATION OF REFERENCE KD (KDCrRlRef)
!
!      do 70 ir= 1, NrLevs
      do 70 ir= 1, 1
         flRigid = .false.
!
! --- find node with bottom MB domain at depth Z_St
         ICpBtMB= 1
         DZTot= -DZ(1) - 1.d-2
         do 66 while (Z_St.lt.DZTot)
            ICpBtMB = ICpBtMB + 1
            DZTot= DZTot - DZ(ICpBtMB)
  66     continue
!
         if (Z_St .gt. ZDraBas) then   
            ICpBot= 1
            DZTot= -DZ(1) - 1.d-2
! --- find node with depth ZDraBas 
            Z_Bot = ZDraBas   
            do 67 while (Z_Bot.lt.DZTot)
               ICpBot = ICpBot + 1
               DZTot= DZTot - DZ(ICpBot)
  67        continue
!
! --- check whether the soil between Z_ST and ZDraBas is a rigid soil
            if (ICpBot.gt.ICpBtMB) then
               do ic = ICpBtMb, ICpBot
                  il= Layer(ic)
                  if (SwSoilShr(il).eq.0) flRigid = .true.
               enddo
               if (flRigid) ICpBot = ICpBtMB
            endif
         else
            ICpBot = ICpBtMB
         endif
!
         if (flDraTub(ir) .and. flRigid) then 
! --- in case of drain tube and static macropores above drainage basis ZDraBas, 
!     plus rigid soil between Z_St and ZDraBas: never contact between drain and
!     MB domain, so no rapid drainage possible!
            KDCrRlRef(ir)= 0.d0
         else    
! --- rapid drainage possible!
!
! --- node at depth 75% from traject surface to draindepth
            ICpHRef = 1
            if (flRigid) then
               Zref = dmin1(0.75d0*Z_St,Z_St+10.d0)
            else
               Zref = dmin1(0.75d0*ZDraBas,ZDraBas+10.d0)
            endif
            DZTot= -DZ(1) - 1.d-2
            do 68 while (Zref.lt.DZTot)
               ICpHRef = ICpHRef + 1
               DZTot= DZTot - DZ(ICpHRef)
  68        continue
!
! --- calculate relative reference KD = KDCrRlRef 
            il= 0
            KDCrRlRef(ir)= 0.d0
            do 69 ic= ICpHRef, ICpBot
               il= Layer(ic)
               if (SwSoilShr(il).ne.0) then
                  HHydrStat = ZDraBas - Z(ic)
                  ThetHydrStat = watcon(ic,HHydrStat,cofgen(1,ic),
     &                                             swsophy,numtab,sptab)
                  if (ic.le.ICpBot .and. Z_St.gt.ZDraBas)
     &              ThetHydrStat = dmin1(0.99d0*Thetas(ic),ThetHydrStat)  
                  VlShriRl= SHRINK(SwSoilShr(il),SwShrInp(il),
     &                  ShrParA(il),ShrParB(il),ShrParC(il),ShrParD(il),
     &                  ShrParE(il),ThethydrStat,ThetSL(il))
                  VlMpDyRl= VlShriRl -
     &                      (1.d0 - (1.d0-VlShriRl)**(1.d0/GeomFac(il)))
               else
                  VlMpDyRl= 0.d0
               endif
               VlMpRl= PpDmCp(1,ic) * (VlMpDyRl + VlMpStCp(ic)/DZ(ic))
               WdthCr= DiPoCp(ic) * (1.d0 - dsqrt(1.d0-VlMpRl))
               KCrRlRef= (WdthCr**RapDraReaExp) / DiPoCp(ic)
               KDCrRlRef(ir)= KDCrRlRef(ir) + KCrRlRef * DZ(ic)     
  69        continue
         endif
  70  continue

!- E. CALCULATION OF SORPTIVITY PARAMETERS SorpAlfa and SorpMax FROM SOIL
!     HYDRAULIC FUNCTIONS according to PARLANGE 
      do 80 il= 1, NumLay
         call PARLANGE(SwSorp(il),il)
  80  continue
   
      return
      end

!.......................................................................
      SUBROUTINE PARLANGE(SwSrp,il)
! ----------------------------------------------------------------------
!     Date               : 31/08/05                                        
!     Purpose            : calculation of Sorptivity from k(h) and 0(h) according 
!                          to Parlange (1975) and fitting of SorpAlfa and SorpMax
!                          parameters of emperical sorptivity relation to the 
!                          Parlange curve
!     Functions called   : moiscap, hconduc, prhead, watcon 
! ----------------------------------------------------------------------
      use Variables
      implicit NONE

! --- global                                                       In
      integer il, SwSrp
! ----------------------------------------------------------------------
! --- local
      integer in, is, it, itIntv, Node, Nsteps
      real*8  Dum, Diffus_h(1000), difmoiscap
      real*8  moiscap, hconduc, Head, Mpow, K_h, prhead, S, S0, Shlp
      real*8  SpF4_2, watcon, Thet(1000), ThetpF4_2, ThetStep  

      data   ThetStep / 1.0d-3 /
! ----------------------------------------------------------------------   

!     find first Node of the Layer
      Node = nod1lay(il)
 
!   - dummy for Function hconduc 
      Dum = 0.d0
!
! --- Calculate Theta(h) and Diffusivity(h) for the relevant range: pF4.2 to h = 0 
      ThetpF4_2= watcon(Node,-1.6d4,CofGen(1,Node),swsophy,numtab,sptab)
      ThetpF4_2= ThetStep * dfloat(idnint(ThetpF4_2/ThetStep))
      NSteps   = idnint((ThetaS(Node)-ThetpF4_2)/ThetStep) + 1
      Thet(1)  = ThetpF4_2
      do 10 it= 1, Nsteps
         if (Thet(it).gt.ThetaS(Node) .or. it.eq.Nsteps) Thet(it)= 
     &                  ThetaS(Node) - 0.5d0*ThetStep
         Head = prhead (Node,dum,cofgen,Thet(it),h,swsophy,numtab,sptab)
         K_h = hconduc (Node,Thet(it),cofgen(1,Node),0,Dum,
     &                                             swsophy,numtab,sptab)    
         Difmoiscap = moiscap (Node,Head,CofGen(1,Node),dt,
     &                                             swsophy,numtab,sptab)
         Diffus_h(it)= K_h / difmoiscap
         Thet(it+1)  = Thet(it) + ThetStep
  10  continue
!
! ---- Calculate Sorptivity according to Parlange for Theta(pF4.2) (SpF4_2) and 
!      for Theta = (ThetaSat+Theta(pF4.2))/2. Exponent Mpow, calculated for this
!      Theta on basis of SpF4_2, is an excellent predictor for the exponent of
!      the curve S(Theta)= S0*(1-Theta/ThetaSat)^M for the range pF4.2 to h = 0       
      itIntv = idnint((ThetaS(Node)-ThetpF4_2) / 2.0d0 / ThetStep)
      it= 1
      do 20 is= 1, 2
         Shlp= 0.d0
         do in= it+1, Nsteps
            Shlp= Shlp + (Thet(in)-Thet(it)) * Diffus_h(in) * ThetStep 
         enddo
         Shlp= dmax1(Shlp,0.d0)
         S   = dsqrt(2.d0 * Shlp)
         if (is.eq.1) then
            SpF4_2= S
         else
            Mpow= dlog10(S/SpF4_2) / dlog10(1.d0 - 
     &                  (Thet(it)-ThetpF4_2) / (ThetaS(Node)-ThetpF4_2))
         endif
         it= it + itIntv
  20  continue
!
! --- Extrapolate SpF4_2 to S0 at ThetaR(esidual)
      S0= SpF4_2 * (1.d0 - (ThetaR(Node)-ThetpF4_2) / 
     &                     (ThetaS(Node)-ThetpF4_2) )** Mpow
!
      if (SwSrp.eq.1) then
! --- Assign values to variables of subroutine ABSORPTION
         SorpAlfa(il)= Mpow
         SorpMax(il) = SorpFacParl(il) * S0
      else
! --- Correction factor when emperical values are input, for use in Darcy option
!     in absorption
         SorpFacParl(il) = dmin1(1.d0,SorpMax(il) / S0)
      endif
!      write(96,'(i5,2f10.5)') il, Mpow,  S0 

      return
      end

!.......................................................................
      SUBROUTINE SHRINKPAR(Itask,ShrParA,ShrParB,ShrParC,ShrParD,
     &                     ShrParE,ThetaS)
! ----------------------------------------------------------------------
!     Date               : 21/08/02                                        
!     Purpose            : calculation of the parameters of the shrinkage 
!                          characteristics of clay and peat from input parametrs
!     Subroutines called : -                             
!     Functions called   : -
!     File usage         : -           
! ----------------------------------------------------------------------
      implicit NONE

! --- global                                                       
      integer Itask

      real*8  ShrParA, ShrParB, ShrParC, ShrParD, ShrParE, ThetaS
! ----------------------------------------------------------------------
! --- local
!      integer 
      real*8  Alfa, Alfa1, Alfa2, AlfMax, AlfMin, Beta1, Beta2, C1, C2
      real*8  C3, Deriv, e_r, e_t, FA, Funct, GA, HA, MoisR1
      character messag*200
! ----------------------------------------------------------------------
!
      goto(1000,2000,3000,4000,5000,6000) Itask 

1000  continue
! --- SwSoilShr= 1: Clay; SwShrInp= 1: shrinkage parameters are given
!   - calculate MoisR1= moisture ratio at transition from normal to residual 
!     shrinkage (stored in variable ShrParD)
      ShrParD= -dlog((ShrParC-1.d0)/(ShrParA*ShrParB)) / ShrParB
!cc------- FOUTMELDING AANPASSEN
      if (ShrParD.gt.Thetas/(1.d0-Thetas)-0.01d0) then
         messag = ' ShrParD.gt.(ThetaS/(1.d0-ThetaS)-0.01d0'
         call fatalerr ('SHRINKPAR',messag)
      endif

      return

2000  continue
! --- SwSoilShr= 1: Clay; SwShrInp= 2: typical points of shrinkage chracteristics
!     are given: void ratio at zero water content (Alfa) and MoisR1. 
!   - calculate parameters shrinkage curve: Beta, Gamma
      if (ShrParA.Gt.ShrParB) then
         messag = ' inconsistent shrinkage input: ShrParA > ShrParB is n
     &ot allowed'
         call fatalerr ('SHRINKPAR',messag)
      endif
      Alfa= ShrParA
      MoisR1= ShrParB
!cc------- ADAPT ERROR MESSAGE
      if (MoisR1.gt.Thetas/(1.d0-Thetas)-0.01d0) then
         messag = ' MoisR1.gt.ThetaS/(1.d0-ThetaS)-0.01d0'
         call fatalerr ('SHRINKPAR',messag)
      endif
      Beta2= -1.d0/MoisR1*dlog((MoisR1)/Alfa)      
      Beta1= Beta2 + 1.d0

!   -iteration loop
      do 210 while (abs(Beta2-Beta1).gt.0.001d0)
         Beta1= Beta2
         Funct= (Alfa+Alfa*MoisR1*Beta1) * dexp(-Beta1*MoisR1)
         Deriv= (-Alfa*MoisR1*MoisR1*Beta1) * dexp(-Beta1*MoisR1)
         Beta2= Beta1 - Funct/Deriv
 210  continue

      ShrParB= Beta2
      ShrParC= 1.d0 + Alfa*Beta2*dexp(-Beta2*MoisR1)
      ShrParD= MoisR1

      return
!
3000  continue
! --- SwSoilShr= 2: Peat; SwShrInp= 1: shrinkage parameters are given
!   - No initial calculations are required
!         VoidR0= ShrParA
!         MoisRa= ShrParB
!         Alfa  = ShrParC
!         Beta  = ShrParD
!         P     = ShrParE
      return
 
4000  continue
! --- SwSoilShr= 2: Peat; SwShrInp= 2: typical points of shrinkage chracteristics
!     are given. 
!   - calculate parameters shrinkage curve: 
!         ShrParC = Alfa 
!         ShrParD = Beta 
!   - set three help constants

      C1 = 1.d0 / (ShrParD / ShrParB) ! 1 / v_P
      C2 = ShrParC  / ShrParD         ! v_t / v_P 
      e_t = ShrParA + (ThetaS/(1.d0-ThetaS) - ShrParA) * ShrParC / 
     &                (ThetaS/(1.d0-ThetaS))  ! e_0 + (e_s-e_0) * v_r / v_s
      if (ShrParE.gt.0.d0) then
         e_r = ShrParA + ShrParC
      else
         e_r = 0.5d0*ShrParA + ShrParC
      endif 
      C3 = (e_r/e_t - 1.d0) / ShrParE  ! ((e_r/e_t) - 1) / P

!   - find value of Alfa in equation by iterative root finding
!   -  C2^Alfa * (exp(-Alfa*C2) - exp(-Alfa*C1)) / (exp(-Alfa) - exp(-Alfa*C1)) - C3 = 0
!   - first estimation of Alfa depends on value of P
      if (abs(ShrParE).gt.0.33d0) then
         Alfa2= 0.5d0
      else
         Alfa2= 0.9d0
      endif
      Alfa1= Alfa2 + 1.d0
!   -iteration loop
      AlfMax = 10.0d0
      AlfMin = 0.001d0
      do 410 while (abs(Alfa2-Alfa1).gt.0.001d0)
         Alfa1= Alfa2
         FA= C2**Alfa1
         GA= dexp((C1-C2)*Alfa1)   - 1.d0
         HA= dexp((C1-1.d0)*Alfa1) - 1.d0
         Funct= FA * GA / HA - C3 
         Deriv= FA*( GA*(1.d0+log(C2)-C2 - (C1-1.d0)/Ha) + (C1-C2)) / HA
         Alfa2= Alfa1 - Funct/Deriv

!   - checking for extreem values and correcting by 'interval halfing'
         if (abs(Alfa2-Alfa1).gt.1.0d-2) then
            if (Alfa2.gt.Alfa1) then 
               if (Alfa1.gt.Alfmin .and. Alfa1.lt.AlfMax-1.0d-3) then
                  Alfmin = Alfa1
               else
                  Alfa2 = (AlfMin + dmin1(Alfa2,AlfMax-1.0d-2)) / 2.d0
               endif
               Alfa2 = dmin1(Alfa2,AlfMax)
            elseif (Alfa2.lt.Alfa1) then 
               if (Alfa1.lt.Alfmax .and. Alfa1.gt.AlfMin+1.0d-3) then
                  Alfmax = Alfa1
               else
                  Alfa2 = (AlfMax + dmax1(Alfa2,AlfMin+1.0d-2)) / 2.d0
               endif
               Alfa2 = dmax1(Alfa2,AlfMin)
            endif
         endif 
 410  continue
!
      ShrParC = Alfa2
      ShrParD = Alfa2 / (ShrParD / ShrParB) ! Beta = Alfa / v_P
!
      return

5000  continue
! --- SwSoilShr= 3: Peat; SwShrInp= 3: shrinkage chracteristics are approximated
!     by 3 straight line-pieces: 
!   - ShrParE is redundant: 
      ShrParE= ShrParE
      return

! --- SwSoilShr= 0: rigid soil. No shrinkage parameters required.
6000  return
      end

!=======================================================================
      SUBROUTINE MACROINTEGRAL(flBegin,FrMpWalWet,
     &              QInIntSatDmCp,QInMtxSatDmCp,QInTopLatDm,QInTopPreDm,
     &              QOutDrRapCp,QOutMtxSatDmCp,QOutMtxUnsDmCp) 
! ----------------------------------------------------------------------
!     Date               : 24/08/02                                        
!     Purpose            : calculation of intermediate values and     
!                          cumulative values          
!     Subroutines called :                               
!     Functions called   : -
!     File usage         : -           
! ----------------------------------------------------------------------
      use Variables
      implicit NONE

! --- global                                                       In
      real*8  FrMpWalWet(MaDm,MaCp), QInIntSatDmCp(MaDm,MaCp)
      real*8  QInMtxSatDmCp(MaDm,MaCp), QInTopLatDm(MaDm)
      real*8  QInTopPreDm(MaDm), QOutDrRapCp(MaCp)
      real*8  QOutMtxSatDmCp(MaDm,MaCp), QOutMtxUnsDmCp(MaDm,MaCp)
      logical flBegin 
!     -                                                            Out
! ----------------------------------------------------------------------
! --- local
      integer ic, id
      real*8  AvFrMpWlWtDm1Cp(MaCp), AvFrMpWlWtDm2Cp(MaCp)
      real*8  DevMasBalDm1, DevMasBalDm2, FrMpWalWetOld(MaDm,MaCp) 
      real*8  IQExcMtxDm1Tot, IQExcMtxDm2Tot, IQOutDrRapTot 
      real*8  QInIntSatDm1Cp(MaCp), QInIntSatDm2Cp(MaCp)
      real*8  QInMtxSatDm1Cp(MaCp), QInMtxSatDm2Cp(MaCp)
      real*8  QOutMtxSatDm1Cp(MaCp), QOutMtxSatDm2Cp(MaCp) 
      real*8  QOutMtxUnsDm1Cp(MaCp), QOutMtxUnsDm2Cp(MaCp)

! ----------------------------------------------------------------------
!
! --- When begin of simulation period: assign values to FrMpWalWetOld
      if (flBegin) then
         do 5 id = 1, NumDm
            do 4 ic = 1, NumNod
               FrMpWalWetOld(id,ic) = FrMpWalWet(id,ic)
   4        continue
   5     continue
         flBegin = .false.
      endif

! --- Assigning fluxes for Domain 1: Main Bypass Flow domain
      QInTopLatDm1= QInTopLatDm(1)
      QInTopPreDm1= QInTopPreDm(1)
      do 10 ic= 1, NumNod
         QInIntSatDm1Cp(ic) = QInIntSatDmCp(1,ic)
         QInMtxSatDm1Cp(ic) = QInMtxSatDmCp(1,ic)
         QOutMtxSatDm1Cp(ic)= QOutMtxSatDmCp(1,ic)
         QOutMtxUnsDm1Cp(ic)= QOutMtxUnsDmCp(1,ic)

!     AvFrMpWlWtDm1Cp = fraction of mp.wall in contact with water for Dm1 averaged over dt
         AvFrMpWlWtDm1Cp(ic) = PpDmCp(1,ic) * 
     &                     (FrMpWalWet(1,ic)+FrMpWalWetOld(1,ic)) / 2.d0
         FrMpWalWetOld(1,ic) = FrMpWalWet(1,ic)
  10  continue
!
! --- Aggregating fluxes for Domain 2: Internal Catchment domain
!   - Initializing 
      QInTopPreDm2= 0.d0
      QInTopLatDm2= 0.d0
      do 20 ic= 1, NumNod
         QInIntSatDm2Cp(ic) = 0.d0
         QInMtxSatDm2Cp(ic) = 0.d0
         QOutMtxSatDm2Cp(ic)= 0.d0
         QOutMtxUnsDm2Cp(ic)= 0.d0
         AvFrMpWlWtDm2Cp(ic)= 0.d0
  20  continue
!   - Aggregating 
      do 30 id= 2, NumDm
         QInTopPreDm2= QInTopPreDm2 + QInTopPreDm(id)
         QInTopLatDm2= QInTopLatDm2 + QInTopLatDm(id)
         do 29 ic= 1, ICpBtDmPot(2)
            QInIntSatDm2Cp(ic)= QInIntSatDm2Cp(ic) +QInIntSatDmCp(id,ic)
            QInMtxSatDm2Cp(ic)= QInMtxSatDm2Cp(ic) +QInMtxSatDmCp(id,ic)
            QOutMtxSatDm2Cp(ic)= QOutMtxSatDm2Cp(ic) + 
     &                                             QOutMtxSatDmCp(id,ic)
            QOutMtxUnsDm2Cp(ic)= QOutMtxUnsDm2Cp(ic) + 
     &                                             QOutMtxUnsDmCp(id,ic)
!   - AvFrMpWlWtDm2Cp = fraction of mp.wall in contact with water for Dm2 averaged over dt
            AvFrMpWlWtDm2Cp(ic)= AvFrMpWlWtDm2Cp(ic) + PpDmCp(id,ic) * 
     &                   (FrMpWalWet(id,ic)+FrMpWalWetOld(id,ic)) / 2.d0
            FrMpWalWetOld(id,ic) = FrMpWalWet(id,ic)
  29     continue
  30  continue
!
! --- Summing up Intermediate values
      IQInTopPreDm1= IQInTopPreDm1 + QInTopPreDm1*DT
      IQInTopLatDm1= IQInTopLatDm1 + QInTopLatDm1*DT
      IQInTopPreDm2= IQInTopPreDm2 + QInTopPreDm2*DT
      IQInTopLatDm2= IQInTopLatDm2 + QInTopLatDm2*DT
!   - Per compartment
      do 40 ic= 1, NumNod    
         IQExcMtxDm1Cp(ic)= IQExcMtxDm1Cp(ic)  + 
     &                      (QOutMtxSatDm1Cp(ic)+QOutMtxUnsDm1Cp(ic) -
     &                      (QInIntSatDm1Cp(ic) +QInMtxSatDm1Cp(ic)))*DT
         IQExcMtxDm2Cp(ic)= IQExcMtxDm2Cp(ic)   + 
     &                      (QOutMtxSatDm2Cp(ic)+QOutMtxUnsDm2Cp(ic) -
     &                      (QInIntSatDm2Cp(ic) +QInMtxSatDm2Cp(ic)))*DT
         IQOutDrRapCp(ic) = IQOutDrRapCp(ic)    +QOutDrRapCp(ic)*DT
         IQMpOutDrRap     = IQMpOutDrRap        +QOutDrRapCp(ic)* DT
!     IAvFrMpWlWtDm1= sum of average wet mp.wall fraction weighted for time step
         IAvFrMpWlWtDm1(ic)= IAvFrMpWlWtDm1(ic)+AvFrMpWlWtDm1Cp(ic)*DT 
         IAvFrMpWlWtDm2(ic)= IAvFrMpWlWtDm2(ic)+AvFrMpWlWtDm2Cp(ic)*DT 
  40  continue
!
! --- summing up Cumulative values
      cQMpLatSs = cQMpLatSs + QMpLatSs 
!      cQMapo    = cQMapo + QMapo*dt   

      do 50 ic = 1, NumNod
         CQMpInIntSatDm1  = CQMpInIntSatDm1  + QInIntSatDm1Cp(ic)  * DT
         CQMpInIntSatDm2  = CQMpInIntSatDm2  + QInIntSatDm2Cp(ic)  * DT
         CQMpInMtxSatDm1  = CQMpInMtxSatDm1  + QInMtxSatDm1Cp(ic)  * DT
         CQMpInMtxSatDm2  = CQMpInMtxSatDm2  + QInMtxSatDm2Cp(ic)  * DT
         CQMpOutMtxSatDm1 = CQMpOutMtxSatDm1 + QOutMtxSatDm1Cp(ic) * DT
         CQMpOutMtxSatDm2 = CQMpOutMtxSatDm2 + QOutMtxSatDm2Cp(ic) * DT
         CQMpOutMtxUnsDm1 = CQMpOutMtxUnsDm1 + QOutMtxUnsDm1Cp(ic) * DT
         CQMpOutMtxUnsDm2 = CQMpOutMtxUnsDm2 + QOutMtxUnsDm2Cp(ic) * DT
         CQMpOutDrRap     = CQMpOutDrRap     + QOutDrRapCp(ic)     * DT
  50  continue
      CQMpInTopPreDm1 = CQMpInTopPreDm1 + QInTopPreDm1 * DT
      CQMpInTopLatDm1 = CQMpInTopLatDm1 + QInTopLatDm1 * DT
      CQMpInTopPreDm2 = CQMpInTopPreDm2 + QInTopPreDm2 * DT
      CQMpInTopLatDm2 = CQMpInTopLatDm2 + QInTopLatDm2 * DT
!
! --- Checking water balance per domain and time step
      IQExcMtxDm1Tot= 0.d0
      IQExcMtxDm2Tot= 0.d0
      IQOutDrRapTot = 0.d0
      do 60 ic= 1, NumNod    
         IQExcMtxDm1Tot= IQExcMtxDm1Tot + IQExcMtxDm1Cp(ic)
         IQExcMtxDm2Tot= IQExcMtxDm2Tot + IQExcMtxDm2Cp(ic)
         IQOutDrRapTot = IQOutDrRapTot  + IQOutDrRapCp(ic)
  60  continue

      DevMasBalDm1= IQInTopPreDm1 + IQInTopLatDm1 - IQExcMtxDm1Tot -
     &              IQOutDrRapTot - WaSrDm1 + IWaSrDm1Beg

      DevMasBalDm2= IQInTopPreDm2 + IQInTopLatDm2 - IQExcMtxDm2Tot -
     &              WaSrDm2 + IWaSrDm2Beg

      if (abs(devmasbaldm1).gt.1.0d-6)   write(98,1) 1,T,DevMasBalDm1,
     &IQInTopPreDm1, IQInTopLatDm1, IQExcMtxDm1Tot,
     &              WaSrDm1, IWaSrDm1Beg, IQOutDrRapTot
      if (abs(devmasbaldm2).gt.1.0d-6)   write(98,1) 2,T,DevMasBalDm2,
     &IQInTopPreDm2, IQInTopLatDm2, IQExcMtxDm2Tot,
     &              WaSrDm2, IWaSrDm2Beg
    1 format( ' Dom ',i1,': ', F11.7, 1x,7f10.7)
      return
      end

!=======================================================================
      SUBROUTINE MACROSTATE(NnCrAr,FlEndSrpEvt,QExcMtxDmCp,
     &             QInTopLatDm,QInTopPreDm,QOutDrRapCp,WaSrMpDm,
     &             ICpBtDm,ICpBtPerZon,ICpSatGWl,ICpSatPeGWl,
     &             ICpTpPerZon,ICpTpSatZon,ICpTpWaSrDm,ArMpSsDm,
     &             AwlCorFac,FrMpWalWet,SorpDmCp,ThtSrpRefDmCp,
     &             TimAbsCumDmCp,VlMpDm,VlMpDmCp,VlMpDyCp,WaSrMp,
     &             WaSrMpDmCp,ZBtDm,ZWaLevDm)
! ----------------------------------------------------------------------
!     Date               : 20/08/02                                        
!     Purpose            : .......state variables at end of timestep
!     Subroutines called : -                             
!     Functions called   : SHRINK
!     File usage         : -           
! ----------------------------------------------------------------------
      use Variables
      implicit NONE

! --- global                                                       In
      integer NnCrAr
      real*8  QExcMtxDmCp(MaDm,MaCp),QInTopLatDm(MaDm) 
      real*8  QInTopPreDm(MaDm), QOutDrRapCp(MaCp), WaSrMpDm(MaDm)   
      logical FlEndSrpEvt(MaDm,MaCp)                                      
!     -                                                            Out
      integer ICpBtDm(MaDm), ICpBtPerZon, ICpSatGWl,ICpSatPeGWl 
      integer ICpTpPerZon, ICpTpSatZon, ICpTpWaSrDm(MaDm) 
      real*8  ArMpSsDm(MaDm), AwlCorFac(Macp), FrMpWalWet(MaDm,MaCp)
      real*8  SorpDmCp(MaDm,MaCp), ThtSrpRefDmCp(MaDm,MaCp)
      real*8  TimAbsCumDmCp(MaDm,MaCp), VlMpDm(MaDm)
      real*8  VlMpDmCp(MaDm,MaCp), VlMpDyCp(MaCp), WaSrMp
      real*8  WaSrMpDmCp(MaDm,MaCp), ZBtDm(MaDm), ZWaLevDm(MaDm)
! ----------------------------------------------------------------------
! --- local
      integer ic, ichlp, ICpBtDmOld(MaDm), ICpBtUnsMtxDm, id, il
      integer NodGwlHlp
      real*8  ArMpSsDy, ArMpSsMin, ArMpSsSt, CritThet, DifVlMpDm
      real*8  DifVlMpDmCp(MaCp), SHRINK, Time
      real*8  VlHlp, VlMpCp(MaCp), VlMpDmCpOld(MaDm,MaCp), VlMpDmOld 
      real*8  VlMpMin, VlShriCp, VlShriRel, WthMpMin

      data    WthMpMin /10.0d-4/   !!!! = lower limit macropores  
! ----------------------------------------------------------------------
!
!   for FORCHECK
      t = t
      t1900 = t1900
!  -- Update water storage in macropore domains
      WaSrMp= 0.d0
      do 10 id= 1, NumDm
          WaSrMpDm(id)= WaSrMpDm(id) + 
     &                 (QInTopLatDm(id) + QInTopPreDm(id)) * DT
          do 9 ic= 1, ICpBtDm(id)
             WaSrMpDm(id)= WaSrMpDm(id) - QExcMtxDmCp(id,ic) * DT
             if (id.eq.1) WaSrMpDm(id)= WaSrMpDm(id) - 
     &                                  QOutDrRapCp(ic) * DT
   9      continue
          WaSrMpDm(id)= dmax1(0.d0,WaSrMpDm(id))
          WaSrMp      = WaSrMp + WaSrMpDm(id)
  10  continue

!- A. VlMpDyCp: VOLUME DYNAMIC MACROPORES (CRACKS) 
!  -- NodGwl= deepest unsaturated compartm.

!!!!!     GIVE WARNING
      NodGwlHlp= NodGwlFlCpZo
      if (NodGwlFlCpZo.gt.NumNod) then
!         stop ' Groundwater level below bottom profile; not possible 
!     &for macropores '
          NodGwlHlp= NumNod
      endif
      do 20 ic= 1, NodGwlHlp
         il= Layer(ic)
         if ((SwSoilShr(il).ne.0) .and. Theta(ic).lt.ThetaS(ic)-1.d-4) 
     &   then
            VlShriRel= SHRINK(SwSoilShr(il),SwShrInp(il),ShrParA(il),
     &         ShrParB(il),ShrParC(il),ShrParD(il),ShrParE(il),
     &         Theta(ic),ThetaS(ic))
            VlShriCp= VlShriRel * Dz(ic) ! VoLume of SHRInkage per unit hor. area
!
            if (Theta(ic).gt.ThetM1(ic)-1.d-8 .and. 
     &          (VlMpDyCp(ic).gt.0.d0 .or. 
     &          (VlMpDyCp(max0(1,ic-1))+VlMpDyCp(ic+1).gt.0.d0))) then
!  -- increasing moisture content in case of cracked soil compartment:
               CritThet= ThetaS(ic)
            else
!  -- decreasing moist. cont., or increasing  moist. cont. in not cracked soil:
               CritThet= ThetCrMp(il)
            endif

!  -- SUBSIDence (SubsidCp) and VoLume of DYnamic MacroPores (VlMpDyCp) 
!     per ComPartment (cm3 per cm2 hor. area of soil matrix)
            if (Theta(ic).lt.CritThet) then
               SubsidCp(ic)= (1.d0-(1.d0-VlShriRel)**(1.d0/GeomFac(il)))
     &                       * Dz(ic)
               VlMpDyCp(ic)= FrArMtrx(ic) * (VlShriCp - SubsidCp(ic)) *
     &                             Dz(ic) / (Dz(ic) - SubsidCp(ic))
            else
               SubsidCp(ic)= VlShriCp
               VlMpDyCp(ic)= 0.d0 
            endif
         else
            VlShriCp    = 0.d0
            SubsidCp(ic)= 0.d0
            VlMpDyCp(ic)= 0.d0 
         endif
!  -- VlMaSh: VOLume of soil MAtrix after SHrinkage; for solute models 
!         VlMaSh(ic)= FrArMtrx(ic) * (Dz(ic) - VlShriCp)
  20  continue
      do 30 ic= NodGwlHlp+1, NumNod
         SubsidCp(ic)= 0.d0
         VlMpDyCp(ic)= 0.d0 
!         VlMaSh(ic)  = FrArMtrx(ic) * Dz(ic)
  30  continue

!- B. VOLUME MACROPORES PER COMPARTIMENT (VlMpCp) AND PER DOMAIN (VlMpDmCp) 
!  -- VlMpCp and ICpBtDm(1) (= ACTUAL bottom (= deepest) compartment number 
!     with macropore volume of first (= deepest) domain)
      ICpBtDmOld(1)= ICpBtDm(1)
      ICpBtDm(1)= 0
      do 40 ic= NumNod, 1, -1
         VlMpCp(ic)= VlMpDyCp(ic) + VlMpStCp(ic)
!   - minimum TOTAL volume of macropores PER COMPARTMENT depends on minimum width 
!     WthMpMin = 0.01 cm of macropores; below this width, pores are no macropores. 
         if (ICpBtDm(1).eq.0) then
            VlMpMin= (1.d0 - (1.d0 - WthMpMin/DiPoCp(ic))**2.d0) *DZ(ic)
            if (VlMpCp(ic).lt.VlMpMin .and. VlMpStCp(ic).lt.1.d-5)
     &         VlMpCp(ic)= 0.d0
            if (VlMpCp(ic).gt.0.d0) ICpBtDm(1)= ic
         endif
  40  continue
      ICpBtDm(1)= max0(ICpBtDm(1),ICpBtDmPot(2))  

!  -- determine for domain 2-NumDm ICpBtDm (limited by ICpBtDm(1)) 
      do 50 id= 2, NumDm
         ICpBtDmOld(id)= ICpBtDm(id)
         ICpBtDm(id)= min0(ICpBtDmPot(id),ICpBtDm(1))
  50  continue
  
!  -- partition of VoLume of MacroPores per ComPartment over the DoMains
      VlMp= 0.d0
      do 60 id= 1, NumDm
!   - save old values
         VlMpDmOld= 0.d0
         do 55 ic= 1, ICpBtDmOld(id)
            VlMpDmCpOld(id,ic)= VlMpDmCp(id,ic)
            VlMpDmOld= VlMpDmOld + VlMpDmCpOld(id,ic)
  55     continue
!   - calculate new values
         VlMpDm(id)= 0.d0
         do 56 ic= 1, ICpBtDm(id)
            VlMpDmCp(id,ic)= PpDmCp(id,ic) * VlMpCp(ic)
            VlMpDm(id)     = VlMpDm(id) + VlMpDmCp(id,ic)
  56     continue
         do 57 ic= ICpBtDm(id)+1, NumNod
            VlMpDmCp(id,ic)= 0.d0
  57     continue  
! LIMIT SHRINKAGE IF TOTAL VOLUME BECOMES SMALLER THAN TOTAL WATER STORAGE (= hysterese)
         if (VlMpDm(id)-WaSrMpDm(id).lt.-1.d-7) then
            DifVlMpDm= 0.d0
            ic= 0
            do 58 while (DifVlMpDm.lt.WaSrMpDm(id)-VlMpDm(id)-1.d-8 
     &                   .and. ic.lt.ICpBtDmPot(id))
               ic= ic + 1
               DifVlMpDmCp(ic)= VlMpDmCpOld(id,ic) - VlMpDmCp(id,ic)
               DifVlMpDmCp(ic)= dmax1(0.d0,DifVlMpDmCp(ic))
               DifVlMpDm= DifVlMpDm + DifVlMpDmCp(ic)
  58        continue
            ichlp= ic
            do 59 ic= 1, ichlp
               VlMpDmCp(id,ic)= VlMpDmCp(id,ic) + 
     &         (WaSrMpDm(id)-VlMpDm(id)) * DifVlMpDmCp(ic)/DifVlMpDm
  59        continue
            VlMpDm(id)= WaSrMpDm(id)
         endif
!  -- determine for each domain depth ZBtDm
         ZBtDm(id)= Z(ICpBtDm(id)) - 0.5d0 * DZ(ICpBtDm(id))
!  -- determine total macropore volume 
         VlMp= VlMp + VlMpDm(id)
!
  60  continue

!- C. AREA OF MACROPORES AT SOIL SURFACE
!  -- ArMpSsDm: ARea at Soil Surface of MacroPores, per DoMain exists of:
!   1 cracks (dynamic macropore volume): because of very thin top compartment 
!     and consequently fast reaction to drying and wetting of this compartment,
!     this calculation is performed for compartment NnCrAr at depth ZnCrAr
      ArMpSsDy= VlMpDyCp(NnCrAr) / (Dz(NnCrAr)-SubsidCp(NnCrAr))
!   2 static macropore volume. This and total macropore volume and partition 
!     over Domains: performed for 1th comp.
      ArMpSsSt= VlMpStCp(1) / Dz(1)
      ArMpSs  = ArMpSsDy + ArMpSsSt
      ArMpSs  = dmin1(0.6d0,ArMpSs)
!   - minimum TOTAL area of macropores at soil surface depends on minimum width
!     WthMpMin = 0.01 cm of macropores; below this width, pores are no macropores.  
      ArMpSsMin= 1.d0 - (1.d0 - WthMpMin/DiPoCp(1))**2.d0
      if (ArMpSs.lt.ArMpSsMin) ArMpSs= 0.d0
      do 70 id= 1, NumDm
         ArMpSsDm(id)= PpDmCp(id,1) * ArMpSs
  70  continue

!   - overall capacity for vertical water inflow at soil surface: KsMpSs 
      KsMpSs= 2.d0*7.2d+8 * (DiPoCp(1)*(1.d0-dsqrt(1.d0-ArMpSs)))**3.d0/ 
     &                       DiPoCp(1)
      KsMpSs= dmax1(KsMpSs,1.d-14)

!- D. CALCULATION PER DOMAIN OF SOME OTHER RELEVANT STATE VARIABLES 
! 
!  -- WAter StoRage per ComPartment (WaSrMpDmCp), FRaction of MacroPore WALl
!     in contact with stored water (FrMpWalWet), ToP ComPartment number with  
!     WAter StoRed in DoMain (ICpTpWaSrDm)
!
      do 80 id= 1, NumDm
!  -- Initialization
         do 77 ic= 1, NumNod
            WaSrMpDmCp(id,ic)= 0.d0
            FrMpWalWet(id,ic)= 0.d0  
  77     continue 
!
         if (ICpBtDm(id).gt.0) then
            ic= ICpBtDm(id)
            VlHlp= VlMpDmCp(id,ic)
            do 78 while(VlHlp.lt.WaSrMpDm(id)-1.d-8 .and. ic.gt.1)
               WaSrMpDmCp(id,ic)= VlMpDmCp(id,ic)
               FrMpWalWet(id,ic)= 1.d0
               ic= ic - 1
               VlHlp= VlHlp + VlMpDmCp(id,ic)
  78        continue
            ICpTpWaSrDm(id)= ic
            if (VlMpDmCp(id,ic).gt.1.d-8) then
               FrMpWalWet(id,ic)= 1.d0 - (VlHlp-WaSrMpDm(id)) / 
     &                            VlMpDmCp(id,ic)
               continue
            else
               FrMpWalWet(id,ic)= 0.d0 
               ICpTpWaSrDm(id)= ic + 1
            endif

!  -- WAter LEVel in macropore DoMains (ZWaLevDm)
            ZWaLevDm(id)= ZBtDm(id)
            do 79 ic= ICpBtDm(id), ICpTpWaSrDm(id)+1, -1
               ZWaLevDm(id)= ZWaLevDm(id) + DZ(ic)
  79        continue
            ZWaLevDm(id)= ZWaLevDm(id) + 
     &              FrMpWalWet(id,ICpTpWaSrDm(id)) * DZ(ICpTpWaSrDm(id))
         else
            ICpTpWaSrDm(id)= 1
            ZWaLevDm(id)= 0.d0
         endif
  80  continue
!
! --- Update cumulative absorption times TimAbsCumDmCp and sorptivity variables
      do 90 id= 1, NumDm
        ICpBtUnsMtxDm= min0(ICpBtDm(id),ICpTpSatZon-1)
         do 87 ic= ICpTpWaSrDm(id), ICpBtUnsMtxDm
            if (FlEndSrpEvt(id,ic)) then  ! End present Sorptivity event
               TimAbsCumDmCp(id,ic)= 0.d0
               SorpDmCp(id,ic)     = 0.d0
               ThtSrpRefDmCp(id,ic)= 0.d0
               AwlCorFac(ic)       = 0.d0
            else                          ! Continue present Sorptivity event
               Time                = TimAbsCumDmCp(id,ic)
!   - ThtSrpRefDmCp = Thet_sat + Delta_thet_theor. = Thet_sat + Thet_theor. - Thet_0
!     Delta_thet_theor. = theoretical increase of theta = term calculated here below 
               ThtSrpRefDmCp(id,ic)= ThtSrpRefDmCp(id,ic) +AwlCorFac(ic)
     &           * FrMpWalWet(id,ic) * PpDmCp(id,ic) * (4.d0/DiPoCp(ic))  
     &           * SorpDmCp(id,ic) * (dsqrt(Time+DT)-dsqrt(Time))              
               TimAbsCumDmCp(id,ic)= TimAbsCumDmCp(id,ic) + DT
            endif
  87     continue
         do 88 ic= 1, ICpTpWaSrDm(id)-1
            TimAbsCumDmCp(id,ic)= 0.d0
            SorpDmCp(id,ic)     = 0.d0
            ThtSrpRefDmCp(id,ic)= 0.d0
  88     continue
         do 89 ic= ICpBtUnsMtxDm+1, NumNod
            TimAbsCumDmCp(id,ic)= 0.d0
            SorpDmCp(id,ic)     = 0.d0
            ThtSrpRefDmCp(id,ic)= 0.d0
  89     continue
  90  continue
!
! --- Update factor for correcting vertical area wall for sorptivity calculations
      do 100 ic = 1, NumNod
         AwlCorFac(ic) = dsqrt(1.0d0-VlMpDmCp(1,ic)/PpDmCp(1,ic)/dz(ic))
 100  continue

! --- Update compartment numbers related to groundwater and perched groundwater level
!
!   - ICpTpSatZon = top compartment of saturated zone (NodGwl deepest unsat. node)
      ICpTpSatZon = NodGwlFlCpZo + 1
      if (GwlFlCpZo.lt.Z(NodGwlFlCpZo)-0.5d0*DZ(NodGwlFlCpZo)) then
         ICpSatGWl = ICpTpSatZon
      else
         ICpSatGWl = -1
         if (NodGwlFlCpZo.eq.1 .and. GwlFlCpZo.gt.Z(NodGwlFlCpZo))
     &      ICpTpSatZon = 1
      endif
!
!   - ICpTpPerZon = top compartment of perched groundwater
      if (NPeGwl.gt.0) then
!    - Perched groundwater exists
         ICpBtPerZon = BPeGWl
         ICpTpPerZon = NPeGwl + 1
         if (PeGWl.lt.Z(NPeGwl)-0.5d0*DZ(NPeGwl)) then
            ICpSatPeGWl = ICpTpPerZon
         else
            ICpSatPeGWl = -1
            if (NPeGwl.eq.1 .and. PeGWl.gt.Z(NPeGwl)) ICpTpPerZon = 1
         endif
      else
!    - No perched groundwater
         ICpBtPerZon = -1
         ICpTpPerZon = ICpTpSatZon
      endif
!
!- E. AGGREGATE VOLUMES AND WATER STORAGES FOR SWAP AND THE INTERFACES
!     WITH OTHER MODELS (ANIMO & PEARL)

!  -- For Interfaces with other models
!   - Domain 1: Main Bypass Flow domain
      WaLevDm1= - ZWaLevDm(1)
      VlMpDm1= VlMpDm(1)
      WaSrDm1= WaSrMpDm(1)

!   - Domain 2: Internal Catchment domain
      VlMpDm2= 0.d0
      WaSrDm2= 0.d0
      do 200 id= 2, NumDm
         VlMpDm2= VlMpDm2 + VlMpDm(id)
         WaSrDm2= WaSrDm2 + WaSrMpDm(id)
 200  continue

      return
      end


!=======================================================================
      real*8 FUNCTION SHRINK(SwSoilShr,SwShrInp,ShrParA,ShrParB,ShrParC,
     &                       ShrParD,ShrParE,Theta,ThetaS)
! ----------------------------------------------------------------------
!     Date               : 15/7/02
!     Purpose            : calculate relative shrinkage for clay or peat soils
! ----------------------------------------------------------------------
      implicit NONE

! --- global
      integer SwShrInp, SwSoilShr
      real*8 ShrParA, ShrParB, ShrParC, ShrParD, ShrParE, Theta, ThetaS 
! ----------------------------------------------------------------------
! --- local
      real*8 Alfa, Beta, Gamma, MoisR, MoisRa, MoisRP, MoisRS
      real*8 MoisRT, P, VlSolidRel, VoidR, VoidR0, VoidRS, VoidRT, VrHlp
      real*8 MoisRi, MR1, MR2, VR1, VR2
! ----------------------------------------------------------------------
      VlSolidRel= 1.d0 - ThetaS 
      MoisR= Theta / VlSolidRel

! --- calculation of VoidR= actual void ratio
      if (SwSoilShr.eq.1) then
!  -- clay soil
         Alfa  = ShrParA
         Beta  = ShrParB
         Gamma = ShrParC
         MoisRa= ShrParD
         if (MoisR.gt.MoisRa) then
            VoidR= MoisR
         else
            VoidR= Alfa*dexp(-Beta*MoisR) + Gamma*MoisR
            VoidR= dmax1(VoidR,Alfa)
         endif

      elseif (SwSoilShr.eq.2) then
!  -- peat soil
!   - according to relation of Hendriks
         VoidR0= ShrParA
         MoisRa= ShrParB
!    - Moist and Void Ratio at saturation
         MoisRS= ThetaS / VlSolidRel
         VoidRS= MoisRS
!
!         if (SwShrInp.eq.1) then
         if (SwShrInp.ne.3) then
            Alfa  = ShrParC
            Beta  = ShrParD
            P     = ShrParE

!    - NorMalised Moist and Void Ratio
            MoisRP= Alfa / Beta
            MoisRT= MoisR / MoisRa
            VoidRT= VoidR0 + (VoidRS-VoidR0)*MoisR/MoisRS
            VrHlp = 1.d0 + P * 
     &           ((MoisRT**Alfa) * (dexp(-Beta*MoisRT) - dexp(-Beta))) / 
     &           ((MoisRP**Alfa) * (dexp(-Alfa)        - dexp(-Beta)))
!
            if (MoisR.lt.MoisRa) then
               VoidR= VoidRT * VrHlp
            else
               VoidR= VoidRT
            endif
!
!   - according to three straight line-pieces
         else
            MoisRi = ShrParC
            if (MoisR.gt.MoisRa) then
               MR1 = MoisRS
               MR2 = MoisRa
               VR1 = VoidRS
               VR2 = VoidR0 + (VoidRS-VoidR0)*MoisRa/MoisRS
            elseif (MoisR.gt.MoisRi) then
               MR1 = MoisRa
               MR2 = ShrParC
               VR1 = VoidR0 + (VoidRS-VoidR0)*MoisRa/MoisRS
               VR2 = ShrParD 
            else
               MR1 = ShrParC
               MR2 = 0.d0
               VR1 = ShrParD 
               VR2 = VoidR0
            endif
            VoidR = VR2 + (VR1-VR2) * (MoisR-MR2) / (MR1-MR2) 
         endif
      endif

! --- calculate relative volume of shrinkage
      SHRINK= ThetaS - VoidR*VlSolidRel

      return
      end

!=======================================================================
      SUBROUTINE MACRORESET(Itask)
! ----------------------------------------------------------------------
!     Date               : 24/08/02                                        
!     Purpose            : calculation of intermediate values and     
!                          cumulative values          
!     Subroutines called :                               
!     Functions called   : -
!     File usage         : -           
! ----------------------------------------------------------------------
      use Variables
      implicit NONE

      integer ic, ITask
! ----------------------------------------------------------------------

      if (ITask.eq.0 .or. ITask.eq.1) then
! set intermediate values to zero
         IQInTopPreDm1= 0.d0
         IQInTopLatDm1= 0.d0
         IQInTopPreDm2= 0.d0
         IQInTopLatDm2= 0.d0
         IQMpOutDrRap = 0.d0

         do ic= 1, NumNod    
            IQExcMtxDm1Cp(ic) = 0.d0
            IQExcMtxDm2Cp(ic) = 0.d0
            IQOutDrRapCp(ic)  = 0.d0 
            IAvFrMpWlWtDm1(ic)= 0.d0 
            IAvFrMpWlWtDm2(ic)= 0.d0 
         enddo

! --- reset states for beginning new balance period
         IWaSrDm1Beg= WaSrDm1
         IWaSrDm2Beg= WaSrDm2
      endif

      if (ITask.eq.0 .or. ITask.eq.2) then
! set cumulative values to zero
         cQMpLatSs       = 0.0d0
         CQMpInIntSatDm1 = 0.0d0
         CQMpInIntSatDm2 = 0.0d0
         CQMpInMtxSatDm1 = 0.0d0
         CQMpInMtxSatDm2 = 0.0d0
         CQMpOutMtxSatDm1= 0.0d0
         CQMpOutMtxSatDm2= 0.0d0
         CQMpOutMtxUnsDm1= 0.0d0
         CQMpOutMtxUnsDm2= 0.0d0
         CQMpInTopPreDm1 = 0.0d0
         CQMpInTopPreDm2 = 0.0d0
         CQMpInTopLatDm1 = 0.0d0
         CQMpInTopLatDm2 = 0.0d0
         CQMpOutDrRap    = 0.0d0    

! --- reset states for beginning new balance period
         WaSrDm1Ini= WaSrDm1
         WaSrDm2Ini= WaSrDm2
      endif

      return
      end

