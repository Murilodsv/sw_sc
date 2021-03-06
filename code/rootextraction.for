! File VersionID:
!   $Id: rootextraction.for 192 2011-02-10 13:39:33Z kroes006 $
! ----------------------------------------------------------------------
      subroutine RootExtraction 
! ----------------------------------------------------------------------
!     update    : February 2011: macrosopic uptake extended with compensation 
!     date      : August 2004
!     purpose   : Calculate the root water extraction rate as function of soil water
!                 pressure head and salinity concentration for each node
! ----------------------------------------------------------------------
      use variables
      implicit none

! --- local variables
      integer node, lay, countpf                                        ! NwRootExtr
      logical flnus
      real*8  top,bot,ecsat,afgen,hlim3,hlim2,qpotrot,qred
      real*8  alpdry,alpwet,alpsol,alpwat,alpfrs,alptot,vsmall,factor
      real*8  qredwet(macp),qreddry(macp),qredsol(macp),qredfrs(macp)
      real*8  rmax,hwet                                                 ! NwRootExtr
      real*8  reldepth,rdensity,phi,sumrho,meandepth                    !
      logical flactive(macp),flhydrlift                                 !
      character messag*200

      save    countpf                                                   ! NwRootExtr
      parameter (vsmall = 1.0d-7)


! ----------------------------------------------------------------------
! --- reset root water extraction array
      do 10 node = 1,numnod
        qrot(node) = 0.0d0
10    continue
      qrosum = 0.0d0
      qreddrysum = 0.0d0
      qredwetsum = 0.0d0
      qredsolsum = 0.0d0
      qredfrssum = 0.0d0

! --- skip routine if there are no roots
      if (rd .lt. 1.d-3) return

! --- determine lowest compartment containing roots
      node = 1
      do while ((z(node) - dz(node)*0.5d0) .gt. (-rd + 1.d-8))
        node = node + 1
      end do
      noddrz = node

! --- skip routine if transpiration rate is zero                        ! NwRootExtr
      if (ptra .lt. 1.d-10) then                                        !
        if (swroottyp .eq. 2) then                                      !
! ---   set matric flux and pressure head at root surface equal to wettest node
          node = 1                                                      !
          hwet = h(node)                                                !
          call matricflux(2,h(node),node)                               !
          mfluxroot = mflux(node)                                       !
          do node = 2,noddrz                                            !
            if (h(node) .gt. hwet) then                                 !
              hwet = h(node)                                            !
              call matricflux(2,h(node),node)                           !
              mfluxroot = mflux(node)                                   !
            endif                                                       !
          enddo                                                         !
        endif                                                           !
! ---   skip root extraction routine                                    !
        return                                                          !

      endif                                                             !

                                                                        !

      if (swroottyp .eq. 1) then

! ===   ROOTWATER EXTRACTION ACCORDING TO FEDDES REDUCTION FUNCTION

! ---   calculate potential root extraction of the compartments
        do node = 1,noddrz
          top = abs((z(node) + 0.5*dz(node)) / rd)
          bot = abs((z(node) - 0.5*dz(node)) / rd)
          qrot(node) = 
     &             (afgen(cumdens,202,bot)-afgen(cumdens,202,top))* ptra

        enddo
        
!=============================================================================        
!        do node = 1,noddrz
!            write (*,65) qrot(node),rd,z(node),dz(node),ptra,h(node)          
!65    format(10F7.3)  
!        enddo    
!      pause
!==============================================================================
          
          
! ---   calculating critical point hlim3 according to feddes
        hlim3=hlim3h
        if (atmdem.ge.adcrl) then
          if (atmdem.le.adcrh)   hlim3 =
     &            hlim3h+((adcrh-atmdem)/(adcrh-adcrl)) *(hlim3l-hlim3h)
        else
          hlim3 = hlim3l
        endif

! ---   calculation of transpiration reduction
        hlim2 = hlim2u
        do 200 node = 1,noddrz
          alpdry = 1.0d0
          alpwet = 1.0d0
          alpwat = 1.0d0
          alpsol = 1.0d0
          alpfrs = 1.0d0

! ---     reduction due to water stress
          if (node.gt.botcom(1)) hlim2=hlim2l
! ---     waterstress/ wet circumstances
          if (h(node).le.hlim1.and.h(node).gt.hlim2) then
            alpwat = (hlim1-h(node))/(hlim1-hlim2)
            alpwet = alpwat
          endif
! ---     waterstress/ dry circumstances
          if (h(node).le.hlim3.and.h(node).ge.hlim4) then
            alpwat = (hlim4-h(node))/(hlim4-hlim3)
            alpdry = alpwat
          endif
! ---     no transpiration 
          if (h(node).gt.hlim1) then
            alpwat = 0.0d0
            alpwet = alpwat
          endif
          if (h(node).lt.hlim4) then
            alpwat = 0.0d0
            alpdry = alpwat
          endif
          

