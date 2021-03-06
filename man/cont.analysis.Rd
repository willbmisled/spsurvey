\name{cont.analysis}
\alias{cont.analysis}
\title{Continuous Data  Analysis for Probability Survey Data}
\description{
  This function organizes input and output for analysis of continuous data 
  generated by a probability survey.  Input can be either an object belonging to
  class spsurvey.analysis (see the documentation for function spsurvey.analysis)
  or through use of the other arguments to this function.
}
\usage{
cont.analysis(sites=NULL, subpop=NULL, design=NULL, data.cont=NULL, sigma=NULL,
   var.sigma=NULL, popsize=NULL, popcorrect=FALSE, pcfsize=NULL, N.cluster=NULL,
   stage1size=NULL, sizeweight=FALSE, total=FALSE, vartype="Local", conf=95,
   pctval=c(5,10,25,50,75,90,95), spsurvey.obj=NULL)
}
\arguments{
  \item{sites}{a data frame consisting of two variables: the first variable is 
    site IDs, and the second variable is a logical vector indicating which
    sites to use in the analysis.  If spsurvey.obj is not provided, then
    this argument is required.  The default is NULL.}
  \item{subpop}{a data frame describing sets of populations and subpopulations 
    for which estimates will be calculated.  The first variable is site  
    IDs.  Each subsequent variable identifies a Type of population, where
    the variable name is used to identify Type.  A Type variable
    identifies each site with one of the subpopulations of that Type.  If
    spsurvey.obj is not provided, then this argument is required.  The
    default is NULL.}
  \item{design}{a data frame consisting of design variables.  If spsurvey.obj is
    not provided, then this argument is required.  The default is NULL.
    Variables should be named as follows:\cr
       siteID = site IDs\cr
       wgt = final adjusted weights, which are either the weights for a
         single-stage sample or the stage two weights for a two-stage sample\cr
       xcoord = x-coordinates for location, which are either the x-coordinates
         for a single-stage sample or the stage two x-coordinates for a
         two-stage sample\cr
       ycoord = y-coordinates for location, which are either the y-coordinates
         for a single-stage sample or the stage two y-coordinates for a
         two-stage sample\cr
       stratum = the stratum codes\cr
       cluster = the stage one sampling unit (primary sampling unit or cluster)
         codes\cr
       wgt1 = final adjusted stage one weights\cr
       xcoord1 = the stage one x-coordinates for location\cr
       ycoord1 = the stage one y-coordinates for location\cr
       support = support values - the value one (1) for a site from a 
         finite resource or the measure of the sampling unit associated 
         with a site from an extensive resource, which is required for 
         calculation of finite and continuous population correction 
         factors\cr
       swgt = size-weights, which is the stage two size-weight for a two-
         stage sample\cr
       swgt1 = stage one size-weights}
  \item{data.cont}{a data frame of continuous response variables.  The first 
    variable is site IDs.  Subsequent variables are response variables.
    Missing data (NA) is allowed.  If spsurvey.obj is not provided, then
    this argument is required.  The default is NULL.}
  \item{sigma}{measurement error variance.  This variable must be a vector
    containing a value for each response variable and must have the names
    attribute set to identify the response variable names.  Missing data (NA)
    is allowed.  The default is NULL.}
  \item{var.sigma}{variance of the measurement error variance.  This variable
    must be a vector containing a value for each response variable and must have
    the names attribute set to identify the response variable names.  Missing
    data (NA) is allowed.  The default is NULL.}
  \item{popsize}{known size of the resource, which is used to perform ratio
    adjustment to estimators expressed using measurement units for the
    resource and to calculate strata proportions for calculating estimates for
    a stratified sample.  For a finite resource, this argument is either the
    total number of sampling units or the known sum of size-weights.  For an
    extensive resource, this argument is the measure of the resource, i.e.,
    either known total length for a linear resource or known total area for an
    areal resource.  The argument must be in the form of a list containing an
    element for each population Type in the subpop data frame, where NULL is a
    valid choice for a population Type.  The list must be named using the
    column names for the population Types in subpop. If a population Type
    doesn't contain subpopulations, then each element of the list is either a
    single value for an unstratified sample or a vector containing a value for
    each stratum for a stratified sample, where elements of the vector are
    named using the stratum codes.  If a population Type contains
    subpopulations, then each element of the list is a list containing an
    element for each subpopulation, where the list is named using the
    subpopulation names.  The element for each subpopulation will be either a
    single value for an unstratified sample or a named vector of values for a
    stratified sample.  The default is NULL.\cr\cr
    Example popsize for a stratified sample:\cr
      popsize = list("Pop 1"=c("Stratum 1"=750,\cr
                               "Stratum 2"=500,\cr
                               "Stratum 3"=250),\cr
                     "Pop 2"=list("SubPop 1"=c("Stratum 1"=350,\cr
                                               "Stratum 2"=250,\cr
                                               "Stratum 3"=150),\cr
                                  "SubPop 2"=c("Stratum 1"=250,\cr
                                               "Stratum 2"=150,\cr
                                               "Stratum 3"=100),\cr
                                  "SubPop 3"=c("Stratum 1"=150,\cr
                                               "Stratum 2"=150,\cr
                                               "Stratum 3"=75)),\cr
                     "Pop 3"=NULL)\cr\cr
    Example popsize for an unstratified sample:\cr
      popsize = list("Pop 1"=1500,\cr
                     "Pop 2"=list("SubPop 1"=750,\cr
                                  "SubPop 2"=500,\cr
                                  "SubPop 3"=375),\cr
                     "Pop 3"=NULL)\cr}
  \item{popcorrect}{a logical value that indicates whether finite or continuous 
    population correction factors should be employed during variance 
    estimation, where TRUE = use the correction factors and FALSE = do not 
    use the correction factors.  The default is FALSE.}
  \item{pcfsize}{size of the resource, which is required for calculation of
    finite and continuous population correction factors for a single-stage
    sample.  For a stratified sample this argument must be a vector containing a
    value for each stratum and must have the names attribute set to identify the
    stratum codes.  The default is NULL.}
  \item{N.cluster}{the number of stage one sampling units in the resource, which 
    is required for calculation of finite and continuous population 
    correction factors for a two-stage sample.  For a stratified sample 
    this variable must be a vector containing a value for each stratum and
    must have the names attribute set to identify the stratum codes.  The
    default is NULL.}
  \item{stage1size}{size of the stage one sampling units of a two-stage sample,
    which is required for calculation of finite and continuous population
    correction factors for a two-stage sample and must have the names
    attribute set to identify the stage one sampling unit codes.  For a
    stratified sample, the names attribute must be set to identify both
    stratum codes and stage one sampling unit codes using a convention where
    the two codes are separated by the & symbol, e.g., "Stratum 1&Cluster 1".
    The default is NULL.}
  \item{sizeweight}{a logical value that indicates whether size-weights should 
    be used in the analysis, where TRUE = use the size-weights and FALSE = 
    do not use the size-weights.  The default is FALSE.}
  \item{total}{a logical value that indicates whether the population total estimate
    should be included in the output Pct data frame, where TRUE = include the
    total estimate and FALSE = do not include the estimate.  The default is FALSE.}
  \item{vartype}{the choice of variance estimator, where "Local" = local mean
    estimator and "SRS" = SRS estimator.  The default is "Local".}
  \item{conf}{the confidence level.  The default is 95\%.}
  \item{pctval}{the set of values at which percentiles are estimated.  The
    default set is: \{5, 10, 25, 50, 75, 90, 95\}.}
  \item{spsurvey.obj}{A list of class spsurvey.analysis that was produced by the
    function spsurvey.analysis.  Depending on input to that function,
    some elements of the list may be NULL.  The default is NULL.}
}
\details{
  CDF estimates are calculated for all unique values of a response variable.
}
\section{Value}{
  Value is a list containing either two or four data frames of population
  estimates for all combinations of population Types, subpopulations within
  Types, and response variables.  The data frames containing deconvoluted CDF
  estimates and deconvoluted percentile estimates are only included in the
  output list when an input value for measurement error variance is provided to
  the function.  CDF estimates are calculated for both proportion and size of
  the population.  Standard error estimates and confidence interval estimates
  also are calculated.  The four data frames are:
  \itemize{
    \item \code{CDF} - a data frame containing the CDF estimates
    \item \code{Pct} - a data frame containing the percentile estimates plus
      population mean, standard deviation, and variance estimates
    \item \code{CDF.D} - a data frame containing the deconvoluted CDF estimates
    \item \code{Pct.D} - a data frame containing the deconvoluted percentile
      estimates
  }
}
\references{
  Diaz-Ramos, S., D.L. Stevens, Jr., and A.R. Olsen. (1996).  \emph{EMAP
  Statistical Methods Manual.} EPA/620/R-96/XXX.  Corvallis, OR: U.S.
  Environmental Protection Agency, Office of Research and Development, National
  Health Effects and Environmental Research Laboratory, Western Ecology
  Division.
}
\author{
Tony Olsen \email{Olsen.Tony@epa.gov}\cr
Tom Kincaid \email{Kincaid.Tom@epa.gov}
}
\seealso{
\code{\link{cdf.est}, \link{total.est}} 
}
\examples{
# Continuous variable example:
mysiteID <- paste("Site", 1:100, sep="")
mysites <- data.frame(siteID=mysiteID, Active=rep(TRUE, 100))
mysubpop <- data.frame(siteID=mysiteID, All.Sites=rep("All Sites",100),
   Resource.Class=rep(c("Good","Poor"), c(55,45)))
mydesign <- data.frame(siteID=mysiteID, wgt=runif(100, 10, 100),
   xcoord=runif(100), ycoord=runif(100), stratum=rep(c("Stratum1",
   "Stratum2"), 50))
ContVar <- rnorm(100, 10, 1)
mydata.cont <- data.frame(siteID=mysiteID, ContVar=ContVar)
mypopsize <- list(All.Sites=c(Stratum1=3500, Stratum2=2000),
   Resource.Class=list(Good=c(Stratum1=2500, Stratum2=1500),
   Poor=c(Stratum1=1000, Stratum2=500)))
cont.analysis(sites=mysites, subpop=mysubpop, design=mydesign,
   data.cont=mydata.cont, popsize=mypopsize)

# Include deconvolution estimates:
mydata.cont <- data.frame(siteID=mysiteID, ContVar=ContVar,
   ContVar.1=ContVar + rnorm(100, 0, sqrt(0.25)),
   ContVar.2=ContVar + rnorm(100, 0, sqrt(0.50)))
mysigma <- c(NA, 0.25, 0.50)
names(mysigma) <- c("ContVar", "ContVar.1", "ContVar.2")
cont.analysis(sites=mysites, subpop=mysubpop[,1:2], design=mydesign,
   data.cont=mydata.cont, sigma=mysigma, popsize=mypopsize[1])
}
\keyword{survey}
\keyword{distribution}
\keyword{univar}
