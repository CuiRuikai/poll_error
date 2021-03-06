library(glue)
library(tidyr)
library(readr)
library(dplyr)
library(foreach)

df_raw <- read_csv("data/output/pres16_state.csv", col_types = cols())

lm_store <- function(cand_text, subset, rho_type, N_text, df = df_raw) {
  
  # reset
  ff <- ff_bias <- ""
  
  
  rho_text <- glue("rho_{cand_text}_{rho_type}") # e.g. rho_hrc_vot
  ff <- glue("log10(abs({rho_text})) ~ log10({N_text})")
  ff_bias <- glue("I(log10(abs({rho_text})) + 0.5*log10({N_text})) ~ log10({N_text})")
  
  # special case with weighted
  if (rho_type == "wvv" & cand_text == "djt") {
    ff <- glue("log10(abs({rho_text})) ~ log10({N_text})")
    ff_bias <- glue("I(log10(abs((cces_pct_djt_wvv - pct_djt_voters) / (sqrt(cces_varhatN_djt_wvv))))) ~ log10({N_text})")
  }
  if (rho_type == "wvv" & cand_text == "hrc") {
    ff <- glue("log10(abs({rho_text})) ~ log10({N_text})")
    ff_bias <- glue("I(log10(abs((cces_pct_hrc_wvv - pct_hrc_voters) / (sqrt(cces_varhatN_hrc_wvv))))) ~ log10({N_text})")
  }
  
  
  ## subset states
  if (subset == "all") dfreg <- df
  if (subset %in% c("D", "R", "swing")) dfreg <- filter(df, color == subset)
  
  ## run model
  if (nrow(dfreg) > 3) {
    mod <- lm(as.formula(ff), dfreg)
    coef <- sprintf("%.2f", coef(mod)[2])
    se <- sprintf("%.2f", summary(mod)$coef[2, 2])
    lab <- glue("{coef} \n({se})")
    coef <- coef(mod)[2] # overwrite
    se <- summary(mod)$coef[2, 2]
    
    # separate regression for getting relative bias
    mod_bias <- lm(as.formula(ff_bias), dfreg)
    coef_bias <- sprintf("%.2f", coef(mod_bias)[2])
    se_bias <- sprintf("%.2f", summary(mod_bias)$coef[2, 2])
    lab_bias <- glue("{coef_bias} \n({se_bias})")
    coef_bias <- coef(mod_bias)[2]
    se_bias <- summary(mod_bias)$coef[2, 2]
    
  } else {
    coef_bias <- se_bias <- lab_bias <- coef <- se <- lab <- NA
  }
  
  # short description
  descrip <- paste0(gsub("_", "-", rho_text), "_", "states-", subset)
  descrip <- gsub("^rho-", "", descrip)
  
  
  tibble(descrip = descrip,
         cand = cand_text,
         subset = subset,
         rho_type = rho_type,
         rho_text = as.character(rho_text),
         N_text = N_text,
         nstates = nrow(dfreg),
         lm_form = as.character(ff),
         coef = coef,
         se = se,
         lab = as.character(lab),
         coef_bias = coef_bias,
         se_bias = se_bias,
         lab_bias = lab_bias)
}


reg_specs <- tibble(cand = c("hrc", "djt", "hcu", "dtu", "hcdu", "dtru"),
                    subset = c("all", "R", "D", "swing", rep(NA, 2)),
                    rho_type = c("vot", "vep", "vvt", "wvv", "pst", rep(NA, 1))) %>%
  complete(cand, subset, rho_type) %>% # all factors
  filter(!(grepl("u", cand) & rho_type == "pst")) # these don't apply

rho_N <- tibble(rho_type = c("vot", "vep", "vvt", "wvv", "pst"),
                N_type = c("tot_votes", "vep", "tot_votes", "tot_votes", "tot_votes"))

reg_specs <- left_join(reg_specs, rho_N, by = "rho_type")


lm_stored <-  foreach(i = 1:nrow(reg_specs), .combine = "bind_rows") %do% {
  lm_store(cand_text = reg_specs$cand[i],
           subset = reg_specs$subset[i],
           rho_type = reg_specs$rho_type[i],
           N_text = reg_specs$N_type[i])
}


# save data
saveRDS(lm_stored, "data/output/rho-N_lm-output.rds")



