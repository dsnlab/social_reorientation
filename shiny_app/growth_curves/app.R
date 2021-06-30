#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(papayaWidget)
library(fslr)
library(shinythemes)
library(shinyRadioMatrix)

mni_brain = readnii('data/MNI152_T1_1mm_brain.nii')
craddock400 = readnii('data/craddock_400.nii.gz')
parcellation_key = read.csv("data/parcellation_key.csv", stringsAsFactors = FALSE)

neuro_data = readRDS("data/plot_data.RDS") %>%
    rename("mean_beta" = expected) %>%
    filter(!label == "other") %>%
    left_join(., parcellation_key)

neuro_data_raw = readRDS("data/plot_data_raw.RDS") %>%
    rename("mean_beta" = beta_std) %>%
    filter(!label == "other") %>%
    left_join(., parcellation_key)

self_parcel_num = c(5, 17, 28, 47, 52, 66, 116, 147, 152, 156, 184, 198, 207, 225, 249, 292, 309, 354, 380)
social_parcel_num = c(18, 23, 29, 49, 54, 59, 62, 63, 67, 76, 111, 114, 139, 143, 146, 150, 178, 179, 189, 203,
                   212, 224, 229, 236, 238, 239, 245, 250, 259, 266, 271, 301, 305, 310, 322, 324, 328, 331,
                   333, 342, 343, 350, 374, 391)

self_parcels = sort(unique(filter(neuro_data, parcellation %in% self_parcel_num)$parcellation_name))
social_parcels = sort(unique(filter(neuro_data, parcellation %in% social_parcel_num)$parcellation_name))

pal_self_other = c("#FFA90A", "#247BA0")
pal_social_academic = c("#63647E", "#F25F5C")
pal_wave = c("#693668", "#A74482", "#F84AA7")
pal_label = c("#47A8BD", "#DBC057", "#FF3366")
pal_gender = c("#70c1b3","#247BA0")

parcel_labeller = labeller(label = c('social' = 'social parcels', 'other' = 'control parcels', 'self' = 'self parcels'),
                           domain = c('social' = 'social domain', 'academic' = 'academic domain'),
                           wave = c("t1" = "wave 1", "t2" = "wave 2", "t3" = "wave 3"))

label_df = expand.grid(label = c("social", "self", "other"),
                       target = c("self", "other"),
                       domain = c("social", "academic"),
                       age = 13,
                       expected_avg = 1,
                       expected_diff = 1)

dcbw = theme_classic() +
    theme(text = element_text(size = 14, family = "Futura Medium", color = "black"),
          panel.background = element_blank(),
          plot.background = element_blank(),
          strip.background = element_blank(),
          strip.text = element_text(size = 14),
          legend.background = element_rect(fill = NA, color = NA),
          axis.line = element_line(color = "black"),
          axis.text = element_text(color = "black"),
          panel.grid.minor = element_blank())

