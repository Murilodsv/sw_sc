! File VersionID:
!   $Id: snow.for 115 2009-01-08 14:17:03Z kroes006 $
! ----------------------------------------------------------------------
      subroutine snow(task)
! ----------------------------------------------------------------------
!     date               : December 2004
!     purpose            : Simulation snow accumulation and melt
! ----------------------------------------------------------------------
      use Variables
      implicit none

      integer   task        
      real*8    smelt      ! snowmelt by temperature [cm swe]
      real*8    smeltr     ! snowmelt by rain [cm swe]
      real*8    SnDefit
      real*8    SnLoss
      
! --- constants
      real*8    cwat       ! specific heat of water [j/kg/k]
      real*8    lm         ! latent heat of melting [j/kg] 
      real*8    ts         ! snow temperature [0 oc] 
 
      parameter(cwat=4180.0d0,lm=333580d0,ts=0.0d0)

! ----------------------------------------------------------------------
      goto (1000,2000) task

1000  continue

! === initialization ===================================================

      if(swinco.ne.3)  ssnow = snowinco

      return

2000  continue

! === snow pack rate and state variables ===============================

! --- reset intermediate snow states
      if (flzerointr) then
        igsnow = 0.0d0
        isubl = 0.0d0
        isnrai = 0.0d0
        ISsnowBeg = Ssnow
      endif

! --- reset cumulative snow states
      if (flzerocumu) then
        cgsnow = 0.0d0
        csubl = 0.0d0
        csnrai = 0.0d0
        cmelt = 0.0d0
        snowinco = ssnow
      endif

! --- when there is snowpack calculate the amount of sublimation
      if (ssnow.gt.0.0d0) then
        subl = peva
        if(swetsine.eq.1) subl = pevaday
        empreva = 0.0d0
        peva = 0.0d0
      endif

! --- when the soil surface is above the freezing point there will be
! --- no accumulation of fresh snow. 
      if (tsoil(1).gt.0.5d0.and.ssnow.lt.1.0d-6.and.gsnow.gt.0.0d0) then
        ssnow = 0.0d0
        melt = gsnow
        subl = 0.d0
      else   
        
! ---   amount of snowmelt [cm swe]
        smelt = snowcoef * (tav-ts)
        
! ---   extra snowmelt when there falls rain on the snowpack [cm swe]
        if (snrai.gt.0.0d0) then
          smeltr = snrai * cwat * (tav-ts) / lm  
        else
          smeltr = 0.0d0
        endif

! ---   total snowmelt [cm swe]
        melt = max(0.0d0,(smelt + smeltr))
      
! ---   amount of snow left [cm swe]
        ssnow = ssnow + snrai + gsnow - subl - melt

! ---   in case of snow deficit: adapt snow loss terms melt and sublimation
        if (ssnow.lt.0.0d0) then
          SnDefit = - Ssnow
          SnLoss  = melt + subl
          melt    = (1.d0 - SnDefit/SnLoss) * melt
          subl    = (1.d0 - SnDefit/SnLoss) * subl
          Ssnow   = 0.d0
        endif
      endif

! --- set cumulative amounts
      igsnow = igsnow + gsnow
      isubl = isubl + subl
      isnrai = isnrai + snrai
      cgsnow = cgsnow + gsnow
      csubl = csubl + subl
      cmelt = cmelt + melt
      csnrai = csnrai + snrai

      return
      end

