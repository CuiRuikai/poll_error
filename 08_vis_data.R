library(cowplot)
library(ggplot2)
library(scales)
library(readr)
library(ggrepel)
library(dplyr)
library(tibble)
library(foreach)
library(glue)

fig.w <- 6*0.80*0.9
fig.h <- 4*0.751*0.9
mfig.w <- fig.w

# labels -----
colorvec <- c("R" =  '#d7191c', "swing" = 'darkgreen', "D" = '#2c7bb6')
rho_pos_labs <- c(`TRUE` = "rho > 0 (Overestimated Clinton)",
                  `FALSE` = "rho < 0 (Underestimated Clinton)")
# percent function
make_pct <- function(dbl, points = FALSE) {
  if (points) 
    return(paste0(round(dbl*100), "%"))

    if (!points) 
    return(paste0(round(dbl, 2)))
}

# data and vars -----
df_raw <- read_csv("data/output/pres16_state.csv", col_types = cols())
df <- df_raw


slopes <- readRDS("data/output/rho-N_lm-output.rds")


# limit parameters ---
# y-axislimit
all_rhos <- unlist(select(df, matches("rho")), use.names = FALSE)
all_pops <- unlist(select(df, vep, tot_votes), use.names = FALSE)

# ranges
lim_rho <- range(all_rhos)
lim_lro <- range(log10(abs(all_rhos)))
lim_lroN <- range(log10(abs(all_rhos)*all_pops))
lim_lpp <- range(log10(all_pops))

# for hist
ylim_hist <- c(0, 12.5)


# labels ------
# log absolute value expressions 

lar_end <- ")"

lar_exp <- 
  list(hrc_vot = expression(log[10]~bgroup("(", abs(~Clinton~~italic(widehat(italic(rho))[N[avp]])), ")")),
       hrc_vep = expression(log[10]~bgroup("(", abs(~Clinton~~italic(widehat(italic(rho))[N[vep]])), ")")),
       hrc_vvt = expression(log[10]~bgroup("(", abs(~Clinton~~italic(widehat(italic(rho))[N[vv]])), ")")),
       hrc_pst = expression(log[10]~bgroup("(", abs(~Clinton~~italic(widehat(italic(rho))[N[post]])), ")")),
       hcu_vot = expression(log[10]~bgroup("(", abs(~Clinton+All~Undecided~~italic(widehat(italic(rho))[N[avp]])), ")")),
       hcu_vep = expression(log[10]~bgroup("(", abs(~Clinton+All~Undecided~~italic(widehat(italic(rho))[N[vep]])), ")")),
       hcu_vvt = expression(log[10]~bgroup("(", abs(~Clinton+All~Undecided~~italic(widehat(italic(rho))[N[vv]])), ")")),
       hcdu_vot =expression(log[10]~bgroup("(", abs(~Clinton+Undecided~Democrats~~italic(widehat(italic(rho))[N[avp]])), ")")),
       hcdu_vep =expression(log[10]~bgroup("(", abs(~Clinton+Undecided~Democrats~~italic(widehat(italic(rho))[N[vep]])), ")")),
       hcdu_vvt =expression(log[10]~bgroup("(", abs(~Clinton+Undecided~Democrats~~italic(widehat(italic(rho))[N[vv]])), ")")),
       djt_vot = expression(log[10]~bgroup("(", abs(~Trump~~italic(widehat(italic(rho))[N[avp]])), ")")+frac(1,2)*log(N)),
       djt_vep = expression(log[10]~bgroup("(", abs(~Trump~~italic(widehat(italic(rho))[N[vep]])), ")")),
       djt_vvt = expression(log[10]~bgroup("(", abs(~Trump~~italic(widehat(italic(rho))[N[vv]])), ")")),
       djt_pst = expression(log[10]~bgroup("(", abs(~Trump~~italic(widehat(italic(rho))[N[post]])), ")")),
       dtu_vot = expression(log[10]~bgroup("(", abs(~Trump+All~Undecided~~italic(widehat(italic(rho))[N[avp]])), ")")),
       dtu_vep = expression(log[10]~bgroup("(", abs(~Trump+All~Undecided~~italic(widehat(italic(rho))[N[vep]])), ")")),
       dtu_vvt = expression(log[10]~bgroup("(", abs(~Trump+All~Undecided~~italic(widehat(italic(rho))[N[vv]])), ")")),
       dtu_vot = expression(log[10]~bgroup("(", abs(~Trump+Undecided~Republicans~~italic(widehat(italic(rho))[N[avp]])), ")")),
       dtu_vep = expression(log[10]~bgroup("(", abs(~Trump+Undecided~Republicans~~italic(widehat(italic(rho))[N[vep]])), ")")),
       dtu_vvt = expression(log[10]~bgroup("(", abs(~Trump+Undecided~Republicans~~italic(widehat(italic(rho))[N[vv]])), ")"))
  )



