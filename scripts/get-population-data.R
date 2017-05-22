#------------------------------------------------------------------------------*
# Get necessary population data
#------------------------------------------------------------------------------*
# Get populaton data used in the analyses from the online repository at
# https://github.com/odeleongt/gt-population
#------------------------------------------------------------------------------*
# SOURCE
# This population estimates are derived from the following official data:
# - Population estimates for each municipality for 2010-2015.
#   + Data provided directly by National Statistics Institute (INE), not
#    publicly hosted by INE but available upon request.
#   + Estimates for simple years of age
# - Official births and deaths data
#   + Data publicly available from INE:
#     https://www.ine.gob.gt/index.php/estadisticas-continuas/vitales2
#   + Data used to confirm uniform distribution of population alive by month
#     of age for age groups <1 year
#------------------------------------------------------------------------------*


#------------------------------------------------------------------------------*
# Load data from published snapshot ----
#------------------------------------------------------------------------------*

# Define file parameters
base_uri <- "https://github.com/odeleongt/gt-population/releases/download"
current_tag <- "v0.2.0"
snapshot_file <- "flu_edinburgh_population.csv"

# Read file directly from online repository
population <- read_csv(
  file = paste(base_uri, current_tag, snapshot_file, sep = "/")
)

# Extract age groups from ddata
labels_age_groups <- c(
  "0-27 days", "28 days-<3 month", "3-5 months", "6-8 months", "9-11 months",
  "0-11 months",
  "12-23 months", "24-35 months", "36-59 months",
  "12-59 months", "24-59 months", "0-59 months"
)




# End of script
