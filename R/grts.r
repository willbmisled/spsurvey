grts <- function(design, DesignID="Site", SiteBegin=1, type.frame="finite",
   src.frame="shapefile", in.shape=NULL, sp.object=NULL, att.frame=NULL,
   id=NULL, xcoord=NULL, ycoord=NULL, stratum=NULL, mdcaty=NULL, startlev=NULL,
   maxlev=11, maxtry=1000, shift.grid=TRUE, do.sample=rep(TRUE, length(design)),
   shapefile=TRUE, prjfilename=NULL, out.shape="sample") {

################################################################################
# Function: grts
# Purpose: Select a generalized random-tesselation stratified (GRTS) sample
# Programmers: Tony Olsen, Tom Kincaid, Don Stevens, Christian Platt,
#              Denis White, Richard Remington
# Date: October 8, 2002
# Last Revised: November 3, 2011
# Description:
#   This function select a GRTS sample of a finite, linear, or area resource.
#   Frame elements must be located in 1- or 2-dimensional coordinate system.
#   Random selection may be generalized random tessellation stratified (GRTS),
#   independent random sample (IRS), or systematic sample.  Sample may be
#   equal probability or unequal probability (either categorical or proportional
#   to auxiliary variable).  May designate panels of sites for surveys over
#   time.
# Arguments:
#   design = named list of stratum design specifications, where each element of
#     design is a list containing the design specifications for a stratum.  For
#     an unstratified sample, design contains a single list.  If the sample is
#     stratified, the names in design must occur among the strata names in the
#     stratum column of the attributes data frame (att.frame).  If the sample is
#     unstratified, the name of the single list in design is arbitrary.  Each
#     list in design has four components:
#       panel = named vector of sample sizes for each panel in the stratum
#       seltype = the type of random selection, which must be one of following:
#         "Equal" - equal probability selection, "Unequal" - unequal probability
#         selection by the categories specified in caty.n and mdcaty, or
#         "Continuous" - unequal probability selection proportional to auxiliary
#         variable mdcaty
#       caty.n = if seltype equals "Unequal", a named vector of sample sizes for
#         each category specified by mdcaty, where sum of the sample sizes must
#         equal sum of the panel sample sizes, and names must be a subset of
#         values in mdcaty
#       over = number of replacement sites ("oversample" sites) for the entire
#         design, which is set equal to 0 if none are required
#     Example design for a stratified sample: 
#       design <- list("Stratum 1"=list(panel=c(Panel=50), seltype="Equal",
#         over=10), "Stratum 2"=list(panel=c("Panel One"=50, "Panel Two"=50),
#         seltype="Unequal", caty.n=c(CatyOne=25, CatyTwo=25, CatyThree=25,
#         CatyFour=25), over=75))
#     Example design for an unstratified sample: 
#       design <- list(None=list(panel=c(Panel1=50, Panel2=100, Panel3=50),
#         seltype="Unequal", caty.n=c("Caty 1"=50, "Caty 2"=25, "Caty 3"=25,
#         "Caty 4"=25, "Caty 5"=75), over=100))
#   DesignID = name for the design, which is used to create a site ID
#      for each site.  The default is "Site".
#   SiteBegin = number to use for first site in the design.  The default is 1.
#   type.frame = the type of frame, which must be one of following: "finite",
#     "linear", or "area".  The default is "finite".
#   src.frame = source of the frame, which equals "shapefile" if the frame is to
#     be read from a shapefile, "sp.object" if the frame is obtained from an sp
#     package object, or "att.frame" if type.frame equals "finite" and the frame
#     is included in att.frame.  The default is "shapefile".
#   in.shape = name (without any extension) of the input shapefile.  If
#     src.frame equal "shapefile" and in.shape equals NULL, then the shapefile
#     or shapefiles in the working directory are used.  The default is NULL.
#   sp.object = name of the sp package object when src.frame equals "sp.object".
#     The default is NULL.
#   att.frame = a data frame composed of attributes associated with elements in
#     the frame, which must contain the columns used for stratum and mdcaty (if
#     required).  If src.frame equals "shapefile" and att.frame equals NULL,
#     then att.frame is created from the dbf file(s) in the working directory.
#     If src.frame equals "sp.object" and att.frame equals NULL, then att.frame
#     is created from the sp object.  If src.frame equals "att.frame", then
#     att.frame must include columns that contain x-coordinates and
#     y-coordinates for each element in the frame.  The default is NULL.
#   id = name of the column from att.frame that identifies the ID value for each
#     element in the frame.  If id equals NULL, a column named "id" that
#     contains values from one through the number of rows in att.frame is added
#     to att.frame.  The default is NULL.
#   xcoord = name of the column from att.frame that identifies x-coordinates
#     when src.frame equals "att.frame".  If xcoord equals NULL, then xcoord is
#     given the value "x".  The default is NULL.
#   ycoord = name of the column from att.frame that identifies y-coordinates
#     when src.frame equals "att.frame".  If ycoord equals NULL, then ycoord is
#     given the value "y".  The default is NULL.
#   stratum = name of the column from att.frame that identifies stratum
#     membership for each element in the frame.  If stratum equals NULL, the
#     design is unstratified, and a column named "stratum" (with all of its
#     elements equal to the stratum name specified in design) is added to
#     att.frame.  The default is NULL.
#   mdcaty = name of the column from att.frame that identifies the unequal
#     probability category for each element in the frame.  The default is NULL.
#   startlev = initial number of hierarchical levels to use for the GRTS grid,
#     which must be less than or equal to maxlev (if maxlev is specified) and
#     cannot be greater than 11.  The default is NULL.
#   maxlev = maximum number of hierarchical levels to use for the GRTS grid,
#     which cannot be greater than 11.  The default is 11.
#   maxtry = maximum number of iterations for randomly generating a point within
#     a grid cell to select a site when type.frame equals "area".  The default
#     is 1000.
#   shift.grid = option to randomly shift the hierarchical grid, where TRUE
#     means shift the grid and FALSE means do not shift the grid, which is
#     useful if one desires strict spatial stratification by hierarchical grid
#     cells.  The default is TRUE.
#   do.sample = named vector that provides the option controlling sample
#     selection for each stratum, where TRUE means select a sample from a
#     stratum and FALSE means return the sample frame for a stratum in reverse
#     hierarchical order.  Note that FALSE can only be used when type.frame
#     equals "points" and seltype equals "Equal".  Names for the vector must
#     match the names in design.  If the vector is not named, then the names in
#     design are used.  The default is TRUE for each stratum.
#   shapefile = option to create a shapefile containing the survey design
#     information,  where TRUE equals create a shapefile and FALSE equals do
#     not create a shapefile.  The default is TRUE.
#   prjfilename = name (without any extension) of the projection file for the
#     input shapefile, which is used to name the projection file for the output
#     shapefile.  The default is NULL.
#   out.shape = name (without any extension) of the output shapefile containing
#     the survey design information.  The default is "sample".
# Results:
#   An sp package object containing the survey design information and any
#   additional attribute variables that were provided.  The object is assigned
#   class "SpatialPointsDataFrame".  For further information regarding the
#   output object, see documentation for the sp package.  Optionally, a
#   shapefile can be created that contains the survey design information.
# Other Functions Required:
#   sp2shape - converts an sp package object to a shapefile
#   getRecordShapeSizes - C function to read the shp file of a line or polygon
#     shapefile and return the length or area for each record in the shapefile
#   grtsarea - select a GRTS sample of an area resource
#   grtslin - select a GRTS sample of a linear resource
#   grtspts - select a GRTS sample of a finite resource
#   read.dbf - function to read the dbf file of a shapefile and return a 
#     data frame containing contents of the file
#   readShapeFilePts - C function to read the shp file of a point shapefile and
#     return a data frame containing the x-coordinates and y-coordinates for
#     elements in the frame
#   SpatialPoints - sp package function to create an object of class
#     SpatialPoints
#   SpatialPointsDataFrame - sp package function to create an object of class
#     SpatialPointsDataFrame
#   writeShapeFilePoint - C function to create a shapefile containing the survey
#     design information
# Example:
#   test.design <- list("Stratum 1"=list(panel=c(Panel=50), seltype="Equal",
#      over=10), "Stratum 2"=list(panel=c("Panel One"=50, "Panel Two"=50),
#      seltype="Unequal", caty.n=c(CatyOne=25, CatyTwo=25, CatyThree=25,
#      CatyFour=25), over=75))
#   test.attframe <- read.dbf("test.shapefile")
#   test.sample <- grts(design=test.design, DesignID="Test.Site",
#      type.frame="area", src.frame="shapefile", in.shape="test.shapefile",
#      att.frame=test.attframe, stratum="test.stratum", mdcaty="test.mdcaty",
#      shapefile=TRUE, out.shape="test.sample")
################################################################################

# Ensure that a design list is provided

if(is.null(design))
   stop("\nA design list must be provided.")

# Ensure that the design list is named and determine strata names from the
# design list

strata.names <- names(design)
if(is.null(strata.names)) {
   if(length(design) > 1) {
      stop("\nThe design list must be named.")
   } else {
      warning("\nSince the single stratum specified in the design list was not named, \n\"None\" will be used for the stratum name.\n")
      strata.names <- "None"
      names(design) <- strata.names
   }
}

# Ensure that src.frame contains a valid value

temp <- match(src.frame, c("shapefile", "sp.object", "att.frame"), nomatch=0)
if(temp == 0)
   stop(paste("\nThe value provided for argument src.frame, \"", src.frame, "\" is not a valid value.", sep=""))

# If src,frame equals "sp.object", then create a temporary shapefile

sp.ind <- FALSE
if(src.frame == "sp.object") {
   if(is.null(sp.object))
      stop("\nAn sp package object is required when the value provided for argument src.frame \nequals \"sp.object\".")
   sp.ind <- TRUE
   src.frame <- "shapefile"
   in.shape <- "tempfile0921"
   sp2shape(sp.object, in.shape)
}

# If src.frame equals "shapefile" and att.frame equals NULL, then create
# att.frame

if(src.frame == "shapefile" && is.null(att.frame))
   att.frame <- read.dbf(in.shape)

# If src.frame equals "att.frame", ensure that type.frame equals "finite"

if(src.frame == "att.frame" && type.frame != "finite")
   stop(paste("\nThe value provided for argument type.frame must equal \"finite\" when argument \nsrc.frame equals \"att.frame\"  The value provided for argument type.frame was \n\"", type.frame, "\".", sep=""))

# If id equals NULL, create ID values
# Otherwise, ensure that the name provided for id identifies a column in
# the attributes data frame, values in the column are unique, the column is
# not a factor (when src.frame equals "att.frame"), and the column contains
# valid values (when src.frame does not equals "att.frame")

if(is.null(id)) {
   id <- "id"
   att.frame$id <- 1:nrow(att.frame)
} else {
   temp <- match(id, names(att.frame), nomatch=0)
   if(temp == 0)
      stop(paste("\nThe value provided for the column from att.frame that identifies ID value for \neach element in the frame, \"", id, "\", does not occur among the columns in \natt.frame.", sep=""))
   if(length(unique(att.frame[, id])) != nrow(att.frame))
      stop(paste("\nThe ID values for elements of the frame that are provided in att.frame are not \nunique.", sep=""))
   if(src.frame == "att.frame") {
      if(is.factor(att.frame[, id]))
         att.frame[, id] <- as.character(att.frame[, id])
   } else {
      if(sp.ind) {
         src.temp <- "sp.object"
      } else {
         src.temp <- "shapefile"
      }
      if(!is.numeric(att.frame[, id]))
         stop(paste("\nThe ID values in column \"", id, "\" of att.frame must be numeric when argument \nsrc.frame equals \"", src.temp, "\".", sep=""))
      if(any(att.frame[, id] < 1))
         stop(paste("\nThe ID values in column \"", id, "\" of att.frame must be positive integers when \nargument src.frame equals \"", src.temp, "\".", sep=""))
      att.temp <- read.dbf(in.shape)
      if(any(att.frame[, id] > nrow(att.temp)))
         stop(paste("\nThe ID values in column \"", id, "\" of att.frame must not exceed the number of \nrecords when argument src.frame equals \"", src.temp, "\".", sep=""))
      rm(att.temp)
      if(!is.integer(att.frame[, id]))
         att.frame[, id] <- as.integer(att.frame[, id])
   }
}

# If stratum equals NULL, ensure that the design list specifies a single stratum
# and add a column named "stratum" to the attributes data frame
# Otherwise, ensure that the name provided for stratum identifies a column in
# the attributes data frame

if(is.null(stratum)) {
   if(length(strata.names) > 1)
      stop("\nThe column from att.frame that identifies stratum membership was not provided \nand design specifies more than one stratum.")
   stratum <- "stratum"
   att.frame$stratum <- factor(rep(strata.names, nrow(att.frame)))
} else {
   temp <- match(stratum, names(att.frame), nomatch=0)
   if(temp == 0)
      stop(paste("\nThe value provided for the column from att.frame that identifies stratum \nmembership for each element in the frame, \"", stratum, "\", does not occur \namong the columns in att.frame.", sep=""))
}

# Ensure that the stratum variable in the attributes data frame is a factor

if(!is.factor(att.frame[,stratum]))
   att.frame[,stratum] <- as.factor(att.frame[,stratum])

# If seltype is not "Equal" for every stratum, then do the following: (1) ensure
# that mdcaty is not NULL and (2) ensure that the name provided for mdcaty
# identifies a column in the attributes data frame 

seltype.ind <- FALSE
for(s in strata.names) {
   if(design[[s]]$seltype != "Equal") {
      seltype.ind <- TRUE
   }
}
if(seltype.ind) {
   if(is.null(mdcaty))
      stop(paste("\nThe name of the column from att.frame that identifies the unequal probability \ncategory for each element in the frame must be provided.", sep=""))
   temp <- match(mdcaty, names(att.frame), nomatch=0)
   if(temp == 0)
      stop(paste("\nThe value provided for the column from att.frame that identifies the unequal \nprobability category for each element in the frame, \"", mdcaty, "\", \ndoes not occur among the columns in att.frame.", sep=""))
}

# Ensure that startlev and maxlev are valid and compatible values

if(!is.null(startlev)) {
   if(startlev < 1)
      stop("\nThe value for startlev cannot be less than 1")
   if(startlev > 11)
      stop("\nThe value for startlev cannot be greater than 11")
   if(maxlev < 1)
      stop("\nThe value for maxlev cannot be less than 1")
   if(maxlev > 11)
      stop("\nThe value for maxlev cannot be greater than 11")
   if(startlev > maxlev)
      stop("\nThe value for startlev cannot be greater than the value for maxlev")
} else {
   if(maxlev < 1)
      stop("\nThe value for maxlev cannot be less than 1")
   if(maxlev > 11)
      stop("\nThe value for maxlev cannot be greater than 11")
}

# Begin the section for a finite population (discrete points)

if(type.frame == "finite") {

   first <- TRUE
   SiteBegin <- SiteBegin

# If src.frame equals "shapefile", then add x-coordinates and y-coordinates to
# att.frame

   if(src.frame == "shapefile") {
      temp <- .Call("readShapeFilePts", in.shape)
      xcoord <- "x"
      ycoord <- "y"
      att.frame$x <- temp$x[att.frame[,id]]
      att.frame$y <- temp$y[att.frame[,id]]

# If src.frame equals "att.frame", ensure that att.frame includes columns
# containing x-coordinates and y-coordinates

   } else if(src.frame == "att.frame") {
      if(is.null(xcoord))
         xcoord <- "x"
      if(is.null(ycoord))
         ycoord <- "y"
      temp <- match(c(xcoord, ycoord), names(att.frame), nomatch=0)
      if(any(temp == 0))
         stop(paste("\nThe names for one or both of the columns containing the x-coordinates and \ny-coordinates, \"", xcoord, "\" and \"", ycoord, "\", \ndo not occur among the column names in att.frame.", sep=""))
   }

# Ensure that do.sample is the correct length and is named

   if(length(do.sample) > 1) {
      if(length(do.sample) != length(design))
         stop("\nArgument do.sample must be the same length as the design list.")
      if(is.null(names(do.sample))) {
         names(do.sample) <- strata.names
      } else {
         temp <- match(names(do.sample), strata.names, nomatch=0)
         if(any(temp) == 0)
            temp.str <- vecprint(names(do.sample)[temp == 0])
            stop(paste("\nThe following names in do.sample do not occur among the names in design:\n", temp.str, sep=""))
      }
   } else if(is.null(names(do.sample))) {
      names(do.sample) <- strata.names
   }

# Begin the loop for strata

   for(s in strata.names) {

      cat(paste("\nStratum:", s, "\n"))

# Create the sample frame

      temp <- att.frame[,stratum] == s
      grtspts.ind <- TRUE
      if(sum(temp) == 0) {
         warning(paste("\nThe stratum column in the attributes data frame contains no values that match \nthe stratum named \"", s, "\" in the design list.\n", sep=""))
         next
      } else if(sum(temp) == 1) {
         warning(paste("\nThe stratum column in the attributes data frame contains a single value that \nmatches the stratum named \"", s, "\" in the design list. \nThe sample for this stratum will be composed of a single point.\n", sep=""))
         grtspts.ind <- FALSE
      }

      if(design[[s]]$seltype == "Equal") {
         sframe <- data.frame(id=I(att.frame[temp, id]),
            x=att.frame[temp, xcoord], y=att.frame[temp, ycoord],
            mdcaty=rep("Equal", nrow(att.frame[temp,])))
      } else if(design[[s]]$seltype == "Unequal") {
         sframe <- data.frame(id=I(att.frame[temp, id]), x=att.frame[temp, xcoord],
            y=att.frame[temp, ycoord], mdcaty=factor(att.frame[temp, mdcaty]))
      } else if(design[[s]]$seltype == "Continuous") {
         sframe <- data.frame(id=I(att.frame[temp, id]), x=att.frame[temp, xcoord],
            y=att.frame[temp, ycoord], mdcaty=att.frame[temp, mdcaty])
      } else {
         stop(paste("\nThe value provided for the type of random selection, \"", design[[s]]$seltype, "\", \nfor stratum \"", s, "\" is not valid.", sep=""))
      }

# If seltype is not "Equal", ensure that mdcaty contains valid values 

      if(design[[s]]$seltype == "Unequal") {
         if(any(is.na(sframe$mdcaty)))
            stop(paste("\nMissing values were detected among the unequal probability category values for \nstratum \"", s, "\".", sep=""))
      } else if(design[[s]]$seltype == "Continuous") {
         if(any(is.na(sframe$mdcaty)))
            stop(paste("\nMissing values were detected among the unequal probability category values for \nstratum \"", s, "\".", sep=""))
         if(!is.numeric(sframe$mdcaty))
            stop(paste("\nThe type of random selection for stratum \"", s, "\" is \"Continuous\", \nbut the unequal probability category values are not numeric.", sep=""))
         if(any(sframe$mdcaty < 0))
            stop(paste("\nNonpositive values were detected among the unequal probability category values \nfor stratum \"", s, "\".", sep=""))
      }

# If seltype is "Unequal", ensure that caty.n is provided and that the names
# in caty.n are included amont the levels of mdcaty

      if(design[[s]]$seltype == "Unequal") {
         if(is.null(design[[s]]$caty.n))
            stop(paste("The type of random selection was set to \"Unequal\", but caty.n was not \nprovided for stratum \"", s, "\".", sep=""))
         temp <- match(names(design[[s]]$caty.n),
            levels(as.factor(sframe$mdcaty)), nomatch=0)
         if(any(temp == 0)) {
            temp.str <- vecprint(names(design[[s]]$caty.n)[temp == 0])
            stop(paste("\nThe following names in caty.n for stratum \"", s, "\" do not occur \namong the levels of the mdcaty variable in att.frame:\n", temp.str, sep=""))
         }
      }

# Ensure that panel and caty.n contain valid values

      if(!is.numeric(design[[s]]$panel))
         stop(paste(" The design list must contain numeric values in the panel argument for \nstratum \"", s, "\".\n", sep=""))
      design[[s]]$panel <- round(design[[s]]$panel)
      design[[s]]$panel <- design[[s]]$panel[design[[s]]$panel > 0]
      if(length(design[[s]]$panel) == 0)
         stop(paste(" The design list does not not contain any valid values of the panel \nargument for stratum \"", s, "\".\n", sep=""))

      if(design[[s]]$seltype == "Unequal") {
         if(!is.numeric(design[[s]]$caty.n))
            stop(paste(" The design list must contain numeric values in the caty.n argument for \nstratum \"", s, "\".\n", sep=""))
         design[[s]]$caty.n <- round(design[[s]]$caty.n)
         design[[s]]$caty.n <- design[[s]]$caty.n[design[[s]]$caty.n > 0]
         if(length(design[[s]]$caty.n) == 0)
            stop(paste(" The design list does not not contain any valid values of the caty.n \nargument for stratum \"", s, "\".\n", sep=""))
      }

# As necessary, remove rows from sframe that have values of mdcaty which are not
# included among the names in caty.n

      if(design[[s]]$seltype == "Unequal") {
         temp <- sframe$mdcaty %in% names(design[[s]]$caty.n)
         if(any(!temp)) {
            sframe <- sframe[temp,]
         }
      }

# Determine overall sample size for the stratum

      if(is.null(design[[s]]$over))
         design[[s]]$over <- 0
      if(design[[s]]$seltype != "Unequal") {
         samplesize <- sum(design[[s]]$panel)
         n.desired <- sum(samplesize, design[[s]]$over)
      } else {
         if(sum(design[[s]]$panel) != sum(design[[s]]$caty.n))
            stop("\nThe sum of panel sample sizes does not equal sum of caty.n sample sizes")
         samplesize <- sum(design[[s]]$caty.n)
         if(design[[s]]$over == 0) {
            n.desired <- design[[s]]$caty.n
         } else {
            over.n <- design[[s]]$over * design[[s]]$caty.n /
               sum(design[[s]]$caty.n)
            if(any(over.n != floor(over.n))) 
               warning(paste("\nOversample size is not proportional to category sample sizes for stratum\n\"", s, "\".\n", sep=""))
            n.desired <- design[[s]]$caty.n + ceiling(over.n)
         }
      }

# Calculate mdm - inclusion probabilities

      if(design[[s]]$seltype == "Equal") 
         	sframe$mdm <- mdmpts(sframe$mdcaty, c(Equal=n.desired))
      else if(design[[s]]$seltype == "Unequal") 
         sframe$mdm <- mdmpts(sframe$mdcaty, n.desired)
      else
         sframe$mdm <- n.desired * sframe$mdcaty / sum(sframe$mdcaty)

# Select the sample

      if(grtspts.ind) {
         stmp <- grtspts(src.frame, in.shape, sframe, sum(n.desired), SiteBegin,
            shift.grid, do.sample[s], startlev, maxlev)
      } else {
         stmp <- data.frame(siteID=SiteBegin, id=sframe$id, xcoord=sframe$x,
            ycoord=sframe$y, mdcaty=sframe$mdcaty, wgt=1/sframe$mdm)
         row.names(stmp) <- 1
         attr(stmp, "nlev") <- NA
      }

# Determine whether the realized sample size is less than the desired size

      if(nrow(stmp) < sum(n.desired))
         warning(paste("\nThe size of the selected sample was less than the desired size for stratum\n\"", s, "\".\n", sep=""))

# Add the stratum variable

      stmp$stratum <- as.factor(rep(s,nrow(stmp)))

# Add panel and oversample structure

      stmp$panel <- as.character(rep("OverSamp",nrow(stmp)))
      n.panel <- length(design[[s]]$panel)
      if(nrow(stmp) < samplesize) {
         n.short <- samplesize - nrow(stmp)
         n.temp <- n.short / n.panel
         if(n.temp != floor(n.temp)) {
            n.temp <- c(ceiling(n.temp), rep(floor(n.temp), n.panel-1))
            i <- 1
            while(sum(n.temp) != n.short) {
               i <- i+1
               n.temp[i] <- n.temp[i] + 1
            }
         }
         np <- c(0, cumsum(design[[s]]$panel - n.temp))
      } else {
         np <- c(0, cumsum(design[[s]]$panel))
      }
      for(i in 1:n.panel)
         stmp$panel[(np[i]+1):np[i+1]] <- names(design[[s]]$panel[i])

# If an oversample is present or the realized sample size is less than the
# desired size, then adjust the weights

      if(design[[s]]$over > 0 || nrow(stmp) < samplesize) {
         if(design[[s]]$seltype != "Unequal") {
            if(nrow(stmp) < samplesize) {
               stmp$wgt <- n.desired * stmp$wgt / nrow(stmp)
            } else {
               stmp$wgt <- n.desired * stmp$wgt / samplesize
            }
         } else {
            if(nrow(stmp) < samplesize) {
               n.caty <- length(design[[s]]$caty.n)
               n.temp <- n.short / n.caty
               nc <- design[[s]]$caty.n - n.temp
            } else {
               nc <- design[[s]]$caty.n
            }
            for(i in names(n.desired)) {
               stmp$wgt[stmp$mdcaty == i] <- n.desired[i] *
                  stmp$wgt[stmp$mdcaty == i] / nc[i]
            }
         }
      }

# Add stratum sample to the output data frame

      if(first) {
         sites <- stmp
         levels(sites$stratum) <- strata.names
         first <- FALSE
      } else {
         sites <- rbind(sites, stmp)
      }
      SiteBegin <- SiteBegin + nrow(stmp)

# End the loop for strata

   }

# End the section for a finite population (discrete points)

} else if(type.frame == "linear") {

# Begin the section for a linear network

   first <- TRUE
   SiteBegin <- SiteBegin

# Ensure that att.frame includes a variable named length_mdm that provides the
# length for each record of the shapefile(s) in the working directory and create
# the variable when necessary

   if(is.null(att.frame$length_mdm)) {
      temp <- .Call("getRecordShapeSizes", in.shape)
      if(length(temp) != nrow(att.frame))
         stop("\nThe number of rows in the attribute data frame does not equal the number of \nrecords in the shapefile(s) in the working directory.")
      att.frame$length_mdm <- temp
   }
   elmsize <- "length_mdm"

# Begin the loop for strata

   for(s in strata.names) {

      cat(paste("\nStratum:", s, "\n"))

# Create the sample frame

      temp <- att.frame[,stratum] == s
      if(sum(temp) == 0) {
         warning(paste("\nThe stratum column in the attributes data frame contains no values that match \nthe stratum named \"", s, "\" in the design list.\n", sep=""))
         next
      }

      if(design[[s]]$seltype == "Equal") {
         sframe <- data.frame(id=att.frame[temp, id],
            mdcaty=rep("Equal", nrow(att.frame[temp,])),
            len=att.frame[temp, elmsize])
      } else if(design[[s]]$seltype == "Unequal") {
         sframe <- data.frame(id=att.frame[temp, id],
            mdcaty=factor(att.frame[temp, mdcaty]),
            len=att.frame[temp, elmsize])
      } else if(design[[s]]$seltype == "Continuous") {
         sframe <- data.frame(id=att.frame[temp, id],
            mdcaty=att.frame[temp, mdcaty],
            len=att.frame[temp, elmsize])
      } else {
         stop(paste("\nThe value provided for the type of random selection, \"", design[[s]]$seltype, "\", \nfor stratum \"", s, "\" is not valid.", sep=""))
      }

# If seltype is not "Equal", ensure that mdcaty contains valid values 

      if(design[[s]]$seltype == "Unequal") {
         if(any(is.na(sframe$mdcaty)))
            stop(paste("\nMissing values were detected among the unequal probability category values for \nstratum \"", s, "\".", sep=""))
      } else if(design[[s]]$seltype == "Continuous") {
         if(any(is.na(sframe$mdcaty)))
            stop(paste("\nMissing values were detected among the unequal probability category values for \nstratum \"", s, "\".", sep=""))
         if(!is.numeric(sframe$mdcaty))
            stop(paste("\nThe type of random selection for stratum \"", s, "\" is \"Continuous\", \nbut the unequal probability category values are not numeric.", sep=""))
         if(any(sframe$mdcaty < 0))
            stop(paste("\nNonpositive values were detected among the unequal probability category values \nfor stratum \"", s, "\".", sep=""))
      }

# If seltype is "Unequal", ensure that caty.n is provided and that the names
# in caty.n and the levels of mdcaty are equivalent

      if(design[[s]]$seltype == "Unequal") {
         if(is.null(design[[s]]$caty.n))
            stop(paste("The type of random selection was set to \"Unequal\", but caty.n was not \nprovided for stratum \"", s, "\".", sep=""))
         temp <- match(names(design[[s]]$caty.n),
            levels(as.factor(sframe$mdcaty)), nomatch=0)
         if(any(temp == 0)) {
            temp.str <- vecprint(names(design[[s]]$caty.n)[temp == 0])
            stop(paste("\nThe following names in caty.n for stratum \"", s, "\" do not occur \namong the levels of the mdcaty variable in att.frame:\n", temp.str, sep=""))
         }
      }

# Ensure that panel and caty.n contain valid values

      if(!is.numeric(design[[s]]$panel))
         stop(paste(" The design list must contain numeric values in the panel argument for \nstratum \"", s, "\".\n", sep=""))
      design[[s]]$panel <- round(design[[s]]$panel)
      design[[s]]$panel <- design[[s]]$panel[design[[s]]$panel > 0]
      if(length(design[[s]]$panel) == 0)
         stop(paste(" The design list does not not contain any valid values of the panel \nargument for stratum \"", s, "\".\n", sep=""))

      if(design[[s]]$seltype == "Unequal") {
         if(!is.numeric(design[[s]]$caty.n))
            stop(paste(" The design list must contain numeric values in the caty.n argument for \nstratum \"", s, "\".\n", sep=""))
         design[[s]]$caty.n <- round(design[[s]]$caty.n)
         design[[s]]$caty.n <- design[[s]]$caty.n[design[[s]]$caty.n > 0]
         if(length(design[[s]]$caty.n) == 0)
            stop(paste(" The design list does not not contain any valid values of the caty.n \nargument for stratum \"", s, "\".\n", sep=""))
      }

# As necessary, remove rows from sframe that have values of mdcaty which are not
# included among the names in caty.n

      if(design[[s]]$seltype == "Unequal") {
         temp <- sframe$mdcaty %in% names(design[[s]]$caty.n)
         if(any(!temp)) {
            sframe <- sframe[temp,]
         }
      }

# Determine overall sample size for the stratum

      if(is.null(design[[s]]$over))
         design[[s]]$over <- 0
      if(design[[s]]$seltype != "Unequal") {
         samplesize <- sum(design[[s]]$panel)
         n.desired <- sum(samplesize, design[[s]]$over)
      } else {
         if(sum(design[[s]]$panel) != sum(design[[s]]$caty.n))
            stop("\nThe sum of panel sample sizes does not equal sum of caty.n sample sizes")
         samplesize <- sum(design[[s]]$caty.n)
         if(design[[s]]$over == 0) {
            n.desired <- design[[s]]$caty.n
         } else {
            over.n <- design[[s]]$over * design[[s]]$caty.n /
               sum(design[[s]]$caty.n)
            if(any(over.n != floor(over.n))) 
               warning(paste("\nOversample size is not proportional to category sample sizes for stratum\n\"", s, "\".\n", sep=""))
            n.desired <- design[[s]]$caty.n + ceiling(over.n)
         }
      }

# Calculate mdm - inclusion probabilities

      if(design[[s]]$seltype == "Equal")
         sframe$mdm <- mdmlin(sframe$len, sframe$mdcaty, c(Equal=n.desired))
      else if(design[[s]]$seltype == "Unequal")
         sframe$mdm <- mdmlin(sframe$len, sframe$mdcaty, n.desired)
      else
         sframe$mdm <- n.desired * sframe$mdcaty /
                       sum(sframe$len * sframe$mdcaty)

# Select the sample

      stmp <- grtslin(in.shape, sframe, sum(n.desired), SiteBegin, shift.grid,
         startlev, maxlev)

# Add the stratum variable

      stmp$stratum <- as.factor(rep(s,nrow(stmp)))

# Add panel and oversample structure

      stmp$panel <- rep("OverSamp",nrow(stmp))
      np <- c(0,cumsum(design[[s]]$panel))
      for(i in 1:length(design[[s]]$panel))
         stmp$panel[(np[i]+1):np[i+1]] <- names(design[[s]]$panel[i])

# If an oversample is present, then adjust the weights

      if(design[[s]]$over > 0) {
         if(design[[s]]$seltype != "Unequal") {
            stmp$wgt <- n.desired * stmp$wgt / samplesize
         } else {
            nc <- design[[s]]$caty.n
            for(i in names(n.desired)) {
               stmp$wgt[stmp$mdcaty == i] <- n.desired[i] *
                  stmp$wgt[stmp$mdcaty == i] / nc[i]
            }
         }
      }

# Add stratum sample to the output data frame

      if(first) {
         sites <- stmp
         levels(sites$stratum) <- strata.names
         first <- FALSE
      } else {
         sites <- rbind(sites, stmp)
      }
      SiteBegin <- SiteBegin + nrow(stmp)

# End the loop for strata

   }

# End the section for a linear network

} else if(type.frame == "area") {

# Begin the section for a polygonal area

   first <- TRUE
   SiteBegin <- SiteBegin

# Ensure that att.frame includes a variable named area_mdm that provides the
# area for each record of the shapefile(s) in the working directory and create
# the variable when necessary

   if(is.null(att.frame$area_mdm)) {
      temp <- .Call("getRecordShapeSizes", in.shape)
      if(length(temp) != nrow(att.frame))
         stop("\nThe number of rows in the attribute data frame does not equal the number of \nrecords in the shapefile(s) in the working directory.")
      att.frame$area_mdm <- temp
   }
   elmsize <- "area_mdm"

# Begin the loop for strata

   for(s in strata.names) {

      cat(paste("\nStratum:", s, "\n"))

# Create the sample frame

      temp <- att.frame[,stratum] == s
      if(sum(temp) == 0) {
         warning(paste("\nThe stratum column in the attributes data frame contains no values that match \nthe stratum named \"", s, "\" in the design list.\n", sep=""))
         next
      }

      if(design[[s]]$seltype == "Equal") {
         sframe <- data.frame(id=att.frame[temp, id],
            mdcaty=rep("Equal", nrow(att.frame[temp,])),
            area=att.frame[temp, elmsize])
      } else if(design[[s]]$seltype == "Unequal") {
         sframe <- data.frame(id=att.frame[temp, id],
            mdcaty=factor(att.frame[temp, mdcaty]),
            area=att.frame[temp, elmsize])
      } else if(design[[s]]$seltype == "Continuous") {
         sframe <- data.frame(id=att.frame[temp, id],
            mdcaty=att.frame[temp, mdcaty],
            area=att.frame[temp, elmsize])
      } else {
         stop(paste("\nThe value provided for the type of random selection, \"", design[[s]]$seltype, "\", \nfor stratum \"", s, "\" is not valid.", sep=""))
      }

# If seltype is not "Equal", ensure that mdcaty contains valid values 

      if(design[[s]]$seltype == "Unequal") {
         if(any(is.na(sframe$mdcaty)))
            stop(paste("\nMissing values were detected among the unequal probability category values for \nstratum \"", s, "\".", sep=""))
      } else if(design[[s]]$seltype == "Continuous") {
         if(any(is.na(sframe$mdcaty)))
            stop(paste("\nMissing values were detected among the unequal probability category values for \nstratum \"", s, "\".", sep=""))
         if(!is.numeric(sframe$mdcaty))
            stop(paste("\nThe type of random selection for stratum \"", s, "\" is \"Continuous\", \nbut the unequal probability category values are not numeric.", sep=""))
         if(any(sframe$mdcaty < 0))
            stop(paste("\nNonpositive values were detected among the unequal probability category values \nfor stratum \"", s, "\".", sep=""))
      }

# If seltype is "Unequal", ensure that caty.n is provided and that the names
# in caty.n and the levels of mdcaty are equivalent

      if(design[[s]]$seltype == "Unequal") {
         if(is.null(design[[s]]$caty.n))
            stop(paste("The type of random selection was set to \"Unequal\", but caty.n was not \nprovided for stratum \"", s, "\".", sep=""))
         temp <- match(names(design[[s]]$caty.n),
            levels(as.factor(sframe$mdcaty)), nomatch=0)
         if(any(temp == 0)) {
            temp.str <- vecprint(names(design[[s]]$caty.n)[temp == 0])
            stop(paste("\nThe following names in caty.n for stratum \"", s, "\" do not occur \namong the levels of the mdcaty variable in att.frame:\n", temp.str, sep=""))
         }
      }

# Ensure that panel and caty.n contain valid values

      if(!is.numeric(design[[s]]$panel))
         stop(paste(" The design list must contain numeric values in the panel argument for \nstratum \"", s, "\".\n", sep=""))
      design[[s]]$panel <- round(design[[s]]$panel)
      design[[s]]$panel <- design[[s]]$panel[design[[s]]$panel > 0]
      if(length(design[[s]]$panel) == 0)
         stop(paste(" The design list does not not contain any valid values of the panel \nargument for stratum \"", s, "\".\n", sep=""))

      if(design[[s]]$seltype == "Unequal") {
         if(!is.numeric(design[[s]]$caty.n))
            stop(paste(" The design list must contain numeric values in the caty.n argument for \nstratum \"", s, "\".\n", sep=""))
         design[[s]]$caty.n <- round(design[[s]]$caty.n)
         design[[s]]$caty.n <- design[[s]]$caty.n[design[[s]]$caty.n > 0]
         if(length(design[[s]]$caty.n) == 0)
            stop(paste(" The design list does not not contain any valid values of the caty.n \nargument for stratum \"", s, "\".\n", sep=""))
      }

# As necessary, remove rows from sframe that have values of mdcaty which are not
# included among the names in caty.n

      if(design[[s]]$seltype == "Unequal") {
         temp <- sframe$mdcaty %in% names(design[[s]]$caty.n)
         if(any(!temp)) {
            sframe <- sframe[temp,]
         }
      }

# Determine overall sample size for the stratum

      if(is.null(design[[s]]$over))
         design[[s]]$over <- 0
      if(design[[s]]$seltype != "Unequal") {
         samplesize <- sum(design[[s]]$panel)
         n.desired <- sum(samplesize, design[[s]]$over)
      } else {
         if(sum(design[[s]]$panel) != sum(design[[s]]$caty.n))
            stop("\nThe sum of panel sample sizes does not equal sum of caty.n sample sizes")
         samplesize <- sum(design[[s]]$caty.n)
         if(design[[s]]$over == 0) {
            n.desired <- design[[s]]$caty.n
         } else {
            over.n <- design[[s]]$over * design[[s]]$caty.n /
               sum(design[[s]]$caty.n)
            if(any(over.n != floor(over.n))) 
               warning(paste("\nOversample size is not proportional to category sample sizes for stratum\n\"", s, "\".\n", sep=""))
            n.desired <- design[[s]]$caty.n + ceiling(over.n)
         }
      }

# Calculate mdm - inclusion probabilities

      if(design[[s]]$seltype == "Equal") 
         sframe$mdm <- mdmarea(sframe$area, sframe$mdcaty, c(Equal=n.desired))
      else if(design[[s]]$seltype == "Unequal") 
         sframe$mdm <- mdmarea(sframe$area, sframe$mdcaty, n.desired)
      else
         sframe$mdm <- n.desired * sframe$mdcaty /
                       sum(sframe$area * sframe$mdcaty)

# Select the sample

      stmp <- grtsarea(in.shape, sframe, sum(n.desired), SiteBegin, shift.grid,
         startlev, maxlev, maxtry)

# Determine whether the realized sample size is less than the desired size

      if(nrow(stmp) < sum(n.desired))
         warning(paste("\nThe size of the selected sample was less than the desired size for stratum \n\"", s, "\".\n", sep=""))

# Add the stratum variable

      stmp$stratum <- as.factor(rep(s, nrow(stmp)))

# Add panel and oversample structure

      stmp$panel <- as.character(rep("OverSamp",nrow(stmp)))
      n.panel <- length(design[[s]]$panel)
      if(nrow(stmp) < samplesize) {
         n.short <- samplesize - nrow(stmp)
         n.temp <- n.short / n.panel
         if(n.temp != floor(n.temp)) {
            n.temp <- c(ceiling(n.temp), rep(floor(n.temp), n.panel-1))
            i <- 1
            while(sum(n.temp) != n.short) {
               i <- i+1
               ntemp[i] <- n.temp[i] + 1
            }
         }
         np <- c(0, cumsum(design[[s]]$panel - n.temp))
      } else {
         np <- c(0, cumsum(design[[s]]$panel))
      }
      for(i in 1:n.panel)
         stmp$panel[(np[i]+1):np[i+1]] <- names(design[[s]]$panel[i])

# If an oversample is present or the realized sample size is less than the
# desired size, then adjust the weights

      if(design[[s]]$over > 0 || nrow(stmp) < samplesize) {
         if(design[[s]]$seltype != "Unequal") {
            if(nrow(stmp) < samplesize) {
               stmp$wgt <- n.desired * stmp$wgt / nrow(stmp)
            } else {
               stmp$wgt <- n.desired * stmp$wgt / samplesize
            }
         } else {
            if(nrow(stmp) < samplesize) {
               n.caty <- length(design[[s]]$caty.n)
               n.temp <- n.short / n.caty
               nc <- design[[s]]$caty.n - n.temp
            } else {
               nc <- design[[s]]$caty.n
            }
            for(i in names(n.desired)) {
               stmp$wgt[stmp$mdcaty == i] <- n.desired[i] *
                  stmp$wgt[stmp$mdcaty == i] / nc[i]
            }
         }
      }

# Add stratum sample to the output data frame

      if(first) {
         sites <- stmp
         levels(sites$stratum) <- strata.names
         first <- FALSE
      } else {
         sites <- rbind(sites, stmp)
      }
      SiteBegin <- SiteBegin + nrow(stmp)

# End the loop for strata

   }

# End the section for a polygonal area

} else {

   stop(paste("\nThe value provided for the type of frame, \"", type.frame, "\", is not valid.", sep=""))

}

# If src.frame equals "sp.object", then remove the temporary shapefile

if(sp.ind) {
   file.remove(paste(in.shape, ".dbf", sep=""), paste(in.shape, ".shp", sep=""), paste(in.shape, ".shx", sep=""))
}

# Add DesignID name to the numeric siteID value to create a new siteID

sites$siteID <- as.character(gsub(" ","0", paste(DesignID,"-",
   format(sites$siteID), sep="")))

# Add Evaluation Status and Evaluation Reason variables to the output data frame

sites$EvalStatus <- rep("NotEval", nrow(sites))
sites$EvalReason <- rep(" ", nrow(sites))

# Add variables from the attributes data frame that are not contained in the
# output data frame

tm <- match(sites$id, att.frame[,id])
if(design[[s]]$seltype == "Equal")
   td <- match(c(id, stratum), names(att.frame))
else
   td <- match(c(id, stratum, mdcaty), names(att.frame))
temp <- names(att.frame)[-td]
if(length(temp) > 0) {
   sites <- cbind(sites, att.frame[tm,-td])
   if(length(temp) == 1)
      names(sites)[ncol(sites)] <- temp
}

# Remove id from the output data frame

sites <- sites[,-match("id", names(sites))]

# If type.frame equals "finite" and src.frame equals "shapefile", then remove x
# and y from the output data frame

if(type.frame == "finite" && src.frame == "shapefile")
   sites <- sites[,-match(c("x", "y"), names(sites))]

# If src.frame equals "shapefile" and type.frame is either "linear" or "area",
# then remove either length_mdm or area_mdm from the output data frame, as
# appropriate

if(src.frame == "shapefile") {
   if(type.frame == "linear")
      sites <- sites[,-match("length_mdm", names(sites))]
   else if(type.frame == "area")
      sites <- sites[,-match("area_mdm", names(sites))]
}

# Add row names to the output data frame

n <- nrow(sites)
IDs <- as.character(1:n)
row.names(sites) <- IDs

# Assign attributes to the output data frame

attr(sites, "design") <- design
ifelse(is.null(startlev),
   attr(sites, "startlev") <- "Not specified",
   attr(sites, "startlev") <- startlev)
ifelse(is.null(maxlev),
   attr(sites, "maxlev") <- "Not specified",
   attr(sites, "maxlev") <- maxlev)
attr(sites, "endlev") <- attributes(stmp)$nlev
attr(sites, "maxtry") <- maxtry
attr(sites, "shift.grid") <- shift.grid
attr(sites, "do.sample") <- do.sample

# Create an sp package object

SpointsMat <- matrix(0, nrow=n, ncol=2)
rownames(SpointsMat) <- IDs
SpointsMat[,1] <- sites[,2]
SpointsMat[,2] <- sites[,3]
sp.obj <- SpatialPointsDataFrame(SpatialPoints(SpointsMat), data=sites)

# Create a shapefile containing the sample information

if(shapefile == TRUE) {
   temp <- sapply(sites, is.factor)
   if(any(temp)) {
      sites.tmp <- sites
      for(i in seq(ncol(sites.tmp))[temp]) {
         sites.tmp[,i] <- as.character(sites.tmp[,i])
         temp <- sites.tmp[,i] == "" | is.na(sites.tmp[,i])
         if(any(temp)) {
            sites.tmp[temp,i] <- " "
         }
      }
      .Call("writeShapeFilePoint", sites.tmp$xcoord, sites.tmp$ycoord,
         prjfilename, names(sites.tmp), sites.tmp, out.shape)
   } else {
      .Call("writeShapeFilePoint", sites$xcoord, sites$ycoord, prjfilename,
         names(sites), sites, out.shape)
   }
}

# Return the sp package object

invisible(sp.obj)
}