# normal rho
rho_exp <- 
  list(hrc_vot = expression(Clinton~~italic(widehat(italic(rho))[N[avp]])),
       hrc_vep = expression(Clinton~~italic(widehat(italic(rho))[N[vep]])),
       hrc_vvt = expression(Clinton~~italic(widehat(italic(rho))[N])),
       hrc_wvv = expression(Clinton~~italic(widehat(italic(rho))[wVV])),
       hrc_pst = expression(Clinton~~italic(widehat(italic(rho))[N[post]])),
       hcu_vot = expression(Clinton+All~Undecideds~~italic(widehat(italic(rho))[N[avp]])),
       hcu_vep = expression(Clinton+All~Undecideds~~italic(widehat(italic(rho))[N[vep]])),
       hcu_vvt = expression(Clinton+All~Undecideds~~italic(widehat(italic(rho))[N])),
       hcdu_vot = expression(Clinton+Undecided~Democrats~~italic(widehat(italic(rho))[N[avp]])),
       hcdu_vep = expression(Clinton+Undecided~Democrats~~italic(widehat(italic(rho))[N[vep]])),
       hcdu_vvt = expression(Clinton+Undecided~Democrats~~italic(widehat(italic(rho))[N])),
       djt_vot = expression(Trump~~italic(widehat(italic(rho))[N[avp]])),
       djt_vep = expression(Trump~~italic(widehat(italic(rho))[N[vep]])),
       djt_vvt = expression(Trump~~italic(widehat(italic(rho))[N])),
       djt_wvv = expression(Trump~~italic(widehat(italic(rho))[wVV])),
       djt_pst = expression(Trump~~italic(widehat(italic(rho))[N[post]])),
       dtu_vot = expression(Trump+All~Undecideds~~italic(widehat(italic(rho))[N[avp]])),
       dtu_vep = expression(Trump+All~Undecideds~~italic(widehat(italic(rho))[N[vep]])),
       dtu_vvt = expression(Trump+All~Undecideds~~italic(widehat(italic(rho))[N])),
       dtru_vot = expression(Trump+Undecided~Republicans~~italic(widehat(italic(rho))[N[avp]])),
       dtru_vep = expression(Trump+Undecided~Republicans~~italic(widehat(italic(rho))[N[vep]])),
       dtru_vvt = expression(Trump+Undecided~Republicans~~italic(widehat(italic(rho))[N])))

# titles
eff_t <- list(
  hrc_vot = expression(frac(n[eff], n):~Clinton~widehat(mu)[avp]),
  hrc_vep = expression(frac(n[eff], n):~Clinton~widehat(mu)[vep]),
  hrc_vvt = expression(frac(n[eff], n):~Clinton~widehat(mu)[vvt]),
  djt_vot = expression(frac(n[eff], n):~Trump~widehat(mu)[avp]),
  djt_vep = expression(frac(n[eff], n):~Trump~widehat(mu)[vep]),
  djt_vvt = expression(frac(n[eff], n):~Trump~widehat(mu)[vv])
)


# clear ----
fig_pdfs <- list.files("figures", pattern = "pdf$", full.names = TRUE, recursive = TRUE)
fig_pdfs <- setdiff(fig_pdfs, grep("(backup|sims|bounds)", fig_pdfs, value = TRUE))
file.remove(fig_pdfs)



# plots for rho vs. N ---------


plot_corr <- function(dat = df, slp = slopes, lmrow) {
  
  slope_i <- slp[lmrow, ]
  cand <- slope_i$cand
  subset <- slope_i$subset
  rho_type <- slope_i$rho_type
  rho_text <- slope_i$rho_text
  N_text <- slope_i$N_text
  filename <- paste0("rho-", slope_i$descrip, ".pdf")
  lab <- slope_i$lab_bias
  
  # pretty labels 
  if (N_text == "tot_votes") xlab_text <- expression(log[10]~plain("(Total Voters)"))
  if (N_text == "vep") xlab_text <- expression(log[10]~plain("(Voting Eligible Population)"))
  lar_code <- gsub("rho_", "", rho_text)
  if (grepl("^h", cand)) ylab_text <- expression(plain("Clinton ")~log[10]~abs(~italic(Z[~list(n, N)] )))
  if (grepl("^d", cand)) ylab_text <- expression(plain("Trump ")~log[10]~abs(~italic(Z[~list(n, N)] )))
  rho_expr <- rho_exp[[lar_code]]
  
  # update lab by adding state subset info
  if (subset == "R") stlab <- "Red states"
  if (subset == "D") stlab <- "Blue states"
  if (subset == "swing") stlab <- "Swing states"
  if (subset == "pos") stlab <- "States where rho > 0" 
  if (subset == "neg") stlab <- "States where rho < 0"
  if (subset == "all") stlab <- ""
  lab <- paste0("", lab)

    
  
  # subset data frame
  if (subset %in% c("R", "D", "swing")) df_plot <- filter(dat, color == subset)
  if (subset == "pos") df_plot <- filter(dat, .data[[rho_text]] > 0)
  if (subset == "neg") df_plot <- filter(dat, .data[[rho_text]] < 0)
  if (subset == "all") df_plot <- dat
  
  # get yvar
  df_plot <- df_plot %>%
    mutate(rhovar = .data[[rho_text]])
  
  # add log version of x and y variable
  df_plot <- df_plot %>%
    mutate(log_abs_rho = log10(abs(rhovar)),
           log_N = log10(.data[[N_text]])) %>% 
    mutate(rho_metric = log_abs_rho + (0.5*log_N))
  
  
  # for sampling weights use the approximate weighted variance and compute directly
  
  if (rho_type == "wvv" & cand == "djt") {
    df_plot <- df_plot %>% 
      mutate(log_N = log10(.data[[N_text]]),
             log_abs_rho = NULL) %>% 
      mutate(rho_metric = log10(abs((cces_pct_djt_wvv - pct_djt_voters) / (sqrt(cces_varhatN_djt_wvv)))))
  }
  if (rho_type == "wvv" & cand == "hrc") {
    df_plot <- df_plot %>% 
      mutate(log_N = log10(.data[[N_text]]),
             log_abs_rho = NULL) %>% 
      mutate(rho_metric = log10(abs((cces_pct_hrc_wvv - pct_hrc_voters) / (sqrt(cces_varhatN_hrc_wvv)))))
  }
  
  
  # data to label
  df_lab <- NULL 
  
  
  # skeleton
  gg0 <- ggplot(df_plot, aes(label = st, color = color)) +
    aes(x = log_N, y = rho_metric) +
    geom_smooth(method = "lm", se = FALSE, color = "gray") +
    geom_point() +
    scale_color_manual(values = colorvec)  +
    theme_bw() +
    coord_cartesian(ylim = c(-2, 2), xlim = lim_lpp) +
    scale_x_continuous(minor_breaks = NULL) +
    scale_y_continuous(minor_breaks = NULL) +
    annotate("text", x = -Inf, y = -Inf, label = "More accurate", color = "darkgray", hjust = -0.3, vjust = -0.5) +
    annotate("text", x = -Inf, y = Inf, label = "Less accurate", color = "darkgray", hjust = -0.3, vjust = 1) +
    annotate("label", x = Inf, y= -Inf, label = lab, hjust = 1.2, vjust = -1, size = 4) +
    guides(color = FALSE) +
    labs(y = ylab_text, 
         x = xlab_text,
         # title = rho_expr,
         subtitle = stlab)
         # caption = lab)
  
  if (NROW(df_lab) > 0) {
    gg0 <- gg0 + 
      geom_text_repel(data = df_lab, aes(label = st))
  }
  
  cat(filename, "\n")
  ggsave(file.path("figures/rho-N/", filename), gg0, width = fig.w, height = fig.h)
  rm(df_plot)
}