ui <- fluidPage(
    theme = shinytheme("united"),

    titlePanel("Developmental trajectory visualizer"),
    p("This app is a companion to the analyses reported in the manuscript:"),
    tags$a(href="https://psyarxiv.com/8eyf5/", "Testing the adolescent social reorientation model using hierarchical growth curve modeling with parcellated fMRI data"),
    p("Authors: Cosme, D., Flournoy, J. C., Livingston, J. L., Dapretto, M., Lieberman, M. D., & Pfeifer, J. H."),
    HTML("<br>"),
    p("In the manuscript, parcels were labelled as supporting self-focused ('self') or other-oriented ('social') cognition; all other parcels were labelled as control regions ('control'). In this app, you can relabel parcels as self or social to examine how this affects the estimated developmental trajectory."),
    p("After relabelling the parcels, a new plot will be generated in the 'Modified' tab. The models are not refit. Instead, when selecting the fitted data to plot, we use the model-expected trajectories for each parcel to re-compute the mean population trajectory for effects of interest as a fast, approximate indication model sensitivity to choice of parcel label. When selecting the raw data to plot, the mean trend line is estimated from this data directly (i.e., not using information from the model). For comparison, a plot with the original labeling scheme is provided in 'Original (fitted)'."),
    HTML("<br>"),

    sidebarPanel(width = 4,
        # parcellation atlas
        h3("Craddock 400 parcellation atlas"),
        p("Use this visualizer to find the parcels listed below. Each parcel has a unique number. By clicking on the colored overlay icon, you can filter the scale range to find a specific parcel (e.g. filter 1-3 to find parcel 2)."),
        papayaOutput("brain"),

        # select data
        h3("Select the data to plot"),
        p("Select either the raw (unfitted) data or the fitted data from the model reported in the manuscript."),
        selectInput(inputId = "dataset",
                    label = "",
                    choices = list("Fitted", "Raw")),

        # select parcels
        h3("Select the parcels to plot"),
        p("Select whether a given parcel is labelled as self or social (i.e., not both). The default is to plot using the labels reported in the manuscript."),
        radioMatrixInput(inputId = 'parcel_assignment',
                         rowIDs = c(social_parcels, self_parcels),
                         rowLLabels = rep("", length(c(social_parcels, self_parcels))),
                         rowRLabels = NULL,
                         choices = c('Social', 'Self', 'Neither'),
                         selected = c(rep('Social', length(social_parcels)), rep('Self', length(self_parcels))),
                         choiceNames = NULL,
                         choiceValues = NULL,
                         labelsWidth = list(NULL, NULL)
                         ),
),
    mainPanel(

        tabsetPanel(type = "tabs",
                    tabPanel("Main effect: Domain",
                             tabsetPanel(
                                 tabPanel("Modified", plotOutput("plot_social")),
                                 tabPanel("Original (fitted)", plotOutput("plot_social_orig"))
                                )
                             ),
                    tabPanel("Main effect: Target",
                             tabsetPanel(
                                 tabPanel("Modified", plotOutput("plot_self")),
                                 tabPanel("Original (fitted)", plotOutput("plot_self_orig"))
                             )
                    ),
                    tabPanel("Interaction: Domain x Target",
                             tabsetPanel(
                                 tabPanel("Modified", plotOutput("plot_interaction")),
                                 tabPanel("Original (fitted)", plotOutput("plot_interaction_orig"))
                             )
                    ),
                    tabPanel("Interaction: Social > Academic by Target",
                             tabsetPanel(
                                 tabPanel("Modified", plotOutput("plot_interaction_social")),
                                 tabPanel("Original (fitted)", plotOutput("plot_interaction_social_orig"))
                             )
                    ),
                    tabPanel("Interaction: Self > Other by Domain",
                             tabsetPanel(
                                 tabPanel("Modified", plotOutput("plot_interaction_self")),
                                 tabPanel("Original (fitted)", plotOutput("plot_interaction_self_orig"))
                             )
                    )
                )
        )
)

