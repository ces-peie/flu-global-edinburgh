#------------------------------------------------------------------------------*
# Get necessary data from server
#------------------------------------------------------------------------------*
# Get data used in the analyses from the VICo sql-server
# A snapshot of the data is saved for convenience, but it should be removed
# before preparing the draft tables and report to share with the collaboration.
#------------------------------------------------------------------------------*




#------------------------------------------------------------------------------*
# Prepare analysis environment ----
#------------------------------------------------------------------------------*

# Load used packages
library(package = "tidyverse")


#------------------------------------------------------------------------------*
# Load data ----
#------------------------------------------------------------------------------*

# Define dataset metadata (snapshot file name, period, sites, etc.)
snapshot_file <- "data/snapshots/vico-server.RData"


# Check if a snapshot is available, otherwise get from server
if(!file.exists(snapshot_file)){
  # Load used packages
  library(package = "DBI")
  
  
  # Build IS NOT NULL conditions
  is_not_null <- function(variables){
    paste(paste(variables, "IS NOT NULL", sep = " "), collapse = " OR ")
  }
  
  
  # Define variables
  variables <- c(
    # Case identifiers
    "SubjectID", "SASubjectID",
    # Case metadata
    "PDAInsertDate", "fechaHoraAdmision", "epiYearAdmision", "epiWeekAdmision",
    "SiteName", "SiteType",
    "NombreDepartamento", "NombreMunicipio", "catchment",
    "departamento", "municipio",
    "actualAdmitido", "seguimientoAdmitidoHospital",
    "elegibleRespira", "pacienteInscritoVico",
    # Patient information
    "edadAnios", "edadMeses", "edadDias", "fechaDeNacimiento",
    # Case definition -- cough
    "sintomasRespiraTos", "sintomasRespiraTosDias",
    # Case definition -- difficulty breathing
    "sintomasRespiraDificultadRespirar", "sintomasRespiraDificultadDias",
    # Case definition -- respiratory rate
    "medidaRespiraPorMinutoPrimeras24Horas", "respiraPorMinutoPrimaras24Horas", 
    "medidaRespiraPorMinuto", "respiraPorMinuto",
    # Case definition -- physician diagnosis
    "egresoDiagnostico1",  "egresoDiagnostico1_esp",
    "egresoDiagnostico2", "egresoDiagnostico2_esp",
    # Case definition -- chest wall indrawing
    "sintomasRespiraNinioCostillasHundidas",
    "respiraExamenFisicoMedicoTirajePecho",
    # Case definition -- danger signs -- cyanosis
    "historiaCianosis", "ninioCianosisObs",
    # Case definition -- danger signs -- difficulty in breastfeeding or drinking
    "ninioBeberMamar",
    # Case definition -- danger signs -- vomiting everything
    "ninioVomitaTodo",
    # Case definition -- danger signs -- convulsions
    "ninioTuvoConvulsiones", "ninioTuvoConvulsionesObs",
    # Case definition -- danger signs -- lethargy
    "ninioTieneLetargiaObs",
    # Case definition -- danger signs -- unconsciousness
    "ninioDesmayoObs",
    # Case definition -- danger signs -- head nodding
    "ninioCabeceoObs",
    # Proxies for severe disease -- ICU
    "cuidadoIntensivoDias",
    # Proxies for severe disease -- oximetry
    "medirOximetroPulso", 
    "oximetroPulso", "oximetroPulso_Lag", "oxiAmb",
    "oximetroPulsoFechaHoraToma_Esti",  "medirOximetroPulsoSinOxi",
    "oxigenoSuplementario", "oxigenoSuplementarioCuanto", 
    "oximetroPulsoNoRazon", "oximetroPulsoNoRazon_esp",
    "oximetroPulsoSinOxiNoRazon",  "oximetroPulsoSinOxiNoRazon_esp",
    "OximetroPulsoSinOxi", "hipoxemia",
    # Proxies for severe disease -- mechanical ventilation
    "ventilacionMecanicaCuanto", "ventilacionMecanicaDias", "ventilacionMecanica",
    # Comorbidities
    "enfermedadesCronicasAlguna",
    "enfermedadesCronicasAsma", "enfermedadesCronicasDiabetes",
    "enfermedadesCronicasCancer", "enfermedadesCronicasEnfermCorazon",
    "enfermedadesCronicasDerrame", "enfermedadesCronicasEnfermHigado",
    "enfermedadesCronicasEnfermRinion", "enfermedadesCronicasEnfermPulmones",
    "enfermedadesCronicasVIHSIDA", "enfermedadesCronicasHipertension",
    "enfermedadesCronicasOtras", "enfermedadesCronicasNacimientoPrematuro",
    # Death
    "muerteViCo", "muerteViCoFecha", "muerteSospechoso",
    "muerteSospechosoFecha",  "muerteHospital", "muerteCualPaso",
    "egresoMuerteFecha", "egresoTipo", "egresoCondicion",
    "seguimientoPacienteMuerteFecha",
    # Lab information
    "viralPCR_Hizo", "viralPCR_FluA", "viralPCR_FluB",
    "viralPCR_FluAH1", "viralPCR_FluAH3",
    "viralPCR_FluAH5a", "viralPCR_FluAH5b",
    "viralPCR_FluASwA", "viralPCR_FluASwH1", "viralPCR_pdmH1", "viralPCR_pdmInFA"
  )
  
  # Define conditions
  conditions <- c(
    # Date available
    is_not_null(
      c("PDAInsertDate", "fechaHoraAdmision", "epiYearAdmision", "epiWeekAdmision")
    ),
    # Age available
    is_not_null(c("edadAnios", "edadMeses", "edadDias", "fechaDeNacimiento"))
  )
  
  # Connect to server
  data_base <- dbConnect(
    odbc::odbc(), "PEIEServer",
    uid = scan("data/user", what = "character"),
    pwd = scan("data/password", what = "character")
  )
  
  # Get cases data from server
  all_respi <- dbGetQuery(
    conn = data_base,
    statement = paste(
      "SELECT", paste(variables, collapse = ", "),
      "FROM Clinicos.Basica_Respira",
      "WHERE", paste0("(", paste(conditions, collapse = ") AND ("), ")")
    )
  )
  
  # Fix truncated variable names and save as tibble
  all_respi <- all_respi %>% set_names(variables) %>% as_tibble()
  
  
  
  # Get sites data from server
  all_sites <- dbGetQuery(
    conn = data_base,
    statement = "SELECT * FROM Control.Sitios"
  )
  
  # Save as tibble
  all_sites <- as_tibble(all_sites)
  
  
  # Disconnect from server
  dbDisconnect(data_base)
  
  # Save snapshot
  save(all_respi, all_sites, file = snapshot_file)
} else {
  # Load available snapshot 
  load(file = snapshot_file)
}


#------------------------------------------------------------------------------*
# Pre process data ----
#------------------------------------------------------------------------------*

# Standardize variable names


# Filter data to keep only necessary cases



#------------------------------------------------------------------------------*
# Save pre processed data ----
#------------------------------------------------------------------------------*




# End of script