# run through all of them
for (i in which(!is.na(slopes$lab) & !(slopes$subset %in% c("pos", "neg")))) {
  plot_corr(lmrow = i)
}


# show distribution of slopes -----
coef_plot <- slopes %>% 
  filter(!subset %in% c("neg", "pos")) %>%
  arrange(subset, rho_type) %>% 
  mutate(descrip = forcats::as_factor(gsub("(hrc|djt|hcu|dtu|hcdu|dtru)-", "", descrip)),
         descrip = forcats::as_factor(gsub("_states-", "; ", descrip)),
         cand = factor(cand, levels = c("hrc", "djt", "hcdu", "dtru",  "hcu", "dtu")),
         emph = case_when(subset == "all" ~ "1", subset != "all" ~ "0"),
         ymin = coef_bias - qnorm(0.975)*se,
         ymax = coef_bias + qnorm(0.975)*se) 

candlab <- c("hrc" = "Clinton Supporters",
             "djt" = "Trump Supporters",
             "hcu" = "Clinton Supporters\n+\nAll Undecideds",
             "dtu" = "Trump Supporters\n+\nAll Undecideds",
             "hcdu" = "Clinton Supporters\n+\nUndecided Democrats",
             "dtru" = "Trump Supporters\n+\nUndecided Republicans")

candlab <- gsub("\\n", " ", candlab) # remove or keep line breaks

colorvec_pn <- c(colorvec, 
                 "all" = "black",
                 "pos" = "#ff7f00",
                 "neg" = "#6a3d9a")

labvec <- c("D" = "Blue states",
            "R" = "Red states", 
            "swing" = "Swing states", 
            "all" = "All states",
            "pos" = "rho > 0 (overestimates)",
            "neg" = "rho < 0 (underestimates)")


plot_coef <- function(df = coef_plot, coefrange = c(-1 , 2), legendpos = "right", cap = "Each point is a regression coefficient with 95 percent CI.") {
  if (legendpos == "right") legendcol <- 1
  if (legendpos == "bottom") legendcol <- 4
  ggplot(df, aes(y = coef_bias, x = descrip, ymin = ymin, ymax = ymax, color = subset, size = emph)) +
    facet_wrap(~cand, labeller = labeller(cand = candlab), ncol = 2) +
    theme(axis.line=element_line()) + 
    scale_color_manual(name = "States used", values = colorvec_pn, labels = labvec) +
    geom_hline(yintercept = 0, linetype = "solid", color = "darkgray") +
    geom_hline(yintercept = 0.5, linetype = "dashed") +
    geom_pointrange(shape = 18) +
    scale_y_continuous(minor_breaks = NULL, limit = coefrange, breaks = c(-1, 0, 0.5, 1, 2)) +
    scale_size_manual(values = c("1" = 1, "0" = 0.75)) +
    guides(size = FALSE, color = guide_legend(ncol = legendcol, reverse = TRUE)) +
    coord_flip() +
    theme_bw() +
    theme(legend.position = legendpos, 
          panel.grid.major.x = element_blank(), panel.grid.major.y = element_blank(),
          strip.text = element_text(size = 11)) +
    labs(x = "Specification of relative error",
         y = expression(Slope~on~log[10]~N),
         caption = cap)
       # Facets separate different estimands (Clinton vs. Trump) and different ways to treat Undecideds.
       # Points ordered by the subset of states (color) and then by estimand (in text).
       # Missing values occur when there were too few observations (3 or less) to calculate a slope.")
}

