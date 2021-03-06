! File VersionID:
!   $Id: calcgrid.for 176 2010-03-13 11:36:14Z kroes006 $
! ----------------------------------------------------------------------
      subroutine calcgrid 
! ----------------------------------------------------------------------
!     Date               : Aug 2004   
!     Purpose            : calculate grid parameters
! ----------------------------------------------------------------------

      use variables
      implicit none

      integer i,j,lay,node,layold
      character messag*200,tmp*11

! --- check correct input of number and height of soil compartments
      do i = 1,nsublay
        if (abs(ncomp(i)*hcomp(i) - hsublay(i)) .gt. 1.d-5) then
! ---     error in input data
          write(tmp,'(i11)') i
          tmp = adjustl(tmp)
          messag ='At the soil water section, part 4, at layer '//
     &   trim(tmp)//' the height of this soil layer hsublay corresponds'
     &    //' not to the product of height and number of compartments'
          call fatalerr ('initsol',messag)
        endif
      end do

! --- position of nodal points and distances between them; also layer 
! --- of each node
      node = 0
      do i = 1,nsublay
        do j = 1,ncomp(i)
          node = node + 1
          dz(node) = hcomp(i)          
          if (node .eq. 1) then
            z(node) = - 0.5 * dz(node)
            disnod(node) = - z(node)
            layer(node) = isoillay(i)
          else
            z(node) = z(node-1) - 0.5*(dz(node-1)+dz(node))
            disnod(node) = z(node-1)-z(node)
            layer(node) = isoillay(i)
          endif
        end do
      end do
      numnod = node
      disnod(numnod+1) = 0.5*dz(numnod)

! --- determine bottom compartment of each soil layer
      layold = 1
      do node = 1, numnod
        if (layer(node) .gt. layold) then
          botcom(layold) = node - 1
          layold = layold + 1
        endif
      end do
      numlay = layold
      botcom(numlay) = numnod

! --- linear interpolation values between nodes
      inpolb(1) = 0.5*dz(1)/disnod(2)
      do node = 2,numnod-1
        inpola(node) = 0.5*dz(node)/disnod(node)
        inpolb(node) = 0.5*dz(node)/disnod(node+1)
      end do
      inpola(numnod) = 0.5*dz(numnod)/disnod(numnod)

! --- find first Node of the Layer
      do lay = 1,numlay
        Node = 1
        do while(Layer(Node).ne.lay)
           Node = Node + 1
        enddo
        nod1lay(lay) = node
      enddo


      return
      end

