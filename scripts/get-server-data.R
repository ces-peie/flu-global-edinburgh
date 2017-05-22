#------------------------------------------------------------------------------*
# Get necessary data from server
#------------------------------------------------------------------------------*
# Get data used in the analyses from the VICo sql-server
# A snapshot of the data is saved for convenience, but it should be removed
# before preparing the draft tables and report to share with the collaboration.
#------------------------------------------------------------------------------*




#------------------------------------------------------------------------------*
# Load data ----
#------------------------------------------------------------------------------*

# Define dataset metadata (snapshot file name, period, sites, etc.)
snapshots_path <- "data/snapshots/"
snapshot_file <- paste0(snapshots_path, "vico-server.RData")


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
    "SiteName", "SiteType", "SiteDepartamento",
    "NombreDepartamento", "NombreMunicipio", "catchment",
    "actualAdmitido", "elegibleRespira", "pacienteInscritoVico",
    # Patient information
    "edadAnios", "edadMeses", "edadDias", "fechaDeNacimiento",
    # Case definition -- physician diagnoses
    "presentaIndicacionRespira", "indicacionRespira", "indicacionRespira_otra",
    # Case definition -- cough
    "sintomasRespiraTos",
    # Case definition -- difficulty breathing
    "sintomasRespiraDificultadRespirar",
    # Case definition -- respiratory rate
    "respiraPorMinutoPrimaras24Horas", 
    "respiraPorMinuto",
    # Case definition -- physician diagnosis
    "egresoDiagnostico1",  "egresoDiagnostico1_esp",
    "egresoDiagnostico2", "egresoDiagnostico2_esp",
    # Case definition -- chest wall indrawing
    "sintomasRespiraNinioCostillasHundidas",
    "respiraExamenFisicoMedicoTirajePecho",
    # Case definition -- danger signs -- cyanosis
    "ninioCianosisObs",
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
    "oximetroPulso",
    "oxigenoSuplementario",
    "OximetroPulsoSinOxi", "hipoxemia",
    # Proxies for severe disease -- mechanical ventilation
    "ventilacionMecanica", "ventilacionMecanicaDias",
    # Comorbidities
    "enfermedadesCronicasAlguna",
    "enfermedadesCronicasAsma", "enfermedadesCronicasDiabetes",
    "enfermedadesCronicasCancer", "enfermedadesCronicasEnfermCorazon",
    "enfermedadesCronicasDerrame", "enfermedadesCronicasEnfermHigado",
    "enfermedadesCronicasEnfermRinion", "enfermedadesCronicasEnfermPulmones",
    "enfermedadesCronicasVIHSIDA", "enfermedadesCronicasHipertension",
    "enfermedadesCronicasNacimientoPrematuro",
    "enfermedadesCronicasInfoAdicional",
    # Death
    "muerteViCo", "muerteSospechoso",
    "muerteHospital", "muerteCualPaso",
    "egresoTipo", "egresoCondicion",
    "seguimientoFechaReporte", "seguimientoPacienteCondicion",
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
  
  
  # Get respiratory indications labels
  labels_respi <- dbGetQuery(
    conn = data_base,
    statement = paste(
      "SELECT * FROM LegalValue.LV_INDICRESPIRA"
    )
  ) %>%
    set_names(tolower(names(.))) %>%
    as_tibble()
  
  
  
  # Get sites data from server
  all_sites <- dbGetQuery(
    conn = data_base,
    statement = "SELECT * FROM Control.Sitios"
  )
  
  # Save as tibble
  all_sites <- as_tibble(all_sites)
  
  
  # Get catchment areas
  catchment <- dbGetQuery(
    conn = data_base,
    statement = paste(
      "SELECT",
      paste(
        "DepartamentoNombre AS department",
        "MunicipioNombre AS municipality",
        "CASE HUSarea WHEN 1 THEN 1 WHEN 2 THEN 0 END AS catchment",
        sep = ", "
      ),
      "FROM INE.Censo2002.Poblacion",
      "WHERE DepartamentoID IN (6, 9)",
      "GROUP BY DepartamentoNombre, DepartamentoID, MunicipioNombre, MunicipioID, HUSarea",
      "ORDER BY DepartamentoID, MunicipioID"
    )
  )
  
  catchment <- as_tibble(catchment)
  
  
  # Disconnect from server
  dbDisconnect(data_base)
  
  # Save snapshot
  save(all_respi, labels_respi, all_sites, catchment, file = snapshot_file)
} else {
  # Load available snapshot 
  load(file = snapshot_file)
}


#------------------------------------------------------------------------------*
# Pre process data ----
#------------------------------------------------------------------------------*