plot_coef(coef_plot, cap = NULL)
ggsave("figures/summ/corr-rho-N_intervals_all.pdf", w = 2*fig.w, h = 1.75*fig.h)

plot_coef(filter(coef_plot, cand %in% c("hrc", "djt")))
ggsave("figures/summ/corr-rho-N_intervals_hrc-djt.pdf", w = 1.7*fig.w, h = 1.2*fig.h)

plot_coef(filter(coef_plot, cand %in% c("hcu", "dtu")))
ggsave("figures/summ/corr-rho-N_intervals_hcu-dtu.pdf", w = 1.3*fig.w, h = 1.3*fig.h)


# Z and N -----

Z_shorthand <- function(muhats, mus, ns) {
  (muhats - mus) / (sqrt(muhats * (1 - muhats) / ns))
}

# so far with vv
yrange <- range(with(df,c(
                     (cces_pct_djt_vv - pct_djt_voters) / (sqrt(cces_pct_djt_vv*(1 - cces_pct_djt_vv) / cces_n_vv)),
                     (cces_pct_hrc_vv - pct_hrc_voters) / (sqrt(cces_pct_hrc_vv*(1 - cces_pct_hrc_vv) / cces_n_vv)))))
                     
ZNn_djt <- ggplot(df, aes(x = log10(tot_votes), 
               y = Z_shorthand(cces_pct_djt_vv, pct_djt_voters, cces_n_vv),
               color = color,
               label = st)) +
  annotate("rect", ymin = -2, ymax = 2, xmin = -Inf, xmax = Inf, alpha = 0.2) +
  geom_point() +
  geom_text_repel(size = 2.5, alpha = 0.7) +
  scale_color_manual(values = colorvec) +
  theme_bw() +
  scale_x_continuous(minor_breaks = FALSE) +
  scale_y_continuous(limits = yrange, breaks = c(-10, -5, -2, 0, 2, 5), minor_breaks = FALSE) +
  guides(color = FALSE) +
  labs(x = expression(log[10]~plain("(Total Voters)")),
       y = expression(Trump~italic(Z[n])))

ZNn_hrc <-  ZNn_djt + 
  aes(y = Z_shorthand(cces_pct_hrc_vv, pct_hrc_voters, cces_n_vv)) +
  labs(y = expression(Clinton~italic(Z[n])))

ZNn_djt + 
  aes(y = Z_shorthand(cces_pct_djt_wvv, pct_djt_voters, cces_n_wvv)) +
  labs(y = "DJT Voters")

ggsave("figures/Zscore/Zscore_djt_vvt.pdf", ZNn_djt, width = fig.w, height = fig.h)
ggsave("figures/Zscore/Zscore_hrc_vvt.pdf", ZNn_hrc, width = fig.w, height = fig.h)

# with weights
ZNn_djt_wvv <- ZNn_djt + 
  aes(y = (cces_pct_djt_wvv - pct_djt_voters) / (sqrt(cces_varhat_djt_wvv))) +
  labs(y = expression(Trump~~italic(Z[~n])~plain("with weights")))

ZNn_hrc_wvv <- ZNn_hrc + 
  aes(y = (cces_pct_hrc_wvv - pct_hrc_voters) / (sqrt(cces_varhat_hrc_wvv))) +
  labs(y = expression(Clinton~~italic(Z[~n])~plain("with weights")))

ggsave("figures/Zscore/Zscore_djt_wvv.pdf", ZNn_djt_wvv, width = fig.w, height = fig.h)
ggsave("figures/Zscore/Zscore_hrc_wvv.pdf", ZNn_hrc_wvv, width = fig.w, height = fig.h)



ggplot(df, aes(x = tot_votes, 
               y = rho_djt_vvt*sqrt(tot_votes - 1),
               color = color,
               label = st)) +
  geom_point()

# check coverage ----

chk_cov <- df %>% 
  mutate(hrc_Z_vv = (cces_pct_hrc_vv - pct_hrc_voters) / (sqrt(cces_pct_hrc_vv*(1 - cces_pct_hrc_vv) / cces_n_vv)),
         hrc_Z_wvv = (cces_pct_djt_wvv - pct_djt_voters) / (sqrt(cces_varhat_djt_wvv)))

mean(abs(chk_cov$hrc_Z_vv) < 2)
mean(abs(chk_cov$hrc_Z_wvv) < 2)


edu <- read_csv("data/input/R11548735_SL040.csv") %>% 
  select(Geo_NAME, matches("SE_T025")) %>% 
  mutate(bach_above = SE_T025_005 + SE_T025_006 + SE_T025_007 + SE_T025_008)  %>% 
  rename(state = Geo_NAME) %>% 
  select(state, bach_above)

chk_cov <- left_join(chk_cov, edu, by = "state") %>% 
  mutate(prop_bach = bach_above / vep)

gg_edu_b <-  ggplot(chk_cov, aes(x = prop_bach, y = (cces_pct_hrc_vv - pct_hrc_voters), color = color, group = color)) +
  scale_color_manual(values = colorvec) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_smooth(method = "gam", aes(group = NULL), se = FALSE, color = "darkgray", alpha = 0.5) +
  geom_smooth(method = "gam", se = FALSE, alpha = 0.25) +
  scale_x_continuous(labels = percent) +
  geom_point(aes(size = vep), alpha = 0.75) +
  geom_text_repel(aes(label = st), alpha = 0.75) +
  theme_bw() +
  guides(color = FALSE, size = FALSE) +
  labs(x = "Proportion of Voting Eligible Population who are\n25+ and have a Bachelor's Degree or Above",
       y = expression(plain("Clinton Error: ")~widehat(italic(p)) - italic(p)))