! ---     reduction due to salt stress
          if (swsolu.eq.1) then
            lay = layer(node)
            ecsat = c2eca * ( cml(node) * 
     &            theta(node)/(thetsl(lay)*c2ecf(lay)) ) **c2ecb 
            if (ecsat .lt. ecmax) then
              alpsol = 1.0d0
            else
              alpsol = (100.0d0 - (ecsat - ecmax)*ecslop) / 100.
              alpsol = max(0.0d0,alpsol)
            endif
          endif

! ----    reduction due to frost conditions
          if (swfrost.eq.1.and.tsoil(node).lt.0.0d0) then
            alpfrs = 0.0d0
          endif

! ----    overall reduction
          qpotrot = qrot(node)
          qrot(node) = qrot(node)*alpwet*alpdry*alpsol*alpfrs
          qrosum = qrot(node) + qrosum         
         
! ----    apportionment to different types stresses (cm)
          qred = qpotrot - qrot(node)
          if(qred.lt.vsmall)then
            qredwet(node) = 0.d0
            qreddry(node) = 0.d0
            qredsol(node) = 0.d0
            qredfrs(node) = 0.d0
          else
            alptot = 0.0d0
!         set flag for non unique stress
            flnus = .true.
            if(alpwet .gt. vsmall) then 
               alptot = alptot + dlog(alpwet)
            else
              qredwet(node) = qred
              qreddry(node) = 0.d0
              qredsol(node) = 0.d0
              qredfrs(node) = 0.d0
              flnus = .false.
            end if
            if(flnus)then
              if(alpdry .gt. vsmall) then 
                 alptot = alptot + dlog(alpdry)
              else
                qredwet(node) = 0.d0
                qreddry(node) = qred
                qredsol(node) = 0.d0
                qredfrs(node) = 0.d0
                flnus = .false.
              end if
            end if
            if(flnus)then
              if(alpsol .gt. vsmall) then 
                 alptot = alptot + dlog(alpsol)
              else
                qredwet(node) = 0.d0
                qreddry(node) = 0.d0
                qredsol(node) = qred
                qredfrs(node) = 0.d0
                flnus = .false.
              end if
            end if
            if(flnus)then
              if(alpfrs .gt. vsmall) then 
                 alptot = alptot + dlog(alpfrs)
              else
                qredwet(node) = 0.d0
                qreddry(node) = 0.d0
                qredsol(node) = 0.d0
                qredfrs(node) = qred
                flnus = .false.
              end if
            end if

            if(flnus)then
              qredwet(node) = dlog(alpwet) / alptot * qred
              qreddry(node) = dlog(alpdry) / alptot * qred
              qredsol(node) = dlog(alpsol) / alptot * qred
              qredfrs(node) = dlog(alpfrs) / alptot * qred
            end if
          end if

          qredwetsum = qredwetsum + qredwet(node)
          qreddrysum = qreddrysum + qreddry(node)
          qredsolsum = qredsolsum + qredsol(node)
          qredfrssum = qredfrssum + qredfrs(node)

200           continue

              
! --    Compensated root water uptake according to Jarvis (1989)
        if (abs(alphacrit-1.0d0).ge.vsmall .and. 
     &                           abs(qrosum-ptra).ge.vsmall) then
          alptot = qrosum / ptra          
          if (alptot .gt. alphacrit) then
            do node = 1,noddrz
              qrot(node) = qrot(node) / alptot            
            enddo
            qredwetsum = 0.0d0
            qreddrysum = 0.0d0
            qredsolsum = 0.0d0
            qredfrssum = 0.0d0
            qrosum = ptra
          else
            do node = 1,noddrz
              qrot(node) = qrot(node) / alphacrit
            enddo
            factor = (ptra - qrosum / alphacrit) / (ptra - qrosum)
            qredwetsum = qredwetsum * factor
            qreddrysum = qreddrysum * factor
            qredsolsum = qredsolsum * factor
            qredfrssum = qredfrssum * factor
            qrosum = qrosum / alphacrit
          endif
        endif


      else if (swroottyp .eq. 2) then


! ===    ROOTWATER EXTRACTION ACCORDING TO MATRIC FLUX POTENTIAL           ! NwRootExtr

! ---   initialization
        phi = 3.1415926d0
        mfluxroot = 0.d0
        flhydrlift = .false.
        if (countpf .eq. 0) countpf = 1

        do node = 1,noddrz
           flactive(node) = .true.
        enddo

! ---   calculate current matric flux potential MFlux
        do node = 1,numnod
          call MatricFlux(2,h(node),node) 
        enddo

