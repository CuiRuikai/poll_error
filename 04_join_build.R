

mm <- readRDS("data/output/mm_popultn_state.rds")
dw <- readRDS("data/output/dw_results_state.rds")
yg <- readRDS("data/output/yg_release_state.rds")
cc <- readRDS("data/output/cc_tabulation_state.rds")


# Join ---
df_joined <-  inner_join(mm, dw, by = "state") %>%
  inner_join(cc, by = "state") %>% 
  inner_join(yg, by = "state")
  
  
# select ----
df <- df_joined %>% 
  mutate(pct_hrc_vep = votes_hrc / vep) %>%
  select(state, st, color, vap, vep, 
         votes_hrc, tot_votes, 
         pct_hrc_vep, pct_hrc_voters,
         cces_pct_hrc_vep, cces_pct_hrc_voters, cces_pct_hrc_raw,
         cces_tothrc_raw,
         cces_tothrc_adj_trn,
         cces_n_raw, cces_n_voters,
         yougov_pct_hrc, yougov_n,
         `State Results Website`)


# categorize swing state, red, blue
# https://docs.google.com/spreadsheets/d/133Eb4qQmOxNvtesw2hdVns073R68EZx4SfCnP4IGQf8/edit#gid=19




# estimate rho ----
rho_estimate <- function(data = df, N, mu, muhat, n) {
  
  N <- data[[N]]
  n <- data[[n]]
  mu <- data[[mu]]
  muhat <- data[[muhat]]
  
  ## parts
  one_over_sqrtN <- 1 / sqrt(N)
  diff_mu <- muhat - mu
  f <- n / N
  one_minus_f <- 1 - f
  s2hat <- mu * (1 - mu)
  
  ## estimate of rho
  one_over_sqrtN * diff_mu / sqrt((one_minus_f / n) * s2hat)
}



df$rho_voter <- rho_estimate(N = "tot_votes",
                             mu = "pct_hrc_voters",
                             muhat = "cces_pct_hrc_voters",
                             n = "cces_n_voters")

df$rho_vep <- rho_estimate(N = "vep",
                             mu = "pct_hrc_voters",
                             muhat = "cces_pct_hrc_raw",
                             n = "cces_n_raw")
# Save ----
write_csv(df, "data/output/pres16_state.csv")


ggplot(df, aes(x = cces_n_voters / cces_n_raw, y = tot_votes / vap)) +
  geom_point() +
  coord_equal() +
  geom_abline(intercept = 0, slope = 1)