gg_edu_Z <- gg_edu_b + aes(y = hrc_Z_vv) +
  labs(y = expression(plain("Clinton")~italic(Z[n]):frac(widehat(italic(p)) - italic(p), sqrt(widehat(italic(p))(1 - widehat(italic(p)))/n))))

plot_grid(gg_edu_b, gg_edu_Z, ncol = 1, align = "v")
ggsave("figures/temp_error-by-education.pdf", h = 8, w = 8)

# check ZnN calculation ---

foo <- df %>% 
  mutate(Z_djt = (cces_pct_djt_wvv - pct_djt_voters) / (sqrt(cces_varhatN_djt_wvv)))


bar <- foo %>% arrange(-Z_djt) %>% 
  mutate(Z_djt_byrho = log10(abs(rho_djt_wvv)) + 0.5*log10(tot_votes),
         Z_djt_log = log10(abs(Z_djt))) %>%
  select(st, state, color, Z_djt, Z_djt_log, Z_djt_byrho, tot_votes, vap, vep)

bar %>% 
  ggplot(aes(x = Z_djt_log, y = Z_djt_byrho, 
             color= color)) +
  theme_bw() +
  coord_equal() +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  scale_color_manual(values = colorvec) +
  guides(color = FALSE, size = FALSE) +
  geom_point(alpha = 0.8) +
  labs(y = expression(log(abs(hat(rho[N]))) + 0.5*log(N)),
       x = expression(log~bgroup("|",italic(frac(hat(p) - p, sqrt(widehat(wVar)))),"|")),
       title = "Comparison of relative error on Trump",
       subtitle = " (validated voters, with weights)")
ggsave("figures/temp_different-var.pdf", w = 5, h = 5)

  bar %>% 
  summarize(mad = mean(abs(Z_djt_log - Z_djt_byrho)))


# bounds of rho ----

df_bounds <- df %>% 
  mutate(fR = cces_n_vv / tot_votes,
         DO = (1 - fR) / fR,
         OG_djt = pct_djt_voters/(1 - pct_djt_voters),
         OG_hrc = pct_hrc_voters/(1 - pct_hrc_voters)) %>%
  rowwise() %>% 
  mutate(lb_djt = -min(sqrt(DO/OG_djt), sqrt(OG_djt/DO)),
         lb_hrc = -min(sqrt(DO/OG_hrc), sqrt(OG_hrc/DO)),
         ub_djt = min(sqrt(OG_djt*DO),1 /sqrt(OG_djt*DO)),
         ub_hrc = min(sqrt(OG_hrc*DO),1 /sqrt(OG_hrc*DO))
         )

ylim_rho_bounds <- range(with(df_bounds,
                   c(lb_djt, lb_hrc, ub_djt, ub_hrc)))

bounds <- ggplot(df_bounds, 
                    aes(x = log10(tot_votes), 
                        y = rho_djt_vvt,
                        ymin = lb_djt,
                        ymax = ub_djt,
                        color = color)) +
  geom_hline(yintercept = -0.005, color = "gray") +
  geom_errorbar(linetype = "dashed", alpha = 0.8, size = 0.3) +
  geom_point() +
  theme_bw() +
  scale_color_manual(values = colorvec) +
  scale_y_continuous(limit = ylim_rho_bounds,
                     breaks = c(-0.005, 0, 0.050), minor_breaks = FALSE) + 
  scale_x_continuous(minor_breaks = FALSE) + 
  labs(x = expression(log[10]~plain("(Total Voters)"))) +
  theme(axis.text.y = element_text(size = 7)) +
  guides(color = FALSE)

bounds_djt <- bounds +
  geom_point(aes(y = lb_djt), alpha = 0.5, size = 1) +
  geom_point(aes(y = ub_djt), alpha = 0.5, size = 1) +
  labs(y = expression(plain("Trump ")~widehat(rho)[N]~plain("(with bounds)")))

bounds_djt

bounds_hrc <- bounds + 
  aes(y = rho_hrc_vvt, ymin = lb_hrc, ymax = ub_hrc) +
  geom_point(aes(y = lb_hrc), alpha = 0.5, size = 1) +
  geom_point(aes(y = ub_hrc), alpha = 0.5, size = 1) +
  labs(y = expression(plain("Clinton ")~widehat(rho)[N]~plain("(with bounds)")))

  

exp_factor <- 1
ggsave("figures/bounds/rho-bounds_djt_vvt.pdf", bounds_djt, h = exp_factor*fig.h, w = exp_factor*fig.w)
ggsave("figures/bounds/rho-bounds_hrc_vvt.pdf", bounds_hrc, h = exp_factor*fig.h, w = exp_factor*fig.w)
  

summary(df$rho_djt_vvt)
summary(df$rho_hrc_vvt)


# Histogram of rho ----

gg0 <- ggplot(df) + geom_vline(xintercept = 0, linetype = "dashed") +
  labs(y = "Count") +
  coord_cartesian(xlim = lim_rho, ylim = ylim_hist) + 
  scale_x_continuous(minor_breaks = NULL) +
  scale_y_continuous(minor_breaks = NULL) +
  geom_histogram(binwidth = 0.001) + theme_bw()
  

