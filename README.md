# Behavioral Archetypes of NASCAR Cup Series Drivers and Applications to Race Prediction

**Savan Patel | SMGT 490 Capstone | Rice University | Spring 2026**

---

## Overview

This project applies unsupervised machine learning to identify behavioral archetypes among
NASCAR Cup Series drivers, shifting the analytical focus from outcome prediction to
process-oriented style classification. Using race-level data from 2017-2024, twelve distinct
behavioral archetypes were identified across four track types, and a Random Forest model
incorporating these archetypes predicted race finishing positions with an RMSE of 10.47 and
championship standings with a Spearman correlation of 0.72-0.83.

## Live Application

[NASCAR Archetype Explorer](https://savanpatel.shinyapps.io/nascar-archetypes/)

The interactive R Shiny app offers three features:
- **Race Preview** — predicted finishing order for any Cup Series track with archetype labels
- **Driver Explorer** — individual driver profiles with behavioral radar charts
- **Archetype Browser** — full driver-by-track-type heatmap with archetype descriptions

## Repository Contents

| File | Description |
|------|-------------|
| `NASCAR.Rmd` | Full analysis workflow: data processing, clustering, and prediction modeling |
| `app.R` | R Shiny web application source code |
| `Final_Report.pdf` | Final research paper |

## Data

Data sourced from the `nascaR.data` R package (Grealis, 2024) via DriverAverages.com.
- NASCAR Cup Series seasons: 2017-2024
- 32 full-time drivers
- 6,992 driver-race entries
- Four track types: short tracks, intermediates, superspeedways, and road courses

## Methods

Behavioral features were engineered relative to the field within each race to isolate style from
equipment quality. Four features were used: relative positions gained, relative stage points,
relative finish variance, and DNF rate. K-Means clustering (k=3) was applied independently
within each track type, producing twelve archetypes in total. A Random Forest regression model
trained on 2017-2022 data was evaluated on a 2023-2024 holdout set.

## Key Findings

- 62.5% of drivers exhibited different behavioral styles across track types, demonstrating
  genuine racing adaptation rather than a single fixed identity
- Behavioral archetype contributed a 10.1% increase in MSE when removed from the
  prediction model, confirming it adds meaningful signal beyond starting position and
  historical performance
- The model correctly identified 38.6% of top-5 finishers per race versus 12.5% by chance

## Archetypes by Track Type

| Track Type | Archetypes |
|------------|------------|
| Short Track | Stage Point Collectors, Late Race Movers, Crashers |
| Intermediate | Stage Hunting Chargers, Conservative Managers, Position Climbers |
| Road Course | Road Course Racers, Points Survivors, Road Course Strugglers |
| Superspeedway | Aggressive Drafters, Pack Racers, Survive and Advance |