! ---   maximum root extraction (M0 = 0)
        do node = 1,noddrz-1
          reldepth = -z(node)/rd
          rdensity = afgen(rdctb,22,reldepth)
          rmax = 1.d0/sqrt(phi*rdensity)
          rootrho(node) = 4.d0/(rootcoefa*rmax * rootcoefa*rmax -
     &     rootradius*rootradius + 2.d0 * (rmax*rmax - rootradius * 
     &     rootradius) * log(rootcoefa*rmax/rootradius))
          qrot(node) = rootrho(node)*mflux(node)*dz(node)
          qrosum = qrot(node) + qrosum
        enddo

! ---   last node, partly filled with roots
        node = noddrz
        meandepth = (z(node)+0.5*dz(node)-rd)/2.d0
        reldepth = meandepth/(-rd)
        rdensity = afgen(rdctb,22,reldepth)
        rmax = 1.d0/sqrt(phi*rdensity)
        rootrho(node) = 4.d0/(rootcoefa*rmax * rootcoefa*rmax -
     &     rootradius*rootradius + 2.d0 * (rmax*rmax - rootradius * 
     &     rootradius) * log(rootcoefa*rmax/rootradius))
        if (node.gt.1) then
          mflux(node) = mflux(node) + (mflux(node-1)-mflux(node))/
     &              (z(node-1)-z(node)) * (meandepth-z(node))
        endif
        qrot(node) = rootrho(node) * mflux(node) *
     &             (z(node) + 0.5*dz(node) + rd)
        qrosum = qrot(node) + qrosum

        if (qrosum .gt. ptra) then
! ---     no water stress, calculate mfluxroot
          sumrho = 0.d0
          do node = 1,noddrz-1
            sumrho = sumrho + rootrho(node)*dz(node)
          enddo
          node = noddrz
          sumrho = sumrho + rootrho(node)*(z(node) + 0.5*dz(node) + rd)
          mfluxroot = (qrosum - ptra) / sumrho

! ---     calculate distribution root water uptake for potential conditions
          qrosum = 0.d0
          do node = 1,noddrz - 1
            qrot(node) = rootrho(node)*(mflux(node)-mfluxroot)*dz(node)
            if (qrot(node) .lt. 0.d0) then
              flhydrlift = .true.
              qrot(node) = 0.d0
              flactive(node) = .false.
            endif
            qrosum = qrot(node) + qrosum
          enddo
          node = noddrz
          qrot(node) = rootrho(node) * (mflux(node)-mfluxroot) *
     &               (z(node) + 0.5*dz(node) + rd)
          if (qrot(node) .lt. 0.d0) then
            flhydrlift = .true.
            qrot(node) = 0.d0
            flactive(node) = .false.
          endif
          qrosum = qrot(node) + qrosum

! ---     extra loop required when flhydrlift = .true.
          do while (flhydrlift)
            flhydrlift = .false.

! ---       determine sum maximum root extraction for active compartments
            qrosum = 0.d0
            do node = 1,noddrz-1
              if (flactive(node)) then
                qrot(node) = rootrho(node)*mflux(node)*dz(node)
                qrosum = qrot(node) + qrosum
              endif
            enddo
            node = noddrz
            if (flactive(node)) then
              qrot(node) = rootrho(node) * mflux(node) *
     &                   (z(node) + 0.5*dz(node) + rd)
              qrosum = qrot(node) + qrosum
            endif

! ---       no water stress, calculate M0 for active compartments
            sumrho = 0.d0
            do node = 1,noddrz-1
              if (flactive(node)) 
     &                          sumrho = sumrho + rootrho(node)*dz(node)
            enddo
            node = noddrz
            if (flactive(node)) sumrho = sumrho + rootrho(node) * 
     &                                 (z(node) + 0.5*dz(node) + rd)
            mfluxroot = (qrosum - ptra) / sumrho

! ---       calculate again distribution root water uptake for potential conditions
            qrosum = 0.d0
            do node = 1,noddrz - 1
              if (flactive(node)) then
                qrot(node) = 
     &                    rootrho(node)*(mflux(node)-mfluxroot)*dz(node)
                if (qrot(node) .lt. 0.d0) then
                  flhydrlift = .true.
                  qrot(node) = 0.d0
                  flactive(node) = .false.
                endif
                qrosum = qrot(node) + qrosum
              endif
            enddo
            node = noddrz
            if (flactive(node)) then
              qrot(node) = rootrho(node) * (mflux(node)-mfluxroot) *
     &                   (z(node) + 0.5*dz(node) + rd)
              if (qrot(node) .lt. 0.d0) then
                flhydrlift = .true.
                qrot(node) = 0.d0
                flactive(node) = .false.
              endif
              qrosum = qrot(node) + qrosum
            endif
          enddo

        else
! ---     actual transpiration less than potential transpiration
          mfluxroot = 0.0d0
        endif                                                             

      else
	
        messag = ' SwRootTyp not defined !'
        call fatalerr('rootextraction',messag)

      endif

      return
      end