rho_vec <- names(rho_exp)


for (rho_name in rho_vec) {
  var_name <- paste0("rho_", rho_name)
  file_name <- paste0("figures/hist/hist_", var_name, ".pdf")
  
  rho_vec <- df[[var_name]]
  options("scipen"=100)
  rhobar <- signif(mean(rho_vec), 2)
  rhoci <- signif(2*sd(rho_vec)/sqrt(length(rho_vec)), 2)
  lab <- paste0(rhobar, " ± ", rhoci)

  gg0 + aes_string(x = var_name) + labs(x = rho_exp[[rho_name]]) +
    annotate("label", x = Inf, y= Inf, label = lab, hjust = 1.1, vjust = 2, size = 4)
  ggsave(file_name, width = fig.w, height = 0.7*fig.h)
  cat(file_name, "\n")
}

# Histogram of cv_turnout
ggplot(df, aes(x = cv_turnout_wgt)) +
  geom_histogram(bins = 25) + theme_bw() +
  labs(x = "Coefficient of Variation of Turnout Adjustment Weights", y = "Count")
ggsave("figures/hist/hist_cv_turnout.pdf", width = fig.w, height = fig.h)

ggplot(df, aes(x = 1 + (cv_common_wgt^2) / (1 - cces_n_vv / tot_votes))) +
  geom_histogram(bins = 25) + theme_bw() +
  labs(x = expression(italic(A[w])==1+frac(CV^2, 1-f[Rvv])),
       y = "Count")
ggsave("figures/hist/hist_Aw.pdf", width = fig.w, height = fig.h)

rm(gg0)

# show differences in rhos ---

df_rho_diff <- df %>% 
  select(state:color, matches("rho"))

df_rho_diff %>% 
  ggplot(aes(x = rho_hrc_vot - rho_dtru_vot)) +
  geom_histogram(bins = 25) + 
  theme_bw()


# what log transforms look like ----
gg0 <- df %>% 
  ggplot(aes(col = color, label = st)) +
  coord_cartesian(xlim = lim_rho, ylim = lim_lro) + 
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_point(alpha = 0.8) +
  scale_color_manual(values = colorvec) +
  theme_bw() +
  scale_x_continuous(minor_breaks = FALSE) +
  scale_y_continuous(minor_breaks = FALSE) +
  guides(color = FALSE)

ycap <- "log(abs(.))"

# four things
log_trans_list <- list(
  gg0 + aes(x = rho_hrc_vot, y = log10(abs(rho_hrc_vot))) +
    labs(x = rho_exp[["hrc_vot"]], y = ycap),
  gg0 + aes(x = rho_djt_vot, y = log10(abs(rho_djt_vot))) +
    labs(x = rho_exp[["djt_vot"]], y = ycap),
  gg0 + aes(x = rho_hrc_vep, y = log10(abs(rho_hrc_vep))) + 
    labs(x = rho_exp[["hrc_vep"]], y = ycap),
  gg0 + aes(x = rho_djt_vep, y = log10(abs(rho_djt_vep))) +
    labs(x = rho_exp[["djt_vep"]], y = ycap)
    )


plot_grid(plotlist = log_trans_list)
ggsave("figures/summ/logabsrho_transformation.pdf", w = fig.w, h = fig.h)

rm(gg0)

# Scatter ------
fig.w <- 1.2*fig.w*0.75
fig.h <- 1.2*fig.h



# colnames
muhats <- grep("cces_pct_", colnames(df), value = TRUE)
muhats <- setdiff(muhats, grep("vep", muhats, value = TRUE))

## generate naive 95 percent CI 

for(v in muhats) {
  
  n_type <- gsub(".*_([a-z]+)$", "\\1", v)
  n_var <- glue("cces_n_{n_type}")

    ub_name <- glue("{v}_ub")
  lb_name <- glue("{v}_lb")
  
  se <- sqrt(df[[v]]*(1 - df[[v]]) / df[[n_var]])
  
  if (v %in% c("cces_pct_hrc_voters", "cces_pct_djt_voters", "cces_pct_hrc_wvv", "cces_pct_djt_wvv")) {
    cand_N <- gsub("cces_pct_", "", v)
    wvarhat <- glue("cces_varhat_{cand_N}")
    se <- sqrt(df[[wvarhat]])
  }
  
  df[[ub_name]] <- df[[v]] + 2*se
  df[[lb_name]] <- df[[v]] - 2*se
  
  rm(se)
}

# make data frame for plots top print
sct_labs <- tibble(var_name = muhats)
sct_labs <- sct_labs %>%
  mutate(ub_name = glue("{var_name}_ub"),
         lb_name = glue("{var_name}_lb")) %>% 
  mutate(cand = case_when(grepl("cces_pct_h", var_name) ~ "H",
                          grepl("cces_pct_d", var_name) ~ "T")) %>%
  mutate(est_t = case_when(grepl("raw$", var_name) ~ "Raw ",
                           grepl("_voters$", var_name) ~ "Turnout-adjusted ",
                           grepl("_vv$", var_name) ~ "Validated Voter ",
                           grepl("_wvv$", var_name) ~ "Validated Voter (with Sampling Weights)\n",
                           grepl("postvoters$", var_name) ~ "Post-Election Wave ")) %>%
  mutate(cand_t = case_when(grepl("_hrc_", var_name) ~ "Clinton Support",
                            grepl("_hrcund_", var_name) ~ "Clinton + All Undecideds",
                            grepl("_hrcdund_", var_name) ~ "Clinton + Undecided Democrats",
                            grepl("_djt_", var_name) ~ "Trump Support",
                            grepl("_djtund_", var_name) ~ "Trump + All Undecideds",
                            grepl("_djtrund_", var_name) ~ "Trump + Undecided Republicans")) %>%
  mutate(ylab_text = paste0(est_t, "Poll Estimate,\n", cand_t)) %>% 
  arrange(var_name)