#------------------------------------------------------------------------------*
# Standardize variable names
#------------------------------------------------------------------------------*
# Conventions:
#   obs: observed / measured by the surveillance nurse
# chart: read from the chart
#  hist: reported by interviewee
#------------------------------------------------------------------------------*
all_respi <- all_respi %>%
  select(
    site_name = SiteName, site_type = SiteType,
    site_department = SiteDepartamento,
    year = epiYearAdmision, week = epiWeekAdmision,
    record_id = SubjectID, record_date = PDAInsertDate,
    case_id = SASubjectID, case_date = fechaHoraAdmision,
    case_department = NombreDepartamento, case_municipality = NombreMunicipio,
    case_in_catchment = catchment,
    hospitalized = actualAdmitido,
    eligible = elegibleRespira, enrolled = pacienteInscritoVico,
    age_years = edadAnios, age_months = edadMeses, age_days = edadDias,
    birth_date = fechaDeNacimiento,
    # Symptoms
    has_respiratory_indications = presentaIndicacionRespira,
    respiratory_indications = indicacionRespira,
    respiratory_indications_other = indicacionRespira_otra,
    cough = sintomasRespiraTos,
    difficulty_breathing = sintomasRespiraDificultadRespirar,
    respiratory_rate_chart = respiraPorMinutoPrimaras24Horas,
    respiratory_rate_obs = respiraPorMinuto,
    chest_wall_indrawing_chart = respiraExamenFisicoMedicoTirajePecho,
    chest_wall_indrawing_obs = sintomasRespiraNinioCostillasHundidas,
    hypoxemia_obs = hipoxemia,
    blood_oxigen_sat = oximetroPulso,
    blood_oxigen_no_supp = OximetroPulsoSinOxi,
    # Danger signs
    cyanosis_obs = ninioCianosisObs,
    difficulty_feeding = ninioBeberMamar,
    vomits_everything = ninioVomitaTodo,
    convulsions_hist = ninioTuvoConvulsiones,
    convulsions_obs = ninioTuvoConvulsionesObs,
    lethargy = ninioTieneLetargiaObs,
    unconciousness = ninioDesmayoObs,
    head_nodding = ninioCabeceoObs,
    # Proxies for severe disease
    ventilation = ventilacionMecanica,
    ventilation_days = ventilacionMecanicaDias,
    icu_days = cuidadoIntensivoDias,
    # Chronic illnesses
    ci_any = enfermedadesCronicasAlguna,
    ci_diabetes = enfermedadesCronicasDiabetes,
    ci_cancer = enfermedadesCronicasCancer,
    ci_cvd = enfermedadesCronicasEnfermCorazon,
    ci_stroke = enfermedadesCronicasDerrame,
    ci_liver = enfermedadesCronicasEnfermHigado,
    ci_kidney = enfermedadesCronicasEnfermRinion,
    ci_lungs = enfermedadesCronicasEnfermPulmones,
    ci_asthma = enfermedadesCronicasAsma,
    ci_hiv = enfermedadesCronicasVIHSIDA,
    ci_hypertension = enfermedadesCronicasHipertension,
    ci_preterm = enfermedadesCronicasNacimientoPrematuro,
    ci_other = enfermedadesCronicasInfoAdicional,
    # Death
    death_hospital = muerteHospital,
    death_enrolled = muerteViCo,
    death_eligible = muerteSospechoso,
    death_quest_stage = muerteCualPaso,
    discharge_type = egresoTipo, # 4 means death
    discharge_condition = egresoCondicion, # 4 means moribund
    # Follow up after discharge
    followup_date = seguimientoFechaReporte,
    followup_condition = seguimientoPacienteCondicion, # 3 means death
    # Physician diagnoses
    diag_1 = egresoDiagnostico1,
    diag_1_other = egresoDiagnostico1_esp,
    diag_2 = egresoDiagnostico2,
    diag_2_other = egresoDiagnostico2_esp,
    # Lab results
    pcr = viralPCR_Hizo,
    flu_a = viralPCR_FluA,
    flu_a_h1 = viralPCR_FluAH1,
    flu_a_h3 = viralPCR_FluAH3,
    flu_a_h5a = viralPCR_FluAH5a,
    flu_a_h5b = viralPCR_FluAH5b,
    flu_a_swa = viralPCR_FluASwA,
    flu_a_swh1 = viralPCR_FluASwH1,
    flu_a_pdmh1 = viralPCR_pdmH1,
    flu_a_pdminfa = viralPCR_pdmInFA,
    flu_b = viralPCR_FluB
  )

all_sites <- all_sites %>%
  select(
    site_type  = TipoSitio, site_name = NombreShortName, site_name_full = Nombre,
    site_department = DeptoShortName,
    long = Longitude, lat = Latitude, altitude = Altitude
  )


#-------------------------------------------------------------------------------*
# Filter data to keep only necessary cases ----
#-------------------------------------------------------------------------------*

# Surveillance data
study_respi <- all_respi %>%
  mutate(
    record_year = year(record_date)
  ) %>%
  filter(
    record_year %in% study_years,
    site_name %in% study_sites
  )

# Sites metadata
study_sites <- all_sites %>%
  filter(
    site_name %in% study_sites
  )




#------------------------------------------------------------------------------*
# Save pre processed data ----
#------------------------------------------------------------------------------*

save(
  study_respi, study_sites, catchment,
  file = paste0(snapshots_path, "study_data.RData")
)



# End of script
