# load data and packages for MLM

# load packages
osuRepo = 'http://ftp.osuosl.org/pub/cran/'
if(!require(tidyverse)){ install.packages('tidyverse',repos=osuRepo) }
if(!require(lmerTest)){ install.packages('lmerTest',repos=osuRepo) }

# load data
## mri
self_parcels = c(5, 17, 28, 47, 52, 66, 116, 147, 152, 156, 184, 198, 207, 225, 249, 292, 309, 354, 380)
social_parcels = c(18, 23, 29, 49, 54, 59, 62, 63, 67, 76, 111, 114, 139, 143, 146, 150, 178, 179, 189, 203, 212, 224, 229, 236, 238, 239, 245, 250, 259, 266, 271, 301, 305, 310, 322, 324, 328, 331, 333, 342, 343, 350, 374, 391)

mri_exclusions = c('s002_t1', 's004_t1', 's008_t1', 's011_t1', 's017_t1',
                   's026_t1', 's033_t2', 's034_t1', 's041_t1', 's044_t1',
                   's047_t1', 's051_t1', 's054_t1', 's057_t1', 's059_t1',
                   's061_t1', 's063_t1', 's070_t2', 's074_t1', 's074_t2',
                   's078_t1', 's084_t1', 's090_t2', 's090_t3', 's094_t1',
                   's094_t2', 's096_t1')

parcellations = read_csv('../data/fxParcellations.csv') %>%
  mutate(label = ifelse(parcellation %in% self_parcels, 'self',
                 ifelse(parcellation %in% social_parcels, 'social', 'other'))) %>%
  mutate(wave = paste0("t", as.numeric(c(`10` = 1, `13` = 2, `16` = 3)[as.character(age)]))) %>%
  select(-age) %>%
  unite(sub_wave, c(subjectID, wave), remove = FALSE) %>%
  group_by(parcellation) %>%
  mutate(inclusion = ifelse(sub_wave %in% mri_exclusions, "excluded from MRI", "completed MRI"),
         beta = ifelse(sub_wave %in% mri_exclusions, NA, beta),
         sd = ifelse(sub_wave %in% mri_exclusions, NA, sd),
         beta_std = scale(beta, center = FALSE, scale = TRUE),
         mean_beta_std = mean(beta_std, na.rm = TRUE)) %>%
  select(-sub_wave) %>%
  ungroup()

parcellations_ex = parcellations %>%
  mutate(beta_std = ifelse(beta_std > mean_beta_std + 3 | beta_std < mean_beta_std - 3, NA, beta_std))

# demographics
demo = read.csv("../data/SFIC_age.pds.gender.csv") %>%
  rename("subjectID" = SID,
         "wave" = wavenum,
         "gender" = Gender) %>%
  mutate(subjectID = sprintf("s%03d", subjectID),
         wave = paste0("t", wave),
         age_c = age - 13,
         age_c2 = age_c^2,
         pdss_c = pdss - 3,
         pdss_c2 = pdss_c^2)

# merge data
merged = parcellations_ex %>%
  full_join(., demo, by = c("subjectID", "wave")) %>%
  mutate(inclusion = ifelse(is.na(inclusion), "didn't complete MRI", inclusion)) %>%
  filter(!(subjectID == "s086" & wave == "t3")) #no MRI, task, or self-report data was collected

# subset data for modeling
neuro_model_data = merged %>%
  filter(!is.na(beta)) %>%
  select(subjectID, wave, age, age_c, age_c2, target, domain, parcellation, label, beta, beta_std)

neuro_model_data_ex = neuro_model_data  %>%
  na.omit()

neuro_model_data_pdss = merged %>%
  filter(!is.na(beta)) %>%
  select(subjectID, wave, pdss, pdss_c, pdss_c2, target, domain, parcellation, label, beta, beta_std)

neuro_model_data_ex_pdss = neuro_model_data_pdss  %>%
  na.omit()

# dummy code target and domain
neuro_model_data_dummy = neuro_model_data_ex %>%
  mutate(target = ifelse(target == "self", .5, -.5),
         domain = ifelse(domain == "social", .5, -.5))

neuro_model_data_dummy_pdss = neuro_model_data_ex_pdss %>%
  mutate(target = ifelse(target == "self", .5, -.5),
         domain = ifelse(domain == "social", .5, -.5))