# starting scatter
gg0 <- ggplot(df, aes(x = pct_hrc_voters, y = cces_pct_hrc_voters, color = color)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_x_continuous(limits = c(-0.005, 1), breaks = c(0, 0.5, 1), labels = percent, expand = c(0, 0)) +
  scale_y_continuous(limits = c(-0.005, 1), breaks = c(0, 0.5, 1), labels = percent, expand = c(0, 0)) +
  scale_color_manual(values = colorvec) +
  guides(size = FALSE, color = FALSE) +
  coord_equal() +
  theme_bw() +
  geom_point(alpha = 1, shape = 20) +
  geom_errorbar(alpha = 0.8, width = 0, size = 0.5) +
  theme(plot.caption = element_text(size = 8))

# loop through and list
sct_gglist <- foreach(i = 1:nrow(sct_labs)) %do% {
  
  if (sct_labs$cand[i] == "H") {
    mu <- df$pct_hrc_voters
    gg <- gg0 +
      annotate("text", x = 0.72, y = 0.1, label = "Poll underestimated\nClinton support", color = "darkgray") +
      annotate("text", x = 0.25, y = 0.9, label = "Poll overestimated\nClinton support", color = "darkgray") +
      labs(x = "Final Clinton Popular Vote Share")
  }
  
  if (sct_labs$cand[i] == "T") {
    mu <- df$pct_djt_voters
    gg <- gg0 + aes(x = pct_djt_voters) +
      annotate("text", x = 0.72, y = 0.1, label = "Poll underestimated\nTrump support", color = "darkgray") +
      annotate("text", x = 0.25, y = 0.9, label = "Poll overestimated\nTrump support", color = "darkgray") +
      labs(x = "Final Trump Popular Vote Share")
  }
  
  rmse <- sqrt(mean((mu - df[[sct_labs$var_name[i]]])^2))
  
  # associate the right y-axis vars (estimate)
  gg <- gg + 
    aes_string(y = sct_labs$var_name[i],
               ymax = sct_labs$ub_name[i],
               ymin = sct_labs$lb_name[i]) +
    ylab(sct_labs$ylab_text[i]) +
    labs(caption = paste0("Root Mean Squared Error: ", sprintf("%3.2f", rmse)))
  
  return(gg)
}

names(sct_gglist) <- sct_labs$var_name


# plot one by one
for (fnames in names(sct_gglist)) {
  est_name <- gsub("cces_pct_", "", fnames)
  est_name <- gsub("postvoters", "pst", est_name)
  est_name <- gsub("_vv", "_vvt", est_name)
  est_name <- gsub("_wvv", "_wvv", est_name)
  est_name <- gsub("voters", "vot", est_name)
  est_name <- gsub("hrcund", "hcu", est_name)
  est_name <- gsub("djtund", "dtu", est_name)
  est_name <- gsub("hrcdund", "hcdu", est_name)
  est_name <- gsub("djtrund", "dtru", est_name)
  
  ggsave(paste0("figures/scatter/scatter_", est_name, ".pdf"), 
         plot = sct_gglist[[fnames]],
         h = fig.h, w = fig.w)
  
  cat(paste0(est_name, ".pdf\n"))
}

# all scatters in grid 
ord_labs <- sort(sct_labs$var_name)

ord_labs <- grep("(_raw|_voters|_vv|_postvoters)", ord_labs, value = TRUE)
stopifnot(length(ord_labs) == 20)  # for grid
ord_gg <- sct_gglist[ord_labs]

gg16 <- plot_grid(ord_gg[[01]], ord_gg[[02]], ord_gg[[04]], ord_gg[[03]],
                  ord_gg[[05]], ord_gg[[06]], ord_gg[[07]], NULL, 
                  ord_gg[[08]], ord_gg[[09]], ord_gg[[10]], NULL,
                  ord_gg[[11]], ord_gg[[12]], ord_gg[[14]], ord_gg[[13]],
                  ord_gg[[15]], ord_gg[[16]], ord_gg[[17]], NULL,
                  ord_gg[[18]], ord_gg[[19]], ord_gg[[20]], NULL,
                  ncol = 4)

save_plot("figures/summ/scatter_all.pdf", gg16, base_height = 3.25, ncol = 4, nrow = 6)


# more summary stats
df_diff <- df %>% 
  mutate(mudiff_hrc_vot = cces_pct_hrc_voters - pct_hrc_voters,
         mudiff_djt_vot = cces_pct_djt_voters - pct_djt_voters)


summary(df_diff$mudiff_djt_vot)
summary(df_diff$mudiff_hrc_vot)

cor(df_diff$mudiff_djt_vot, df_diff$mudiff_hrc_vot)

ggplot(df_diff, aes(x = mudiff_hrc_vot, y = mudiff_djt_vot, color = color, size = vap)) +
  geom_point(alpha = 0.8) +
  theme_bw() +
  scale_color_manual(values = colorvec) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_abline(intercept = 0, slope = -1) +
  coord_equal() +
  labs(y = expression(widehat(mu[Trump]) - mu[Trump]),
       x = expression(widehat(mu[Clinton]) - mu[Clinton])) +
  guides(color = FALSE, size = FALSE)
ggsave("figures/scatter/scatter_error_vs_error.pdf", h = fig.h, w = fig.w)



# Map -----

source("data/input/state_coords.R")
df_map <- left_join(df, st)

gg0 <- ggplot(df_map, aes(x = col, y = row, fill = color)) + 
  geom_tile(alpha = 0) +
  geom_tile(color = "white", alpha = 0.5, size = 1) +
  geom_text(color = "black", size = 2.75) +
  scale_fill_manual(values = colorvec) +
  scale_y_reverse() +
  coord_equal() +
  theme_minimal() +
  theme(panel.border = element_blank()) +
  theme(panel.grid = element_blank()) +  
  theme(panel.background = element_blank()) +
  theme(axis.ticks = element_blank()) +
  theme(axis.text = element_blank()) +
  labs(x = NULL, y = NULL, title = NULL) +
  guides(fill = FALSE, alpha = FALSE)



gg0 + aes(label = make_pct(effratio_hrc_vot)) +
  labs(title = eff_t[["hrc_vot"]])
ggsave("figures/map/map_hrc_vot.pdf", h = fig.h, w = mfig.w)

gg0 + aes(label = make_pct(effratio_hrc_vep)) +
  labs(title = eff_t[["hrc_vep"]])
ggsave("figures/map/map_hrc_vep.pdf", h = fig.h, w = mfig.w)

gg0 + aes(label = make_pct(effratio_djt_vot)) +
  labs(title = eff_t[["djt_vot"]])
ggsave("figures/map/map_djt_vot.pdf", h = fig.h, w = mfig.w)

gg0 + aes(label = make_pct(effratio_djt_vep)) +
  labs(title = eff_t[["djt_vep"]])
ggsave("figures/map/map_djt_vep.pdf", h = fig.h, w = mfig.w)

rm(gg0)

# the percentages as a dot/barplot --

# arrange
df_dot <-  df %>% 
  arrange(desc(pct_hrc_voters)) %>%
  mutate(st = forcats::as_factor(st))


gg0 <-  ggplot(df_dot, aes(x = st, y = effratio_hrc_vot, fill = color)) + 
  scale_y_continuous(name = NULL, label = percent, expand = c(0, 0)) +
  scale_fill_manual(values = colorvec) +
  geom_col(alpha = 0.8) +
  theme_bw() +
  theme(axis.text.x  = element_text(angle = 90, vjust = 0.5, size = 6),
        axis.text.y = element_text(size = 13),
        panel.grid.major.x = element_blank()) +
  guides(fill = FALSE)  +
  labs(x = "")


gg0 + aes(y = effratio_hrc_vot) +
  labs(title = eff_t[["hrc_vot"]])
ggsave("figures/bars/bars_hrc_vot.pdf", h = fig.h, w = mfig.w)

gg0 + aes(y = effratio_hrc_vep) +
  labs(title = eff_t[["hrc_vep"]])
ggsave("figures/bars/bars_hrc_vep.pdf", h = fig.h, w = mfig.w)

gg0 + aes(y = effratio_djt_vot) +
  scale_y_continuous(name = NULL, label = percent, expand = c(0, 0), limit = c(0, 1)) +
  labs(title = eff_t[["djt_vot"]])
ggsave("figures/bars/bars_djt_vot.pdf", h = fig.h, w = mfig.w)

gg0 + aes(y = effratio_djt_vep) +
  scale_y_continuous(name = NULL, label = percent, expand = c(0, 0), limit = c(0, 1)) +
  labs(title = eff_t[["djt_vep"]])
ggsave("figures/bars/bars_djt_vep.pdf", h = fig.h, w = mfig.w)



both <- left_join(old, df, by = c("state", "st", "color", "vap", "vep", "votes_hrc", "votes_djt", "tot_votes", "pct_djt_voters"))

ggplot(both, aes(x = cces_pct_djt_vv.x, y = cces_pct_djt_vv.y, color = color)) + 
  geom_point() + geom_text_repel(aes(label = st)) + geom_abline(intercept = 0, slope = 1) + 
  scale_color_manual(values = colorvec) + theme_bw() + 
  scale_x_continuous("CCES Trump Estimate (Old)", labels = percent) + 
  scale_y_continuous("CCES Trump Estimate (New)", labels = percent) 

ggplot(both, aes(x = 100*(cces_pct_djt_vv.x - pct_djt_voters), 
                 y = 100*(cces_pct_djt_vv.y - pct_djt_voters),
                 color = color)) + 
  geom_point() + geom_text_repel(aes(label = st)) + geom_abline(intercept = 0, slope = 1) + 
  scale_color_manual(values = colorvec) + theme_bw() + 
  scale_x_continuous("CCES Trump Polling Error (Old)", labels = unit_format(unit = "pp")) + 
  scale_y_continuous("CCES Trump Polling Error (New)", labels = unit_format(unit = "pp")) 