server <- function(input, output, session) {
    fitted_data <- reactive({
        neuro_data
    })

    parcel_data <- reactive({
        req(input$parcel_assignment)
        req(input$dataset)

        if (input$dataset == "Raw") {
            data = neuro_data_raw
        } else {
            data = neuro_data
        }

        data %>%
            filter(parcellation_name %in% names(input$parcel_assignment[input$parcel_assignment %in% c('Social', 'Self')])) %>%
            mutate(label = unlist(input$parcel_assignment[parcellation_name]),
                   label = case_when(label == 'Social' ~ 'social',
                                     label == 'Self' ~ 'self',
                                     label == 'Neither' ~ NA_character_))
    })

    output$brain <- renderPapaya({
        x = papaya(list(mni_brain, craddock400), hide_controls = TRUE)
        x$elementId = NULL
        x
    })

    output$plot_social_orig <- renderPlot({
        fitted_data() %>%
        distinct(parcellation, target, domain, age, label, .keep_all = T) %>%
        group_by(subjectID, age, label, domain, parcellation) %>%
        ggplot(aes(x = age, y = mean_beta, color = domain)) +
        geom_smooth(aes(group = interaction(parcellation, domain)), size = .1,
                    method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
        geom_smooth(aes(fill = domain), method = "lm", formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
        scale_color_manual(name = "", values = pal_social_academic) +
        scale_fill_manual(name = "", values = pal_social_academic) +
        scale_x_continuous(breaks = c(10, 13, 16)) +
        facet_grid(~label, labeller = parcel_labeller) +
        labs(x = "\nage", y = "mean predicted BOLD signal value\n") +
        dcbw +
        theme(legend.position = c(.1, .9),
              legend.spacing.y = unit(.01, 'cm'),
              legend.margin = unit(0, "cm"))
    })

    output$plot_social <- renderPlot({
        parcel_data() %>%
            distinct(parcellation, target, domain, age, label, .keep_all = T) %>%
            group_by(subjectID, age, label, domain, parcellation) %>%
            ggplot(aes(x = age, y = mean_beta, color = domain)) +
            geom_smooth(aes(group = interaction(parcellation, domain)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = domain), method = "lm", formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(name = "", values = pal_social_academic) +
            scale_fill_manual(name = "", values = pal_social_academic) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~label, labeller = parcel_labeller) +
            labs(x = "\nage", y = "mean predicted BOLD signal value\n") +
            dcbw +
            theme(legend.position = c(.1, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(0, "cm"))
    })

    output$plot_self_orig <- renderPlot({
        fitted_data() %>%
            distinct(parcellation, target, domain, age, label, .keep_all = T) %>%
            group_by(subjectID, age, label, target, parcellation) %>%
            ggplot(aes(x = age, y = mean_beta, color = target)) +
            geom_smooth(aes(group = interaction(parcellation, target)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = target), method = "lm", formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(name = "", values = pal_self_other) +
            scale_fill_manual(name = "", values = pal_self_other) +
            scale_size_manual(values = c(.1, .1)) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~label, labeller = parcel_labeller) +
            labs(x = "\nage", y = "mean predicted BOLD signal value\n") +
            dcbw +
            theme(legend.position = c(.1, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(0, "cm"))
    })

    output$plot_self <- renderPlot({
        parcel_data() %>%
            distinct(parcellation, target, domain, age, label, .keep_all = T) %>%
            group_by(subjectID, age, label, target, parcellation) %>%
            ggplot(aes(x = age, y = mean_beta, color = target)) +
            geom_smooth(aes(group = interaction(parcellation, target)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = target), method = "lm", formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(name = "", values = pal_self_other) +
            scale_fill_manual(name = "", values = pal_self_other) +
            scale_size_manual(values = c(.1, .1)) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~label, labeller = parcel_labeller) +
            labs(x = "\nage", y = "mean predicted BOLD signal value\n") +
            dcbw +
            theme(legend.position = c(.1, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(0, "cm"))
    })

    output$plot_interaction_orig <- renderPlot({
        fitted_data() %>%
            distinct(parcellation, target, domain, age, mean_beta, label, .keep_all = T) %>%
            ggplot(aes(x = age, y = mean_beta, group = interaction(target, domain), color = domain, linetype = target)) +
            geom_smooth(aes(group = interaction(parcellation, domain, target)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = domain), method = 'lm', formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(values = pal_social_academic) +
            scale_fill_manual(values = pal_social_academic) +
            scale_size_manual(values = c(.05, .05)) +
            scale_linetype_manual(name = "", values = c("dotted", "solid")) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~ label, labeller = parcel_labeller) +
            labs(x = '\nage', y = 'mean standardized parameter estimate\n',
                 color = '', linetype = '', fill = '') +
            guides(linetype = guide_legend(override.aes = list(color = "black"))) +
            dcbw +
            theme(legend.position = c(.2, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(.5, "cm"),
                  legend.direction = "vertical",
                  legend.box = "horizontal")
    })

    output$plot_interaction <- renderPlot({
        parcel_data() %>%
            distinct(parcellation, target, domain, age, mean_beta, label, .keep_all = T) %>%
            ggplot(aes(x = age, y = mean_beta, group = interaction(target, domain), color = domain, linetype = target)) +
            geom_smooth(aes(group = interaction(parcellation, domain, target)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = domain), method = 'lm', formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(values = pal_social_academic) +
            scale_fill_manual(values = pal_social_academic) +
            scale_size_manual(values = c(.05, .05)) +
            scale_linetype_manual(name = "", values = c("dotted", "solid")) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~ label, labeller = parcel_labeller) +
            labs(x = '\nage', y = 'mean standardized parameter estimate\n',
                 color = '', linetype = '', fill = '') +
            guides(linetype = guide_legend(override.aes = list(color = "black"))) +
            dcbw +
            theme(legend.position = c(.2, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(.5, "cm"),
                  legend.direction = "vertical",
                  legend.box = "horizontal")
    })

    output$plot_interaction_social_orig = renderPlot({
        fitted_data() %>%
            group_by(subjectID, age, label, target, domain, parcellation) %>%
            mutate(mean_beta_avg = mean(mean_beta, na.rm = TRUE)) %>%
            select(subjectID, age, label, target, domain, mean_beta_avg) %>%
            unique() %>%
            spread(domain, mean_beta_avg) %>%
            mutate(avg_diff = social - academic) %>%
            distinct(parcellation, age, label, .keep_all = T) %>%
            ggplot(aes(x = age, y = avg_diff, color = target)) +
            geom_smooth(aes(group = interaction(parcellation, target)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = target), method = 'lm', formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(values = pal_self_other) +
            scale_fill_manual(values = pal_self_other) +
            scale_size_manual(values = c(.1, .1)) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~ label, labeller = parcel_labeller) +
            labs(x = '\nage', y = 'mean standardized parameter estimate\n',
                 color = '', fill = '') +
            dcbw +
            theme(legend.position = c(.1, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(0, "cm"))
    })

    output$plot_interaction_social = renderPlot({
        parcel_data() %>%
            group_by(subjectID, age, label, target, domain, parcellation) %>%
            mutate(mean_beta_avg = mean(mean_beta, na.rm = TRUE)) %>%
            select(subjectID, age, label, target, domain, mean_beta_avg) %>%
            unique() %>%
            spread(domain, mean_beta_avg) %>%
            mutate(avg_diff = social - academic) %>%
            distinct(parcellation, age, label, .keep_all = T) %>%
            ggplot(aes(x = age, y = avg_diff, color = target)) +
            geom_smooth(aes(group = interaction(parcellation, target)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = target), method = 'lm', formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(values = pal_self_other) +
            scale_fill_manual(values = pal_self_other) +
            scale_size_manual(values = c(.1, .1)) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~ label, labeller = parcel_labeller) +
            labs(x = '\nage', y = 'mean standardized parameter estimate\n',
                 color = '', fill = '') +
            dcbw +
            theme(legend.position = c(.1, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(0, "cm"))
    })

    output$plot_interaction_self_orig = renderPlot({
        fitted_data() %>%
            group_by(subjectID, age, label, domain, target, parcellation) %>%
            mutate(mean_beta_avg = mean(mean_beta, na.rm = TRUE)) %>%
            select(subjectID, age, label, domain, target, mean_beta_avg) %>%
            unique() %>%
            spread(target, mean_beta_avg) %>%
            mutate(avg_diff = self - other) %>%
            distinct(parcellation, age, label, .keep_all = T) %>%
            ggplot(aes(x = age, y = avg_diff, color = domain)) +
            geom_smooth(aes(group = interaction(parcellation, domain)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = domain), method = 'lm', formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(values = pal_social_academic) +
            scale_fill_manual(values = pal_social_academic) +
            scale_size_manual(values = c(.1, .1)) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~ label, labeller = parcel_labeller) +
            labs(x = '\nage', y = 'mean standardized parameter estimate\n',
                 color = '', fill = '') +
            dcbw +
            theme(legend.position = c(.1, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(0, "cm"))
    })

    output$plot_interaction_self = renderPlot({
        parcel_data() %>%
            group_by(subjectID, age, label, domain, target, parcellation) %>%
            mutate(mean_beta_avg = mean(mean_beta, na.rm = TRUE)) %>%
            select(subjectID, age, label, domain, target, mean_beta_avg) %>%
            unique() %>%
            spread(target, mean_beta_avg) %>%
            mutate(avg_diff = self - other) %>%
            distinct(parcellation, age, label, .keep_all = T) %>%
            ggplot(aes(x = age, y = avg_diff, color = domain)) +
            geom_smooth(aes(group = interaction(parcellation, domain)), size = .1,
                        method = "lm", formula = y ~ poly(x, 2), se = FALSE, show.legend = FALSE) +
            geom_smooth(aes(fill = domain), method = 'lm', formula = y ~ poly(x, 2), size = 1.2, se = FALSE) +
            scale_color_manual(values = pal_social_academic) +
            scale_fill_manual(values = pal_social_academic) +
            scale_size_manual(values = c(.1, .1)) +
            scale_x_continuous(breaks = c(10, 13, 16)) +
            facet_grid(~ label, labeller = parcel_labeller) +
            labs(x = '\nage', y = 'mean standardized parameter estimate\n',
                 color = '', fill = '') +
            dcbw +
            theme(legend.position = c(.1, .9),
                  legend.spacing.y = unit(.01, 'cm'),
                  legend.margin = unit(0, "cm"))
    })
}

# Run the application
shinyApp(ui = ui, server = server)
