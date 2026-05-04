# ══════════════════════════════════════════════════════════════════════════════
# NASCAR Race Preview — Shiny App
# SMGT 490 Capstone | Savan Patel
# ══════════════════════════════════════════════════════════════════════════════

library(shiny)
library(tidyverse)
library(randomForest)
library(ggplot2)
library(fmsb)
library(shinythemes)

# ── LOAD PRE-COMPUTED DATA ────────────────────────────────────────────────────
within_track_clusters <- readRDS("within_track_clusters.rds")
rf_enhanced           <- readRDS("rf_enhanced.rds")
rf_s1                 <- readRDS("rf_s1.rds")
rf_s2                 <- readRDS("rf_s2.rds")
enhanced_model_data   <- readRDS("enhanced_model_data.rds")
archetype_colors      <- readRDS("archetype_colors.rds")

# ── HELPER DATA ───────────────────────────────────────────────────────────────
track_list <- enhanced_model_data |>
  distinct(Track, track_type) |>
  arrange(track_type, Track)

drivers <- sort(unique(within_track_clusters$Driver))

archetype_descriptions <- tibble(
  archetype_label = c(
    "Stage Hunting Chargers", "Conservative Managers", "Position Climbers",
    "Points Survivors", "Road Course Racers", "Road Course Strugglers",
    "Crashers", "Stage Point Collectors", "Late Race Movers",
    "Aggressive Drafters", "Pack Racers", "Survive and Advance"
  ),
  track_type = c(
    "Intermediate", "Intermediate", "Intermediate",
    "Road Course", "Road Course", "Road Course",
    "Short Track", "Short Track", "Short Track",
    "Superspeedway", "Superspeedway", "Superspeedway"
  ),
  description = c(
    "Gain positions and hunt stage points aggressively. Inconsistent but fast.",
    "Manage tires and avoid risk. Very consistent but rarely lead.",
    "Start at the back and move up. Ignore stage points entirely.",
    "Oval specialists just surviving road courses. Play it safe.",
    "Fully engaged on road courses. Gain positions and earn stage points.",
    "Struggle with road course demands. High attrition risk.",
    "Aggressive but unreliable on short tracks. High DNF rate.",
    "Methodical stage point collectors. Low DNF, consistent results.",
    "Save tires for late-race moves. Avoid stage points, gain late.",
    "Push hard in the draft and hunt stage points. High DNF risk.",
    "Deep in the pack. High variance and very high DNF rate.",
    "Play it conservative on superspeedways. Let attrition work for them."
  )
)

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- navbarPage(
  title = "🏁 NASCAR Behavioral Archetypes",
  theme = shinytheme("flatly"),
  
  # ── TAB 1: RACE PREVIEW ───────────────────────────────────────────────────
  tabPanel("Race Preview",
           sidebarLayout(
             sidebarPanel(
               h4("Select a Track"),
               selectInput("track_select", "Track:",
                           choices = sort(unique(track_list$Track)),
                           selected = "Charlotte Motor Speedway"),
               hr(),
               uiOutput("track_type_badge"),
               br(),
               h5("About this prediction"),
               p("Predicted finishing order is based on each driver's behavioral
          archetype at this track type, historical relative performance,
          recent form (last 5 races), and manufacturer.",
                 style = "font-size: 12px; color: #666;"),
               br(),
               p("Model accuracy across 71 test races (2023-2024):",
                 style = "font-size: 12px; color: #555; font-weight: bold;"),
               tags$ul(
                 tags$li("Top-5 overlap: 38.6%", style = "font-size: 12px;"),
                 tags$li("Top-10 overlap: 56.8%", style = "font-size: 12px;"),
                 tags$li("Championship standing correlation: 0.72-0.83",
                         style = "font-size: 12px;")
               )
             ),
             mainPanel(
               h3(textOutput("race_title")),
               plotOutput("race_prediction_plot", height = "750px"),
               br(),
               h4("Historical Archetype Performance at This Track Type"),
               plotOutput("archetype_perf_plot", height = "280px")
             )
           )
  ),
  
  # ── TAB 2: DRIVER EXPLORER ────────────────────────────────────────────────
  tabPanel("Driver Explorer",
           sidebarLayout(
             sidebarPanel(
               h4("Select a Driver"),
               selectInput("driver_select", "Driver:",
                           choices = drivers,
                           selected = "Chase Elliott"),
               hr(),
               h5("Behavioral Adaptability"),
               uiOutput("driver_adaptability_badge"),
               br(),
               h5("Archetype by Track Type"),
               tableOutput("driver_archetype_table")
             ),
             mainPanel(
               h3(textOutput("driver_title")),
               plotOutput("driver_archetype_tiles", height = "130px"),
               br(),
               fluidRow(
                 column(6, plotOutput("driver_rel_finish_plot", height = "320px")),
                 column(6, plotOutput("driver_radar_plot",      height = "320px"))
               )
             )
           )
  ),
  
  # ── TAB 3: ARCHETYPE BROWSER ──────────────────────────────────────────────
  tabPanel("Archetype Browser",
           sidebarLayout(
             sidebarPanel(
               h4("Filter"),
               selectInput("track_type_filter", "Track Type:",
                           choices = c("All", "Intermediate", "Road Course",
                                       "Short Track", "Superspeedway"),
                           selected = "All"),
               hr(),
               h5("What are archetypes?"),
               p("Each track type has 3 behavioral archetypes identified by K-Means
          clustering. They describe HOW drivers race relative to the field —
          not how good they are overall.",
                 style = "font-size: 12px; color: #666;"),
               br(),
               p("Most drivers shift between 2-3 archetypes depending on track type,
          showing genuine behavioral adaptation.",
                 style = "font-size: 12px; color: #666;")
             ),
             mainPanel(
               h3("Driver Archetypes by Track Type"),
               p("Drivers ordered by intermediate track relative finish performance (best at top).",
                 style = "color: #666; font-size: 13px;"),
               plotOutput("heatmap_plot", height = "750px"),
               br(),
               h4("Archetype Descriptions"),
               tableOutput("archetype_desc_table")
             )
           )
  ),
  
  # ── TAB 4: ABOUT ──────────────────────────────────────────────────────────
  tabPanel("About",
           fluidRow(
             column(8, offset = 2,
                    br(),
                    h3("NASCAR Behavioral Archetype Analysis"),
                    h4("SMGT 490 Capstone | Savan Patel | Rice University 2026"),
                    hr(),
                    h4("Research Question"),
                    p("Can NASCAR Cup Series drivers be clustered into distinct in-race
          behavioral style patterns based on their relative performance
          tendencies, and do these styles predict race outcomes across
          different track types?"),
                    h4("Methodology"),
                    tags$ul(
                      tags$li("Data: NASCAR Cup Series 2017-2024 via nascaR.data package"),
                      tags$li("Sample: 32 full-time drivers, 6,992 driver-race entries"),
                      tags$li("Clustering: K-Means (k=3) within each of 4 track types independently"),
                      tags$li("Features: Relative positions gained, relative stage points,
                  finish variance, DNF rate — all field-normalized per race"),
                      tags$li("Validation: Bootstrap stability (Jaccard 0.61-0.89),
                  ANOVA p < 0.001 across all track types"),
                      tags$li("Prediction: Random Forest — RMSE 10.47,
                  championship standing correlation 0.72-0.83")
                    ),
                    h4("Key Findings"),
                    tags$ul(
                      tags$li("12 distinct behavioral archetypes across 4 track types"),
                      tags$li("62.5% of drivers shift between 2 behavioral styles by track type"),
                      tags$li("Behavioral archetype ranks 3rd in feature importance for race prediction"),
                      tags$li("Superspeedways show the smallest performance gap — the 'equalizer effect'"),
                      tags$li("Chase Elliott's road course advantage (-8.46 relative finish)
                  is the strongest track specialization in the dataset")
                    ),
                    h4("Limitations"),
                    tags$ul(
                      tags$li("Race-level data limits precision — lap-level data would allow
                  more direct behavioral measurement"),
                      tags$li("Small sample (32 drivers) affects cluster stability"),
                      tags$li("Random Forest compresses predicted finish positions toward the mean"),
                      tags$li("Part-time specialists excluded by full-time filter")
                    ),
                    hr(),
                    p("Data: nascaR.data (Grealis, 2024) | DriverAverages.com",
                      style = "color: #888; font-size: 12px;")
             )
           )
  )
)

# ── SERVER ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  # ── HELPERS ───────────────────────────────────────────────────────────────
  selected_track_type <- reactive({
    track_list |>
      filter(Track == input$track_select) |>
      pull(track_type) |>
      first()
  })
  
  # ── RACE PREVIEW ──────────────────────────────────────────────────────────
  output$track_type_badge <- renderUI({
    tt <- selected_track_type()
    color <- switch(tt,
                    "Intermediate"  = "#3498db",
                    "Short Track"   = "#e74c3c",
                    "Superspeedway" = "#2ecc71",
                    "Road Course"   = "#f39c12",
                    "#95a5a6"
    )
    tags$div(
      tags$span(tt,
                style = paste0(
                  "background-color:", color, "; color: white; padding: 4px 12px;",
                  "border-radius: 12px; font-weight: bold; font-size: 13px;"
                )
      )
    )
  })
  
  output$race_title <- renderText({
    paste("Predicted Race Order —", input$track_select)
  })
  
  output$race_prediction_plot <- renderPlot({
    tt <- selected_track_type()
    
    drivers_at_tt <- within_track_clusters |>
      filter(track_type == tt)
    
    # Use driver's avg relative finish to simulate a starting grid
    set.seed(42)
    race_sim <- drivers_at_tt |>
      mutate(
        Start          = rank(avg_rel_finish + runif(n(), -3, 3),
                              ties.method = "random"),
        track_type     = factor(tt,
                                levels = levels(enhanced_model_data$track_type)),
        Season         = factor("2024",
                                levels = levels(enhanced_model_data$Season)),
        Make           = factor("Chevrolet",
                                levels = levels(enhanced_model_data$Make)),
        recent_form_5  = avg_rel_finish +
          mean(enhanced_model_data$Finish, na.rm = TRUE),
        track_hist_avg = avg_rel_finish +
          mean(enhanced_model_data$Finish, na.rm = TRUE),
        archetype_label = factor(as.character(archetype_label),
                                 levels = levels(enhanced_model_data$archetype_label))
      )
    
    race_sim$predicted_finish <- predict(rf_enhanced, newdata = race_sim)
    
    results <- race_sim |>
      arrange(predicted_finish) |>
      mutate(
        predicted_rank   = row_number(),
        predicted_finish = round(predicted_finish, 1),
        Driver           = fct_reorder(Driver, desc(predicted_rank))
      )
    
    ggplot(results,
           aes(x = predicted_finish, y = Driver,
               fill = as.character(archetype_label))) +
      geom_col(show.legend = TRUE) +
      geom_text(aes(label = paste0("#", predicted_rank, "  ", Driver)),
                x = 0.3, hjust = 0, color = "white",
                fontface = "bold", size = 3.5) +
      geom_text(aes(label = round(predicted_finish, 1)),
                hjust = -0.2, size = 3, color = "grey30") +
      scale_fill_manual(values = archetype_colors,
                        name   = paste(tt, "Archetype")) +
      scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
      labs(x       = "Predicted Finish Position",
           y       = NULL,
           caption = "Based on behavioral archetype, historical performance,
                      recent form & manufacturer") +
      theme_minimal(base_size = 12) +
      theme(
        axis.text.y        = element_blank(),
        panel.grid.major.y = element_blank(),
        legend.position    = "bottom",
        plot.caption       = element_text(color = "grey50", size = 9)
      )
  })
  
  output$archetype_perf_plot <- renderPlot({
    tt <- selected_track_type()
    
    bar_data <- within_track_clusters |>
      filter(track_type == tt) |>
      group_by(archetype_label) |>
      summarise(avg_rel_finish = mean(avg_rel_finish, na.rm = TRUE),
                .groups = "drop")
    
    ggplot(bar_data,
           aes(x = reorder(archetype_label, avg_rel_finish),
               y = avg_rel_finish,
               fill = as.character(archetype_label))) +
      geom_col(show.legend = FALSE) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
      geom_text(aes(label = round(avg_rel_finish, 1)),
                hjust = ifelse(bar_data$avg_rel_finish < 0, 1.2, -0.2),
                size = 4, fontface = "bold") +
      scale_fill_manual(values = archetype_colors) +
      coord_flip() +
      labs(title    = paste("Historical Performance by Archetype —", tt),
           subtitle = "Negative = better than field average",
           x        = NULL,
           y        = "Avg Relative Finish vs Field") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.major.y = element_blank(),
            plot.title = element_text(face = "bold"))
  })
  
  # ── DRIVER EXPLORER ───────────────────────────────────────────────────────
  driver_data <- reactive({
    within_track_clusters |>
      filter(Driver == input$driver_select) |>
      mutate(track_type = factor(track_type,
                                 levels = c("Short Track", "Intermediate",
                                            "Superspeedway", "Road Course")))
  })
  
  output$driver_title <- renderText({
    paste(input$driver_select, "— Behavioral Profile")
  })
  
  output$driver_adaptability_badge <- renderUI({
    d      <- driver_data()
    n_uniq <- n_distinct(d$cluster)
    label  <- case_when(
      n_uniq == 1 ~ "Rigid — 1 style",
      n_uniq == 2 ~ "Moderate — 2 styles",
      n_uniq == 3 ~ "Highly Adaptive — 3 styles",
      TRUE        ~ "—"
    )
    color <- case_when(
      n_uniq == 1 ~ "#e74c3c",
      n_uniq == 2 ~ "#f39c12",
      n_uniq == 3 ~ "#2ecc71",
      TRUE        ~ "#95a5a6"
    )
    tags$div(
      tags$span(label,
                style = paste0(
                  "background-color:", color, "; color: white; padding: 4px 12px;",
                  "border-radius: 12px; font-weight: bold; font-size: 13px;"
                )
      )
    )
  })
  
  output$driver_archetype_table <- renderTable({
    driver_data() |>
      select(
        `Track Type`      = track_type,
        `Archetype`       = archetype_label,
        `Avg Rel Finish`  = avg_rel_finish
      ) |>
      mutate(`Avg Rel Finish` = round(`Avg Rel Finish`, 2))
  })
  
  output$driver_archetype_tiles <- renderPlot({
    d <- driver_data()
    ggplot(d, aes(x = track_type, y = 1, fill = archetype_label)) +
      geom_tile(color = "white", linewidth = 2, height = 0.6) +
      geom_text(aes(label = archetype_label),
                fontface = "bold", color = "white", size = 4) +
      scale_fill_manual(values = archetype_colors) +
      labs(title = paste(input$driver_select,
                         "— Archetype by Track Type"),
           x = NULL, y = NULL) +
      theme_minimal() +
      theme(
        axis.text.y     = element_blank(),
        legend.position = "none",
        panel.grid      = element_blank(),
        plot.title      = element_text(face = "bold", size = 13),
        axis.text.x     = element_text(size = 12, face = "bold")
      )
  })
  
  output$driver_rel_finish_plot <- renderPlot({
    d <- driver_data()
    ggplot(d, aes(x = track_type, y = avg_rel_finish,
                  fill = archetype_label)) +
      geom_col(show.legend = FALSE) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
      geom_text(aes(label = round(avg_rel_finish, 2)),
                vjust = ifelse(d$avg_rel_finish < 0, 1.5, -0.5),
                fontface = "bold", size = 4) +
      scale_fill_manual(values = archetype_colors) +
      labs(title    = "Avg Relative Finish by Track Type",
           subtitle = "Negative = better than field average",
           x        = NULL,
           y        = "Avg Relative Finish") +
      theme_minimal(base_size = 12) +
      theme(plot.title = element_text(face = "bold"))
  })
  
  output$driver_radar_plot <- renderPlot({
    d <- driver_data()
    
    all_ranges <- within_track_clusters |>
      summarise(
        pos_min   = min(avg_rel_pos_gained),
        pos_max   = max(avg_rel_pos_gained),
        stage_min = min(avg_rel_stage_pts),
        stage_max = max(avg_rel_stage_pts),
        var_min   = min(rel_finish_variance),
        var_max   = max(rel_finish_variance),
        dnf_min   = min(dnf_rate),
        dnf_max   = max(dnf_rate)
      )
    
    radar_norm <- d |>
      mutate(
        pos_n   = (avg_rel_pos_gained  - all_ranges$pos_min) /
          (all_ranges$pos_max  - all_ranges$pos_min),
        stage_n = (avg_rel_stage_pts   - all_ranges$stage_min) /
          (all_ranges$stage_max - all_ranges$stage_min),
        var_n   = (rel_finish_variance - all_ranges$var_min) /
          (all_ranges$var_max  - all_ranges$var_min),
        dnf_n   = (dnf_rate            - all_ranges$dnf_min) /
          (all_ranges$dnf_max  - all_ranges$dnf_min)
      ) |>
      select(track_type, pos_n, stage_n, var_n, dnf_n) |>
      column_to_rownames("track_type")
    
    colnames(radar_norm) <- c("Pos Gained", "Stage Pts",
                              "Finish Var", "DNF Rate")
    
    radar_data <- rbind(rep(1, 4), rep(0, 4), radar_norm)
    
    track_colors <- c(
      "Short Track"   = "#e74c3c",
      "Intermediate"  = "#3498db",
      "Superspeedway" = "#2ecc71",
      "Road Course"   = "#f39c12"
    )
    
    available <- rownames(radar_norm)
    cols      <- track_colors[available]
    
    par(mar = c(1, 1, 2, 1))
    radarchart(radar_data, axistype = 1,
               pcol  = cols,
               pfcol = adjustcolor(cols, alpha.f = 0.15),
               plwd  = 2.5,
               cglcol = "grey", cglty = 1, vlcex = 0.9,
               title = "Behavioral Profile by Track Type")
    legend("topright", legend = available, col = cols,
           lty = 1, lwd = 2, bty = "n", cex = 0.8)
  })
  
  # ── ARCHETYPE BROWSER ─────────────────────────────────────────────────────
  output$heatmap_plot <- renderPlot({
    plot_data <- within_track_clusters |>
      select(Driver, track_type, archetype_label, avg_rel_finish)
    
    if (input$track_type_filter != "All") {
      plot_data <- plot_data |>
        filter(track_type == input$track_type_filter)
    }
    
    plot_data <- plot_data |>
      mutate(
        Driver     = fct_reorder(
          Driver,
          avg_rel_finish * (track_type == "Intermediate"),
          .fun = sum
        ),
        track_type = factor(track_type,
                            levels = c("Short Track", "Intermediate",
                                       "Superspeedway", "Road Course"))
      )
    
    ggplot(plot_data,
           aes(x = track_type, y = Driver, fill = archetype_label)) +
      geom_tile(color = "white", linewidth = 0.5) +
      geom_text(aes(label = archetype_label), size = 2.8,
                color = "white", fontface = "bold") +
      scale_fill_manual(values = archetype_colors) +
      labs(x = NULL, y = NULL) +
      theme_minimal(base_size = 11) +
      theme(
        legend.position = "none",
        panel.grid      = element_blank(),
        axis.text.y     = element_text(size = 9),
        axis.text.x     = element_text(size = 11, face = "bold")
      )
  })
  
  output$archetype_desc_table <- renderTable({
    desc <- archetype_descriptions
    
    if (input$track_type_filter != "All") {
      desc <- desc |>
        filter(track_type == input$track_type_filter)
    }
    
    desc |>
      select(
        `Track Type`  = track_type,
        `Archetype`   = archetype_label,
        `Description` = description
      )
  })
}

# ── RUN ───────────────────────────────────────────────────────────────────────
shinyApp(ui = ui, server = server)